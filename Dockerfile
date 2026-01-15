FROM python:3.12-slim

# 1. System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Setup Working Directory
WORKDIR /app

# 4. Environment Variables
# UV_PROJECT_ENVIRONMENT pointing to /usr/local tells uv to sync to the system python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_PROJECT_ENVIRONMENT="/usr/local" \
    UV_COMPILE_BYTECODE=1 \
    HF_HOME=/tmp/huggingface \
    SENTENCE_TRANSFORMERS_HOME=/tmp/huggingface

# 5. Install Dependencies (Layer Caching)
# We copy ONLY the dependency files first so code changes don't trigger a re-install
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-dev

# 6. Pre-download models
# This runs using the system python where dependencies were just synced
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('paraphrase-MiniLM-L3-v2')"

# 7. Copy Code & Set Permissions
COPY . .
RUN useradd -m -u 1000 user && chown -R user:user /app

# 8. Switch to HF user
USER user

EXPOSE 7860

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]