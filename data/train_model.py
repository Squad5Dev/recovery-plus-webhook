import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from joblib import dump

# Load the data
df = pd.read_csv('sample_data.csv')

# Create a pipeline with a TfidfVectorizer and a LogisticRegression model
pipeline = make_pipeline(
    TfidfVectorizer(),
    LogisticRegression()
)

# Train the model
pipeline.fit(df['symptom'], df['response'])

# Save the model
dump(pipeline, 'model.joblib')

print("Model trained and saved as model.joblib")
