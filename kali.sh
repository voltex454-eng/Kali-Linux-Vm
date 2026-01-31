#!/bin/bash
# Kali Linux GUI + 100GB Storage + Clean Progress Bar

ISO_LINK="https://old.kali.org/kali-images/kali-2023.3/kali-linux-2023.3-live-amd64.iso"
ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

clear

echo "------------------------------------------------"
echo "   Kali Linux: Cloud PC (100GB Storage Mode)    "
echo "------------------------------------------------"

# 1. Install Tools (Silent)
echo "[1/6] Installing Essential Tools..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 2. Setup VNC (Silent)
if [ ! -d "novnc" ]; then
    echo "[2/6] Configuring VNC Viewer..."
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download ISO (Clean Bar Mode)
if [ ! -f "$ISO_NAME" ]; then
    echo "[3/6] Downloading Kali Linux ISO..."
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    echo "[3/6] ISO found. Skipping download."
fi

# 4. Create Disk (UPDATED: 100GB)
if [ ! -f "$DISK_NAME" ]; then
    echo "[*] Creating Storage Disk (100GB)..."
    # Yahan change kiya hai: 20G -> 100G
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo "[4/6] Booting Virtual Machine..."
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
echo "[5/6] Starting Display Server..."
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

# 6. Public URL (Clean Output)
echo "[6/6] Generating Public Link (Please Wait)..."

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
echo "========================================================"
echo "      ✅  KALI LINUX STARTED (100GB DISK)! "
echo "========================================================"
echo ""
echo " 🔗 ACCESS URL:  $PUBLIC_URL"
echo ""
echo "========================================================"
echo " ⏳ URL Expires in: 60 Minutes"
echo " 🛑 Stop Machine: Press Ctrl + C"
echo "========================================================"

# Silent Loop
while kill -0 $SSH_PID 2>/dev/null; do
    sleep 5
done
