#!/bin/bash

# Ubuntu 24.04 LTS Docker & Kubernetes Setup mit n8n und ChatGPT API

# Automatische Installation und Konfiguration

set -e

# Konfiguration - Diese Werte anpassen

OPENAI_API_KEY=””                   # ChatGPT API Key hier eintragen
N8N_PASSWORD=“admin123”             # n8n Admin Passwort
N8N_USER=“admin”                    # n8n Benutzer
LAN_IP=””                           # Automatisch ermittelt wenn leer
TIMEZONE=“Europe/Berlin”            # Zeitzone

# Kubernetes Namespace

K8S_NAMESPACE=“automation”

# Ports

N8N_PORT=5678
CHATGPT_API_PORT=3001

# Farben für Output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
PURPLE=’\033[0;35m’
NC=’\033[0m’

# Logging Funktionen

log() {
echo -e “${GREEN}[$(date +’%Y-%m-%d %H:%M:%S’)] $1${NC}”
}

error() {
echo -e “${RED}[ERROR] $1${NC}”
exit 1
}

warning() {
echo -e “${YELLOW}[WARNING] $1${NC}”
}

info() {
echo -e “${BLUE}[INFO] $1${NC}”
}

success() {
echo -e “${PURPLE}[SUCCESS] $1${NC}”
}

# Root-Check

check_root() {
if [[ $EUID -ne 0 ]]; then
error “Dieses Script muss als root ausgeführt werden”
fi
}

# Ubuntu Version prüfen

check_ubuntu_version() {
if ! grep -q “Ubuntu 24.04” /etc/os-release; then
warning “Nicht Ubuntu 24.04 erkannt. Script könnte nicht korrekt funktionieren.”
else
log “Ubuntu 24.04 LTS erkannt”
fi
}

# LAN IP ermitteln

get_lan_ip() {
if [[ -z “$LAN_IP” ]]; then
LAN_IP=$(ip route get 8.8.8.8 | awk ‘{print $7}’ | head -n1)
log “LAN IP automatisch ermittelt: $LAN_IP”
fi
}

# System Updates

update_system() {
log “Aktualisiere System…”
apt update -y
apt upgrade -y
apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
}

# Docker Installation

install_docker() {
log “Installiere Docker…”

```
# Docker GPG Key hinzufügen
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker Repository hinzufügen
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Service starten
systemctl enable docker
systemctl start docker

# Aktueller Benutzer zu docker Gruppe hinzufügen
if [[ -n "$SUDO_USER" ]]; then
    usermod -aG docker $SUDO_USER
    log "Benutzer $SUDO_USER zu docker Gruppe hinzugefügt"
fi

success "Docker erfolgreich installiert"
```

}

# Kubernetes Installation (k3s - leichtgewichtig)

install_kubernetes() {
log “Installiere Kubernetes (k3s)…”

```
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# k3s Service starten
systemctl enable k3s
systemctl start k3s

# kubectl für alle Benutzer verfügbar machen
mkdir -p /home/$SUDO_USER/.kube
cp /etc/rancher/k3s/k3s.yaml /home/$SUDO_USER/.kube/config
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube

# kubectl alias
echo 'alias k=kubectl' >> /home/$SUDO_USER/.bashrc

success "Kubernetes (k3s) erfolgreich installiert"
```

}

# Kubernetes Namespace erstellen

create_k8s_namespace() {
log “Erstelle Kubernetes Namespace: $K8S_NAMESPACE”
kubectl create namespace $K8S_NAMESPACE –dry-run=client -o yaml | kubectl apply -f -
}

# n8n Kubernetes Deployment

deploy_n8n() {
log “Deploye n8n zu Kubernetes…”

```
cat > /tmp/n8n-deployment.yaml << EOF
```

## apiVersion: apps/v1
kind: Deployment
metadata:
name: n8n
namespace: $K8S_NAMESPACE
labels:
app: n8n
spec:
replicas: 1
selector:
matchLabels:
app: n8n
template:
metadata:
labels:
app: n8n
spec:
containers:
- name: n8n
image: n8nio/n8n:latest
ports:
- containerPort: 5678
env:
- name: N8N_BASIC_AUTH_ACTIVE
value: “true”
- name: N8N_BASIC_AUTH_USER
value: “$N8N_USER”
- name: N8N_BASIC_AUTH_PASSWORD
value: “$N8N_PASSWORD”
- name: WEBHOOK_URL
value: “http://$LAN_IP:$N8N_PORT”
- name: N8N_HOST
value: “$LAN_IP”
- name: N8N_PORT
value: “$N8N_PORT”
- name: N8N_PROTOCOL
value: “http”
- name: TZ
value: “$TIMEZONE”
volumeMounts:
- name: n8n-data
mountPath: /home/node/.n8n
volumes:
- name: n8n-data
hostPath:
path: /opt/n8n-data
type: DirectoryOrCreate

apiVersion: v1
kind: Service
metadata:
name: n8n-service
namespace: $K8S_NAMESPACE
spec:
type: NodePort
selector:
app: n8n
ports:

- port: 5678
  targetPort: 5678
  nodePort: $N8N_PORT
  protocol: TCP
  EOF
  
  kubectl apply -f /tmp/n8n-deployment.yaml
  success “n8n Deployment erstellt”
  }

# ChatGPT API Container (Node.js API Gateway)

deploy_chatgpt_api() {
log “Deploye ChatGPT API Gateway…”

```
if [[ -z "$OPENAI_API_KEY" ]]; then
    warning "OPENAI_API_KEY nicht gesetzt. Setze einen Dummy-Wert."
    OPENAI_API_KEY="your-openai-api-key-here"
fi

# Erstelle Node.js API Gateway
mkdir -p /opt/chatgpt-api
cat > /opt/chatgpt-api/package.json << EOF
```

{
“name”: “chatgpt-api-gateway”,
“version”: “1.0.0”,
“description”: “ChatGPT API Gateway für n8n”,
“main”: “server.js”,
“scripts”: {
“start”: “node server.js”
},
“dependencies”: {
“express”: “^4.18.2”,
“cors”: “^2.8.5”,
“axios”: “^1.6.0”
}
}
EOF

```
cat > /opt/chatgpt-api/server.js << 'EOF'
```

const express = require(‘express’);
const cors = require(‘cors’);
const axios = require(‘axios’);

const app = express();
const PORT = process.env.PORT || 3001;
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

app.use(cors());
app.use(express.json({ limit: ‘10mb’ }));

// Health Check
app.get(’/health’, (req, res) => {
res.json({ status: ‘OK’, timestamp: new Date().toISOString() });
});

// ChatGPT API Proxy
app.post(’/chat/completions’, async (req, res) => {
try {
if (!OPENAI_API_KEY || OPENAI_API_KEY === ‘your-openai-api-key-here’) {
return res.status(400).json({
error: ‘OpenAI API Key nicht konfiguriert’
});
}

```
    const response = await axios.post('https://api.openai.com/v1/chat/completions', 
        req.body, 
        {
            headers: {
                'Authorization': `Bearer ${OPENAI_API_KEY}`,
                'Content-Type': 'application/json'
            }
        }
    );

    res.json(response.data);
} catch (error) {
    console.error('ChatGPT API Error:', error.message);
    res.status(error.response?.status || 500).json({
        error: error.response?.data || 'Internal Server Error'
    });
}
```

});

// Einfache Chat Funktion für Tests
app.post(’/simple-chat’, async (req, res) => {
try {
const { message, model = ‘gpt-3.5-turbo’ } = req.body;

```
    if (!message) {
        return res.status(400).json({ error: 'Message required' });
    }

    const chatData = {
        model: model,
        messages: [
            { role: 'user', content: message }
        ],
        max_tokens: 1000,
        temperature: 0.7
    };

    const response = await axios.post('/chat/completions', chatData, {
        baseURL: `http://localhost:${PORT}`,
        headers: { 'Content-Type': 'application/json' }
    });

    res.json({
        message: response.data.choices[0].message.content,
        usage: response.data.usage
    });
} catch (error) {
    res.status(500).json({ error: error.message });
}
```

});

app.listen(PORT, ‘0.0.0.0’, () => {
console.log(`ChatGPT API Gateway läuft auf Port ${PORT}`);
console.log(`Health Check: http://localhost:${PORT}/health`);
});
EOF

```
# Dockerfile erstellen
cat > /opt/chatgpt-api/Dockerfile << EOF
```

FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install –production
COPY server.js ./
EXPOSE 3001
CMD [“npm”, “start”]
EOF

```
# Docker Image bauen
cd /opt/chatgpt-api
docker build -t chatgpt-api-gateway:latest .

# Kubernetes Deployment
cat > /tmp/chatgpt-api-deployment.yaml << EOF
```

## apiVersion: apps/v1
kind: Deployment
metadata:
name: chatgpt-api
namespace: $K8S_NAMESPACE
labels:
app: chatgpt-api
spec:
replicas: 1
selector:
matchLabels:
app: chatgpt-api
template:
metadata:
labels:
app: chatgpt-api
spec:
containers:
- name: chatgpt-api
image: chatgpt-api-gateway:latest
imagePullPolicy: Never
ports:
- containerPort: 3001
env:
- name: OPENAI_API_KEY
value: “$OPENAI_API_KEY”
- name: PORT
value: “3001”

apiVersion: v1
kind: Service
metadata:
name: chatgpt-api-service
namespace: $K8S_NAMESPACE
spec:
type: NodePort
selector:
app: chatgpt-api
ports:

- port: 3001
  targetPort: 3001
  nodePort: $CHATGPT_API_PORT
  protocol: TCP
  EOF
  
  kubectl apply -f /tmp/chatgpt-api-deployment.yaml
  success “ChatGPT API Gateway deployed”
  }

# Firewall konfigurieren

configure_firewall() {
log “Konfiguriere Firewall…”

```
ufw --force enable
ufw allow ssh
ufw allow $N8N_PORT/tcp
ufw allow $CHATGPT_API_PORT/tcp
ufw allow 6443/tcp  # Kubernetes API

success "Firewall konfiguriert"
```

}

# Services Status prüfen

check_services() {
log “Prüfe Services Status…”

```
sleep 30  # Warten bis Services gestartet sind

echo -e "\n${BLUE}=== Service Status ===${NC}"
echo -e "Docker: $(systemctl is-active docker)"
echo -e "k3s: $(systemctl is-active k3s)"

echo -e "\n${BLUE}=== Kubernetes Pods ===${NC}"
kubectl get pods -n $K8S_NAMESPACE

echo -e "\n${BLUE}=== Kubernetes Services ===${NC}"
kubectl get services -n $K8S_NAMESPACE
```

}

# Installations-Info anzeigen

show_installation_info() {
echo -e “\n${GREEN}=== Installation Abgeschlossen ===${NC}\n”

```
echo -e "${BLUE}Zugriff URLs:${NC}"
echo -e "  n8n Web Interface: http://$LAN_IP:$N8N_PORT"
echo -e "  n8n Login: $N8N_USER / $N8N_PASSWORD"
echo -e "  ChatGPT API: http://$LAN_IP:$CHATGPT_API_PORT"
echo -e "  API Health Check: http://$LAN_IP:$CHATGPT_API_PORT/health"

echo -e "\n${BLUE}API Endpoints:${NC}"
echo -e "  ChatGPT Proxy: POST http://$LAN_IP:$CHATGPT_API_PORT/chat/completions"
echo -e "  Simple Chat: POST http://$LAN_IP:$CHATGPT_API_PORT/simple-chat"

echo -e "\n${BLUE}Kubernetes Commands:${NC}"
echo -e "  Pods anzeigen: kubectl get pods -n $K8S_NAMESPACE"
echo -e "  Services anzeigen: kubectl get services -n $K8S_NAMESPACE"
echo -e "  Logs anzeigen: kubectl logs -n $K8S_NAMESPACE deployment/n8n"

echo -e "\n${YELLOW}Wichtige Hinweise:${NC}"
echo -e "  1. OpenAI API Key in der Konfiguration setzen"
echo -e "  2. n8n Passwort nach dem ersten Login ändern"
echo -e "  3. Firewall ist aktiviert - nur notwendige Ports geöffnet"
echo -e "  4. Services sind über das gesamte LAN erreichbar"

if [[ "$OPENAI_API_KEY" == "your-openai-api-key-here" ]]; then
    echo -e "\n${RED}⚠️  ACHTUNG: OpenAI API Key nicht gesetzt!${NC}"
    echo -e "   API Key setzen: kubectl set env deployment/chatgpt-api -n $K8S_NAMESPACE OPENAI_API_KEY=your-real-api-key"
fi
```

}

# Test API Funktion

test_api() {
log “Teste API Endpoints…”

```
# Health Check
if curl -s http://$LAN_IP:$CHATGPT_API_PORT/health > /dev/null; then
    success "ChatGPT API Gateway erreichbar"
else
    warning "ChatGPT API Gateway nicht erreichbar"
fi

# n8n Check
if curl -s http://$LAN_IP:$N8N_PORT > /dev/null; then
    success "n8n Web Interface erreichbar"
else
    warning "n8n Web Interface nicht erreichbar"
fi
```

}

# Hauptfunktion

main() {
log “Starte Ubuntu 24.04 Docker & Kubernetes Setup…”

```
check_root
check_ubuntu_version
get_lan_ip

update_system
install_docker
install_kubernetes

sleep 10  # Warten bis k3s vollständig gestartet ist

create_k8s_namespace
deploy_n8n
deploy_chatgpt_api
configure_firewall

check_services
test_api
show_installation_info

success "Setup erfolgreich abgeschlossen!"
```

}

# API Key Eingabe wenn nicht gesetzt

prompt_api_key() {
if [[ -z “$OPENAI_API_KEY” ]]; then
echo -e “${YELLOW}OpenAI API Key eingeben (oder Enter für später):${NC}”
read -p “API Key: “ api_key
if [[ -n “$api_key” ]]; then
OPENAI_API_KEY=”$api_key”
fi
fi
}

# Script Hilfe

show_help() {
echo “Ubuntu 24.04 Docker & Kubernetes Setup mit n8n und ChatGPT”
echo “”
echo “Verwendung: $0 [OPTIONEN]”
echo “”
echo “Das Script installiert:”
echo “  - Docker & Docker Compose”
echo “  - Kubernetes (k3s)”
echo “  - n8n Workflow Automation”
echo “  - ChatGPT API Gateway”
echo “”
echo “Optionen:”
echo “  -h, –help    Diese Hilfe anzeigen”
echo “  –no-prompt   Keine interaktive API Key Eingabe”
echo “”
echo “Vor der Ausführung OPENAI_API_KEY Variable setzen!”
}

# Kommandozeilen-Parameter

case “${1:-}” in
-h|–help)
show_help
exit 0
;;
–no-prompt)
main
;;
*)
prompt_api_key
main
;;
esac