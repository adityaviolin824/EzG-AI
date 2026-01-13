FROM python:3.13-slim

# 1. System dependencies (Root)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Tools (Root)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 3. Setup Working Directory
WORKDIR /app

# 4. Environment Variables (HF requires 7860)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=7860 \
    HOME=/home/user

# 5. Install Dependencies as ROOT (Ensures --system works)
COPY requirements.txt .
RUN uv pip install --no-cache --system --index-strategy unsafe-best-match -r requirements.txt

# 6. Pre-download models as ROOT (Saves to global cache)
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('paraphrase-MiniLM-L3-v2')"

# 7. Copy Code
COPY . .

# 8. THE HF FIX: Create user with UID 1000 and give ownership of /app
RUN useradd -m -u 1000 user && chown -R user:user /app

# 9. Switch to user at the VERY END
USER user

EXPOSE 7860

# 10. Start (Hugging Face ignores the EXPOSE and looks for 7860)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]