#!/bin/bash
# KALI LINUX ADVANCED MANAGER (Menu System)
# Version: 2025.3 (Stable Direct ISO) | Mouse: USB-Mouse Fix

# --- COLORS ---
ORANGE='\033[1;33m'
GRAY='\033[1;90m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# --- CONFIGURATION ---
ISO_LINK="https://archive.kali.org/kali-images/kali-2025.3/kali-linux-2025.3-live-amd64.iso"
ISO_NAME="kali-linux-2025.3-live-amd64.iso"
DISK_NAME="kali_storage.qcow2"

# --- FUNCTIONS ---

function header() {
    clear
    echo -e "${GRAY}------------------------------------------------${NC}"
    echo -e "${ORANGE}      🚀 KALI LINUX: ADVANCED CLOUD PC      ${NC}"
    echo -e "${GRAY}------------------------------------------------${NC}"
}

function stop_vm() {
    echo -e "${ORANGE}[*]${GRAY} Stopping VM and cleaning processes...${NC}"
    pkill -f qemu-system-x86_64 > /dev/null 2>&1
    killall qemu-system-x86_64 > /dev/null 2>&1
    pkill -f websockify > /dev/null 2>&1
    pkill -f ssh > /dev/null 2>&1
    rm -f tunnel.log
    sleep 2
    echo -e "${GREEN}[✓] VM Stopped Successfully.${NC}"
}

function create_vm() {
    header
    echo -e "${ORANGE}[1/4]${GRAY} Updating System & Installing Tools...${NC}"
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

    echo -e "${ORANGE}[2/4]${GRAY} Setting up VNC Engine...${NC}"
    if [ ! -d "novnc" ]; then
        git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
        git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
    fi

    echo -e "${ORANGE}[3/4]${GRAY} Checking/Downloading ISO (2025.3)...${NC}"
    if [ ! -f "$ISO_NAME" ]; then
        wget --show-progress -O "$ISO_NAME" "$ISO_LINK"
    else
        echo -e "${GREEN}[✓] ISO already exists.${NC}"
    fi

    echo -e "${ORANGE}[4/4]${GRAY} Creating 100GB Storage Disk...${NC}"
    if [ ! -f "$DISK_NAME" ]; then
        qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
    else
        echo -e "${GREEN}[✓] Disk already exists.${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Setup Complete! Press Enter to return to menu.${NC}"
    read
}

function start_vm() {
    header
    # Check if files exist
    if [ ! -f "$ISO_NAME" ] || [ ! -f "$DISK_NAME" ]; then
        echo -e "${RED}❌ Error: VM not created yet! Select Option 1 first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${ORANGE}[*]${GRAY} Cleaning old sessions...${NC}"
    stop_vm > /dev/null 2>&1 # Silent clean

    echo -e "${ORANGE}[*]${GRAY} Booting Kali Linux (Live Desktop)...${NC}"
    # MOUSE FIX: -usb -device usb-mouse added
    qemu-system-x86_64 \
      -m 4G \
      -smp 2 \
      -usb -device usb-mouse \
      -hda "$DISK_NAME" \
      -cdrom "$ISO_NAME" \
      -boot d \
      -vnc :0 \
      -net nic,model=virtio -net user \
      -daemonize

    echo -e "${ORANGE}[*]${GRAY} Starting VNC Server...${NC}"
    ./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

    echo -e "${ORANGE}[*]${GRAY} Generating Public Link...${NC}"
    nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

    # Wait for URL
    echo -e "${GRAY}    (Waiting for Pinggy URL...)${NC}"
    count=0
    while ! grep -q "https://" tunnel.log; do
        sleep 1
        ((count++))
        if [ $count -ge 20 ]; then
            echo -e "${RED}⚠️  Link generation taking long. Retrying tunnel...${NC}"
            pkill -f ssh
            nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &
            count=0
        fi
    done

    PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

    clear
    echo -e "${GRAY}========================================================${NC}"
    echo -e "${GREEN}      ✅  VM IS RUNNING IN BACKGROUND!  ${NC}"
    echo -e "${GRAY}========================================================${NC}"
    echo ""
    echo -e "${GRAY} 🔗 URL:  ${ORANGE}$PUBLIC_URL${NC}"
    echo ""
    echo -e "${GRAY}========================================================${NC}"
    echo -e "${GRAY} 🔄 TRICK: ${ORANGE}Run 'Restart' if link expires.${NC}"
    echo -e "${GRAY} ⚠️  NOTE: ${ORANGE}Don't close this tab, just minimize.${NC}"
    echo -e "${GRAY}========================================================${NC}"
    echo ""
    echo -e "${ORANGE}Press Enter to return to Main Menu (VM will keep running).${NC}"
    read
}

# --- MAIN LOOP ---

while true; do
    header
    echo -e "${ORANGE} 1.${GRAY} Create Kali Linux VM (Download & Setup)"
    echo -e "${ORANGE} 2.${GRAY} Start VM (Get Link)"
    echo -e "${ORANGE} 3.${GRAY} Restart VM (Fix Link/Lag)"
    echo -e "${ORANGE} 4.${GRAY} Stop VM (Power Off)"
    echo -e "${ORANGE} 5.${GRAY} Exit Script"
    echo -e "${GRAY}------------------------------------------------${NC}"
    echo -n -e "${ORANGE}Select Option [1-5]: ${NC}"
    read choice

    case $choice in
        1)
            create_vm
            ;;
        2)
            start_vm
            ;;
        3)
            stop_vm
            start_vm
            ;;
        4)
            stop_vm
            echo -e "${ORANGE}Press Enter to continue...${NC}"
            read
            ;;
        5)
            stop_vm
            echo -e "${GREEN}Bye Bye! 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid Option!${NC}"
            sleep 1
            ;;
    esac
done
