from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from haystack import Pipeline
from haystack.components.retrievers import InMemoryEmbeddingRetriever
from haystack.components.embedders import SentenceTransformersTextEmbedder
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
from haystack.dataclasses import Document
import os

app = FastAPI()

# Qdrant-Dokumentenstore
QDRANT_URL = os.environ.get("QDRANT_URL", "http://qdrant:6333")
COLLECTION_NAME = "haystack_docs"

document_store = QdrantDocumentStore(
    url=QDRANT_URL,
    collection_name=COLLECTION_NAME,
    recreate_index=False,
    embedding_dim=384  # Hängt vom Embedding-Modell ab!
)

# Embedding-Modell
embedder = SentenceTransformersTextEmbedder(
    model_name_or_path="sentence-transformers/all-MiniLM-L6-v2"
)

# Retriever für RAG
retriever = InMemoryEmbeddingRetriever(
    document_store=document_store,
    embedding_model=embedder
)

# Pipeline bauen
pipe = Pipeline()
pipe.add_component("embedder", embedder)
pipe.add_component("retriever", retriever)
pipe.connect("embedder.embedding", "retriever.query_embedding")

# UPLOAD-ENDPOINT: Dokument ins Vektorsystem einpflegen
@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    text = (await file.read()).decode("utf-8")
    document = Document(content=text, meta={"filename": file.filename})
    document_store.write_documents([document])
    return JSONResponse({"detail": f"Datei '{file.filename}' erfolgreich indexiert!"})

# ASK-ENDPOINT: Frage an das System stellen
class AskRequest(BaseModel):
    question: str

@app.post("/ask")
async def ask_question(req: AskRequest):
    query = req.question
    results = pipe.run(
        data={
            "embedder": {"text": query},
            "retriever": {"top_k": 3}
        }
    )
    docs = results["retriever"]["documents"]
    answers = [doc.content for doc in docs]
    return {"answers": answers}
