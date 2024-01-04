#!/bin/bash
if command -v termux-setup-storage; then
  echo For termux, please use https://raw.githubusercontent.com/The-MoonTg-project/Moon-Userbot/main/termux-install.sh
  exit 1
fi

if [[ $UID != 0 ]]; then
  echo Please run this script as root
  exit 1
fi

apt update -y
apt install python3 python3-pip git ffmpeg wget gnupg -y || exit 2

su -c "python3 -m pip install -U pip" $SUDO_USER
su -c "python3 -m pip install -U wheel pillow" $SUDO_USER

if [[ -d "Moon-Userbot" ]]; then
  cd Moon-Userbot
elif [[ -f ".env.dist" ]] && [[ -f "main.py" ]] && [[ -d "modules" ]]; then
  :
else
  git clone https://github.com/The-MoonTg-project/Moon-Userbot || exit 2
  cd Moon-Userbot || exit 2
fi

if [[ -f ".env" ]] && [[ -f "my_account.session" ]]; then
  echo "It seems that Moon-Userbot is already installed. Exiting..."
  exit
fi

su -c "python3 -m pip install -U -r requirements.txt" $SUDO_USER || exit 2

echo
echo "Enter API_ID and API_HASH"
echo "You can get it here -> https://my.telegram.org/"
echo "Leave empty to use defaults (please note that default keys significantly increases your ban chances)"
read -r -p "API_ID > " api_id

if [[ $api_id = "" ]]; then
  api_id="2040"
  api_hash="b18441a1ff607e10a989891a5462e627"
else
  read -r -p "API_HASH > " api_hash
fi

echo
echo "SET PM PERMIT warn limit"
read -r -p "PM_LIMIT warn limit > " pm_limit

if [[ $pm_limit = "" ]]; then
  pm_limit="3"
  echo "limit not provided by user set to default"
fi

echo
echo "Enter APIFLASH_KEY for webshot plugin"
echo "You can get it here -> https://apiflash.com/dashboard/access_keys"
read -r -p "APIFLASH_KEY > " apiflash_key

if [[ $apiflash_key = "" ]]; then
  echo "NOTE: API Not set you'll get errors with webshot & ws module"
fi

echo
echo "Enter RMBG_KEY for remove background module"
echo "You can get it here -> https://www.remove.bg/dashboard#api-key"
read -r -p "RMBG_KEY > " rmbg_key

if [[ $rmbg_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use remove background modules"
fi

echo
echo "Enter VT_KEY for VirusTotal"
echo "You can get it here -> https://www.virustotal.com/"
read -r -p "VT_KEY > " vt_key

if [[ $vt_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use VirusTotal module"
fi

echo
echo "Enter GEMINI_KEY if you want to use AI"
echo "You can get it here -> https://makersuite.google.com/app/apikey"
read -r -p "GEMINI_KEY > " gemini_key

if [[ $gemini_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use AI modules"
fi

echo
echo "Enter VCA_API_KEY for aiutils"
echo "Learn How to Get One --> https://github.com/VisionCraft-org/VisionCraft?tab=readme-ov-file#obtaining-an-api-key"
read -r -p "VCA_API_KEY > " vca_api_key

if [[ $vca_api_key = "" ]]; then
  echo "NOTE: API Not set you'll not be able to use aiutils module/pligins"
fi

echo
echo "Choose database type:"
echo "[1] MongoDB db_url"
echo "[2] MongoDB localhost"
echo "[3] Sqlite (default)"
read -r -p "> " db_type

echo
case $db_type in
  1)
    echo "Please enter db_url"
    echo "You can get it here -> https://mongodb.com/atlas"
    read -r -p "> " db_url
    db_name=Moon_Userbot
    db_type=mongodb
    ;;
  2)
    if systemctl status mongodb; then
      wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
      source /etc/os-release
      echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
      apt update
      apt install mongodb -y
      systemctl daemon-reload
      systemctl enable mongodb
    fi
    systemctl start mongodb

    db_url=mongodb://localhost:27017
    db_name=Moon_Userbot
    db_type=mongodb
    ;;
  *)
    db_name=db.sqlite3
    db_type=sqlite3
    ;;
esac

cat > .env << EOL
API_ID=${api_id}
API_HASH=${api_hash}
# sqlite/sqlite3 or mongo/mongodb
DATABASE_TYPE=${db_type}
# file name for sqlite3, database name for mongodb
DATABASE_NAME=${db_name}
# only for mongodb
DATABASE_URL=${db_url}
APIFLASH_KEY=${apiflash_key}
RMBG_KEY=${rmbg_key}
VT_KEY=${vt_key}
GEMINI_KEY=${gemini_key}
VCA_API_KEY=${vca_api_key}
PM_LIMIT=${pm_limit}
EOL

chown -R $SUDO_USER:$SUDO_USER .

echo
echo "Choose installation type:"
echo "[1] PM2"
echo "[2] Systemd service"
echo "[3] Custom (default)"
read -r -p "> " install_type

su -c "python3 install.py ${install_type}" $SUDO_USER || exit 3

case $install_type in
  1)
    if ! command -v pm2; then
      curl -fsSL https://deb.nodesource.com/setup_17.x | bash
      apt install nodejs -y
      npm install pm2 -g
      su -c "pm2 startup" $SUDO_USER
      env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER
    fi
    su -c "pm2 start main.py --name Moon --interpreter python3" $SUDO_USER
    su -c "pm2 save" $SUDO_USER

    echo
    echo "============================"
    echo "Great! Moon-Userbot installed successfully and running now!"
    echo "Installation type: PM2"
    echo "Start with: \"pm2 start Moon\""
    echo "Stop with: \"pm2 stop Moon\""
    echo "Process name: Moon"
    echo "============================"
    ;;
  2)
    cat > /etc/systemd/system/Moon.service << EOL
[Unit]
Description=Service for Moon Userbot
[Service]
Type=simple
ExecStart=$(which python3) ${PWD}/main.py
WorkingDirectory=${PWD}
Restart=always
User=${SUDO_USER}
Group=${SUDO_USER}
[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl start Moon
    systemctl enable Moon

    echo
    echo "============================"
    echo "Great! Moon-Userbot installed successfully and running now!"
    echo "Installation type: Systemd service"
    echo "Start with: \"sudo systemctl start Moon\""
    echo "Stop with: \"sudo systemctl stop Moon\""
    echo "============================"
    ;;
  *)
    echo
    echo "============================"
    echo "Great! Moon-Userbot installed successfully!"
    echo "Installation type: Custom"
    echo "Start with: \"python3 main.py\""
    echo "============================"
    ;;
esac

chown -R $SUDO_USER:$SUDO_USER .