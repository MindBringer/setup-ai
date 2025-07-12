
from flask import Flask, request, jsonify
from haystack.components.converters import TextFileToDocument
from haystack.components.converters import PDFToTextConverter
from haystack.components.converters import DocxToTextConverter
from haystack_config import build_pipeline, OllamaLocalGenerator
import os

app = Flask(__name__)

rag_pipeline, retriever, prompt_builder, _ = build_pipeline()

@app.route('/upload', methods=['POST'])
def upload():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    temp_path = os.path.join("/tmp", file.filename)
    file.save(temp_path)

    converter = TextFileToDocument()
    with open(temp_path, "r", encoding="utf-8") as f:
        text = f.read()

    result = converter.run(sources=[{"text": text, "meta": {"name": file.filename}}])
    docs = result["documents"]

    rag_pipeline.run(data={"cleaner": {"documents": docs}})
    os.remove(temp_path)

    return jsonify({'status': 'uploaded and indexed'}), 200

@app.route('/query', methods=['POST'])
def query():
    data = request.get_json()
    question = data.get('question')
    model = data.get('model', 'mistral')

    if not question:
        return jsonify({'error': 'No question provided'}), 400

    retrieved_docs = retriever.run(query=question)["documents"]
    prompt = prompt_builder.run(documents=retrieved_docs, query=question)["prompt"]

    generator = OllamaLocalGenerator(model_name=model)
    answer = generator.run(prompt=prompt)["replies"][0]

    return jsonify({'answer': answer})

@app.route('/models', methods=['GET'])
def get_models():
    import requests
    try:
        response = requests.get("http://ollama:11434/api/tags")
        response.raise_for_status()
        models = response.json().get("models", [])
        model_names = [m["name"] for m in models]
        return jsonify({"models": model_names})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000)
