#!/bin/bash
# Kali Linux: FINAL DIAGNOSTIC MODE (Internet & Download Fix)

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"
ISO_LINK="https://cdimage.kali.org/kali-images/kali-rolling/kali-linux-rolling-live-amd64.iso"

clear
echo -e "${CYAN}------------------------------------------------${NC}"
echo -e "${CYAN}   🚀 KALI LINUX: DIAGNOSTIC MODE               ${NC}"
echo -e "${CYAN}------------------------------------------------${NC}"

# 0. KILL OLD PROCESSES
echo -e "${RED}[!] Killing old background processes...${NC}"
pkill -f qemu-system-x86_64 > /dev/null 2>&1
killall qemu-system-x86_64 > /dev/null 2>&1
sleep 2

# 1. FORCE DELETE OLD ISO (Start Fresh)
echo -e "${RED}[!] Deleting old corrupt files...${NC}"
rm -f "$ISO_NAME"

# 2. CHECK INTERNET
echo -e "${YELLOW}[1/7] Checking Internet Connection...${NC}"
if ! ping -c 3 google.com > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: No Internet! Please Restart your Codespace.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Internet is working.${NC}"

# 3. INSTALL TOOLS
echo -e "${YELLOW}[2/7] Installing Tools...${NC}"
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 4. DOWNLOAD WITH ERROR CHECKING
echo -e "${BLUE}[3/7] Downloading Kali Rolling (This takes time)...${NC}"
wget --show-progress -O "$ISO_NAME" "$ISO_LINK"

# Check if download succeeded
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR: Download Failed! Link might be blocked or busy.${NC}"
    exit 1
fi

# 5. VERIFY FILE SIZE
FILE_SIZE=$(stat -c%s "$ISO_NAME")
if [ "$FILE_SIZE" -lt 2000000000 ]; then
    echo -e "${RED}❌ ERROR: File too small ($FILE_SIZE bytes). Download corrupted.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Download Verified! Size looks good.${NC}"

# 6. SETUP VNC
if [ ! -d "novnc" ]; then
    echo -e "${YELLOW}[4/7] Setting up VNC...${NC}"
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 7. CREATE DISK
if [ ! -f "$DISK_NAME" ]; then
    echo -e "${BLUE}[5/7] Creating 100GB Disk...${NC}"
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 8. START VM
echo -e "${YELLOW}[6/7] Booting Machine...${NC}"
qemu-system-x86_64 \
  -m 4G \
  -smp 2 \
  -hda "$DISK_NAME" \
  -cdrom "$ISO_NAME" \
  -boot d \
  -vnc :0 \
  -net nic,model=virtio -net user \
  -daemonize

# 9. GENERATE URL
echo -e "${YELLOW}[7/7] Generating Link...${NC}"
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
rm -f tunnel.log
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

SSH_PID=$!
while ! grep -q "https://" tunnel.log; do sleep 1; done
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

# --- SUCCESS ---
clear
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}      ✅  KALI LINUX STARTED SUCCESSFULLY!  ${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo -e "${CYAN} 🔗 URL:  $PUBLIC_URL ${NC}"
echo ""
echo -e "${RED}========================================================${NC}"
echo -e "${YELLOW} ⏳ Note: Wait 1 minute inside the browser for it to load.${NC}"
echo -e "${RED}========================================================${NC}"

while kill -0 $SSH_PID 2>/dev/null; do sleep 5; done
