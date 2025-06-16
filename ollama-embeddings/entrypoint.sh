#!/bin/bash
set -e
set -o pipefail

# Configuration
OLLAMA_MODEL="${OLLAMA_EMBEDDING_MODEL:-nomic-embed-text}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

# Start Ollama server in background
echo "[ENTRYPOINT] Menjalankan ollama serve di background..."
ollama serve &
OLLAMA_PID=$!

# Wait for server root endpoint to be ready
echo "[ENTRYPOINT] Menunggu Ollama embeddings service di port $OLLAMA_PORT..."
until curl -sf http://localhost:$OLLAMA_PORT/ > /dev/null; do
  echo "[ENTRYPOINT] Endpoint belum siap, ulangi..."
  sleep 2
done

# Pull model jika belum tersedia
if ! ollama list | grep -q "$OLLAMA_MODEL"; then
  echo "[ENTRYPOINT] Model $OLLAMA_MODEL belum ada, menarik dari registry..."
  ollama pull "$OLLAMA_MODEL"
else
  echo "[ENTRYPOINT] Model $OLLAMA_MODEL sudah tersedia."
fi

# Tunggu model muncul di daftar tag
until curl -sf http://localhost:$OLLAMA_PORT/api/tags | grep -q "$OLLAMA_MODEL"; do
  echo "[ENTRYPOINT] Menunggu model $OLLAMA_MODEL tersedia di server..."
  sleep 2
done

echo "[ENTRYPOINT] Model $OLLAMA_MODEL siap digunakan!"
touch /tmp/model_ready

# Biarkan proses utama jalan di foreground
wait $OLLAMA_PID
