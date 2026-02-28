from fastapi import FastAPI, File, UploadFile, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import credentials, initialize_app, auth
from ultralytics import YOLO
from pymongo import MongoClient
from datetime import datetime
import shutil
import os
import uuid

app = FastAPI(title="CivicSense AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

cred = credentials.Certificate("serviceAccountKey.json")
initialize_app(cred)

MONGO_URI = "your_mongodb_uri"

client = MongoClient(MONGO_URI)
db = client["civicsense"]
collection = db["detections"]

model = YOLO("yolov8n.pt")


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        token = credentials.credentials
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


@app.get("/")
def home():
    return {"status": "Backend running successfully"}


@app.post("/detect")
async def detect_image(
    file: UploadFile = File(...),
    user=Depends(verify_token),
):
    try:
        unique_id = str(uuid.uuid4())
        file_path = f"temp_{unique_id}.jpg"

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        results = model(file_path)

        detections = []

        for r in results:
            for box in r.boxes:
                confidence = float(box.conf)
                if confidence < 0.4:
                    continue

                detections.append({
                    "class": model.names[int(box.cls)],
                    "confidence": round(confidence, 2)
                })

        os.remove(file_path)

        record = {
            "user_id": user["uid"],
            "timestamp": datetime.utcnow(),
            "total_objects": len(detections),
            "detections": detections
        }

        collection.insert_one(record)

        return {
            "status": "success",
            "user_id": user["uid"],
            "total_objects": len(detections),
            "detections": detections
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/history")
def get_user_history(user=Depends(verify_token)):
    records = list(
        collection.find(
            {"user_id": user["uid"]},
            {"_id": 0}
        ).sort("timestamp", -1)
    )

    return {
        "status": "success",
        "count": len(records),
        "data": records
    }
@app.post("/detect")
async def detect_image(
    file: UploadFile = File(...),
    latitude: float = None,
    longitude: float = None,
    user=Depends(verify_token),
):
    try:
        unique_id = str(uuid.uuid4())
        file_path = f"temp_{unique_id}.jpg"

        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        results = model(file_path)

        detections = []

        for r in results:
            for box in r.boxes:
                confidence = float(box.conf)

                if confidence < 0.4:
                    continue

                detections.append({
                    "class": model.names[int(box.cls)],
                    "confidence": round(confidence, 2)
                })

        os.remove(file_path)

        # ==============================
        # RISK SCORE CALCULATION
        # ==============================
        risk_score = len(detections)

        risk_level = "Low"
        if risk_score >= 5:
            risk_level = "High"
        elif risk_score >= 3:
            risk_level = "Medium"

        # ==============================
        # SAVE TO MONGODB
        # ==============================
        record = {
            "user_id": user["uid"],
            "timestamp": datetime.utcnow(),
            "latitude": latitude,
            "longitude": longitude,
            "risk_level": risk_level,
            "total_objects": len(detections),
            "detections": detections
        }

        collection.insert_one(record)

        return {
            "status": "success",
            "user_id": user["uid"],
            "latitude": latitude,
            "longitude": longitude,
            "risk_level": risk_level,
            "total_objects": len(detections),
            "detections": detections
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))