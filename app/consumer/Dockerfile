FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Use -u to run python in unbuffered mode, ensuring logs are sent immediately
CMD ["python", "-u", "app.py"]
