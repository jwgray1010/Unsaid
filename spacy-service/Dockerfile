FROM python:3.11-slim

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends build-essential gcc && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# install the English model (use sm for smaller image, md for better vectors)
RUN python -m spacy download en_core_web_md

COPY app.py .

ENV PORT=8080
ENV SPACY_MODEL=en_core_web_md
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
