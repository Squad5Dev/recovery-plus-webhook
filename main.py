import os
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from fastapi.responses import StreamingResponse, JSONResponse
import json
import base64
import requests

import io

# Set the environment variable for Google Cloud credentials
# This is crucial for the Dialogflow client to find the credentials file.
# os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "dialogflow-credentials.json"

app = FastAPI()

# Add CORS middleware
origins = [
    os.environ.get("FRONTEND_URL", "http://localhost:3000")  # In production, replace with your Flutter app's domain.
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
    "models/gemini-1.5-flash",
    system_instruction=(
        "You are RecoveryPlus Doctor Assistant, a professional and knowledgeable virtual doctor who supports "
        "post-surgery and post-operation patients. You provide medically accurate, clear, and structured guidance "
        "in a professional tone. Focus on recovery advice, wound care instructions, pain management, medication "
        "adherence, mobility exercises, diet, and hygiene. Always explain information in a clinical yet patient-friendly way. "
        "If patients describe symptoms such as severe pain, fever, infection signs, bleeding, or breathing difficulties, "
        "firmly instruct them to immediately contact your doctor or emergency services. Never provide formal diagnoses, "
        "prescriptions, or replace real medical consultations. Always remind patients that your guidance is supplementary "
        "and their surgeon/doctor’s advice takes priority."
    )
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
        print(f"Error generating content: {e}")
        return JSONResponse(status_code=500, content={"error": "An error occurred while processing your request."})

class PrescriptionRequest(BaseModel):
    image: UploadFile

@app.post("/process_prescription")
async def process_prescription(image: UploadFile = File(...)):
    # OCR.space API Key (replace with your actual key)
    ocr_space_api_key = "K81353006888957" # User provided API key
    ocr_space_api_url = "https://api.ocr.space/parse/image"

    try:
        image_data = await image.read()
        
        # Convert image to base64
        base64_image = base64.b64encode(image_data).decode('utf-8')

        payload = {
            'base64Image': 'data:image/jpeg;base64,' + base64_image,
            'language': 'eng',
            'isOverlayRequired': False,
            'OCREngine': 2, # Use OCR Engine 2 for better handwriting recognition
        }
        headers = {
            'apikey': ocr_space_api_key,
        }

        ocr_response = requests.post(ocr_space_api_url, data=payload, headers=headers)
        ocr_response.raise_for_status() # Raise an exception for HTTP errors
        ocr_result = ocr_response.json()

        if ocr_result and ocr_result['ParsedResults']:
            extracted_text = ocr_result['ParsedResults'][0]['ParsedText']
        else:
            extracted_text = ""

        if not extracted_text.strip():
            return JSONResponse(status_code=400, content={"error": "No text found in the image by OCR."})

        # Configure the Gemini API key from environment variable
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

        # Create a GenerativeModel instance for this specific task
        extraction_model = genai.GenerativeModel("models/gemini-1.5-flash-latest")

        prompt = f'''You are an expert at digitizing medical prescriptions. Your task is to extract structured information from the prescription text provided.
        The prescription may contain multiple medications and exercises.

        For each medication, you must extract:
        - "name": The name of the medication.
        - "dosage": The amount of the medication to be taken at one time (e.g., "1 tablet", "500 mg", "3 mL").
        - "timings": A list of specific times (in 24-hour format, e.g., "08:00", "14:30") the medication should be taken.
            - If explicit times are mentioned (e.g., "8 AM", "7:00 to 8:45"), use those. Convert to 24-hour format if necessary.
            - If frequency is mentioned but no explicit times, infer timings based on common patterns:
                - "once daily" or "OD": ["09:00"]
                - "twice daily" or "BID": ["09:00", "21:00"]
                - "thrice daily" or "TID": ["09:00", "14:00", "21:00"]
                - "four times a day" or "QID": ["06:00", "12:00", "18:00", "24:00"]
                - "as needed" or "SOS": [] (empty list)
            - If no frequency or explicit times are mentioned, default to an empty list [].

        For each exercise, you must extract:
        - "name": The name of the exercise.
        - "duration": How long the exercise should be performed (e.g., "15 minutes", "30 seconds").
        - "frequency": How often the exercise should be performed (e.g., "twice a day", "3 times a week").

        **Important Instructions:**
        - The medication name, dosage, and timings may not be on the same line. Look at the surrounding lines to find the related information.
        - Pay close attention to common medical abbreviations (e.g., OD for once a day, BID for twice a day, QID for four times a day, SOS for as needed, etc.).
        - If a piece of information is not present, leave the corresponding value as null (except for timings, which should be an empty list if not found or inferred).
        - Return the extracted information in a clean, valid JSON format, with no extra text or markdown.

        **Example 1 Prescription:**
        Medication: Amoxicillin 500mg, take 1 capsule three times a day after meals.
        Exercise: Light stretching, 10 minutes, morning and evening.
        Medication: Ibuprofen 200mg, take 1 tablet as needed for pain.

        **Example 1 JSON Output:**
        {{
          "medications": [
            {{"name": "Amoxicillin", "dosage": "500mg", "timings": ["after meals"]}},
            {{"name": "Ibuprofen", "dosage": "200mg", "timings": []}}
          ],
          "exercises": [
            {{"name": "Light stretching", "duration": "10 minutes", "frequency": "morning and evening"}}
          ]
        }}

        **Example 2 Prescription:**
        Medication: Aspirin 100mg, take 1 tablet daily at 7:00 AM.
        Medication: Vitamin D, 1 capsule, once a week.
        Exercise: Arm circles, 5 minutes, 3 times a day (9 AM, 1 PM, 5 PM).

        **Example 2 JSON Output:**
        {{
          "medications": [
            {{"name": "Aspirin", "dosage": "100mg", "timings": ["07:00"]}},
            {{"name": "Vitamin D", "dosage": "1 capsule", "timings": ["once a week"]}}
          ],
          "exercises": [
            {{"name": "Arm circles", "duration": "5 minutes", "frequency": "3 times a day"}}
          ]
        }}

        **Example 1 Prescription:**
        Medication: Amoxicillin 500mg, take 1 capsule three times a day after meals.
        Exercise: Light stretching, 10 minutes, morning and evening.
        Medication: Ibuprofen 200mg, take 1 tablet as needed for pain.

        **Example 1 JSON Output:**
        {{
          "medications": [
            {"name": "Amoxicillin", "dosage": "500mg", "timings": ["09:00", "14:00", "19:00"]},
            {"name": "Ibuprofen", "dosage": "200mg", "timings": []}
          ],
          "exercises": [
            {"name": "Light stretching", "duration": "10 minutes", "frequency": "morning and evening"}
          ]
        }}

        **Example 2 Prescription:**
        Medication: Aspirin 100mg, take 1 tablet daily at 7:00 AM.
        Medication: Vitamin D, 1 capsule, once a week.
        Exercise: Arm circles, 5 minutes, 3 times a day (9 AM, 1 PM, 5 PM).

        **Example 2 JSON Output:**
        {{
          "medications": [
            {{"name": "Aspirin", "dosage": "100mg", "timings": ["07:00"]}},
            {{"name": "Vitamin D", "dosage": "1 capsule", "timings": []}}
          ],
          "exercises": [
            {{"name": "Arm circles", "duration": "5 minutes", "frequency": "3 times a day"}}
          ]
        }}

        Prescription:
        {extracted_text}
        '''

        response = await extraction_model.generate_content_async(prompt)

        # Assuming the response is a single text part containing the JSON string
        extracted_json_str = response.text
        print(f"Extracted JSON string: {extracted_json_str}")

        try:
            start = extracted_json_str.index('{')
            end = extracted_json_str.rindex('}') + 1
            json_str = extracted_json_str[start:end]
            return json.loads(json_str)
        except ValueError:
            return JSONResponse(status_code=500, content={"error": "Could not find JSON in the response."})

    except Exception as e:
        print(f"Error processing prescription: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})
