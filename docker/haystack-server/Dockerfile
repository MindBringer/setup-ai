FROM python:3.11-slim

WORKDIR /app

# Haystack + Qdrant-Client + alle Extras
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Optional: configs, pipelines etc. kopieren
# COPY my_config.yml .

EXPOSE 8000

CMD ["python", "-m", "haystack.server"]