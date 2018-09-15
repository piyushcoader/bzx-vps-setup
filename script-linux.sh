#!/bin/bash

#run these 2 lines if you copy script to VPS
#chmod +x ./BZXInstallVPS.sh
#./BZXInstallVPS.sh

## Definitions 
#define default bitcoinzerox P2P Port
port=29301

echo "BitcoinZero VPS setup 5.0.0.5"
echo "BZX MN SETUP"
echo "@cryptochain, @shinner"
echo ""
sleep 1


#make sure Uncomplicated Firewall package is installed
sudo apt-get -y install ufw
#open firewall 
ufw allow 22/tcp
ufw limit 22/tcp
ufw allow ${port}/tcp
ufw logging on
ufw --force enable


# Check if a swap file exists and create if one doesn't exist
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "! 'Swap file already active, skippping swap creation' !"
else
    sudo fallocate -l 3G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo echo -e "/swapfile none swap sw 0 0 \n" >> /etc/fstab
fi

generate_rpc () {
  # Generate random rpc credentials
  rpcuser=$(date +%s | sha256sum | base64 | head -c 8)
  rpcpassword=$(date +%s | sha256sum | base64 | head -c 20)
}


bzx_conf_seeds () {
# Append info to a conf file
echo "
addnode=195.181.220.161
addnode=80.211.195.164
addnode=80.211.204.90
addnode=185.33.145.4
addnode=195.200.244.73
addnode=90.229.169.216
addnode=159.69.127.124
addnode=95.216.148.61
addnode=198.58.122.106
addnode=140.82.8.25
addnode=5.79.119.106
addnode=81.171.19.63
addnode=149.28.116.28
addnode=144.202.49.208
addnode=45.63.77.245
addnode=173.199.90.253
addnode=149.28.112.130
addnode=144.202.51.57
addnode=104.207.141.35
addnode=45.76.225.23
addnode=149.28.117.91
addnode=207.148.9.125
addnode=149.28.119.14
addnode=45.76.230.172
addnode=155.4.52.111
addnode=66.42.78.210
addnode=159.69.156.108
addnode=159.69.118.240
addnode=107.191.49.190
addnode=144.202.16.248
" >> ~/.bitcoinzero/bitcoinzero.conf
}


get_ip () {
# Get server primary IPv4 address
ipaddress=$(curl ipinfo.io/ip)
}

spe_set_mn () {
# Let Write the masternode information to the bitcoinzero config 
echo "
bznode=1
externalip=${ipaddress}:${port}
bznodeprivkey=${masternodegenkey}
" >> ~/.bitcoinzero/bitcoinzero.conf
}



#make folder and get full blockchain
mkdir .bitcoinzero
cd .bitcoinzero
sudo apt-get -y install unzip </dev/null
sleep 2
echo "Get chain files...."
wget https://www.hexxcoin.net/cf/chainfilesbin.zip
echo "Unzip chain files...."
sudo unzip chainfilesbin.zip
cd 


# get bitcoinzero daemon
echo "Get daemon..."
wget https://github.com/BitcoinZeroOfficial/bitcoinzero/releases/download/5.0.0.5/linux-x64.tar.gz

tar -xvf  linux-x64.tar.gz
chmod +x bitcoinzerod
chmod +x bitcoinzero-cli
mv bitcoinzerod /usr/local/bin
mv bitcoinzero-cli /usr/local/bin
sleep 1


# start bitcoinzero daemon
cd
bitcoinzerod -daemon
sleep 10

#Get virtual privatekey
masternodegenkey=$(bitcoinzero-cli bznode genkey)

# stop bitcoinzero daemon
bitcoinzero-cli stop
sleep 10 
pkill -f bitcoinzerod 
sleep 1

#remove default config
rm ~/.bitcoinzero/bitcoinzero.conf

# make bitcoinzero config file
generate_rpc
echo "rpcuser=${rpcuser}
rpcpassword=${rpcpassword}
rpcallowip=127.0.0.1
server=1
listen=1
maxconnections=64
rescan=0
"  > ~/.bitcoinzero/bitcoinzero.conf

get_ip
spe_set_mn
bzx_conf_seeds


# start bitcoinzero daemon again
sleep 1 
bitcoinzerod -daemon
sleep 10 

bitcoinzero-cli getinfo

stty -echo
echo 
echo
echo "Continue in your computer controller wallet"
echo "1. Send 15m BZX to your controller wallet address and wait 15 confirmations"
echo "2. Use in debug window bznode outputs command to see TrxOutID and TrxOutInd"
echo "3. Write into bznode.conf line:" 
echo
echo MyMN ${ipaddress}:${port} ${masternodegenkey} TrxOutID TrxOutInd
echo
echo edit settings with nano-editor if needed:
echo nano ~/.bitcoinzero/bitcoinzero.conf
echo

stty echo
