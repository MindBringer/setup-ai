from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from haystack import Pipeline
from haystack.dataclasses import Document
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
from haystack.components.embedders import SentenceTransformersDocumentEmbedder, SentenceTransformersTextEmbedder
from haystack.components.retrievers import DensePassageRetriever

import os
import tempfile

app = FastAPI()

# Qdrant als DocumentStore (mit persistenter Datenbank, anpassbar)
QDRANT_URL = os.environ.get("QDRANT_URL", "http://qdrant:6333")
document_store = QdrantDocumentStore(
    url=QDRANT_URL,
    collection_name="haystack_docs",
    embedding_dim=768,
    recreate_index=False  # False: Index bleibt beim Neustart erhalten!
)

# Embedding-Modelle (kannst du anpassen)
document_embedder = SentenceTransformersDocumentEmbedder(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)
query_embedder = SentenceTransformersTextEmbedder(
    model_name="sentence-transformers/all-MiniLM-L6-v2"
)
retriever = DensePassageRetriever(document_store=document_store)

# Frage-Antwort-Pipeline
pipe = Pipeline()
pipe.add_component("retriever", retriever)
pipe.connect("retriever.embedding", "retriever.documents")

# Hilfsfunktion: Text extrahieren (hier einfach für TXT/PDF erweiterbar)
def extract_text_from_file(file: UploadFile) -> str:
    if file.content_type == "text/plain":
        return file.file.read().decode("utf-8")
    elif file.filename.endswith(".pdf"):
        # Für PDF: Mit PyPDF2, pdfminer o.ä. nachrüsten!
        return "[PDF-Text-Extraktion hier einfügen]"
    else:
        return "[Unbekanntes Dateiformat]"

# UPLOAD-ENDPUNKT (Speichert und indexiert das Dokument)
@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    # Temporär speichern (kannst du anpassen)
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name

    # Text extrahieren (hier nur TXT, PDF kannst du mit PyPDF2 nachrüsten)
    text = ""
    try:
        with open(tmp_path, "rb") as f:
            text = f.read().decode("utf-8")
    except Exception as e:
        return JSONResponse({"detail": f"Fehler beim Lesen: {e}"}, status_code=400)

    # Indexieren im DocumentStore
    document_store.write_documents([Document(content=text, meta={"filename": file.filename})])

    # Optional: Lösche temp file
    os.remove(tmp_path)
    return JSONResponse({"detail": f"Datei '{file.filename}' wurde gespeichert und indexiert."})

# ASK-ENDPUNKT (Frage-Antwort mit Retriever)
class AskRequest(BaseModel):
    question: str

@app.post("/ask")
async def ask_question(req: AskRequest):
    question = req.question
    results = pipe.run(
        data={"retriever": {"query": question}}
    )
    # Extrahiere Antwort aus Ergebnis
    docs = results["retriever"]["documents"]
    if docs:
        # Die beste Antwort + ggf. Quellen
        top = docs[0]
        return {
            "answer": top.content,
            "meta": top.meta
        }
    else:
        return {"answer": "Keine Antwort gefunden.", "meta": {}}
