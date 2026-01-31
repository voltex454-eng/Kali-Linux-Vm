#!/bin/bash
# Kali Linux 2026 (W05 Latest) + 100GB Disk

# Tere link ka "Live" version (Direct Desktop khulega)
ISO_LINK="https://cdimage.kali.org/kali-weekly/kali-linux-2026-W05-live-amd64.iso"
ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

clear
echo "------------------------------------------------"
echo "   Kali Linux: 2026 LATEST (Week 5 Edition)     "
echo "------------------------------------------------"

# 1. Install Tools
echo "[1/6] Installing Tools..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 2. Setup VNC
if [ ! -d "novnc" ]; then
    echo "[2/6] Configuring VNC..."
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download ISO (Clean Bar Mode)
if [ ! -f "$ISO_NAME" ]; then
    echo "[3/6] Downloading Kali Linux 2026 (W05)..."
    wget -q --show-progress -O "$ISO_NAME" "$ISO_LINK"
else
    echo "[3/6] ISO found. Skipping download."
fi

# 4. Create Disk
if [ ! -f "$DISK_NAME" ]; then
    echo "[*] Creating Storage Disk (100GB)..."
    qemu-img create -f qcow2 "$DISK_NAME" 100G > /dev/null
fi

# 5. Start VM
echo "[4/6] Booting 2026 Machine..."
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
echo "[5/6] Generating Link..."
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
rm -f tunnel.log
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

SSH_PID=$!
while ! grep -q "https://" tunnel.log; do sleep 1; done
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

clear
echo "========================================================"
echo "      ✅  KALI LINUX 2026 (W05) IS LIVE! "
echo "========================================================"
echo ""
echo " 🔗 URL:  $PUBLIC_URL"
echo ""
echo "========================================================"
echo " ⏳ URL Expires in: 60 Minutes"
echo " 🛑 Stop Machine: Press Ctrl + C"
echo " 🟢 Run Script Again: To Generate New Url"
echo "========================================================"

while kill -0 $SSH_PID 2>/dev/null; do sleep 5; done
