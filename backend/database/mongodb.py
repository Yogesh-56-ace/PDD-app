import os
import sys
import json
import re
from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import PyMongoError, ServerSelectionTimeoutError, NetworkTimeout

# Configure stdout for UTF-8 to support emoji on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# 1. Load environment variables from .env file
load_dotenv()
backend_env = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
if os.path.exists(backend_env):
    load_dotenv(backend_env)

MONGO_URI = os.environ.get('MONGO_URI')
DB_NAME = os.environ.get('DB_NAME', 'posture_ai')
LOCAL_STORAGE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'local_db_store.json')


class LocalCollectionFallback:
    """Persistent local JSON collection fallback when MongoDB Atlas IP whitelist or network blocks connection."""
    def __init__(self, collection_name, storage_file):
        self.name = collection_name
        self.storage_file = storage_file

    def _load_all(self):
        if os.path.exists(self.storage_file):
            try:
                with open(self.storage_file, 'r', encoding='utf-8') as f:
                    return json.load(f).get(self.name, [])
            except Exception:
                return []
        return []

    def _save_all(self, docs):
        data = {}
        if os.path.exists(self.storage_file):
            try:
                with open(self.storage_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
            except Exception:
                data = {}
        data[self.name] = docs
        with open(self.storage_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str)

    def find_one(self, filter_dict=None):
        results = self.find(filter_dict)
        return results[0] if results else None

    def find(self, filter_dict=None):
        docs = self._load_all()
        if not filter_dict:
            return docs

        matched = []
        for doc in docs:
            match = True
            for key, expected in filter_dict.items():
                if isinstance(expected, dict) and '$regex' in expected:
                    pattern = expected['$regex']
                    flags = re.IGNORECASE if expected.get('$options') == 'i' else 0
                    val = str(doc.get(key, ''))
                    if not re.search(pattern, val, flags):
                        match = False
                        break
                elif doc.get(key) != expected:
                    match = False
                    break
            if match:
                matched.append(doc)
        return matched

    def insert_one(self, doc):
        docs = self._load_all()
        doc_copy = dict(doc)
        if '_id' not in doc_copy:
            doc_copy['_id'] = doc_copy.get('user_id', str(len(docs) + 1))
        docs.append(doc_copy)
        self._save_all(docs)
        
        class InsertResult:
            def __init__(self, inserted_id):
                self.inserted_id = inserted_id
                self.acknowledged = True
        return InsertResult(doc_copy['_id'])

    def update_one(self, filter_dict, update_dict, upsert=False):
        docs = self._load_all()
        found = False
        set_vals = update_dict.get('$set', update_dict)
        for i, doc in enumerate(docs):
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                docs[i].update(set_vals)
                found = True
                break
        if not found and upsert:
            new_doc = dict(filter_dict)
            new_doc.update(set_vals)
            if '_id' not in new_doc:
                new_doc['_id'] = new_doc.get('user_id', str(len(docs) + 1))
            docs.append(new_doc)
        self._save_all(docs)

    def replace_one(self, filter_dict, replacement, upsert=False):
        docs = self._load_all()
        found = False
        for i, doc in enumerate(docs):
            match = True
            for k, v in filter_dict.items():
                if doc.get(k) != v:
                    match = False
                    break
            if match:
                docs[i] = dict(replacement)
                found = True
                break
        if not found and upsert:
            docs.append(dict(replacement))
        self._save_all(docs)


class ResilientMongoCollection:
    """Wrapper that routes to PyMongo Atlas when online, or Local JSON fallback when Atlas times out."""
    def __init__(self, real_collection, collection_name, storage_file):
        self.real_collection = real_collection
        self.name = collection_name
        self.fallback = LocalCollectionFallback(collection_name, storage_file)

    def find_one(self, filter_dict=None):
        try:
            return self.real_collection.find_one(filter_dict)
        except (ServerSelectionTimeoutError, NetworkTimeout, PyMongoError) as e:
            print(f"[WARN] Atlas unreachable ({e}), executing find_one on local fallback '{self.name}'.")
            return self.fallback.find_one(filter_dict)

    def find(self, filter_dict=None):
        try:
            return list(self.real_collection.find(filter_dict or {}))
        except (ServerSelectionTimeoutError, NetworkTimeout, PyMongoError) as e:
            print(f"[WARN] Atlas unreachable ({e}), executing find on local fallback '{self.name}'.")
            return self.fallback.find(filter_dict)

    def insert_one(self, doc):
        try:
            return self.real_collection.insert_one(doc)
        except (ServerSelectionTimeoutError, NetworkTimeout, PyMongoError) as e:
            print(f"[WARN] Atlas unreachable ({e}), executing insert_one on local fallback '{self.name}'.")
            return self.fallback.insert_one(doc)

    def update_one(self, filter_dict, update_dict, upsert=False):
        try:
            return self.real_collection.update_one(filter_dict, update_dict, upsert=upsert)
        except (ServerSelectionTimeoutError, NetworkTimeout, PyMongoError) as e:
            print(f"[WARN] Atlas unreachable ({e}), executing update_one on local fallback '{self.name}'.")
            return self.fallback.update_one(filter_dict, update_dict, upsert=upsert)

    def replace_one(self, filter_dict, replacement, upsert=False):
        try:
            return self.real_collection.replace_one(filter_dict, replacement, upsert=upsert)
        except (ServerSelectionTimeoutError, NetworkTimeout, PyMongoError) as e:
            print(f"[WARN] Atlas unreachable ({e}), executing replace_one on local fallback '{self.name}'.")
            return self.fallback.replace_one(filter_dict, replacement, upsert=upsert)


class ResilientMongoDatabase:
    """Resilient database proxy ensuring zero connection timeout crashes and multi-tier fallback."""
    def __init__(self, uri, db_name):
        self.db_name = db_name
        self.active_type = "JSONFallback"
        self.atlas_client = None
        self.atlas_db = None

        # 1. Try primary URI (Atlas)
        if uri:
            try:
                c = MongoClient(uri, serverSelectionTimeoutMS=2500, connectTimeoutMS=2500)
                c.admin.command('ping')
                self.atlas_client = c
                self.atlas_db = c[db_name]
                self.active_type = "Atlas"
                print(f"✅ [DB] Connected successfully to MongoDB Atlas Cloud ('{db_name}')")
            except Exception as e:
                print(f"⚠️ [DB] Atlas cloud connection unavailable ({e})")

        # 2. Try local MongoDB service if Atlas was unavailable
        if not self.atlas_db:
            local_uri = os.environ.get('LOCAL_MONGO_URI', 'mongodb://localhost:27017')
            try:
                c = MongoClient(local_uri, serverSelectionTimeoutMS=2000, connectTimeoutMS=2000)
                c.admin.command('ping')
                self.atlas_client = c
                self.atlas_db = c[db_name]
                self.active_type = "LocalMongo"
                print(f"✅ [DB] Connected successfully to Local MongoDB Service at {local_uri} ('{db_name}')")
            except Exception as e:
                print(f"⚠️ [DB] Local MongoDB service unavailable ({e}). Using resilient JSON fallback.")
                c = MongoClient(uri or local_uri, serverSelectionTimeoutMS=1000, connectTimeoutMS=1000)
                self.atlas_client = c
                self.atlas_db = c[db_name]

        self._collections = {}

    def __getitem__(self, name):
        return self.get_collection(name)

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        return self.get_collection(name)

    def get_collection(self, name):
        if name not in self._collections:
            self._collections[name] = ResilientMongoCollection(
                self.atlas_db[name], name, LOCAL_STORAGE_FILE
            )
        return self._collections[name]

    def list_collection_names(self):
        try:
            return self.atlas_db.list_collection_names()
        except Exception:
            return ['users', 'reports', 'history', 'settings']


# Initialize resilient database instance
db = ResilientMongoDatabase(MONGO_URI, DB_NAME)
client = db.atlas_client

# Target collections
users_collection = db['users']
reports_collection = db['reports']
history_collection = db['history']
settings_collection = db['settings']

