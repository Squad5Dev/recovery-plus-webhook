import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.generativeai import GenerativeModel

# Set the environment variable for Google Cloud credentials
# This is crucial for the Dialogflow client to find the credentials file.
# os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "dialogflow-credentials.json"

app = FastAPI()

# Add CORS middleware
origins = [
    "*" # Allow all origins for development. In production, restrict to your Flutter app's domain.
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

# Initialize Gemini API
# The API key will be provided via an environment variable in Render
model = GenerativeModel("gemini-1.5-flash")

@app.get("/")
def read_root():
    return {"status": "online"}

@app.post("/gemini-webhook")
async def gemini_webhook(request: ChatRequest):
    user_message = request.message

    try:
        # Start a new chat session (or retrieve existing one if needed for history)
        # For simplicity, we'll treat each request as a new turn for now.
        chat = model.start_chat(history=[])
        response = await chat.send_message(user_message)
        return {"reply": response.candidates[0].content.parts[0].text}
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}