# syntax=docker/dockerfile:1
FROM python:3.9-slim AS builder

WORKDIR /app

# Install zip utility and its dependencies
RUN apt-get update && apt-get install -y zip --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Create the /build directory where the zip files will be stored inside the image
RUN mkdir -p /build

COPY app/requirements.txt .
RUN pip install --target python -r \
    requirements.txt

COPY app/ .

# These zip commands will now successfully write to /build
RUN zip -r /build/create_link.zip create_link.py python/
RUN zip -r /build/redirect.zip redirect.py python/
