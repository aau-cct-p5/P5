# Use an official Python base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies (if needed)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements into the container
COPY requirements.txt ./

# Install python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy all project files into the container
COPY . .

# Expose no specific port since this is a training job, not a service
# EXPOSE 8080

CMD ["python", "main.py"]
