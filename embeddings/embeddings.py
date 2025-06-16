import os
from langchain_ollama import OllamaEmbeddings
from langchain_chroma import Chroma
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

PDF_FILE = os.getenv("PDF_FILE")
CHROMA_DIR = os.getenv("CHROMA_DIR")

OLLAMA_MODEL = os.getenv("OLLAMA_EMBEDDING_MODEL")
OLLAMA_URL = os.getenv("OLLAMA_EMBEDDING_URL")

def embed_documents():
    try:
        # Load PDF
        loader = PyPDFLoader(PDF_FILE)
        docs = loader.load()
        # Split teks
        splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        chunks = splitter.split_documents(docs)

        # Setup embedding model → HARUS nomic-embed-text
        embedding = OllamaEmbeddings(
            model=OLLAMA_MODEL,
            base_url=OLLAMA_URL
        )

        # Simpan ke Chroma Vectorstore
        Chroma.from_documents(
            documents=chunks,
            embedding=embedding,
            persist_directory=CHROMA_DIR
        )

        print(f"[INFO] Memuat PDF dari: {PDF_FILE}")
        print(f"[INFO] Jumlah halaman: {len(docs)}")
        print(f"[INFO] Jumlah chunk: {len(chunks)}")
        print(f"[INFO] Menyimpan embedding ke: {CHROMA_DIR}")

    except Exception as e:
        print(f"[INFO] Memuat PDF dari: {PDF_FILE}")
        print(f"[INFO] Jumlah halaman: {len(docs)}")
        print(f"[INFO] Jumlah chunk: {len(chunks)}")
        print(f"[INFO] Menyimpan embedding ke: {CHROMA_DIR}")
        print(f"[Embeddings] Gagal embed: {e}")

if __name__ == "__main__":
    embed_documents()
