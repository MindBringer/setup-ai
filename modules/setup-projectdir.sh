#!/bin/bash
set -euo pipefail

# Funktion zur Prüfung von Kommandos
check_command() {
  local cmd_output
  if cmd_output="$($@ 2>&1)"; then
    echo "✅ Befehl erfolgreich: $*"
  else
    echo "❌ Fehler: $*"
    echo "$cmd_output"
    return 1
  fi
}

# Projektverzeichnis, .env, Dateikopien...
echo "[MODUL] setup-projectdir"
### === [3/8] Verzeichnisse & Dateien ===
echo "[3/8] 📁 Projektverzeichnis vorbereiten..."
mkdir -p "$PROJECT_DIR/keycloak"
cd "$PROJECT_DIR"

if [ ! -f .env ]; then
  cat <<EOD > .env
EMBEDDING_URL=http://embedding:8000
EMBEDDING_API_KEY=YOUR_API_KEY_HERE
QDRANT_URL=http://qdrant:6333
WHISPER_HF_TOKEN=hf_xxxxxxxxxxxxx
VITE_API_BASE_URL=http://api.local
VITE_KEYCLOAK_URL=https://auth.local
VITE_KEYCLOAK_REALM=mein-unternehmen
VITE_KEYCLOAK_CLIENT_ID=frontend
EOD
  echo "⚠️ .env Dummy angelegt – bitte anpassen!"
fi
export $(grep -v '^[[:space:]]*#' .env | xargs)

### === [4/8] Dateien kopieren ===
echo "[4/8] 📂 Dateien vorbereiten..."
cp "$SCRIPT_DIR/docker/docker-compose.yml" "$PROJECT_DIR/docker-compose.yml"
cp "$SCRIPT_DIR/docker/Caddyfile" "$PROJECT_DIR/Caddyfile"

# Kopiere frontend build
mkdir -p "$PROJECT_DIR/frontend"
cp -r "$SCRIPT_DIR/docker/frontend/." "$PROJECT_DIR/frontend/"
#cd "$PROJECT_DIR/frontend"
#[ ! -d node_modules ] && npm install
#npm run build

# Kopiere n8n-Dateien
mkdir -p "$PROJECT_DIR/n8n"
cp -r "$SCRIPT_DIR/docker/n8n/." "$PROJECT_DIR/n8n/"

# Kopiere whisperX-Dateien
mkdir -p "$PROJECT_DIR/whisperx"
cp -r "$SCRIPT_DIR/docker/whisperx/." "$PROJECT_DIR/whisperx/"

# Kopiere haystack-Dateien
mkdir -p "$PROJECT_DIR/backend"
cp -r "$SCRIPT_DIR/docker/backend/." "$PROJECT_DIR/backend/"

# Kopiere crewAI-Dateien
mkdir -p "$PROJECT_DIR/crewai"
cp -r "$SCRIPT_DIR/docker/crewai/." "$PROJECT_DIR/crewai/"

### === [5/7] Firewall vorbereiten ===
echo "[5/7] 🔐 Konfiguriere Firewall..."
if command -v ufw &>/dev/null; then
  sudo ufw allow 22/tcp
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw allow 5678/tcp
  sudo ufw allow 8080/tcp
  sudo ufw allow 6333/tcp
  sudo ufw allow 8001/tcp
  sudo ufw allow 9000/tcp
  sudo ufw allow 11434/tcp
  sudo ufw --force enable || true
fi
