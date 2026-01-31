#!/bin/bash
# Kali Linux: FINAL REPAIR (Auto-Kill + Rolling Latest)

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# --- STEP 0: KILL GHOST PROCESSES (Ye Lock Error Fix Karega) ---
echo -e "${RED}[!] Checking for old background processes...${NC}"
pkill -f qemu-system-x86_64 > /dev/null 2>&1
killall qemu-system-x86_64 > /dev/null 2>&1
sleep 2
echo -e "${GREEN}[✓] System Cleaned. Disk Unlocked.${NC}"
# -------------------------------------------------------------

ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

# OFFICIAL ROLLING LINK (Always Latest, Never Fails)
ISO_LINK="https://cdimage.kali.org/kali-images/kali-rolling/kali-linux-rolling-live-amd64.iso"

clear
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}   🚀 KALI LINUX: UNLOCKED EDITION              ${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"

# 1. Install Tools
echo -e "${YELLOW}[1/6] Installing Essential Tools...${NC}"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 2. Setup VNC
if [ ! -d "novnc" ]; then
    echo -e "${YELLOW}[2/6] Configuring VNC Viewer...${NC}"
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download ISO (Clean & Safe)
if [ ! -f "$ISO_NAME" ]; then
    echo -e "${BLUE}[3/6] Downloading Latest Rolling Release...${NC}"
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    # Check if file is broken/empty (Previous error fix)
    FILE_SIZE=$(stat -c%s "$ISO_NAME")
    if [ "$FILE_SIZE" -lt 100000000 ]; then
        echo -e "${RED}⚠️ Found broken file. Re-downloading...${NC}"
        rm -f "$ISO_NAME"
        wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
    else
        echo -e "${GREEN}[3/6] ISO found. Skipping download.${NC}"
    fi
fi

# 4. Create Disk
if [ ! -f "$DISK_NAME" ]; then
    echo -e "${BLUE}[*] Creating Storage Disk (100GB)...${NC}"
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo -e "${YELLOW}[4/6] Booting New Virtual Machine...${NC}"
qemu-system-x86_64 \
  -m 4G \
  -smp 2 \
  -hda "$DISK_NAME" \
  -cdrom "$ISO_NAME" \
  -boot d \
  -vnc :0 \
  -net nic,model=virtio -net user \
  -daemonize

# 6. Public URL
echo -e "${YELLOW}[5/6] Generating Secure Link...${NC}"
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
rm -f tunnel.log
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

SSH_PID=$!
while ! grep -q "https://" tunnel.log; do sleep 1; done
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

# --- FINAL SCREEN ---
clear
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}      ✅  KALI LINUX IS LIVE & UNLOCKED!  ${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo -e "${CYAN} 🔗 ACCESS URL:  $PUBLIC_URL ${NC}"
echo ""
echo -e "${RED}========================================================${NC}"
echo -e "${YELLOW} ⏳ WARNING: The URL expires automatically after 60 minutes.${NC}"
echo -e "${YELLOW} 🔄 TRICK: Run the script again to generate a new URL.${NC}"
echo -e "${RED} 🛑 Stop Machine: Press Ctrl + C ${NC}"
echo -e "${RED}========================================================${NC}"

while kill -0 $SSH_PID 2>/dev/null; do sleep 5; done
