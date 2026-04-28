# /src/server/Dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y gcc libpq-dev

# Copy requirements first to leverage Docker cache
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy ONLY the server code (ignores the client folder entirely)
COPY . /app/

EXPOSE 8000

# Start the Gunicorn production server
CMD ["gunicorn", "--workers", "3", "--bind", "0.0.0.0:8000", "cwsn_backend.wsgi:application"]
