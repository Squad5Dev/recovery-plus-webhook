import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from fastapi.responses import StreamingResponse
from fastapi.responses import JSONResponse
import json

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

class PrescriptionRequest(BaseModel):
    prescription_text: str

# Initialize Gemini API
# The API key will be provided via an environment variable in Render
model = genai.GenerativeModel(
    "models/gemini-1.5-flash",
    system_instruction="You are RecoveryPlus Doctor Assistant, a professional and knowledgeable virtual doctor who supports post-surgery and post-operation patients. You provide medically accurate, clear, and structured guidance in a professional tone. Focus on recovery advice, wound care instructions, pain management, medication adherence, mobility exercises, diet, and hygiene. Always explain information in a clinical yet patient-friendly way. If patients describe symptoms such as severe pain, fever, infection signs, bleeding, or breathing difficulties, firmly instruct them to immediately contact your doctor or emergency services. Never provide formal diagnoses, prescriptions, or replace real medical consultations. Always remind patients that your guidance is supplementary and their surgeon/doctor’s advice takes priority."
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

@app.post("/process_prescription")
async def process_prescription(request: PrescriptionRequest):
    prescription_text = request.prescription_text
    try:
        # Configure the Gemini API key from environment variable
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

        # Create a GenerativeModel instance for this specific task
        # Using gemini-pro for structured data extraction
        extraction_model = genai.GenerativeModel("models/gemini-1.5-flash-latest")

        prompt = f'''You are an expert at digitizing medical prescriptions. Your task is to extract structured information from the prescription text provided.
The prescription may contain multiple medications and exercises.

For each medication, you must extract:
- "name": The name of the medication.
- "dosage": The amount of the medication to be taken at one time (e.g., "1 tablet", "500 mg", "3 mL").
- "frequency": How often the medication should be taken (e.g., "once daily", "every 6 hours", "as needed").
- "time_of_day": Specific times the medication should be taken, if mentioned (e.g., "morning", "evening", "8 AM", "before bed"). If not specified, infer from frequency or leave as null.

For each exercise, you must extract:
- "name": The name of the exercise.
- "duration": How long the exercise should be performed (e.g., "15 minutes", "30 seconds").
- "frequency": How often the exercise should be performed (e.g., "twice a day", "3 times a week").

**Important Instructions:**
- The medication name, dosage, frequency, and time_of_day may not be on the same line. Look at the surrounding lines to find the related information.
- Pay close attention to common medical abbreviations (e.g., OD for once a day, BID for twice a day, QID for four times a day, SOS for as needed, etc.).
- If a piece of information is not present, leave the corresponding value as null.
- Return the extracted information in a clean, valid JSON format, with no extra text or markdown.

**Example 1 Prescription:**
Medication: Amoxicillin 500mg, take 1 capsule three times a day after meals.
Exercise: Light stretching, 10 minutes, morning and evening.
Medication: Ibuprofen 200mg, take 1 tablet as needed for pain.

**Example 1 JSON Output:**
{{
  "medications": [
    {{"name": "Amoxicillin", "dosage": "500mg", "frequency": "three times a day", "time_of_day": "after meals"}},
    {{"name": "Ibuprofen", "dosage": "200mg", "frequency": "as needed", "time_of_day": null}}
  ],
  "exercises": [
    {{"name": "Light stretching", "duration": "10 minutes", "frequency": "morning and evening"}}
  ]
}}

Return the data in the following JSON format:
{{
  "medications": [{{"name": "", "dosage": "", "frequency": "", "time_of_day": ""}}],
  "exercises": [{{'name': '', 'duration': '', 'frequency': ''}}]
}}

Prescription:
{prescription_text}
'''
        
        response = await extraction_model.generate_content_async(prompt)
        
        # Assuming the response is a single text part containing the JSON string
        extracted_json_str = response.text
        print(f"Extracted JSON string: {extracted_json_str}")

        # Find the start and end of the JSON
        try:
            start = extracted_json_str.index('{')
            end = extracted_json_str.rindex('}') + 1
            json_str = extracted_json_str[start:end]
            return json.loads(json_str)
        except ValueError:
            # Handle case where '{' or '}' are not in the string
            return JSONResponse(status_code=500, content={"error": "Could not find JSON in the response."})

    except Exception as e:
        print(f"Error processing prescription: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})
