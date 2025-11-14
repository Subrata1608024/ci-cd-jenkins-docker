# Build a tiny Flask app container
FROM python:3.11-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

# Install runtime deps
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy app code
COPY app /app

EXPOSE 5000

# Image-level healthcheck (Compose also defines one; Compose will override this)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD python -c "import os,urllib.request,sys; \
url=f'http://localhost:{os.environ.get(\"PORT\",\"5000\")}/health'; \
import urllib.error; \
import json; \
import time; \
import socket; \
try:\
    resp=urllib.request.urlopen(url,timeout=2);\
    sys.exit(0 if resp.status==200 else 1)\
except Exception:\
    sys.exit(1)"

CMD ["python", "app.py"]
