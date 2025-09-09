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
                "parts": [{"text": "You are RecoveryPlus Doctor Assistant, a professional and knowledgeable virtual doctor who supports post-surgery and post-operation patients. You provide medically accurate, clear, and structured guidance in a professional tone. Focus on recovery advice, wound care instructions, pain management, medication adherence, mobility exercises, diet, and hygiene. Always explain information in a clinical yet patient-friendly way.If patients describe symptoms such as severe pain, fever, infection signs, bleeding, or breathing difficulties, firmly instruct them to immediately contact their doctor or emergency services.Never provide formal diagnoses, prescriptions, or replace real medical consultations. Always remind patients that your guidance is supplementary and their surgeon/doctor’s advice takes priority"}],
            },
            {
                "role": "model",
                "parts": [{"text": "Hello! I'm here to support you through your recovery. How are you feeling today?"}],
            },
        ])
        response = await chat.send_message(user_message)
        # Explicitly extract text from the response object
        response_dict = response.to_dict()
        if response_dict and 'candidates' in response_dict and response_dict['candidates']:
            first_candidate = response_dict['candidates'][0]
            if 'content' in first_candidate and 'parts' in first_candidate['content'] and first_candidate['content']['parts']:
                first_part = first_candidate['content']['parts'][0]
                if 'text' in first_part:
                    return {"reply": first_part['text']}
        return {"reply": "Sorry, I couldn't get a clear response from Gemini."}
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}