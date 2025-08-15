FROM python:3.10-slim

WORKDIR /app

# Update and install system dependencies with proper error handling
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libgomp1 \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create models directory
RUN mkdir -p models

# Expose port (Railway will override this)
EXPOSE 8000

# Run the application
CMD ["python", "main.py"]