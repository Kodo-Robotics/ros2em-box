#!/bin/bash
set -eux

# Download and unpack code-server
ARCH_RAW=$(uname -m)
if [[ "$ARCH_RAW" == "x86_64" ]]; then
    ARCH="linux-amd64"
elif [[ "$ARCH_RAW" == "aarch64" ]]; then
    ARCH="linux-arm64"
else
    echo "Unsupported architecture: $ARCH_RAW"
    exit 1
fi

VERSION="4.90.1"
INSTALL_DIR="/home/vagrant/.local/code-server"

mkdir -p $INSTALL_DIR
curl -fL https://github.com/coder/code-server/releases/download/v$VERSION/code-server-$VERSION-$ARCH.tar.gz \
    | tar xz --strip-components=1 -C $INSTALL_DIR

# VS Code Server startup script
cat <<EOF > /home/vagrant/start-code-server.sh
#!/bin/bash
$INSTALL_DIR/bin/code-server --bind-addr 0.0.0.0:8080 --auth none
EOF
chmod +x /home/vagrant/start-code-server.sh

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/code-server.service
[Unit]
Description=VS Code Server
After=network.target

[Service]
Type=simple
User=vagrant
ExecStart=/home/vagrant/start-code-server.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable code-server.service
sudo systemctl start code-server.service