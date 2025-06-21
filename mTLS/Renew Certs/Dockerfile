# Step 1: Use a Python slim image to install boto3 and other dependencies
FROM python:3.11-slim-bullseye as builder

# Step 2: Set working directory and install boto3
WORKDIR /app

# Install boto3 and its dependencies
RUN pip install --upgrade pip
RUN pip install --no-cache-dir --target=/app boto3

# Step 3: Create a distroless image
FROM gcr.io/distroless/python3-debian11

# Step 4: Copy boto3 and its dependencies from the builder image
COPY --from=builder /app /app

# Step 5: Set working directory in distroless image
WORKDIR /app

# Step 6: Set Python path to include app directory
ENV PYTHONPATH=/app

# Step 7: Set user to non-root for security best practices
USER nonroot:nonroot

# Step 8: Set entrypoint to Python3 to run scripts or interactive shell
ENTRYPOINT ["python3"]
CMD ["-c", "import boto3; print('Boto3 is installed and ready to use!')"]
