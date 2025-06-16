#!/bin/bash
set -euo pipefail
trap 'kill $(jobs -p) 2>/dev/null || true' EXIT

if [[ "${1:-}" == "--clean" ]]; then
  echo "=== Cleanup semua resource sebelumnya ==="
  kubectl delete all --all
  echo "=== Hapus hasil embedding di hostPath ==="
  rm -rf /embeddings/data/chroma/*
fi


echo "=== [1/8] Validasi file yang diperlukan ==="
missing=false
[[ -f ollama-chat/entrypoint.sh ]] || { echo "File 'ollama-chat/entrypoint.sh' tidak ditemukan."; missing=true; }
[[ -f ollama-embeddings/entrypoint.sh ]] || { echo "File 'ollama-embeddings/entrypoint.sh' tidak ditemukan."; missing=true; }

if [[ "$missing" = true ]]; then
  echo "Pastikan semua file entrypoint.sh tersedia sebelum membuild image."
  exit 1
fi


echo "=== [2/8] Build Docker images secara paralel ==="
docker build -t ollama-chat:latest -f ollama-chat/Dockerfile ollama-chat/
docker build -t ollama-embeddings:latest -f ollama-embeddings/Dockerfile ollama-embeddings/
docker build -t embeddings:latest ./embeddings &
docker build -t api:latest ./api &
docker build -t streamlit-ui:latest ./streamlit-ui &
wait
# Validasi semua image tersedia
missing_images=()
for image in ollama-chat ollama-embeddings embeddings api streamlit-ui; do
  if ! docker image inspect ${image}:latest > /dev/null 2>&1; then
    missing_images+=("$image")
  fi
done
if [[ ${#missing_images[@]} -gt 0 ]]; then
  echo "Error: Image berikut tidak ditemukan setelah build:"
  for img in "${missing_images[@]}"; do echo "  - $img:latest"; done
  exit 1
fi
echo "Semua image selesai dibuild dan terdeteksi secara lokal"


echo "=== [3/8] Terapkan konfigurasi Kubernetes ==="
kubectl apply -f ./kubernetes/


echo "=== [4/8] Menunggu semua pod Ollama & API sampai READY ==="
kubectl wait --for=condition=ready pod -l app=ollama-chat --timeout=600s
kubectl wait --for=condition=ready pod -l app=ollama-embeddings --timeout=600s
kubectl wait --for=condition=ready pod -l app=api --timeout=600s
echo "Semua pod Ollama sudah siap."


echo "=== [5/8] Menunggu embeddings Job selesai ==="
kubectl wait --for=condition=complete --timeout=600s job/embeddings-job

EMBEDDING_STATUS=$(kubectl get job embeddings-job -o jsonpath='{.status.succeeded}' || echo "0")
if [[ "$EMBEDDING_STATUS" != "1" ]]; then
  echo "Embeddings job gagal. Cek log dengan:"
  echo "    kubectl logs job/embeddings-job"
  exit 1
fi
echo "Embeddings job selesai dan berhasil"


echo "=== [6/8] Menunggu Streamlit UI sampai READY ==="
kubectl wait --for=condition=ready pod -l app=streamlit-ui --timeout=120s


echo "=== [7/8] Cek status pods ==="
kubectl get pods


echo "=== [8/8] Port forwarding streamlit-ui ke localhost:8501 ==="
if curl -s http://localhost:8501 | grep -q "Streamlit"; then
  echo "Streamlit UI sekarang tersedia di: http://localhost:8501"
else
  echo "Gagal port-forward Streamlit UI. Cek log berikut:"
  cat ./logs/portforward.log | tail -n 20
  echo "Coba jalankan manual:"
  echo "    kubectl port-forward deployment/streamlit-ui 8501:8501"
  kill $PF_PID
fi