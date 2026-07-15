import firebase_admin
from firebase_admin import credentials, firestore
from google.genai import types
from datetime import datetime, timezone

class FirestoreManager:
    def __init__(self):
        self.cred = credentials.Certificate("firebase_credentials.json")
        firebase_admin.initialize_app(credential=self.cred)
        self.db = firestore.client()

    def get_curr_summary(self, uid: str, chatid: str) -> str:
        try:
            chat_ref = self.db.collection("users").document(uid).collection("chats").document(chatid)

            doc = chat_ref.get()

            if doc.exists:
                data = doc.to_dict()
                headers = data.get("headers", {})
                if "running_summary" in headers:
                    return headers["running_summary"]
                
            chat_ref.set({"headers": {"running_summary": ""}}, merge=True)

            return ""

        except Exception as e:
            print(f"Error fetching/initializing summary: {e}")
            return ""    
    
    def set_curr_summary(self, uid: str, chatid: str, summary_text: str) -> None:
        try:
            current_summary = self.get_curr_summary(uid, chatid)

            if current_summary:
                updated_summary = f"{current_summary} {summary_text}"
            else:
                updated_summary = summary_text

            chat_ref = self.db.collection("users").document(uid).collection("chats").document(chatid)
            
            chat_ref.update({"headers.running_summary": updated_summary})

            print(f"Successfully updated summary for chat {chatid}")

        except Exception as e:
            print(f"Error: {e}")

    def fetch_chat_length(self, uid: str, chatid: str) -> int:
        try:
            messages_ref = self.db.collection("users").document(uid).collection("chats").document(chatid).collection("messages")

            query = messages_ref.count()
            results = query.get()
            
            count = results[0][0].value
            
            return count

        except Exception as e:
            print(f"Error fetching chat length: {e}")
            return 0
    

    def get_user_summary(self, uid: str) -> str:
        try:
            doc = self.db.collection("users").document(uid).get()
            user_dict = doc.to_dict() or {}
            
            return user_dict.get("aiSummary") or ""
            
        except Exception as e:
            print(f"Error: {e}")
            return ""

    def set_user_summary(self, uid: str, new_summary: str) -> None:
        try:
            current_summary = self.get_user_summary(uid)
            if current_summary:
                updated_summary = f"{current_summary} {new_summary}"
            else:
                updated_summary = new_summary

            user_ref = self.db.collection("users").document(uid)
            user_ref.set({'aiSummary': updated_summary}, merge=True)
            print(f"Successfully appended summary for user {uid}")
        except Exception as e:
            print(f"Error: {e}")
    

    def fetch_chat_history(self, uid: str, chatid: str, *args, limit: int):
        chat_ref = self.db.collection("users").document(uid).collection("chats").document(chatid)
        messages_query = chat_ref.collection("messages").order_by("timestamp", direction=firestore.Query.DESCENDING).limit(limit).get()
        history = []
        raw_msgs = reversed(list(messages_query)) 
        for msg in raw_msgs:
            m = msg.to_dict()
            role = "user" if m["isUser"] else "model"
            history.append(types.Content(role=role, parts=[types.Part.from_text(text=m["text"])]))
        if history and history[0].role != "user":
            history.pop(0)
        return history
    
    def fetch_chatrooms(self, uid: str):
        chatrooms = []
        chat_ref_stream = self.db.collection("users").document(uid).collection("chats").order_by("createdAt", direction=firestore.Query.ASCENDING).stream()

        for room in chat_ref_stream:
            room_data = room.to_dict()
            room_data["id"] = room.id
            if "createdAt" in room_data and room_data["createdAt"]:
                room_data["createdAt"] = room_data["createdAt"].isoformat()
            chatrooms.append(room_data)

        return chatrooms
    
    def fetch_messages(self, uid: str, chatid: str):
        serialized_messages = []
        messages_ref_stream = self.db.collection("users").document(uid).collection("chats").document(chatid).collection("messages").order_by("timestamp", direction=firestore.Query.ASCENDING).stream()
        
        for doc in messages_ref_stream:
            message_data = doc.to_dict()
            message_data["id"] = doc.id 
            
            if "timestamp" in message_data and message_data["timestamp"]:
                message_data["timestamp"] = message_data["timestamp"].isoformat()
                
            serialized_messages.append(message_data)
            
        return serialized_messages

    def delete_chatroom(self, uid: str, chatid: str):
        self.db.collection("users").document(uid).collection("chats").document(chatid).delete()
    
    def delete_messages(self, uid: str, chatid: str, messageids: list[str]):
        delete_batch = self.db.batch()
        chat_messages_ref = self.db.collection("users").document(uid).collection("chats").document(chatid).collection("messages")

        for messageid in messageids:
            chat_message = chat_messages_ref.document(messageid)
            delete_batch.delete(chat_message)
    
        delete_batch.commit()

    def save_new_message(self, text: str, uid: str, chatid: str, *args, is_user: bool):
        new_msg_ref = self.db.collection("users").document(uid).collection("chats").document(chatid).collection("messages").document()
        
        message_data = {"text": text, "isUser": is_user, "timestamp": datetime.now(timezone.utc)}
        
        new_msg_ref.set(message_data)
        message_data["id"] = new_msg_ref.id
        message_data["timestamp"] = message_data["timestamp"].isoformat()
        return message_data
    
    def create_chatroom(self, uid:str, title: str, bot_type: str):
        new_chatroom_ref = self.db.collection("users").document(uid).collection("chats").document()

        chatroom_data = {"createdAt": datetime.now(timezone.utc), "headers": {"title": title, "botType": bot_type}}

        new_chatroom_ref.set(chatroom_data)
        chatroom_data["id"] = new_chatroom_ref.id
        chatroom_data["createdAt"] = chatroom_data["createdAt"].isoformat()
        return chatroom_data

    def rename_chatroom(self, uid: str, chatid: str, new_name: str) -> None:
        chat_ref = self.db.collection("users").document(uid).collection("chats").document(chatid)
        chat_ref.update({"headers.title": new_name})
        print(f"Successfully renamed chat {chatid} to {new_name}")
    
    def add_new_user(self, uid: str, username: str, email: str):
        self.db.collection("users").document(uid).create({"username": username, "email": email})

    def get_user_details(self, uid: str):
        user_ref = self.db.collection("users").document(uid)
        user = user_ref.get().to_dict()
        return user
    
    def update_username(self, uid: str, *args, username):
        user_ref = self.db.collection("users").document(uid)
        user_ref.update({"username": username})
    
    def update_email(self, uid: str, *args, email):
        user_ref = self.db.collection("users").document(uid)
        user_ref.update({"email": email}) 