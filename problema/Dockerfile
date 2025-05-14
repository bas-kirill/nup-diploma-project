FROM python:3.11-slim

# Install AWS CLI v2 dependencies
RUN apt-get update && \
    apt-get install -y unzip curl && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Set working directory
WORKDIR /app

# Copy code
COPY requirements.txt .
COPY s3_sync.py .

# Install Python dependencies (if any)
RUN pip install --no-cache-dir -r requirements.txt

# Run script on container start
CMD ["python", "s3_sync.py"]
