#!/bin/bash
# Kali Linux GUI + 100GB Storage + Clean Progress Bar

# --- COLORS (Orange + Gray Theme) ---
ORANGE='\033[1;33m'
GRAY='\033[1;90m'
NC='\033[0m' # No Color

ISO_LINK="https://cdimage.kali.org/kali-2025.4/kali-linux-2025.4-installer-amd64.iso"
ISO_NAME="linux-2025.4-installer-amd64.iso"
DISK_NAME="kali_storage.qcow2"

clear

echo -e "${GRAY}------------------------------------------------${NC}"
echo -e "${ORANGE}   Kali Linux: Cloud PC (100GB Storage Mode)    ${NC}"
echo -e "${GRAY}------------------------------------------------${NC}"

# 1. Install Tools (Silent)
echo -e "${ORANGE}[1/6]${GRAY} Installing Essential Tools...${NC}"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 2. Setup VNC (Silent)
if [ ! -d "novnc" ]; then
    echo -e "${ORANGE}[2/6]${GRAY} Configuring VNC Viewer...${NC}"
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download ISO (Clean Bar Mode)
if [ ! -f "$ISO_NAME" ]; then
    echo -e "${ORANGE}[3/6]${GRAY} Downloading Kali Linux ISO...${NC}"
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    echo -e "${ORANGE}[3/6]${GRAY} ISO found. Skipping download.${NC}"
fi

# 4. Create Disk (UPDATED: 100GB)
if [ ! -f "$DISK_NAME" ]; then
    echo -e "${ORANGE}[*]${GRAY} Creating Storage Disk (100GB)...${NC}"
    # Yahan change kiya hai: 20G -> 100G
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo -e "${ORANGE}[4/6]${GRAY} Booting Virtual Machine...${NC}"
qemu-system-x86_64 \
  -m 4G \
  -smp 2 \
  -hda "$DISK_NAME" \
  -cdrom "$ISO_NAME" \
  -boot d \
  -vnc :0 \
  -net nic,model=virtio -net user \
  -daemonize

# Start noVNC
echo -e "${ORANGE}[5/6]${GRAY} Starting Display Server...${NC}"
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

# 6. Public URL (Clean Output)
echo -e "${ORANGE}[6/6]${GRAY} Generating Public Link (Please Wait)...${NC}"

rm -f tunnel.log

# SSH Tunnel (Logs Hidden)
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

SSH_PID=$!

# Wait for URL
while ! grep -q "https://" tunnel.log; do
    sleep 1
done

# URL Extract
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

# --- FINAL CLEAN SCREEN ---
clear
echo -e "${GRAY}========================================================${NC}"
echo -e "${ORANGE}      ✅  KALI LINUX STARTED (100GB DISK)! ${NC}"
echo -e "${GRAY}========================================================${NC}"
echo ""
echo -e "${GRAY} 🔗 ACCESS URL:  ${ORANGE}$PUBLIC_URL${NC}"
echo ""
echo -e "${GRAY}========================================================${NC}"
echo -e "${GRAY} ⏳ URL Expires in: ${ORANGE}60 Minutes${NC}"
echo -e "${GRAY} 🛑 Stop Machine: ${ORANGE}Press Ctrl + C${NC}"
echo -e "${GRAY} 🔄 TRICK: ${ORANGE}Run This Script Again To Generate a New URL${NC}"
echo -e "${GRAY}========================================================${NC}"

# Silent Loop
while kill -0 $SSH_PID 2>/dev/null; do
    sleep 5
done
