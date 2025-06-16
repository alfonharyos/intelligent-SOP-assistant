#!/bin/bash
set -e

# Configuration
OLLAMA_MODEL="${OLLAMA_CHAT_MODEL:-llama3.2:latest}"  # Lightweight chat model
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

# Start Ollama server in background
ollama serve &
OLLAMA_PID=$!

# Wait for server to be ready
echo "Waiting for Ollama chat service to start..."
until curl -sf http://localhost:$OLLAMA_PORT/ > /dev/null; do
  sleep 2
done

# Pull model if not exists
if ! ollama list | grep -q "$OLLAMA_MODEL"; then
  echo "Pulling $OLLAMA_MODEL..."
  ollama pull "$OLLAMA_MODEL"
fi

# Keep service running
echo "Ollama chat service ready with model: $OLLAMA_MODEL"
touch /tmp/model_ready

wait "$OLLAMA_PID"
