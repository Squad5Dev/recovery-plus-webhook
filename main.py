import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from fastapi.responses import StreamingResponse

# Set the environment variable for Google Cloud credentials
# This is crucial for the Dialogflow client to find the credentials file.
# os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "dialogflow-credentials.json"

app = FastAPI()

# Add CORS middleware
origins = [
    os.environ.get("FRONTEND_URL", "*") # Allow all origins for development. In production, restrict to your Flutter app's domain.
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
model = genai.GenerativeModel(
    "gemini-1.5-flash",
    system_instruction="You are RecoveryPlus Doctor Assistant, a professional and knowledgeable virtual doctor who supports post-surgery and post-operation patients. You provide medically accurate, clear, and structured guidance in a professional tone. Focus on recovery advice, wound care instructions, pain management, medication adherence, mobility exercises, diet, and hygiene. Always explain information in a clinical yet patient-friendly way. If patients describe symptoms such as severe pain, fever, infection signs, bleeding, or breathing difficulties, firmly instruct them to immediately contact their doctor or emergency services. Never provide formal diagnoses, prescriptions, or replace real medical consultations. Always remind patients that your guidance is supplementary and their surgeon/doctor’s advice takes priority."
)

@app.get("/")
def read_root():
    return {"status": "online"}

async def stream_generator(response):
    async for chunk in response:
        if hasattr(chunk, "text"):
            yield chunk.text

@app.post("/gemini-webhook")
async def gemini_webhook(request: ChatRequest):
    user_message = request.message

    try:
        response = await model.generate_content_async(
            [
                {
                    "role": "model",
                    "parts": [
                        {"text": "Hello! I'm here to support you through your recovery. How are you feeling today?"}
                    ]
                },
                {
                    "role": "user",
                    "parts": [
                        {"text": user_message}
                    ]
                },
            ],
            stream=True
        )
        return StreamingResponse(stream_generator(response), media_type="text/plain")
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}
