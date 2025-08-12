import os
import sys
from pathlib import Path
from typing import Dict, Any, List
import tempfile
import shutil
from contextlib import asynccontextmanager
import urllib.request

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware

# Global variables
IS_RAILWAY = any([
    "RAILWAY_ENVIRONMENT" in os.environ,
    "RAILWAY_STATIC_URL" in os.environ,
    os.path.exists("/app")
])

if IS_RAILWAY:
    MODEL_PATH = "/app/models/best.pt"
else:
    MODEL_PATH = r"C:/Users/carlc/Desktop/API  AI REFEREE MODEL/runs/detect/train3/weights/best.pt"

MODEL_URL = os.getenv("MODEL_URL")
scorer_instance = None

# Try to import ML libraries
ML_AVAILABLE = False
IMPORT_ERROR = None
try:
    # Import the fix BEFORE importing basketball_referee
    try:
        import yolo_loader_fix
    except ImportError:
        print("Warning: yolo_loader_fix not found")

    import cv2
    from basketball_referee import ImprovedFreeThrowScorer, CVATDatasetConverter, FreeThrowModelTrainer

    ML_AVAILABLE = True
    print("✅ ML dependencies loaded successfully")
except Exception as e:
    IMPORT_ERROR = str(e)
    print(f"⚠️ ML dependencies not available: {e}")
    print("API will run in limited mode")


def download_model():
    """Download model from URL if not present"""
    if os.path.exists(MODEL_PATH):
        print(f"Model already exists at {MODEL_PATH}")
        return True

    if not MODEL_URL:
        print("Model not found locally and MODEL_URL not set")
        return False

    try:
        print(f"Downloading model from {MODEL_URL}")
        os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
        print("Model downloaded successfully")
        return True
    except Exception as e:
        print(f"Failed to download model: {e}")
        return False


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    global scorer_instance

    print("\n" + "=" * 60)
    print("🏀 AI BASKETBALL REFEREE API STARTING")
    print("=" * 60)
    print(f"Python version: {sys.version}")
    print(f"Platform: Railway" if IS_RAILWAY else "Local")
    print(f"Model path: {MODEL_PATH}")
    print(f"ML libraries available: {ML_AVAILABLE}")

    if not ML_AVAILABLE:
        print(f"Import error: {IMPORT_ERROR}")
        print("Running in LIMITED MODE - API endpoints only")
    else:
        # Try to download and load model
        if IS_RAILWAY and not os.path.exists(MODEL_PATH):
            download_model()

        if os.path.exists(MODEL_PATH):
            try:
                print("Loading model...")
                scorer_instance = ImprovedFreeThrowScorer(MODEL_PATH)
                print("✅ Model loaded successfully!")
            except Exception as e:
                print(f"❌ Failed to load model: {e}")

    print("=" * 60 + "\n")

    yield

    print("\nShutting down API...")


# Create FastAPI app
app = FastAPI(
    title="AI Basketball Referee API",
    description="Automated basketball free throw scoring",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint with status info."""
    railway_url = os.getenv("RAILWAY_STATIC_URL", "")

    return {
        "message": "🏀 AI Basketball Referee API",
        "status": "ready" if scorer_instance else "limited",
        "ml_available": ML_AVAILABLE,
        "model_loaded": scorer_instance is not None,
        "endpoints": {
            "root": "/",
            "status": "/status",
            "health": "/health",
            "docs": "/docs"
        },
        "deployment": {
            "platform": "railway" if IS_RAILWAY else "local",
            "url": f"https://{railway_url}" if railway_url else None
        },
        "error": IMPORT_ERROR if not ML_AVAILABLE else None
    }


@app.get("/status")
async def status():
    """Detailed status endpoint."""
    return {
        "api": "online",
        "ml_libraries": {
            "available": ML_AVAILABLE,
            "error": IMPORT_ERROR
        },
        "model": {
            "loaded": scorer_instance is not None,
            "path": MODEL_PATH,
            "exists": os.path.exists(MODEL_PATH),
            "url_set": bool(MODEL_URL)
        },
        "environment": {
            "platform": "railway" if IS_RAILWAY else "local",
            "python_version": sys.version.split()[0],
            "numpy_issue": "NumPy 2.x detected - need to downgrade to 1.x" if "NumPy 2" in (
                        IMPORT_ERROR or "") else None
        }
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/score_video/")
async def score_video(video_file: UploadFile = File(...)) -> Dict[str, Any]:
    """Analyze basketball video - only works if ML libraries are loaded."""

    if not ML_AVAILABLE:
        raise HTTPException(
            status_code=503,
            detail=f"ML libraries not available: {IMPORT_ERROR}. Please fix NumPy version."
        )

    if scorer_instance is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please set MODEL_URL environment variable."
        )

    # Video processing code here...
    return {"message": "Video processing endpoint"}


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))
    print(f"Starting server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)