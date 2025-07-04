#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list
sudo add-apt-repository universev -y
sudo apt-get update
sudo apt-get install -y vault auditd uidmap fuse-overlayfs
