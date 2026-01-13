FROM python:3.13-slim

# 1. Setup User and Home (Hugging Face standard)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=7860

WORKDIR $HOME/app

# 2. Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. System dependencies
# Note: apt-get requires root, so we use a temporary switch
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*
USER user

# 4. Install Python deps
COPY --chown=user:user requirements.txt .
RUN uv pip install --no-cache --system --index-strategy unsafe-best-match -r requirements.txt

# 5. Pre-download models (prevents timeout during first boot)
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('paraphrase-MiniLM-L3-v2')"

# 6. Copy application code
COPY --chown=user:user . .

# 7. Metadata/Execution
EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/status || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]