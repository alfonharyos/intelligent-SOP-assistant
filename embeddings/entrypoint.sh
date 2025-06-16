#!/bin/bash
set -e

until curl -sf $OLLAMA_EMBEDDING_URL/api/tags | grep -q "$OLLAMA_MODEL"; do
  echo "[ENTRYPOINT] Menunggu model $OLLAMA_MODEL tersedia di server..."
  sleep 2
done

# Jalankan perintah utama
exec "$@"