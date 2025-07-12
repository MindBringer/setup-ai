
#from haystack_integrations.document_stores.weaviate import WeaviateDocumentStore
from haystack.components.preprocessors import DocumentCleaner, DocumentSplitter
from haystack.components.writers import DocumentWriter
from haystack.components.builders import PromptBuilder
from haystack.components.retrievers.in_memory import BM25Retriever
from haystack.pipelines import Pipeline
from haystack.components.generators import TextGenerator
from haystack.components.document_stores.weaviate import WeaviateDocumentStore
import requests

class OllamaLocalGenerator(TextGenerator):
    def __init__(self, model_name="mistral", host="http://ollama:11434"):
        super().__init__()
        self.model_name = model_name
        self.url = f"{host}/api/generate"

    def run(self, prompt: str):
        payload = {
            "model": self.model_name,
            "prompt": prompt,
            "stream": False
        }
        response = requests.post(self.url, json=payload)
        response.raise_for_status()
        result = response.json()
        return {"replies": [result["response"].strip()]}

def build_pipeline():
    doc_store = WeaviateDocumentStore(
        host="weaviate",
        port=8080,
        embedding_dim=384,
        recreate_index=True
    )

    cleaner = DocumentCleaner()
    splitter = DocumentSplitter(split_by="word", split_length=200)
    writer = DocumentWriter(document_store=doc_store)
    retriever = BM25Retriever(document_store=doc_store)

    prompt_template = """
    Given these documents:
    {% for doc in documents %}
      {{ doc.content }}
    {% endfor %}
    Answer the question: {{query}}
    """
    prompt_builder = PromptBuilder(template=prompt_template)

    rag_pipeline = Pipeline()
    rag_pipeline.add_component("cleaner", cleaner)
    rag_pipeline.add_component("splitter", splitter)
    rag_pipeline.add_component("writer", writer)
    rag_pipeline.add_component("retriever", retriever)
    rag_pipeline.add_component("prompt_builder", prompt_builder)

    rag_pipeline.connect("cleaner", "splitter")
    rag_pipeline.connect("splitter", "writer")

    return rag_pipeline, retriever, prompt_builder, None
