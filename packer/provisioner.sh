#! /bin/bash

set -eux

sudo yum -y update
sudo yum -y install git
git clone https://github.com/vulsio/vulsctl.git
sudo amazon-linux-extras install -y docker
sudo usermod -aG docker ec2-user
sudo systemctl start docker
sudo systemctl enable docker
