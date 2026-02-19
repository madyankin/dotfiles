#!/bin/bash
# Kali Linux Security Tools Setup Script
# Run this inside the Kali container to install common pentesting tools

set -e

echo "=== Updating Kali Linux ==="
apt-get update && apt-get upgrade -y

echo "=== Installing Core Web Application Testing Tools ==="
apt-get install -y \
    burpsuite \
    nikto \
    dirb \
    gobuster \
    sqlmap \
    wfuzz \
    ffuf \
    httpie \
    jq \
    curl \
    wget

echo "=== Installing Authentication & Session Testing Tools ==="
apt-get install -y \
    hydra \
    john \
    hashcat

echo "=== Installing Network Tools ==="
apt-get install -y \
    nmap \
    netcat-openbsd \
    tcpdump \
    wireshark-common

echo "=== Installing API Testing Tools ==="
apt-get install -y \
    python3-pip

pip3 install --break-system-packages \
    requests \
    pyjwt \
    httpx \
    aiohttp

echo "=== Installing Additional Utilities ==="
apt-get install -y \
    vim \
    tmux \
    git \
    tree

echo "=== Setup Complete ==="
echo "Common tools installed:"
echo "  - burpsuite: Web proxy and scanner"
echo "  - nikto: Web server scanner"
echo "  - gobuster/dirb/ffuf: Directory brute forcing"
echo "  - sqlmap: SQL injection automation"
echo "  - hydra: Password brute forcing"
echo "  - nmap: Network scanning"
echo "  - httpie: HTTP client"
echo ""
echo "Your pentest files are mounted at /pentest"
