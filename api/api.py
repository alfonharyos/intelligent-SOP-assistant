from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os
from langchain_ollama import OllamaEmbeddings
from langchain_chroma import Chroma
import traceback
import json

app = FastAPI()

# ENV untuk Chat
CHAT_MODEL = os.getenv("OLLAMA_CHAT_MODEL")
CHAT_BASE_URL = os.getenv("OLLAMA_CHAT_URL")

# ENV untuk Embedding
EMBEDDING_MODEL = os.getenv("OLLAMA_EMBEDDING_MODEL")
EMBEDDING_URL = os.getenv("OLLAMA_EMBEDDING_URL")
CHROMA_DIR = os.getenv("CHROMA_DIR")

@app.get("/health")
def health_check():
    return {"status": "ok"}

class QuestionRequest(BaseModel):
    question: str

@app.post("/ask")
async def query_qa(req: QuestionRequest):
    try:
        print("=== Load Chroma ===")
        print("Path:", CHROMA_DIR)

        # Load Chroma vectorstore dengan embedding model khusus
        vectorstore = Chroma(
            persist_directory=CHROMA_DIR,
            embedding_function=OllamaEmbeddings(
                model=EMBEDDING_MODEL,
                base_url=EMBEDDING_URL
            )
        )

        # Generate embedding & search
        query_embedding = vectorstore._embedding_function.embed_query(req.question)
        docs = vectorstore.similarity_search_by_vector(query_embedding, k=3)
        context_text = "\n".join([doc.page_content for doc in docs])

        # Kirim prompt ke model Chat
        payload = {
            "model": CHAT_MODEL,
            "prompt": f"Context:\n{context_text}\n\nQuestion:\n{req.question}\nAnswer:",
            "stream": False 
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(f"{CHAT_BASE_URL}/api/generate", json=payload, timeout=300.0)
            if response.status_code != 200:
                raise HTTPException(status_code=response.status_code, detail=response.text)
            print("== Raw response from Ollama ==")
            print(response.text)
            try:
                data = response.json()
                answer = data.get("response")
            except json.JSONDecodeError:
                print("Gagal decode JSON. Dump raw text:")
                print(response.text)
                raise
        return {"answer": answer}


    except Exception as e:
        import traceback
        traceback.print_exc()
        print("Error:", str(e))
        return {"error": str(e)}

