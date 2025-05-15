# Use Debian
FROM debian:stable-slim

# Install minimal dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    wget \
    python3 \
    novnc \
    websockify \
    && rm -rf /var/lib/apt/lists/*

# Download the latest Debian netinst ISO (using the redirect URL)
RUN wget -q https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/ -O /tmp/debian-iso.html && \
    ISO_URL=$(grep -oP 'https://cdimage.debian.org/debian-cd/[^"]*amd64-netinst.iso' /tmp/debian-iso.html | head -1) && \
    wget -q "$ISO_URL" -O /debian.iso && \
    rm /tmp/debian-iso.html

# Create startup script
RUN echo '#!/bin/bash\n\
\n\
# Create blank 20GB disk image\n\
qemu-img create -f qcow2 /disk.qcow2 20G\n\
\n\
# Start QEMU with full interactive installation\n\
qemu-system-x86_64 \\\n\
    -enable-kvm \\\n\
    -cdrom /debian.iso \\\n\
    -drive file=/disk.qcow2,format=qcow2 \\\n\
    -m 4G \\\n\
    -smp 4 \\\n\
    -device virtio-net,netdev=net0 \\\n\
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \\\n\
    -vnc 0.0.0.0:0 \\\n\
    -nographic &\n\
\n\
# Start noVNC\n\
websockify --web /usr/share/novnc/ 6080 localhost:5900 &\n\
\n\
echo "================================================"\n\
echo "Debian Installation Starting..."\n\
echo "1. Connect to VNC: http://localhost:6080"\n\
echo "2. Complete the interactive installation"\n\
echo "3. Set your username/password when prompted"\n\
echo "4. After reboot, SSH will be available on port 2222"\n\
echo "================================================"\n\
\n\
tail -f /dev/null\n\
' > /start-vm.sh && chmod +x /start-vm.sh

EXPOSE 6080 2222

CMD ["/start-vm.sh"]
