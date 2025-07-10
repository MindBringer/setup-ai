FROM python:3.11-slim

# Arbeitsverzeichnis setzen
WORKDIR /app

# Systemtools + Buildtools für Python & Dokumentverarbeitung
RUN apt-get update && apt-get install -y \
    libmagic1 poppler-utils build-essential gcc \
    && rm -rf /var/lib/apt/lists/*

# Python-Requirements vorbereiten
COPY requirements.txt .

# pip-tools: Versionen einfrieren + saubere Installation
RUN pip install --no-cache-dir pip-tools \
    && pip-compile requirements.txt \
    && pip install --no-cache-dir -r requirements.lock

# Anwendungscode hinzufügen
COPY . /app

# Start der API mit Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8001"]
