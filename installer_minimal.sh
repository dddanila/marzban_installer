#!/bin/bash

function install()
{
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    service xray start
    wget -qO- https://bootstrap.pypa.io/get-pip.py | python3 -
    alembic upgrade head
    sudo ln -s $(pwd)/marzban-cli.py /usr/bin/marzban-cli
    sudo chmod +x /usr/bin/marzban-cli
}

function download_032()
{
    wget https://github.com/Gozargah/Marzban/archive/refs/tags/v0.3.2.tar.gz
    tar -xf v0.3.2.tar.gz
    rm -rf v0.3.2.tar.gz
    cd Marzban-0.3.2/
    sed -i "s/latest/v0.3.2/" docker-compose.yml
    install;
}

function download_latest()
{
    git clone https://github.com/Gozargah/Marzban.git
    cd Marzban/
    install;
}

clear
printf "#########Установка Marzban(minimal)#########\n"
printf "1) Скачать Marzban-v0.3.2\n"
printf "2) Скачать Marzban-Latest\n"
printf "0) Отмена\n\n"
read -p "> " CMD

sudo apt-get update && sudo apt-get upgrade -y
sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf 
echo "\$nrconf{restart} = 'a';" >> /etc/needrestart/needrestart.conf 
sudo apt-get install --assume-yes git
sudo apt-get --assume-yes install apt-transport-https ca-certificates gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_releasudo apt-get update)"
sudo apt-get --assume-yes install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get --assume-yes update
sudo apt-get --assume-yes install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get --assume-yes install docker-compose
chmod +x /usr/local/bin/docker-compose
systemctl start docker
systemctl enable docker

case $CMD in
  1) download_032;;
  2) download_latest;;
  *) exit 0;; 
esac
