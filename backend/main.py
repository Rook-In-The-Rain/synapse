from fastapi import FastAPI, Request, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from google import genai
from llm_utils.cache_manager import CacheManager
from llm_utils.firebase_connector import FirestoreManager
from llm_utils.load_prompts import load_character_prompt, load_teacher_prompt
from contextlib import asynccontextmanager
from llm_core.llm_heart import ask_study_question, ask_relax_question
from dotenv import load_dotenv
import uvicorn, httpx, yaml


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Initializing Gemini Clients...zzzzz")
    import os
    load_dotenv()
    
    study_client = genai.Client(api_key=os.environ["TEACHER_API_KEY"])
    relaxer_client = genai.Client(api_key=os.environ["RELAXER_API_KEY"])
    app.state.relaxer_client = relaxer_client
    app.state.study_client = study_client

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    with open("app_config.yaml", "r") as file:
        config = yaml.safe_load(file)
        model = config["ai_models"]["study_model"]

    manager = CacheManager(study_client, model=model)
    app.state.cache_manager = manager
    app.state.firestore_manager = FirestoreManager()
    
    print("Startup Complete. App is ready :D")

    manager.list_all_caches()

    yield 

    print("Shutting down...zzzzz")

security = HTTPBearer()

async def verify_global_uid(request: Request, credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        request.state.uid = decoded_token["uid"]
        
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired, Please log in again."
        )
    except auth.InvalidIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid auth token"
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not verify auth credentials."
        )

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(lifespan=lifespan, dependencies=[Depends(verify_global_uid)])

@app.get("/")
def root():
    return "Hi! App Alive!"

def RIchat(chatid, request : Request):
    uid = request.state.uid
    client = request.app.state.relaxer_client
    prompt = load_character_prompt("RI_Mira")
    firestore = request.app.state.firestore_manager
    history = firestore.fetch_chat_history(uid, chatid, limit=20)
    prompt = prompt.replace("{{curr_user_summary}}", firestore.get_user_summary(uid))
    prompt = prompt.replace("{{curr_chat_summary}}", firestore.get_curr_summary(uid, chatid))
    resp_stream = ask_relax_question(client=client, system_instruction=prompt, chat_history=history, uid=uid, user_service=firestore, chatid=chatid)

    return StreamingResponse(resp_stream, media_type="text/plain")

def AIchat(chatid, model, request : Request):
    uid = request.state.uid
    client = request.app.state.study_client
    firestore = request.app.state.firestore_manager
    cache = request.app.state.cache_manager.get_cache_name(load_teacher_prompt(model))
    history = firestore.fetch_chat_history(uid, chatid, limit=10)
    resp_stream = ask_study_question(client=client, cache=cache, chat_history=history, uid=uid, chatid=chatid, firestore=firestore)
    
    return StreamingResponse(resp_stream, media_type="text/plain")

@app.post("/chatrooms/{chatid}/generate")
def generate_response(chatid: str, data: dict, request: Request):
    model = data.get("model")
    return AIchat(chatid, model, request) if model.startswith("A") else RIchat(chatid, request)

@app.post("/users")
def create_new_user(data: dict, request: Request):
    uid = request.state.uid
    firestore = request.app.state.firestore_manager
    username, email = data.get("username"), data.get("email")
    firestore.add_new_user(uid, username, email)
    return {"message": f"{username} added successfully!"}

@app.get("/users")
def get_user_details(request: Request):
    uid = request.state.uid
    firestore = request.app.state.firestore_manager
    user = firestore.get_user_details(uid)
    return user

@app.put("/users")
def update_user_details(data: dict, request: Request):
    uid = request.state.uid
    firestore = request.app.state.firestore_manager
    username = data.get("username")
    email = data.get("email")
    if username:
        firestore.update_username(uid, username=username)
    elif email:
        firestore.update_email(uid, email=email)
    return {"message": "details updated!"}

@app.post("/chatrooms/{chatid}/messages")
def save_message(chatid: str, data: dict, request: Request):
    firestore = request.app.state.firestore_manager
    uid = request.state.uid
    is_user = data.get("isUser")
    text = data.get("text")
    message_data = firestore.save_new_message(text, uid, chatid, is_user=is_user)
    return message_data

@app.post("/chatrooms")
def create_new_chatroom(data: dict, request: Request):
    firestore = request.app.state.firestore_manager
    uid = request.state.uid
    title = data.get("title")
    bot_type = data.get("botType")
    chatroom_data = firestore.create_chatroom(uid, title, bot_type)
    return chatroom_data

@app.get("/quote")
@limiter.limit("10/minute")
async def quote(request: Request):
    api_url = "https://zenquotes.io/api/random"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(api_url)
    
    if response.status_code == 200:
        data = response.json()
        return {
            "quote": data[0]["q"], 
            "author": data[0]["a"]
        }
    
    return {"quote": "padhlo chahe kahi se, selection hoga yahi se.", "author": "Alex Pendy"}

@app.get("/chatrooms")
def get_chatrooms(request: Request):
    firestore = request.app.state.firestore_manager
    uid = request.state.uid
    return {"chatrooms": firestore.fetch_chatrooms(uid)}

@app.get("/chatrooms/{chatid}/messages")
def get_chatroom_messages(chatid: str, request: Request):
    firestore = request.app.state.firestore_manager
    uid = request.state.uid  
    
    return {"messages": firestore.fetch_messages(uid, chatid)}

@app.delete("/chatrooms/{chatid}")
def delete_chatroom(chatid: str, request: Request):
    firestore = request.app.state.firestore_manager
    uid = request.state.uid 
    
    firestore.delete_chatroom(uid, chatid)
    
    return {"message": f"chatroom {chatid} has been deleted."}

@app.delete("/chatrooms/{chatid}/messages")
def delete_messages(chatid: str, data: dict, request: Request):
    uid = request.state.uid
    firestore = request.app.state.firestore_manager
    message_ids = data.get("messageIds")
    firestore.delete_messages(uid, chatid, message_ids)

    return {"message": f"messages {message_ids} in chatroom {chatid} deleted successfully"}

@app.put("/chatrooms/{chatid}/rename")
def rename_chatroom(chatid: str, data: dict, request: Request):
    uid = request.state.uid
    new_name = data.get("new_name")
    firestore = request.app.state.firestore_manager

    firestore.rename_chatroom(uid, chatid, new_name)

    return {"message": f"Chatroom renamed successfully"}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)