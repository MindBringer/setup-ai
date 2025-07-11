import React, { useState } from "react";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

export default function Upload() {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFile(e.target.files?.[0] || null);
    setResult(null);
  };

  const handleUpload = async () => {
    if (!file) return;
    setUploading(true);
    setResult(null);

    const formData = new FormData();
    formData.append("file", file);

    const resp = await fetch(`${API_URL}/upload`, {
      method: "POST",
      body: formData,
    });

    const data = await resp.json();
    setUploading(false);
    setResult(data.detail || data.status || "Upload abgeschlossen!");
  };

  return (
    <div className="mt-8 p-4 border rounded-xl shadow">
      <h2 className="text-lg font-bold mb-2">Dokument hochladen</h2>
      <input type="file" onChange={handleFileChange} />
      <button
        onClick={handleUpload}
        disabled={!file || uploading}
        className="ml-2 bg-green-600 text-white px-4 py-2 rounded"
      >
        {uploading ? "Hochladen..." : "Upload"}
      </button>
      {result && (
        <div className="mt-2 text-sm text-gray-700">{result}</div>
      )}
    </div>
  );
}