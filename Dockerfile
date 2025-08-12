FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir fastapi uvicorn[standard] python-multipart

# Install PyTorch CPU version
RUN pip install torch==2.0.1+cpu torchvision==0.15.2+cpu --extra-index-url https://download.pytorch.org/whl/cpu

# Install other dependencies
RUN pip install opencv-python-headless==4.8.1.78 ultralytics numpy pillow pyyaml scikit-learn requests

# Copy application
COPY . .

# Create models directory
RUN mkdir -p models

# Use Railway's PORT
CMD python main.py