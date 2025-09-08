from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from typing import Optional
import os, spacy
from spacy.lang.en import English
from starlette.middleware.cors import CORSMiddleware

INTERNAL_KEY = os.getenv("SPACY_INTERNAL_KEY", "")
MODEL = os.getenv("SPACY_MODEL", "en_core_web_md")

try:
    nlp = spacy.load(MODEL, disable=["ner"])   # enable "ner" if you really need it
except Exception:
    nlp = English()  # fallback keeps service alive even if model load fails

app = FastAPI(title="Unsaid spaCy", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

class ProcessBody(BaseModel):
    text: str
    wantTokens: Optional[bool] = True
    wantSents: Optional[bool] = True
    wantDeps: Optional[bool] = True

@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL}

@app.post("/process")
async def process(req: Request, body: ProcessBody):
    if INTERNAL_KEY and req.headers.get("x-internal-key") != INTERNAL_KEY:
        raise HTTPException(status_code=401, detail="unauthorized")

    doc = nlp(body.text or "")
    tokens = [{"text": t.text, "lemma": (t.lemma_ or t.text).lower(), "pos": (t.pos_ or "X").upper(), "i": i}
              for i, t in enumerate(doc)] if body.wantTokens else []
    sents = [{"start": s.start_char, "end": s.end_char} for s in doc.sents] if body.wantSents and doc.has_annotation("SENT_START") else [{"start":0, "end":len(body.text or "")}] if body.wantSents else []
    deps   = [{"i": i, "head": (t.head.i if t.head is not None else None), "dep": t.dep_} for i, t in enumerate(doc)] if body.wantDeps else []

    # Compact fields your TS expects:
    return {
        "tokens": tokens,
        "sents": sents,
        "deps": deps,
        "sarcasm": {"present": False, "score": 0.0},
        "context": {"label": "general", "score": 0.1},
        "phraseEdges": {"hits": []}
    }
