#/bin/bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y docker.io docker-compose
wget https://github.com/Gozargah/Marzban/archive/refs/tags/v0.3.2.tar.gz
tar -xf v0.3.2.tar.gz
rm -rf v0.3.2.tar.gz
cd Marzban-0.3.2/
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
service xray start
wget -qO- https://bootstrap.pypa.io/get-pip.py | python3 -
alembic upgrade head
sudo ln -s $(pwd)/marzban-cli.py /usr/bin/marzban-cli
sudo chmod +x /usr/bin/marzban-cli
read -p "Enter username: " username
read -p "Enter password: " password
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

TOKEN=$(curl -X "POST" \
  "http://127.0.0.1:8000/api/admin/token" \
  -H "accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=&username=$username&password=$password&scope=&client_id=&client_secret=")

TOKEN=$(parse_json $TOKEN access_token)
echo $TOKEN >> token.txt
printf "TOKEN:\n$TOKEN\n"
