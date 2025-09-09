# Post-Surgery Healthcare Chatbot API

This is a simple chatbot API that provides responses to post-surgery symptoms.

## How to run the application

1. **Build the Docker image:**

   ```bash
   docker build -t post-surgery-chatbot-api .
   ```

2. **Run the Docker container:**

   ```bash
   docker run -d -p 8000:8000 --name chatbot-api post-surgery-chatbot-api
   ```

## How to use the API

You can use `curl` or any other API client to interact with the API.

### Get the root endpoint

```bash
curl http://localhost:8000/
```

**Response:**

```json
{"message":"Welcome to the Post-Surgery Healthcare Chatbot API"}
```

### Get a prediction

```bash
curl -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d '{"symptom": "I have a fever"}'
```

**Response:**

```json
{"response":"It is normal to have a low-grade fever after surgery. However, if it persists or goes above 101°F (38.3°C), please contact your doctor."}
```

## How to stop and remove the container

```bash
docker stop chatbot-api
docker rm chatbot-api
```
