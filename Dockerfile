# syntax=docker/dockerfile:1
FROM python:3.9-slim AS builder

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --target python -r \
requirements.txt

COPY app/ .

RUN zip -r /build/create_link.zip create_link.py \
python/
RUN zip -r /build/redirect.zip redirect.py \
python/
