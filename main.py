import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai

# Configure Gemini API with API key from env
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

app = FastAPI()

# Add CORS middleware
origins = [
    "*"  # Allow all origins for dev. In prod, restrict to your Flutter app's domain.
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define the request body model
class ChatRequest(BaseModel):
    sessionId: str
    message: str

# Initialize Gemini Model
model = genai.GenerativeModel("gemini-1.5-flash")

@app.get("/")
def read_root():
    return {"status": "online"}

@app.post("/gemini-webhook")
async def gemini_webhook(request: ChatRequest):
    user_message = request.message

    try:
        # Create a new chat for each request (stateless)
        chat = model.start_chat(history=[])
        response = chat.send_message(user_message)  # ✅ No await needed
        return {"reply": response.text}
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}