FROM python:3.10-slim

WORKDIR /app

# Install system dependencies (e.g. libmagic for filetype detection)
RUN apt-get update && apt-get install -y \
    build-essential \
    libmagic1 \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
