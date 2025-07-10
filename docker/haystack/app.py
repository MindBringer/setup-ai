from fastapi import FastAPI
from haystack import Pipeline
from haystack.dataclasses import Document
from haystack_integrations.document_stores.qdrant import QdrantDocumentStore
from haystack.components.embedders import SentenceTransformersDocumentEmbedder, SentenceTransformersTextEmbedder
from haystack.components.retrievers import DensePassageRetriever

app = FastAPI()
document_store = QdrantDocumentStore(":memory:", embedding_dim=768, recreate_index=True)

document_store.write_documents([Document(content="Hello world!")])

document_embedder = SentenceTransformersDocumentEmbedder(model_name="sentence-transformers/all-MiniLM-L6-v2")
query_embedder = SentenceTransformersTextEmbedder(model_name="sentence-transformers/all-MiniLM-L6-v2")
retriever = DensePassageRetriever(document_store=document_store, embedding_model=query_embedder)
document_store.update_embeddings(document_embedder)

pipeline = Pipeline()
pipeline.add_node(component=retriever, name="Retriever", inputs=["Query"])
pipeline.add_node(component=document_embedder, name="Embedder", inputs=["Retriever"])

@app.get("/search")
def search(q: str):
    results = pipeline.run(query=q, params={"Retriever": {"top_k": 5}})
    hits = [d.content for d in results["documents"]]
    return {"query": q, "results": hits}