import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.cloud import dialogflow

# Set the environment variable for Google Cloud credentials
# This is crucial for the Dialogflow client to find the credentials file.
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "dialogflow-credentials.json"

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

@app.get("/")
def read_root():
    return {"status": "online"}

@app.post("/dialogflow-webhook")
async def dialogflow_webhook(request: ChatRequest):
    project_id = "recovery-plus-46ec2"
    session_id = request.sessionId
    text = request.message
    language_code = "en-US"

    session_client = dialogflow.SessionsClient()
    session = session_client.session_path(project_id, session_id)

    text_input = dialogflow.TextInput(text=text, language_code=language_code)
    query_input = dialogflow.QueryInput(text=text_input)

    try:
        response = session_client.detect_intent(
            request={"session": session, "query_input": query_input}
        )
        fulfillment_text = response.query_result.fulfillment_text
        return {"reply": fulfillment_text}
    except Exception as e:
        print(f"Error: {e}")
        return {"reply": "Sorry, something went wrong."}
