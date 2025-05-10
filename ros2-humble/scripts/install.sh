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

# Xfce minimal + VNC
sudo apt install -y xfce4 xfce4-terminal tigervnc-standalone-server dbus-x11

mkdir -p ~/.vnc
echo '#!/bin/bash' > ~/.vnc/xstartup
echo 'xrdb $HOME/.Xresources' >> ~/.vnc/xstartup
echo 'startxfce4 &' >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# Systemd service for VNC, bound to localhost
cat <<EOF | sudo tee /etc/systemd/system/vncserver@vagrant.service
[Unit]
Description=TigerVNC Server
After=network.target

[Service]
Type=forking
User=vagrant
ExecStartPre=-/usr/bin/vncserver -kill :1 > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :1 -geometry 1280x720 -depth 24 -localhost -SecurityTypes None,TLSNone
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vncserver@vagrant.service
sudo systemctl start vncserver@vagrant.service

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
ExecStart=/home/vagrant/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:6080
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