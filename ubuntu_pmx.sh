#!/bin/bash

# Ubuntu Server Proxmox VM Installation Script

# Automatische Installation eines Ubuntu Servers als Proxmox VM mit SSH-Zugang

set -e

# Konfiguration - Diese Werte anpassen

VM_ID=100                           # VM ID (eindeutig)
VM_NAME=“ubuntu-server”             # VM Name
VM_CORES=2                          # CPU Cores
VM_MEMORY=2048                      # RAM in MB
VM_DISK_SIZE=20G                    # Festplattengröße
VM_STORAGE=“local-lvm”              # Proxmox Storage
VM_BRIDGE=“vmbr0”                   # Netzwerk Bridge
ISO_STORAGE=“local”                 # ISO Storage Location
SSH_USER=“admin”                    # SSH Benutzer
SSH_PASSWORD=“SecurePass123!”       # SSH Passwort (später ändern!)
VM_IP=“192.168.1.100/24”           # Statische IP (optional)
VM_GATEWAY=“192.168.1.1”           # Gateway (optional)
VM_DNS=“8.8.8.8”                   # DNS Server

# Farben für Output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Logging Funktion

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

# Prüfen ob das Script als root läuft

check_root() {
if [[ $EUID -ne 0 ]]; then
error “Dieses Script muss als root ausgeführt werden”
fi
}

# Prüfen ob Proxmox VE installiert ist

check_proxmox() {
if ! command -v qm &> /dev/null; then
error “Proxmox VE ist nicht installiert oder qm Kommando nicht verfügbar”
fi
log “Proxmox VE erkannt”
}

# Prüfen ob VM ID bereits existiert

check_vm_exists() {
if qm status $VM_ID &> /dev/null; then
error “VM mit ID $VM_ID existiert bereits”
fi
log “VM ID $VM_ID ist verfügbar”
}

# Ubuntu ISO herunterladen falls nicht vorhanden

download_ubuntu_iso() {
local iso_path=”/var/lib/vz/template/iso”
local ubuntu_iso=“ubuntu-22.04.3-live-server-amd64.iso”
local iso_url=“https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso”

```
if [[ ! -f "$iso_path/$ubuntu_iso" ]]; then
    log "Ubuntu ISO wird heruntergeladen..."
    cd "$iso_path"
    wget -O "$ubuntu_iso" "$iso_url" || error "Fehler beim Herunterladen der Ubuntu ISO"
    log "Ubuntu ISO erfolgreich heruntergeladen"
else
    log "Ubuntu ISO bereits vorhanden"
fi

echo "$ubuntu_iso"
```

}

# Cloud-init Konfiguration erstellen

create_cloud_init_config() {
local user_data=”/tmp/user-data-$VM_ID”
local meta_data=”/tmp/meta-data-$VM_ID”

```
# User-data für Cloud-init
cat > "$user_data" << EOF
```

#cloud-config
users:

- name: $SSH_USER
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
  lock_passwd: false
  passwd: $(openssl passwd -6 ‘$SSH_PASSWORD’)
  ssh_authorized_keys: []

# SSH Konfiguration

ssh_pwauth: true
disable_root: false

# Packages installieren

packages:

- openssh-server
- curl
- wget
- vim
- htop
- net-tools

# Services aktivieren

runcmd:

- systemctl enable ssh
- systemctl start ssh
- ufw allow ssh
- echo ‘PermitRootLogin yes’ >> /etc/ssh/sshd_config
- systemctl restart ssh

# Netzwerk Konfiguration (falls statische IP gewünscht)

write_files:

- path: /etc/netplan/00-installer-config.yaml
  content: |
  network:
  version: 2
  ethernets:
  enp0s18:
  addresses: [$VM_IP]
  gateway4: $VM_GATEWAY
  nameservers:
  addresses: [$VM_DNS]
  permissions: ‘0644’

final_message: “Ubuntu Server Installation abgeschlossen. SSH ist verfügbar.”
EOF

```
# Meta-data für Cloud-init
cat > "$meta_data" << EOF
```

instance-id: $VM_NAME
local-hostname: $VM_NAME
EOF

```
log "Cloud-init Konfiguration erstellt"
```

}

# VM erstellen

create_vm() {
local ubuntu_iso=$(download_ubuntu_iso)

```
log "Erstelle VM $VM_ID ($VM_NAME)..."

# VM erstellen
qm create $VM_ID \
    --name $VM_NAME \
    --cores $VM_CORES \
    --memory $VM_MEMORY \
    --net0 virtio,bridge=$VM_BRIDGE \
    --scsihw virtio-scsi-pci \
    --scsi0 $VM_STORAGE:$VM_DISK_SIZE \
    --ide2 $ISO_STORAGE:iso/$ubuntu_iso,media=cdrom \
    --boot order=scsi0 \
    --ostype l26 \
    --agent enabled=1

log "VM $VM_ID erfolgreich erstellt"
```

}

# Autostart konfigurieren

configure_autostart() {
log “Konfiguriere Autostart für VM $VM_ID…”
qm set $VM_ID –onboot 1
}

# VM starten

start_vm() {
log “Starte VM $VM_ID…”
qm start $VM_ID

```
# Warten bis VM gestartet ist
local timeout=300
local counter=0

while [[ $counter -lt $timeout ]]; do
    if qm status $VM_ID | grep -q "running"; then
        log "VM $VM_ID erfolgreich gestartet"
        return 0
    fi
    sleep 5
    counter=$((counter + 5))
    info "Warte auf VM Start... (${counter}s/${timeout}s)"
done

error "VM Start Timeout erreicht"
```

}

# Installations-Info anzeigen

show_installation_info() {
echo -e “\n${GREEN}=== Ubuntu Server VM Installation Abgeschlossen ===${NC}\n”
echo -e “${BLUE}VM Details:${NC}”
echo -e “  VM ID: $VM_ID”
echo -e “  Name: $VM_NAME”
echo -e “  Cores: $VM_CORES”
echo -e “  Memory: ${VM_MEMORY}MB”
echo -e “  Disk: $VM_DISK_SIZE”
echo -e “  Network: $VM_BRIDGE”
echo -e “\n${BLUE}SSH Zugang:${NC}”
echo -e “  Benutzer: $SSH_USER”
echo -e “  Passwort: $SSH_PASSWORD”
echo -e “  IP: $VM_IP (falls konfiguriert)”
echo -e “\n${YELLOW}Nächste Schritte:${NC}”
echo -e “  1. Warte bis Ubuntu Installation abgeschlossen ist”
echo -e “  2. Verbinde via SSH: ssh $SSH_USER@<vm-ip>”
echo -e “  3. Ändere das Standard-Passwort!”
echo -e “  4. Konfiguriere SSH-Keys für bessere Sicherheit”
echo -e “\n${YELLOW}VM Verwaltung:${NC}”
echo -e “  Status: qm status $VM_ID”
echo -e “  Stoppen: qm stop $VM_ID”
echo -e “  Starten: qm start $VM_ID”
echo -e “  Console: qm terminal $VM_ID”
}

# Hauptfunktion

main() {
log “Starte Ubuntu Server VM Installation…”

```
check_root
check_proxmox
check_vm_exists
create_vm
configure_autostart
start_vm
show_installation_info

log "Installation erfolgreich abgeschlossen!"
```

}

# Script Hilfe

show_help() {
echo “Ubuntu Server Proxmox VM Installation Script”
echo “”
echo “Verwendung: $0 [OPTIONEN]”
echo “”
echo “Das Script erstellt automatisch eine Ubuntu Server VM in Proxmox”
echo “mit SSH-Zugang und grundlegender Konfiguration.”
echo “”
echo “Vor der Ausführung die Konfigurationsvariablen am Anfang”
echo “des Scripts anpassen!”
echo “”
echo “Optionen:”
echo “  -h, –help    Diese Hilfe anzeigen”
echo “”
}

# Kommandozeilen-Parameter verarbeiten

case “${1:-}” in
-h|–help)
show_help
exit 0
;;
*)
main “$@”
;;
esac