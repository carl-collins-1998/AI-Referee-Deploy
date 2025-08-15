FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1-mesa-glx \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a constraints file to lock numpy version
RUN echo "numpy==1.26.4" > /app/constraints.txt

# Install numpy first with explicit version
RUN pip install --no-cache-dir numpy==1.26.4

# Install core dependencies
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    python-multipart==0.0.6 \
    pyyaml==6.0.1 \
    requests==2.31.0 \
    pillow>=10.0.0

# Install PyTorch CPU (this is compatible with numpy 1.x)
RUN pip install --no-cache-dir \
    torch==2.1.0 \
    torchvision==0.16.0 \
    --index-url https://download.pytorch.org/whl/cpu

# Install OpenCV
RUN pip install --no-cache-dir opencv-python-headless==4.8.1.78

# Install scikit-learn and its dependencies
RUN pip install --no-cache-dir \
    scikit-learn==1.3.2 \
    scipy==1.11.4 \
    joblib==1.3.2 \
    threadpoolctl==3.2.0

# Install matplotlib and dependencies for ultralytics
RUN pip install --no-cache-dir \
    matplotlib==3.7.2 \
    pandas==2.0.3 \
    seaborn==0.12.2 \
    tqdm==4.66.1 \
    psutil==5.9.5

# Finally install ultralytics with constraint
RUN pip install --no-cache-dir -c /app/constraints.txt ultralytics==8.0.200

# Verify numpy hasn't been upgraded
RUN python -c "import numpy as np; assert np.__version__ == '1.26.4', f'NumPy version is {np.__version__}, expected 1.26.4'"

# Copy application files
COPY . .

# Create models directory
RUN mkdir -p /app/models

# Quick test of imports
RUN python -c "import warnings; warnings.filterwarnings('ignore'); import numpy; print(f'NumPy: {numpy.__version__}')"
RUN python -c "import warnings; warnings.filterwarnings('ignore'); import torch; print(f'PyTorch: {torch.__version__}')"
RUN python -c "import warnings; warnings.filterwarnings('ignore'); import cv2; print(f'OpenCV: {cv2.__version__}')"

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONWARNINGS=ignore
ENV PORT=8000

EXPOSE 8000

CMD ["python", "main.py"]