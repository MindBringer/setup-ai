import React, { useState } from "react";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

export default function Ask() {
  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState<string | null>(null);

  const handleAsk = async () => {
    setAnswer("...");
    const resp = await fetch(`${API_URL}/ask`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question }),
    });
    const data = await resp.json();
    setAnswer(data.answer || "Keine Antwort");
  };

  return (
    <div className="max-w-xl mx-auto mt-8 p-4 border rounded-xl shadow">
      <h1 className="text-xl font-bold mb-2">Haystack Playground</h1>
      <input
        value={question}
        onChange={e => setQuestion(e.target.value)}
        placeholder="Frage stellen..."
        className="w-full p-2 border rounded mb-2"
      />
      <button
        onClick={handleAsk}
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        Ask
      </button>
      {answer && (
        <div className="mt-4 p-2 bg-gray-100 rounded">
          <strong>Antwort:</strong>
          <div>{answer}</div>
        </div>
      )}
    </div>
  );
}
