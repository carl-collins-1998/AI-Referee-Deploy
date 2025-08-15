FROM python:3.10-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Fix apt sources and install dependencies
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    wget && \
    rm -rf /var/lib/apt/lists/*


# Set the working directory
WORKDIR /app

# Copy requirements first to leverage Docker caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose port (change if your FastAPI runs on another port)
EXPOSE 8000

# Run FastAPI app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
