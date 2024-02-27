!/bin/bash

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
    username="admin"
    printf "Имя пользователя: $username\n"
    password="$(password_generate)"
    printf "Сгенерирован пароль: $password\n"
    cp .env.example .env
    echo "SUDO_USERNAME = $username" >> .env
    echo "SUDO_PASSWORD = $password" >> .env
    echo "SQLALCHEMY_DATABASE_URL = 'sqlite:///db.sqlite3'" >> .env
    echo "DOCS=true" >> .env
    echo "WEBHOOK_ADDRESS = 'http://0.0.0.0:9000/'" >> .env
    echo "WEBHOOK_SECRET = 'something-very-very-secret'" >> .env
    echo "VITE_BASE_API='https://0.0.0.0:8000/api/'" >> .env
    echo "JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 5184000" >> .env
    docker-compose build
    docker-compose up -d
    echo "Запуск..."
    sleep 15
}

function download_latest()
{
    git clone https://github.com/Gozargah/Marzban.git
    cd Marzban/
    install;
}

clear
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

download_latest;

TOKEN=$(curl -X "POST" \
  "http://127.0.0.1:8000/api/admin/token" \
  -H "accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=&username=$username&password=$password&scope=&client_id=&client_secret=")

TOKEN=$(parse_json $TOKEN access_token)
echo "Username: $username" >> ~/token.txt
echo "Password: $password" >> ~/token.txt
echo "Token: $TOKEN" >> ~/token.txt
clear
cat token.txt
