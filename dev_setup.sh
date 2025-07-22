#!/bin/bash

# RAG System Development Environment Setup Script

# Optimized for Ubuntu 24.04.2 LTS (Noble Numbat)

# Last updated: July 2025

set -e  # Exit on any error

# Colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Logging function

log() {
echo -e “${GREEN}[$(date +’%Y-%m-%d %H:%M:%S’)] $1${NC}”
}

warning() {
echo -e “${YELLOW}[WARNING] $1${NC}”
}

error() {
echo -e “${RED}[ERROR] $1${NC}”
exit 1
}

# Check if running as root

if [[ $EUID -eq 0 ]]; then
error “This script should not be run as root for security reasons.”
fi

# System check

log “Checking system compatibility…”

# Check Ubuntu version

if ! lsb_release -d | grep -q “Ubuntu 24.04”; then
warning “This script is optimized for Ubuntu 24.04 LTS”
echo “Current version: $(lsb_release -d | cut -f2)”
read -p “Continue anyway? (y/N): “ -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
exit 1
fi
fi

# Check for GPU

log “Checking for NVIDIA GPU…”
if lspci | grep -i nvidia > /dev/null; then
GPU_AVAILABLE=true
log “NVIDIA GPU detected: $(lspci | grep -i nvidia | head -1)”
else
GPU_AVAILABLE=false
warning “No NVIDIA GPU detected. Will setup CPU-only environment.”
fi

# Update system

log “Updating system packages…”
sudo apt update && sudo apt upgrade -y

# Install essential packages

log “Installing essential development packages…”
sudo apt install -y   
curl   
wget   
git   
vim   
htop   
tree   
unzip   
build-essential   
software-properties-common   
apt-transport-https   
ca-certificates   
gnupg   
lsb-release   
python3   
python3-pip   
python3-venv   
python3-dev   
nodejs   
npm   
redis-server   
postgresql   
postgresql-contrib

# Audio processing dependencies

log “Installing audio processing libraries…”
sudo apt install -y   
ffmpeg   
libsndfile1-dev   
libportaudio2   
portaudio19-dev   
libasound2-dev   
libpulse-dev   
pulseaudio   
alsa-utils

# NVIDIA GPU Setup (if available)

if [ “$GPU_AVAILABLE” = true ]; then
log “Setting up NVIDIA drivers and CUDA…”

```
# Remove any existing NVIDIA drivers
sudo apt remove --purge nvidia* -y
sudo apt autoremove -y

# Install NVIDIA drivers (latest stable)
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# Add NVIDIA package repositories
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

# Install CUDA Toolkit 12.9 (latest as of July 2025)
sudo apt install -y cuda-toolkit-12-9

# Install cuDNN
sudo apt install -y libcudnn8 libcudnn8-dev

# Add CUDA to PATH
echo 'export PATH=/usr/local/cuda-12.9/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc

log "NVIDIA setup complete. REBOOT REQUIRED for drivers to take effect."
```

fi

# Docker installation

log “Installing Docker and Docker Compose…”
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg –dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo “deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable” | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group

sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit (if GPU available)

if [ “$GPU_AVAILABLE” = true ]; then
log “Installing NVIDIA Container Toolkit…”
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)   
&& curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg –dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg   
&& curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list |   
sed ‘s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g’ |   
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure –runtime=docker
sudo systemctl restart docker
fi

# Python environment setup

log “Setting up Python development environment…”

# Create virtual environment for RAG system

python3 -m venv ~/rag-env
source ~/rag-env/bin/activate

# Upgrade pip

pip install –upgrade pip setuptools wheel

# Core ML/AI packages

log “Installing Python ML/AI packages…”
pip install torch torchvision torchaudio –index-url https://download.pytorch.org/whl/cu121
pip install transformers accelerate bitsandbytes
pip install sentence-transformers
pip install openai anthropic
pip install langchain langchain-community langchain-openai
pip install chromadb faiss-cpu weaviate-client qdrant-client
pip install numpy pandas scikit-learn matplotlib seaborn
pip install jupyter jupyterlab

# Audio processing packages

log “Installing audio processing Python packages…”
pip install whisper
pip install pyannote.audio
pip install librosa soundfile
pip install speech_recognition
pip install pydub

# Web framework and API packages

log “Installing web framework packages…”
pip install fastapi uvicorn[standard]
pip install flask flask-cors
pip install websockets
pip install redis celery
pip install sqlalchemy psycopg2-binary
pip install pydantic python-multipart

# Development tools

log “Installing development tools…”
pip install black flake8 isort pytest pytest-asyncio
pip install python-dotenv
pip install rich typer click

# Node.js and frontend tools

log “Setting up Node.js environment…”
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install global Node.js packages

sudo npm install -g yarn create-react-app @vue/cli next pnpm

# VS Code installation

log “Installing Visual Studio Code…”
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg –dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c ‘echo “deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main” > /etc/apt/sources.list.d/vscode.list’
sudo apt update
sudo apt install -y code

# PostgreSQL setup

log “Configuring PostgreSQL…”
sudo -u postgres createdb ragdb
sudo -u postgres createuser –createdb –pwprompt raguser

# Redis setup

log “Configuring Redis…”
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Create project directory structure

log “Creating RAG project structure…”
mkdir -p ~/rag-system/{
backend/{api,agents,rag,audio,models,database},
frontend/{web,mobile},
docker,
configs,
scripts,
data/{documents,audio,vectors},
logs,
tests
}

# Create basic configuration files

log “Creating configuration templates…”

# Docker Compose template

cat > ~/rag-system/docker/docker-compose.dev.yml << ‘EOF’
version: ‘3.8’

services:
postgres:
image: postgres:15
environment:
POSTGRES_DB: ragdb
POSTGRES_USER: raguser
POSTGRES_PASSWORD: ragpass
ports:
- “5432:5432”
volumes:
- postgres_data:/var/lib/postgresql/data

redis:
image: redis:7-alpine
ports:
- “6379:6379”

weaviate:
command:
- –host
- 0.0.0.0
- –port
- ‘8080’
- –scheme
- http
image: semitechnologies/weaviate:1.21.2
ports:
- 8080:8080
restart: on-failure:0
environment:
QUERY_DEFAULTS_LIMIT: 25
AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: ‘true’
PERSISTENCE_DATA_PATH: ‘/var/lib/weaviate’
DEFAULT_VECTORIZER_MODULE: ‘none’
ENABLE_MODULES: ‘text2vec-transformers’
volumes:
- weaviate_data:/var/lib/weaviate

volumes:
postgres_data:
weaviate_data:
EOF

# Environment template

cat > ~/rag-system/configs/.env.template << ‘EOF’

# Database

DATABASE_URL=postgresql://raguser:ragpass@localhost:5432/ragdb
REDIS_URL=redis://localhost:6379

# API Keys

OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key

# Vector Database

WEAVIATE_URL=http://localhost:8080

# Audio

WHISPER_MODEL=base
ENABLE_SPEAKER_DIARIZATION=true

# Development

DEBUG=true
LOG_LEVEL=INFO
EOF

# Basic requirements.txt

cat > ~/rag-system/requirements.txt << ‘EOF’

# Core ML/AI

torch>=2.0.0
transformers>=4.30.0
sentence-transformers>=2.2.0
accelerate>=0.20.0

# Vector Databases

weaviate-client>=3.22.0
chromadb>=0.4.0
faiss-cpu>=1.7.4

# Audio Processing

openai-whisper>=20230314
pyannote.audio>=2.1.1
librosa>=0.10.0
soundfile>=0.12.0

# Web Framework

fastapi>=0.100.0
uvicorn[standard]>=0.22.0
websockets>=11.0
python-multipart>=0.0.6

# Database

sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
redis>=4.5.0

# Development

python-dotenv>=1.0.0
pydantic>=2.0.0
pytest>=7.4.0
black>=23.0.0
EOF

# Create activation script

cat > ~/rag-system/activate.sh << ‘EOF’
#!/bin/bash
source ~/rag-env/bin/activate
cd ~/rag-system
export PYTHONPATH=$PYTHONPATH:$(pwd)
echo “RAG Development Environment Activated!”
echo “Project directory: $(pwd)”
echo “Python: $(which python)”
echo “Pip packages: $(pip list | wc -l) installed”
EOF
chmod +x ~/rag-system/activate.sh

# Create basic FastAPI app

cat > ~/rag-system/backend/api/main.py << ‘EOF’
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title=“RAG System API”, version=“1.0.0”)

app.add_middleware(
CORSMiddleware,
allow_origins=[”*”],
allow_credentials=True,
allow_methods=[”*”],
allow_headers=[”*”],
)

@app.get(”/”)
async def root():
return {“message”: “RAG System API is running!”}

@app.get(”/health”)
async def health():
return {“status”: “healthy”, “version”: “1.0.0”}

@app.post(”/upload/audio”)
async def upload_audio(file: UploadFile = File(…)):
return {“filename”: file.filename, “status”: “uploaded”}

if **name** == “**main**”:
uvicorn.run(app, host=“0.0.0.0”, port=8000)
EOF

# Final setup

log “Final setup steps…”

# Add activation to bashrc

echo “# RAG System” >> ~/.bashrc
echo “alias rag=‘source ~/rag-system/activate.sh’” >> ~/.bashrc

# Create desktop shortcut

cat > ~/Desktop/RAG-System.desktop << ‘EOF’
[Desktop Entry]
Version=1.0
Type=Application
Name=RAG System
Comment=Launch RAG Development Environment
Exec=gnome-terminal – bash -c “source ~/rag-system/activate.sh; bash”
Icon=applications-development
Terminal=true
Categories=Development;
EOF
chmod +x ~/Desktop/RAG-System.desktop

# Installation summary

log “Installation Summary:”
echo “==================================”
echo “✅ Ubuntu 24.04 LTS optimized setup”
echo “✅ Python 3.12 + Virtual Environment”
echo “✅ Docker + Docker Compose”
if [ “$GPU_AVAILABLE” = true ]; then
echo “✅ NVIDIA Drivers + CUDA 12.9”
echo “✅ NVIDIA Container Toolkit”
fi
echo “✅ Audio Processing Libraries”
echo “✅ ML/AI Python Packages”
echo “✅ PostgreSQL + Redis”
echo “✅ VS Code”
echo “✅ Project Structure Created”
echo “==================================”

warning “IMPORTANT NEXT STEPS:”
echo “1. REBOOT your system to activate NVIDIA drivers”
echo “2. Run ‘source ~/.bashrc’ or restart terminal”
echo “3. Use ‘rag’ command to activate environment”
echo “4. Copy configs/.env.template to .env and fill in API keys”
echo “5. Run ‘cd ~/rag-system/docker && docker-compose -f docker-compose.dev.yml up -d’”
echo “”
echo “Project location: ~/rag-system”
echo “Activation: ‘rag’ or ‘source ~/rag-system/activate.sh’”

log “Setup completed successfully! 🎉”

# Test GPU setup if available

if [ “$GPU_AVAILABLE” = true ]; then
echo “”
echo “After reboot, test GPU setup with:”
echo “nvidia-smi”
echo “docker run –rm –gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi”
fi