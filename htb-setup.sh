#!/bin/bash

set -e

echo "[+] Installing Go..."
sudo rm -rf /usr/local/go ~/go
wget -q https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
rm go1.24.4.linux-amd64.tar.gz

mkdir -p "$HOME/go/bin"
echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH' >> ~/.bashrc
export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH

echo "[+] Installing PureDNS..."
go install github.com/d3mondev/puredns/v2@latest

echo "[+] Installing MassDNS..."
git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
sudo make install

echo "[+] Downloading Wordlists..."
wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/subdomains-top1million-20000.txt
wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/resolvers.txt

cd ..

echo "[+] Installing Nuclei..."
NUCLEI_VERSION=$(curl -sL https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | grep -oP '"tag_name": "\K[^"]+')
wget -q "https://github.com/projectdiscovery/nuclei/releases/download/${NUCLEI_VERSION}/nuclei_${NUCLEI_VERSION#v}_linux_amd64.zip"
unzip -qo "nuclei_${NUCLEI_VERSION#v}_linux_amd64.zip" nuclei
mv nuclei "$HOME/go/bin/nuclei"
chmod +x "$HOME/go/bin/nuclei"
rm -f "nuclei_${NUCLEI_VERSION#v}_linux_amd64.zip"

echo "[+] Downloading Nuclei Templates..."
~/go/bin/nuclei -ut

echo
echo "[+] Done!"
go version
which puredns
which nuclei
which massdns
