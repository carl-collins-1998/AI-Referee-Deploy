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
    libglib2.0-0 \
    libgl1-mesa-glx \
    wget \
    && rm -rf /var/lib/apt/lists/*

# CRITICAL: Install and pin numpy 1.x FIRST
RUN pip install --no-cache-dir numpy==1.26.4

# Install PyTorch with CPU support (before ultralytics to avoid conflicts)
RUN pip install --no-cache-dir \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch==2.0.1+cpu \
    torchvision==0.15.2+cpu \
    --no-deps

# Install torch dependencies without upgrading numpy
RUN pip install --no-cache-dir \
    typing-extensions \
    sympy \
    networkx \
    jinja2 \
    filelock \
    --upgrade-strategy only-if-needed

# Install OpenCV and PIL
RUN pip install --no-cache-dir \
    opencv-python-headless==4.8.1.78 \
    pillow>=10.0.0 \
    --no-deps

# Install OpenCV dependencies
RUN pip install --no-cache-dir \
    --upgrade-strategy only-if-needed \
    numpy==1.26.4

# Install ultralytics dependencies BEFORE ultralytics
RUN pip install --no-cache-dir \
    matplotlib>=3.3.0 \
    pyyaml>=5.3.1 \
    requests>=2.23.0 \
    scipy>=1.4.1 \
    tqdm>=4.64.0 \
    pandas>=1.1.4 \
    seaborn>=0.11.0 \
    psutil \
    py-cpuinfo \
    thop>=0.1.1 \
    --upgrade-strategy only-if-needed

# Install ultralytics without dependencies
RUN pip install --no-cache-dir --no-deps ultralytics==8.0.200

# Install scikit-learn without upgrading numpy
RUN pip install --no-cache-dir \
    scikit-learn==1.3.2 \
    --no-deps

RUN pip install --no-cache-dir \
    joblib>=1.1.1 \
    threadpoolctl>=2.0.0 \
    scipy>=1.5.0 \
    --upgrade-strategy only-if-needed

# Install FastAPI and web server
RUN pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    python-multipart==0.0.6

# CRITICAL: Ensure numpy hasn't been upgraded
RUN pip install --no-cache-dir --force-reinstall numpy==1.26.4

# Verify numpy version
RUN python -c "import numpy; assert numpy.__version__.startswith('1.'), f'NumPy {numpy.__version__} is not 1.x'; print(f'NumPy version confirmed: {numpy.__version__}')"

# Copy application code
COPY . .

# Create the yolo_loader_fix.py if it doesn't exist
RUN echo 'import warnings\nwarnings.filterwarnings("ignore", message=".*NumPy.*")\nimport numpy as np\nprint(f"NumPy fix loaded: {np.__version__}")' > /app/yolo_loader_fix.py

# Create models directory
RUN mkdir -p /app/models

# Test that imports work
RUN python -c "import numpy; print(f'NumPy: {numpy.__version__}')" && \
    python -c "import torch; print(f'PyTorch: {torch.__version__}')" && \
    python -c "import cv2; print(f'OpenCV: {cv2.__version__}')" && \
    python -c "from ultralytics import YOLO; print('Ultralytics imported successfully')"

# Install all packages with constraints
RUN pip install --no-cache-dir -c constraints.txt -r requirements.txt

ENV PYTHONUNBUFFERED=1
ENV PORT=8000

EXPOSE 8000

CMD ["python", "main.py"]