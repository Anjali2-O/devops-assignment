
# Use a lightweight Python base image
FROM python:3.12-slim

# Prevent Python from buffering logs
ENV PYTHONUNBUFFERED=1

# Set the working directory inside the container
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/ .

# Create a dedicated non-root application user
RUN useradd --create-home --shell /usr/sbin/nologin appuser \
    && chown -R appuser:appuser /app

# Run application processes without root privileges
USER appuser

# FastAPI default startup command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
