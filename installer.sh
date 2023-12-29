#!/bin/bash

function parse_json()
{
    echo $1 | \
    sed -e 's/[{}]/''/g' | \
    sed -e 's/", "/'\",\"'/g' | \
    sed -e 's/" ,"/'\",\"'/g' | \
    sed -e 's/" , "/'\",\"'/g' | \
    sed -e 's/","/'\"---SEPERATOR---\"'/g' | \
    awk -F=':' -v RS='---SEPERATOR---' "\$1~/\"$2\"/ {print}" | \
    sed -e "s/\"$2\"://" | \
    tr -d "\n\t" | \
    sed -e 's/\\"/"/g' | \
    sed -e 's/\\\\/\\/g' | \
    sed -e 's/^[ \t]*//g' | \
    sed -e 's/^"//'  -e 's/"$//'
}


function password_generate()
{
    SYMBOLS=""
    for symbol in {A..Z} {a..z} {0..9}; do SYMBOLS=$SYMBOLS$symbol; done
    SYMBOLS=$SYMBOLS''
    PWD_LENGTH=16
    PASSWORD=""
    RANDOM=256
    for i in `seq 1 $PWD_LENGTH`
    do
    PASSWORD=$PASSWORD${SYMBOLS:$(expr $RANDOM % ${#SYMBOLS}):1}
    done
    echo $PASSWORD
}


function install()
{
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    service xray start
    wget -qO- https://bootstrap.pypa.io/get-pip.py | python3 -
    alembic upgrade head
    sudo ln -s $(pwd)/marzban-cli.py /usr/bin/marzban-cli
    sudo chmod +x /usr/bin/marzban-cli
    clear
    read -p "Enter username: " username
    read -p "Enter password: " password
    
    if [[ -z $username ]]
      then
          username="admin"
          printf "Имя пользователя: $username\n"
      else
          printf "Имя пользователя введено.\n"
    fi

    if [[ -z $password ]]
      then
          password="$(password_generate)"
          printf "Сгенерирован пароль: $password\n"
      else
          printf "Пароль введен.\n"
    fi
    cp .env.example .env
    echo "SUDO_USERNAME = $username" >> .env
    echo "SUDO_PASSWORD = $password" >> .env
    echo "SQLALCHEMY_DATABASE_URL = 'sqlite:///db.sqlite3'" >> .env
    echo "DOCS=true" >> .env
    echo "WEBHOOK_ADDRESS = 'http://0.0.0.0:9000/'" >> .env
    echo "WEBHOOK_SECRET = 'something-very-very-secret'" >> .env
    echo "VITE_BASE_API='https://0.0.0.0:8000/api/'" >> .env
    echo "JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440" >> .env
    docker-compose build
    docker-compose up -d
    sleep 5
}

function download_032()
{
    wget https://github.com/Gozargah/Marzban/archive/refs/tags/v0.3.2.tar.gz
    tar -xf v0.3.2.tar.gz
    rm -rf v0.3.2.tar.gz
    cd Marzban-0.3.2/
    install;
}

function download_latest()
{
    git clone https://github.com/Gozargah/Marzban.git
    cd Marzban/
    install;
}

clear
printf "#########Установка Marzban#########\n"
printf "1) Установить Marzban-0.3.2\n"
printf "2) Установить Marzban-Latest\n"
printf "0) Отмена\n\n"
read -p "> " CMD

sudo apt-get update && sudo apt-get upgrade -y
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install --assume-yes libpq-dev
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

TOKEN=$(curl -X "POST" \
  "http://127.0.0.1:8000/api/admin/token" \
  -H "accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=&username=$username&password=$password&scope=&client_id=&client_secret=")

TOKEN=$(parse_json $TOKEN access_token)
echo "Username: $username" >> ~/token.txt
echo "Password: $password" >> ~/token.txt
echo "Token: $TOKEN" >> ~/token.txt
printf "TOKEN:\n$TOKEN\n"
