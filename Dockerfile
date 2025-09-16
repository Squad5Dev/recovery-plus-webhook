# Use an official Python runtime as a parent image
FROM python:3.10-slim-buster

# Install Tesseract OCR and its language data
RUN apt-get update && \
    apt-get install -y tesseract-ocr libtesseract-dev libleptonica-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed Python packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run the uvicorn server when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]