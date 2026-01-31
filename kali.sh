#!/bin/bash
# Kali Linux GUI VM (VNC in Browser)
# Created for GitHub Codespaces & Cloud Shells

ISO_LINK="https://old.kali.org/kali-images/kali-2023.3/kali-linux-2023.3-live-amd64.iso"
ISO_NAME="kali-linux.iso"
DISK_NAME="kali_storage.qcow2"

echo "------------------------------------------------"
echo "   Kali Linux: Full Desktop Experience (GUI)    "
echo "------------------------------------------------"

# 1. Update & Install QEMU + Utilities
echo "[1/5] Installing QEMU & Virtualization Tools..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils python3-numpy git wget > /dev/null 2>&1

# 2. Download noVNC (For Browser Access)
if [ ! -d "novnc" ]; then
    echo "[2/5] Setting up VNC Viewer (noVNC)..."
    git clone --depth 1 https://github.com/novnc/noVNC.git novnc > /dev/null 2>&1
    git clone --depth 1 https://github.com/novnc/websockify novnc/utils/websockify > /dev/null 2>&1
fi

# 3. Download Kali ISO
if [ ! -f "$ISO_NAME" ]; then
    echo "[3/5] Downloading Kali Linux ISO (This may take time)..."
    wget -O "$ISO_NAME" "$ISO_LINK" --show-progress
else
    echo "[3/5] ISO already exists. Skipping download."
fi

# 4. Create Storage (Hard Disk)
if [ ! -f "$DISK_NAME" ]; then
    echo "[*] Creating virtual hard drive (20GB)..."
    qemu-img create -f qcow2 "$DISK_NAME" 20G > /dev/null
fi

# 5. Start VM & VNC
echo "[4/5] Starting Kali VM in Background..."

# Launch QEMU with VNC enabled on localhost:5900
qemu-system-x86_64 \
  -m 4G \
  -smp 2 \
  -hda "$DISK_NAME" \
  -cdrom "$ISO_NAME" \
  -boot d \
  -vnc :0 \
  -net nic,model=virtio -net user \
  -daemonize

echo "[5/5] Starting Web Interface..."

# Forward VNC to Web Port 6080
./novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &

echo "------------------------------------------------"
echo "✅ VM Successfully Started!"
echo "------------------------------------------------"
echo "To access your Kali Desktop:"
echo "1. Go to the 'PORTS' tab in Codespaces."
echo "2. Find Port '6080'."
echo "3. Click the Globe Icon (🌐) to open in browser."
echo "4. Click 'Connect' and enjoy!"
echo "------------------------------------------------"
echo "Note: The boot process may take 2-3 minutes."
