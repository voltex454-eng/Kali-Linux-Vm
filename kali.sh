#!/bin/bash
# Kali Linux: 2026 LATEST AUTO-DETECT + Colorful + 100GB
# Features: Automatically finds the correct Weekly Live ISO

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"
# Official Weekly Directory
BASE_URL="https://cdimage.kali.org/kali-weekly/"

clear
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}   🚀 KALI LINUX: 2026 LATEST HUNTER            ${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"

# 0. CLEANUP (Auto-fix bad downloads)
if [ -f "$ISO_NAME" ]; then
    FILE_SIZE=$(stat -c%s "$ISO_NAME")
    if [ "$FILE_SIZE" -lt 100000000 ]; then
        echo -e "${RED}🗑️  Cleaning up corrupted file...${NC}"
        rm -f "$ISO_NAME"
    fi
fi

# 1. Install Tools
echo -e "${YELLOW}[1/7] Installing Essential Tools...${NC}"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh curl > /dev/null 2>&1

# 2. Setup VNC
if [ ! -d "novnc" ]; then
    echo -e "${YELLOW}[2/7] Configuring VNC Viewer...${NC}"
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. SMART DOWNLOAD (The Logic)
if [ ! -f "$ISO_NAME" ]; then
    echo -e "${BLUE}[3/7] Searching Server for Latest 2026 Live ISO...${NC}"
    
    # 1. Server se list nikalo
    # 2. 'live-amd64.iso' dhoondo (Installer ignore karo)
    # 3. Sort karke sabse latest wala select karo
    LATEST_FILE=$(curl -sL "$BASE_URL" | grep -o 'kali-linux-[0-9]\{4\}-W[0-9]\{2\}-live-amd64.iso' | sort -V | tail -n 1)
    
    if [ -z "$LATEST_FILE" ]; then
        echo -e "${RED}⚠️  Auto-detect failed. Using fallback rolling...${NC}"
        ISO_LINK="https://cdimage.kali.org/current/kali-linux-rolling-live-amd64.iso"
    else
        echo -e "${GREEN}✅ FOUND LATEST VERSION: $LATEST_FILE ${NC}"
        ISO_LINK="${BASE_URL}${LATEST_FILE}"
    fi

    echo -e "${BLUE}[4/7] Downloading: $LATEST_FILE ...${NC}"
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    echo -e "${GREEN}[3/7] ISO found. Skipping download.${NC}"
fi

# 4. Create Disk
if [ ! -f "$DISK_NAME" ]; then
    echo -e "${BLUE}[*] Creating Storage Disk (100GB)...${NC}"
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo -e "${YELLOW}[5/7] Booting Latest Kali...${NC}"
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
echo -e "${YELLOW}[6/7] Generating Secure Link...${NC}"
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
rm -f tunnel.log
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

SSH_PID=$!
while ! grep -q "https://" tunnel.log; do sleep 1; done
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

# --- FINAL COLORFUL SCREEN ---
clear
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}      ✅  KALI LINUX (LATEST) IS LIVE!  ${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo -e "${CYAN} 🔗 ACCESS URL:  $PUBLIC_URL ${NC}"
echo ""
echo -e "${RED}========================================================${NC}"
echo -e "${YELLOW} ⏳ WARNING: The URL expires automatically after 60 minutes.${NC}"
echo -e "${YELLOW} 🔄 TRICK: Run the script again to generate a new URL.${NC}"
echo -e "${RED} 🛑 Stop Machine: Press Ctrl + C ${NC}"
echo -e "${RED}========================================================${NC}"

# Keep Running
while kill -0 $SSH_PID 2>/dev/null; do sleep 5; done
