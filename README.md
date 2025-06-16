# Intelligent SOP Assistant: RAG Chatbot with Local LLM on Kubernetes

## Chatbot SOP Divisi (RAG + Ollama + Kubernetes)
Proyek ini membangun ``chatbot`` internal per divisi untuk menjawab pertanyaan berdasarkan ``dokumen SOP`` dalam format PDF menggunakan pendekatan RAG (Retrieval-Augmented Generation) dengan ``LLM lokal``. Sistem ini berjalan di atas ``Kubernetes lokal`` dengan modul-modul terpisah untuk embedding, API, dan antarmuka pengguna berbasis Streamlit.

---

## Tujuan
- Mempermudah karyawan memahami SOP masing-masing divisi.
- Mengurangi beban pertanyaan berulang ke tim senior atau HR.
- Memberikan jawaban berbasis konteks dari dokumen PDF secara efisien menggunakan model LLM lokal.

---

## Arsitektur
```
+-------------------+
|       PDF SOP     |
|    Divisi (*.pdf) |
+--------+----------+
         |
         v
+---------------------------+
|    Embedder (Job K8s)     |
|  - Ekstrak & embed dokumen|
|  - Simpan ke Chroma Vector|
+---------------------------+
         |
         v
+---------------------------+
|       API Service         |
|  - Endpoint /ask (POST)   |
|  - Cari konteks terdekat  |
|  - Kirim prompt ke LLM    |
+---------------------------+
         |
         v
+---------------------------+
|     LLM (Ollama Model)    |
|  - Bahasa Indonesia       |
|  - Model Chat + Embed     |
+---------------------------+
         |
         v
+---------------------------+
|  Streamlit UI (Frontend)  |
|  - Form tanya jawab       |
|  - Tampilkan respons      |
+---------------------------+
```
---

## Komponen Utama

Backend & Embedding: ``FastAPI + LangChain + Chroma``

LLM: ``Ollama`` (local model serving)

UI: ``Streamlit``

Deployment: ``Docker + Kubernetes``

1. Ollama (LLM Lokal)
    - Model: llama3.2 (bisa gemma, mistral, atau llama versi chat).
    - Embed model: nomic-embed-text.  

    Containerized dalam image ollama dengan entrypoint yang menunggu model siap.

2. Embedder (Job Kubernetes)    
    Menjalankan skrip Python: 
    - Load PDF
    - Potong ke dalam chunks
    - Buat embedding
    - Simpan ke Chroma (/data/chroma)

3. FastAPI  
    Endpoint POST /ask
    -   Menerima pertanyaan
    - Cari similarity di Chroma VectorStore
    - Susun prompt
    - Kirim ke LLM dan kembalikan jawaban

4. Streamlit UI     
    Tampilan pengguna sederhana untuk mengirim pertanyaan dan melihat jawaban.

---

## Struktur Folder
```
project-root/
├── ollama-main/
│   ├── Dockerfile
│   └── entrypoint.sh        ← setup model sebelum serve
│
├── ollama-embeeddings/
│   ├── Dockerfile
│   └── entrypoint.sh        ← setup model sebelum serve
│
├── embeeddings/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── requirements.txt     ← langchain, chromadb, PyPDF2, etc.
│   ├── embeeddings.py       ← load PDF, generate embedding
│   └── data/
│       └── pdf/
│
├── api/
│   ├── Dockerfile
│   ├── requirements.txt     ← fastapi, httpx
│   └── main.py              ← FastAPI: menerima query, panggil embeeddings + ollama
│
├── streamlit-ui/
│   ├── Dockerfile
│   ├── requirements.txt     ← streamlit, requests
│   └── app.py               ← chat ke endpoint API
│
├── kubernetes/
│   ├── ollama-main.yaml
│   ├── ollama-embeeddings.yaml
│   ├── embeeddings.yaml
│   ├── api.yaml
│   └── streamlit.yaml
│
├── deploy.sh
└── README.md
```
---

## Cara Deploy
1. Start Kubernetes Cluster lokal (misal Docker Desktop).

2. Deploy LLM Ollama:
```bash
kubectl apply -f kubernetes/ollama-deployment.yaml
```

3. Jalankan Embedder (sekali saja untuk setiap PDF):
```bash
kubectl apply -f kubernetes/embedding-job.yaml
```

4. Deploy API:
```bash
kubectl apply -f kubernetes/api-deployment.yaml
```

5. Deploy Streamlit UI:
```bash
kubectl apply -f kubernetes/streamlit-deployment.yaml
```

6. Deploy semua langsung bisa jalankan ``deploy.sh``
```bash
./deploy.sh
```

7. Jalankan kode berikut untuk menjalankan UI di port 8501
```bash
kubectl port-forward deployment/streamlit-ui 8501:8501
```

8. Streamlit UI sekarang tersedia di: http://localhost:8501
---

### Contoh Pertanyaan
"Apa saja tahapan revisi desain di studio?"

"Kapan SOP produksi berlaku?"

"Siapa yang harus dihubungi untuk cuti?"

## Catatan dan saran
- Semua komunikasi antar service menggunakan service name Kubernetes (api-service, ollama-chat, ollama-embeddings).

- SOP hanya untuk studio, kedepan jika ingin SOP per divisi: bisa gunakan struktur /data/chroma/<divisi> dan extend API-nya kembali.

- Belum ada autentikasi (bisa ditambahkan via token API).

- Bisa ditambahkan pengecekan log aktivitas.

---

## Hasil
Hasil 1
![hasil-1](./intelligent-SOP-assistant/img/hasil-1.png)

Hasil 2
![hasil-2](..\img\hasil-2.png)

Hasil 3
![hasil-3](..\img\hasil-3.png)
