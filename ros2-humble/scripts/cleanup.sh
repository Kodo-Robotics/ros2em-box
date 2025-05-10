#!/bin/bash
set -eux

sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /home/vagrant/.cache/*
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -rf /EMPTY