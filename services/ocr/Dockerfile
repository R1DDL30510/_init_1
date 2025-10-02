# syntax=docker/dockerfile:1.6
FROM python:3.11.9-slim-bullseye@sha256:fe8df05de0fe659668a0b6fa204c652092e3e96832a9c7d6f8cc1e0e03e663d8

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

COPY vendor/wheels/ocr /tmp/wheels
COPY services/ocr/requirements.txt /tmp/requirements.txt
RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl libxml2 libxslt1.1 \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-index --find-links=/tmp/wheels --requirement /tmp/requirements.txt \
    && rm -rf /tmp/wheels /root/.cache/pip

COPY services/ocr/app /app/app
COPY vendor/models/ocr /app/models

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
