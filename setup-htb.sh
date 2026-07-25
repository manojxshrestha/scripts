#!/usr/bin/env bash
set -e

echo "[+] Updating Go..."

# Reset bashrc (optional)
mv ~/.bashrc ~/.bashrc_bad 2>/dev/null || true
cp /etc/skel/.bashrc ~/.bashrc 2>/dev/null || true

# Remove old Go
sudo rm -rf /usr/local/go ~/go

# Install Go
GO_VERSION="1.24.4"

wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"

sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm -f "go${GO_VERSION}.linux-amd64.tar.gz"

mkdir -p "$HOME/go/bin"

if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

export PATH=/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin:$PATH

echo "[+] Go Installed:"
go version

echo
echo "[+] Installing PureDNS..."
go install github.com/d3mondev/puredns/v2@latest

echo
echo "[+] Installing MassDNS..."

if [ ! -d massdns ]; then
    git clone https://github.com/blechschmidt/massdns.git
fi

cd massdns
make
sudo make install
cd ..

echo
echo "[+] Downloading wordlists..."

wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/subdomains-top1million-20000.txt
wget -nc https://raw.githubusercontent.com/manojxshrestha/wordlists/refs/heads/main/resolvers.txt

echo
echo "[+] Installation Complete!"
echo
echo "Go:       $(go version)"
echo "PureDNS:  $(which puredns)"
echo "MassDNS:  $(which massdns)"
echo
echo "Wordlists:"
echo "  - subdomains-top1million-20000.txt"
echo "  - resolvers.txt"
