#!/bin/bash
# Kali Linux GUI + Clean Public URL
# Created for GitHub Codespaces

ISO_LINK="https://old.kali.org/kali-images/kali-2023.3/kali-linux-2023.3-live-amd64.iso"
ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

echo "------------------------------------------------"
echo "   Kali Linux: Full Desktop (Clean URL Mode)    "
echo "------------------------------------------------"

# 1. Update & Install Tools
echo "[1/6] Installing QEMU & Tools..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget ssh > /dev/null 2>&1

# 2. Download noVNC
if [ ! -d "novnc" ]; then
    echo "[2/6] Setting up VNC Viewer..."
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download ISO
if [ ! -f "$ISO_NAME" ]; then
    echo "[3/6] Downloading Kali Linux ISO..."
    wget -O "$ISO_NAME" "$ISO_LINK" --show-progress
else
    echo "[3/6] ISO found. Skipping download."
fi

# 4. Create Disk
if [ ! -f "$DISK_NAME" ]; then
    echo "[*] Creating Storage..."
    qemu-img create -f qcow2 "$DISK_NAME" 20G > /dev/null
fi

# 5. Start VM
echo "[4/6] Starting Kali VM..."
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
echo "[5/6] Starting Web Interface..."
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

# 6. Create Tunnel (Clean Mode)
echo "[6/6] Generating Public URL..."

# Purana log hatao
rm -f tunnel.log

# SSH Tunnel start karo (Background me)
# -q ka matlab 'Quiet' (Kam shor machayega)
nohup ssh -q -p 443 -R0:localhost:6080 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 free.pinggy.io > tunnel.log 2>&1 &

# PID save kar lo taaki baad me check kar sakein
SSH_PID=$!

# URL aane ka wait karo
while ! grep -q "https://" tunnel.log; do
    sleep 1
done

# URL Extract karo
PUBLIC_URL=$(grep -o "https://[^ ]*.pinggy.link" tunnel.log | head -n 1)

# Screen Clear karke sirf result dikhao
clear
echo "========================================================"
echo "      ✅  KAL LINUX VM STARTED SUCCESSFULLY! "
echo "========================================================"
echo ""
echo " 🔗 YOUR VNC URL:  $PUBLIC_URL"
echo ""
echo "========================================================"
echo " ⏳ This URL expires in 60 minutes."
echo " ⚠️ DO NOT CLOSE THIS TERMINAL (Press Ctrl+C to Stop)"
echo "========================================================"

# --- SILENT LOOP ---
# Ye loop tab tak chalega jab tak SSH zinda hai.
# Screen par kuch nahi likhega.
while kill -0 $SSH_PID 2>/dev/null; do
    sleep 5
done
