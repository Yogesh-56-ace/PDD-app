import os
import uuid
from pymongo import MongoClient

class MongoDocumentSnapshot:
    def __init__(self, doc_id, data):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        if not self._data:
            return {}
        # Remove BSON ObjectId to prevent JSON serialization issues
        res = dict(self._data)
        if '_id' in res:
            del res['_id']
        return res

class MongoFirestoreDocument:
    def __init__(self, collection_name, doc_id, client):
        self.collection_name = collection_name
        self.id = doc_id
        self.client = client
        self.collection = client.db[collection_name]

    def get(self):
        data = self.collection.find_one({'_id': self.id})
        return MongoDocumentSnapshot(self.id, data)

    def set(self, data, merge=False):
        # Keep consistent with mock_firebase preservation of id
        data['id'] = self.id
        data['_id'] = self.id
        
        if merge:
            self.collection.update_one({'_id': self.id}, {'$set': data}, upsert=True)
        else:
            self.collection.replace_one({'_id': self.id}, data, upsert=True)
        return self

    def update(self, data):
        self.collection.update_one({'_id': self.id}, {'$set': data}, upsert=True)
        return self

    def delete(self):
        self.collection.delete_one({'_id': self.id})
        return True

class MongoFirestoreQuery:
    def __init__(self, collection_name, client, query_filter=None, sort_field=None, sort_dir=1, limit_num=None):
        self.collection_name = collection_name
        self.client = client
        self.collection = client.db[collection_name]
        self.query_filter = query_filter or {}
        self.sort_field = sort_field
        self.sort_dir = sort_dir
        self.limit_num = limit_num

    def where(self, field, op, value):
        # Emulate firestore operators
        mongo_op = None
        if op == '==':
            mongo_op = value
        elif op == '>':
            mongo_op = {'$gt': value}
        elif op == '<':
            mongo_op = {'$lt': value}
        elif op == 'array_contains':
            # Mongo matches values inside arrays directly
            mongo_op = value
            
        new_filter = dict(self.query_filter)
        if mongo_op is not None:
            new_filter[field] = mongo_op
            
        return MongoFirestoreQuery(
            self.collection_name, 
            self.client, 
            new_filter, 
            self.sort_field, 
            self.sort_dir, 
            self.limit_num
        )

    def order_by(self, field, direction='ASCENDING'):
        s_dir = 1 if direction == 'ASCENDING' else -1
        return MongoFirestoreQuery(
            self.collection_name, 
            self.client, 
            self.query_filter, 
            field, 
            s_dir, 
            self.limit_num
        )

    def limit(self, num):
        return MongoFirestoreQuery(
            self.collection_name, 
            self.client, 
            self.query_filter, 
            self.sort_field, 
            self.sort_dir, 
            num
        )

    def get(self):
        cursor = self.collection.find(self.query_filter)
        if self.sort_field:
            cursor = cursor.sort(self.sort_field, self.sort_dir)
        if self.limit_num:
            cursor = cursor.limit(self.limit_num)
            
        docs = []
        for doc in cursor:
            doc_id = doc.get('id', str(doc.get('_id', '')))
            docs.append(MongoDocumentSnapshot(doc_id, doc))
        return docs

class MongoFirestoreCollection:
    def __init__(self, name, client):
        self.name = name
        self.client = client
        self.collection = client.db[name]

    def document(self, doc_id=None):
        if not doc_id:
            doc_id = str(uuid.uuid4())[:8]
        return MongoFirestoreDocument(self.name, doc_id, self.client)

    def where(self, field, op, value):
        query = MongoFirestoreQuery(self.name, self.client)
        return query.where(field, op, value)

    def get(self):
        cursor = self.collection.find({})
        docs = []
        for doc in cursor:
            doc_id = doc.get('id', str(doc.get('_id', '')))
            docs.append(MongoDocumentSnapshot(doc_id, doc))
        return docs

class MongoFirestore:
    def __init__(self, uri, db_name="posture_fix_pro"):
        self.client = MongoClient(uri)
        self.db = self.client[db_name]
        print(f"[INFO] Successfully connected to MongoDB Atlas database '{db_name}'.")

    def collection(self, name):
        return MongoFirestoreCollection(name, self)
