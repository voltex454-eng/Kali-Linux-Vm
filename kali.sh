#!/bin/bash
# Kali Linux Colorful + 100GB + English Warnings

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# Link (Weekly Live - Always Latest)
ISO_LINK="https://cdimage.kali.org/kali-weekly/kali-linux-2026-W05-installer-amd64.iso"
ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

clear
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}   🚀 KALI LINUX: ULTIMATE COLORFUL EDITION     ${NC}"
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

# 3. Download ISO
if [ ! -f "$ISO_NAME" ]; then
    echo -e "${BLUE}[3/6] Downloading Latest Kali Linux...${NC}"
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    echo -e "${GREEN}[3/6] ISO found. Skipping download.${NC}"
fi

# 4. Create Disk
if [ ! -f "$DISK_NAME" ]; then
    echo -e "${BLUE}[*] Creating Storage Disk (100GB)...${NC}"
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo -e "${YELLOW}[4/6] Booting Virtual Machine...${NC}"
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

# --- FINAL COLORFUL SCREEN ---
clear
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}      ✅  KALI LINUX IS LIVE & READY!  ${NC}"
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
