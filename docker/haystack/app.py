from fastapi import FastAPI
import requests
import os

app = FastAPI()
HAYSTACK_URL = os.environ.get("HAYSTACK_URL", "http://haystack:8000")

@app.get("/")
def root():
    return {"msg": "Custom Haystack API up & running!"}

@app.get("/haystack-health")
def haystack_health():
    try:
        r = requests.get(f"{HAYSTACK_URL}/health")
        return r.json()
    except Exception as e:
        return {"error": str(e)}