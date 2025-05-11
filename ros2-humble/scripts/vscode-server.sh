#!/bin/bash
set -eux

# Download and unpack code-server
ARCH_RAW=$(uname -m)
if [[ "$ARCH_RAW" == "x86_64" ]]; then
    ARCH="x64"
elif [[ "$ARCH_RAW" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH_RAW"
    exit 1
fi

VERSION="1.100.03093"
INSTALL_DIR="/home/vagrant/.local/vscodium"

mkdir -p $INSTALL_DIR
curl -fL https://github.com/VSCodium/vscodium/releases/download/$VERSION/VSCodium-linux-$ARCH-$VERSION.tar.gz \
    | tar xz --strip-components=1 -C $INSTALL_DIR

# Add VSCodium to Path
echo 'export PATH=$PATH:/home/vagrant/.local/vscodium/bin' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

# VS Code Server startup script
cat <<EOF > /home/vagrant/start-vscodium.sh
#!/bin/bash
$INSTALL_DIR/code --no-sandbox
EOF
chmod +x /home/vagrant/start-vscodium.sh

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/vscodium.service
[Unit]
Description=VSCodium
After=network.target

[Service]
Type=simple
User=vagrant
ExecStart=/home/vagrant/start-vscodium.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vscodium.service
sudo systemctl start vscodium.service