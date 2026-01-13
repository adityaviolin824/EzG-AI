FROM python:3.13-slim

# 1. Install system dependencies as ROOT (default)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Install 'uv' as ROOT
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Setup the HF user (UID 1000 is required)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1

WORKDIR $HOME/app

# 4. Install Python dependencies
# We use --index-strategy to avoid the 'requests' version conflict we saw earlier
COPY --chown=user:user requirements.txt .
RUN uv pip install --no-cache --system --index-strategy unsafe-best-match -r requirements.txt

# 5. Pre-download the model so it's ready inside the image
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('paraphrase-MiniLM-L3-v2')"

# 6. Copy the rest of your code
COPY --chown=user:user . .

# 7. Start the FastAPI app on port 7860
EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]