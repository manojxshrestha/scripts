
#!/bin/bash

set -e

echo "[+] Installing Go..."
sudo rm -rf /usr/local/go "$HOME/go"
wget -q https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
rm go1.24.4.linux-amd64.tar.gz

mkdir -p "$HOME/go/bin"

grep -qxF 'export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH' "$HOME/.bashrc" || \
    echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH' >> "$HOME/.bashrc"

export PATH="/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH"

echo "[+] Installing PureDNS..."
go install github.com/d3mondev/puredns/v2@latest

echo "[+] Installing MassDNS..."
if [ ! -d massdns ]; then
    git clone https://github.com/blechschmidt/massdns.git
fi

cd massdns
make
sudo make install

echo "[+] Downloading Wordlists..."
wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/subdomains-top1million-20000.txt
wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/resolvers.txt

cd ..

echo "[+] Installing Nuclei..."
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

echo "[+] Installing/Updating Nuclei Templates..."
"$HOME/go/bin/nuclei" -update-templates

echo
echo "[+] Done!"

go version
command -v puredns
command -v nuclei
command -v massdns
