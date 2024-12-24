#!/bin/bash

PORT=41010
RPCPORT=41011
CONF_DIR=~/.edelweis
COINZIP='https://github.com/edelweiscoin/EDEL/releases/download/v1.1/edelweis-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/edelweis.service
[Unit]
Description=Edelweis Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/edelweisd -datadir=/data/edel
ExecStop=-/usr/local/bin/edelweis-cli -datadir=/data/edel stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable edelweis.service
  systemctl start edelweis.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm edelweis-qt edelweis-tx edelweis-linux.zip
  chmod +x edelweis*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget http://cdn.delion.xyz/edel.zip
  unzip edel.zip
  rm edel.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> edelweis.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> edelweis.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> edelweis.conf_TEMP
  echo "rpcport=$RPCPORT" >> edelweis.conf_TEMP
  echo "listen=1" >> edelweis.conf_TEMP
  echo "server=1" >> edelweis.conf_TEMP
  echo "daemon=1" >> edelweis.conf_TEMP
  echo "maxconnections=250" >> edelweis.conf_TEMP
  echo "masternode=1" >> edelweis.conf_TEMP
  echo "" >> edelweis.conf_TEMP
  echo "port=$PORT" >> edelweis.conf_TEMP
  echo "externalip=$IP:$PORT" >> edelweis.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> edelweis.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> edelweis.conf_TEMP
  mv edelweis.conf_TEMP edelweis.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Edelweis Service: ${GREEN}systemctl start edelweis${NC}"
echo -e "Check Edelweis Status Service: ${GREEN}systemctl status edelweis${NC}"
echo -e "Stop Edelweis Service: ${GREEN}systemctl stop edelweis${NC}"
echo -e "Check Masternode Status: ${GREEN}edelweis-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Edelweis Masternode Installation Done${NC}"
exec bash
exit
