FROM python:3.15-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5 AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------------------------------------------------------------------------
FROM python:3.15-slim@sha256:63bb298d2b7b88f176f51b5189f54ce6535c997682ea70885d2132f5d473a8a5

LABEL org.opencontainers.image.title="unifi2netbox" \
      org.opencontainers.image.description="Sync UniFi devices, interfaces, VLANs, WLANs and cables into NetBox" \
      org.opencontainers.image.source="https://github.com/patricklind/unifi2netbox"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# iputils-ping is needed for DHCP static-IP candidate verification
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends iputils-ping && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

COPY main.py /app/
COPY sync/ /app/sync/
COPY unifi/ /app/unifi/
COPY data/ /app/data/

RUN addgroup --system app && \
    adduser --system --ingroup app --home /home/app app && \
    mkdir -p /app/logs && \
    chown -R app:app /app /home/app

USER app

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import sys; sys.exit(0)"]

CMD ["python", "main.py"]
