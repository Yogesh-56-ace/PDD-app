import uuid
from datetime import datetime

class MockFirestoreCollection:
    def __init__(self, name, db):
        self.name = name
        self.db = db

    def document(self, doc_id=None):
        if not doc_id:
            doc_id = str(uuid.uuid4())
        return MockFirestoreDocument(self.name, doc_id, self.db)

    def where(self, field, op, value):
        # returns query builder
        return MockFirestoreQuery(self.name, field, op, value, self.db)

    def get(self):
        docs = []
        for doc_id, data in self.db.data.get(self.name, {}).items():
            docs.append(MockDocumentSnapshot(doc_id, data))
        return docs

class MockFirestoreDocument:
    def __init__(self, collection_name, doc_id, db):
        self.collection_name = collection_name
        self.id = doc_id
        self.db = db

    def get(self):
        data = self.db.data.get(self.collection_name, {}).get(self.id)
        return MockDocumentSnapshot(self.id, data)

    def set(self, data, merge=False):
        if self.collection_name not in self.db.data:
            self.db.data[self.collection_name] = {}
        
        # Preserve original id inside the record
        data['id'] = self.id
        if merge and self.id in self.db.data[self.collection_name]:
            self.db.data[self.collection_name][self.id].update(data)
        else:
            self.db.data[self.collection_name][self.id] = data
        return self

    def update(self, data):
        if self.collection_name in self.db.data and self.id in self.db.data[self.collection_name]:
            self.db.data[self.collection_name][self.id].update(data)
        return self

    def delete(self):
        if self.collection_name in self.db.data and self.id in self.db.data[self.collection_name]:
            del self.db.data[self.collection_name][self.id]
        return True

class MockFirestoreQuery:
    def __init__(self, collection_name, field, op, value, db):
        self.collection_name = collection_name
        self.field = field
        self.op = op
        self.value = value
        self.db = db

    def get(self):
        results = []
        all_docs = self.db.data.get(self.collection_name, {})
        for doc_id, data in all_docs.items():
            val = data.get(self.field)
            match = False
            if self.op == '==' and val == self.value:
                match = True
            elif self.op == '>' and val > self.value:
                match = True
            elif self.op == '<' and val < self.value:
                match = True
            elif self.op == 'array_contains' and isinstance(val, list) and self.value in val:
                match = True
            
            if match:
                results.append(MockDocumentSnapshot(doc_id, data))
        return results

    def order_by(self, field, direction='ASCENDING'):
        return self # simplified order_by support

    def limit(self, num):
        return self # simplified limit support

class MockDocumentSnapshot:
    def __init__(self, doc_id, data):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return self._data or {}

class MockFirestore:
    def __init__(self):
        self.data = {
            'users': {
                'demo_user_123': {
                    'user_id': 'demo_user_123',
                    'name': 'Yogesh',
                    'email': 'user@gmail.com',
                    'password_hash': '$2b$12$KNYhZ8zYI9m9x9X.7l8i5eW.h9dGpeQ.jP.1vQ3Y2t9k8h6q7.e7W' # pre-hashed 'password123'
                }
            },
            'settings': {
                'demo_user_123': {
                    'user_id': 'demo_user_123',
                    'audio_alert': True,
                    'sensitivity': 'medium',
                    'reminder_interval': 15
                }
            },
            'sessions': {}
        }

    def collection(self, name):
        return MockFirestoreCollection(name, self)
