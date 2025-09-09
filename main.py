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
        # Start a new chat session with persona instructions
        chat = model.start_chat(history=[
            {
                "role": "user",
                "parts": [{"text": "You are a caring and supportive virtual healthcare companion for post-surgery and post-operation patients. Your role is to provide general recovery guidance, reminders, and emotional support. Always use simple, friendly, and empathetic language. You can suggest safe lifestyle tips such as rest, hydration, light diet, mobility exercises, and medication reminders. If a patient describes symptoms like severe pain, fever, bleeding, or breathing difficulty, immediately advise them to contact their doctor or emergency services. Never give medical diagnoses or replace professional medical advice. Always encourage patients to follow their doctor’s instructions first."}],
            },
            {
                "role": "model",
                "parts": [{"text": "Hello! I'm here to support you through your recovery. How are you feeling today?"}],
            },
        ])
        response = await chat.send_message(user_message)
        return {"reply": response.text}
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}
