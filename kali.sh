#!/bin/bash
# KALI LINUX ADVANCED (ANTI-CRASH EDITION)
# RAM: 2GB (Safe for Codespace) | Mouse: Trackpad Style

# --- COLORS ---
ORANGE='\033[1;33m'
GRAY='\033[1;90m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# --- CONFIGURATION ---
ISO_LINK="https://archive.kali.org/kali-images/kali-2025.3/kali-linux-2025.3-live-amd64.iso"
ISO_NAME="kali-linux-2025.3-live-amd64.iso"
DISK_NAME="kali_storage.qcow2"

# --- FUNCTIONS ---

function header() {
    clear
    echo -e "${GRAY}------------------------------------------------${NC}"
    echo -e "${ORANGE}   🚀 KALI LINUX: SAFE MODE (2GB RAM)       ${NC}"
    echo -e "${GRAY}------------------------------------------------${NC}"
}

function stop_vm() {
    echo -e "${ORANGE}[*]${GRAY} Stopping VM...${NC}"
    pkill -f qemu-system-x86_64 > /dev/null 2>&1
    killall qemu-system-x86_64 > /dev/null 2>&1
    pkill -f websockify > /dev/null 2>&1
    pkill -f ssh > /dev/null 2>&1
    rm -f tunnel.log
    sleep 2
    echo -e "${GREEN}[✓] VM Stopped.${NC}"
}

function create_vm() {
    header
    echo -e "${ORANGE}[1/4]${GRAY} Installing Tools...${NC}"
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

    echo -e "${ORANGE}[2/4]${GRAY} Setting up VNC...${NC}"
    if [ ! -d "novnc" ]; then
        git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
        git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
    fi

    echo -e "${ORANGE}[3/4]${GRAY} Checking ISO (2025.3)...${NC}"
    if [ ! -f "$ISO_NAME" ]; then
        wget --show-progress -O "$ISO_NAME" "$ISO_LINK"
    else
        echo -e "${GREEN}[✓] ISO Ready.${NC}"
    fi

    echo -e "${ORANGE}[4/4]${GRAY} Checking Storage (100GB)...${NC}"
    if [ ! -f "$DISK_NAME" ]; then
        qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
    else
        echo -e "${GREEN}[✓] Disk Ready.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Setup Done! Press Enter.${NC}"
    read
}

function start_vm() {
    header
    if [ ! -f "$ISO_NAME" ]; then
        echo -e "${RED}❌ Error: Please run Option 1 (Create VM) first.${NC}"
        read
        return
    fi

    echo -e "${ORANGE}[*]${GRAY} Cleaning old processes...${NC}"
    stop_vm > /dev/null 2>&1

    echo -e "${ORANGE}[*]${GRAY} Booting Kali (2GB RAM Mode)...${NC}"
    
    # --- CRASH FIX: RAM reduced to 2G ---
    # Mouse: USB Mouse added for smooth trackpad feel without glitches
    qemu-system-x86_64 \
      -m 2G \
      -smp 2 \
      -usb -device usb-mouse \
      -hda "$DISK_NAME" \
      -cdrom "$ISO_NAME" \
      -boot d \
      -vnc :0 \
      -net nic,model=virtio -net user \
      -daemonize

    echo -e "${ORANGE}[*]${GRAY} Starting VNC...${NC}"
    ./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

    echo -e "${ORANGE}[*]${GRAY} Generating Link...${NC}"
    nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

    echo -e "${GRAY}    (Waiting for URL...)${NC}"
    count=0
    while ! grep -q "https://" tunnel.log; do
        sleep 1
        ((count++))
        if [ $count -ge 20 ]; then
             echo -e "${RED}⚠️  Retrying Tunnel...${NC}"
             pkill -f ssh
             nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &
             count=0
        fi
    done

    PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

    clear
    echo -e "${GRAY}========================================================${NC}"
    echo -e "${GREEN}      ✅  VM RUNNING (2GB RAM - SAFE)  ${NC}"
    echo -e "${GRAY}========================================================${NC}"
    echo ""
    echo -e "${GRAY} 🔗 URL:  ${ORANGE}$PUBLIC_URL${NC}"
    echo ""
    echo -e "${GRAY}========================================================${NC}"
    echo -e "${GRAY} 🔄 TRICK: ${ORANGE}Run 'Restart' if link dies.${NC}"
    echo -e "${GRAY}========================================================${NC}"
    echo ""
    echo -e "${ORANGE}Press Enter to return to Menu.${NC}"
    read
}

# --- MENU ---
while true; do
    header
    echo -e "${ORANGE} 1.${GRAY} Create Kali VM"
    echo -e "${ORANGE} 2.${GRAY} Start VM (Get Link)"
    echo -e "${ORANGE} 3.${GRAY} Restart VM"
    echo -e "${ORANGE} 4.${GRAY} Stop VM (Kill All)"
    echo -e "${ORANGE} 5.${GRAY} Exit Menu Only"
    echo -e "${GRAY}------------------------------------------------${NC}"
    echo -n -e "${ORANGE}Select: ${NC}"
    read choice

    case $choice in
        1) create_vm ;;
        2) start_vm ;;
        3) stop_vm; start_vm ;;
        4) stop_vm; read ;;
        5) exit 0 ;;
        *) echo "Invalid"; sleep 1 ;;
    esac
done
