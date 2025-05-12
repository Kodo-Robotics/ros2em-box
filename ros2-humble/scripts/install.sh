#!/bin/bash
set -eux

# Update core & utilities
sudo apt update
sudo apt install -y curl gnupg2 ca-certificates lsb-release software-properties-common

# Remove unneeded packages
sudo apt purge -y snapd apport ufw unattended-upgrades

# Install ROS2
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
  http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt install -y ros-humble-desktop

echo "source /opt/ros/humble/setup.bash" >> /home/vagrant/.bashrc

# Minimal GUI + VNC
sudo apt install -y x11vnc xvfb fluxbox dbus-x11 xterm

# Startup script for X session
mkdir -p /home/vagrant/.vnc
cat <<'EOF' > /home/vagrant/.vnc/startup.sh
#!/bin/bash
export DISPLAY=:1
Xvfb :1 -screen 0 1280x720x24 &
sleep 2
fluxbox &
x11vnc -display :1 -nopw -forever -shared -xrandr &
wait
EOF
chmod +x /home/vagrant/.vnc/startup.sh
chown -R vagrant:vagrant /home/vagrant/.vnc

# Systemd service for VNC
cat <<EOF | sudo tee /etc/systemd/system/x11vnc.service
[Unit]
Description=Start virtual X session with x11vnc
After=network.target

[Service]
User=vagrant
ExecStart=/home/vagrant/.vnc/startup.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

# Install noVNC
sudo apt install -y git python3-websockify
git clone https://github.com/novnc/noVNC.git /home/vagrant/noVNC
cd /home/vagrant/noVNC
git checkout v1.4.0
ln -s vnc.html index.html

# Systemd service for websockify
cat <<EOF | sudo tee /etc/systemd/system/novnc.service
[Unit]
Description=noVNC websockify server
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/noVNC
ExecStart=/home/vagrant/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 0.0.0.0:6080
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable novnc.service
sudo systemctl start novnc.service

# Passwordless sudo and auto-login setup
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/99_vagrant_nopasswd
sudo passwd -d vagrant

# Cleanup
sudo apt autoremove -y
sudo apt clean