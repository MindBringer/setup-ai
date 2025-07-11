FROM deepset/haystack:base-main

# Set working directory
WORKDIR /app

# Install Qdrant integration
RUN pip install qdrant-haystack

# Copy app script
COPY app.py .

# Expose port for REST API
EXPOSE 8000

# Entry point
