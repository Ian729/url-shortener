import os
import random
import string
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from pydantic import BaseModel
from redis import Redis
import hashlib

app = FastAPI()

# Redis client (uses REDIS_URL env var or defaults to localhost)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
redis_client = Redis.from_url(REDIS_URL, decode_responses=True)


class URL(BaseModel):
    url: str


def _generate_code(length: int = 6) -> str:
    return ''.join(
        random.choices(string.ascii_letters + string.digits, k=length)
    )


@app.post("/shorten")
def shorten_url(url: URL):
    # normalize and hash the URL for reverse lookup
    url_value = url.url.strip()
    url_hash = hashlib.sha256(url_value.encode("utf-8")).hexdigest()
    url_key = f"url:{url_hash}"

    # if a short code already exists for this URL, return it
    existing = redis_client.get(url_key)
    if existing:
        return {"short_url": f"/{existing}"}

    # Otherwise, attempt to create a new short code atomically
    for _ in range(5):
        short_code = _generate_code()
        # try to set the short_code only if it doesn't already exist
        created = redis_client.setnx(short_code, url_value)
        if created:
            # successful — set reverse mapping.
            # If someone else set the reverse mapping in the meantime,
            # prefer the existing mapping and remove ours.
            prev = redis_client.get(url_key)
            if prev:
                # cleanup our newly created key and return the existing mapping
                redis_client.delete(short_code)
                return {"short_url": f"/{prev}"}
            redis_client.set(url_key, short_code)
            return {"short_url": f"/{short_code}"}

    # fallback: try a longer code if collisions occur (very unlikely)
    for _ in range(3):
        short_code = _generate_code(8)
        created = redis_client.setnx(short_code, url_value)
        if created:
            prev = redis_client.get(url_key)
            if prev:
                redis_client.delete(short_code)
                return {"short_url": f"/{prev}"}
            redis_client.set(url_key, short_code)
            return {"short_url": f"/{short_code}"}

    # as a last resort, set without NX (this should be extremely rare)
    short_code = _generate_code(10)
    redis_client.set(short_code, url_value)
    redis_client.set(url_key, short_code)
    return {"short_url": f"/{short_code}"}


@app.get("/{short_code}")
def redirect_to_url(short_code: str):
    target = redis_client.get(short_code)
    if target:
        return RedirectResponse(url=str(target))
    raise HTTPException(status_code=404, detail="URL not found")


@app.get("/", response_class=HTMLResponse)
def read_root():
    with open("static/index.html") as f:
        return HTMLResponse(content=f.read(), status_code=200)
