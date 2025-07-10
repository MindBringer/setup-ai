FROM deepset/haystack:base-v22.14.3

# Set working directory
WORKDIR /app

# Install Qdrant integration
RUN pip install qdrant-haystack

# Copy app script
COPY app.py .

# Expose port for REST API
EXPOSE 8000

# Entry point
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]