FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Unzip is not in the base image
RUN apt-get update && apt-get install -y \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Select which version of the app to use (1, 2, or 3)
ARG APP_VERSION=1

# Copy the chosen app file as app.py (module name 'app')
COPY artifacts/app_v${APP_VERSION}.zip ./artifacts/
COPY artifacts/app_v${APP_VERSION}.zip.sha256 ./artifacts/

# The build will crash here if hash mismatch
# Workdir change is needed as checksum has filename only
WORKDIR /app/artifacts
RUN sha256sum -c ./app_v${APP_VERSION}.zip.sha256

# Unzip the artifact and copy the app.py to the working directory
RUN unzip ./app_v${APP_VERSION}.zip -d ./extracted
RUN cp ./extracted/app.py /app/app.py

# Clean up extracted files and artifacts to keep the image tidy
RUN rm -rf ./extracted ./artifacts
WORKDIR /app

# Copy all tests
COPY tests/ ./tests/

# Quick fix for module import
ENV PYTHONPATH=/app

# Run pytest on the tests directory
# CMD ["pytest", "tests"]

# Entrypoint to allow on-demand debugging
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "-m", "pytest", "-q"]
