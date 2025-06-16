FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY embeddings.py .
COPY entrypoint.sh .
COPY data/pdf/buku_saku_studio.pdf /data/pdf/

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python", "embeddings.py"]
