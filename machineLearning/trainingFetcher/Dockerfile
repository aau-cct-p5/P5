# Dockerfile

FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Default command in training mode, can be overridden by docker-compose or command-line.
CMD ["python", "trainingFetching.py"]
