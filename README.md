# 🎯 Bug Bounty & CTF Automation Scripts

[![GitHub stars](https://img.shields.io/github/stars/manojxshrestha/scripts?style=flat-square)](https://github.com/manojxshrestha/scripts/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/manojxshrestha/scripts?style=flat-square)](https://github.com/manojxshrestha/scripts/network)
[![License](https://img.shields.io/github/license/manojxshrestha/scripts?style=flat-square)](LICENSE)

> 🚀 **A comprehensive collection of automation scripts for bug bounty hunting, penetration testing, and CTF competitions.**

---

## 📋 Table of Contents

- [Overview](#overview)
- [🌟 Featured Tools](#-featured-tools)
  - [ferox2nuclei](#ferox2nuclei)
  - [DastFuzzer](#dastfuzzer)
  - [subenum](#subenum)
- [📁 All Scripts](#-all-scripts)
- [🚀 Quick Start](#-quick-start)
- [💻 Installation](#-installation)
- [🎯 Usage Examples](#-usage-examples)
- [🏆 CTF/Hackathon Workflow](#-ctfhackathon-workflow)
- [🔧 Requirements](#-requirements)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)
- [👨‍💻 Author](#-author)

---

## Overview

This repository contains a curated collection of automation scripts designed for:

- 🔍 **Reconnaissance** - Subdomain enumeration, endpoint discovery
- 🌐 **Web Application Testing** - Fuzzing, vulnerability scanning
- 🛡️ **Security Assessment** - Automated vulnerability detection
- 🏴‍☠️ **CTF Competitions** - Fast, efficient target enumeration
- 💰 **Bug Bounty Hunting** - Comprehensive target analysis

### ✨ Key Features

- ⚡ **Fast & Efficient** - Optimized for speed and accuracy
- 🔄 **Automation** - Minimal manual intervention required
- 🎯 **CTF-Ready** - Battle-tested in live competitions
- 📊 **Well-Documented** - Clear usage instructions
- 🔧 **Modular** - Use individual scripts or complete workflows

---

## 🌟 Featured Tools

### ferox2nuclei

**The ultimate automation suite for feroxbuster → nuclei workflow.**

🎯 **What it does:**
- Processes feroxbuster directory enumeration results
- **Auto-detects ferox-*.txt files** (no manual path configuration needed!)
- Automatically categorizes findings (Admin, API, Backups, etc.)
- Generates ready-to-use nuclei scan commands
- Extracts clean URLs for vulnerability scanning

📦 **Includes:**
- `ferox2nuclei.sh` - Main processor (v3.0 with auto-detection)
- `nucleiwithadmin.sh` - Admin panel scanning
- `nucleiwithsensitive.sh` - Sensitive data exposure
- `nucleiwithnucleiNorm.sh` - General CVE scanning
- `nucleiwithgraphql.sh` - GraphQL endpoint testing
- `nucleiwithendpoints.sh` - API endpoint fuzzing
- `nucleiwithgoodENUM.sh` - File enumeration
- `nucleiwithsignup.sh` - Authentication testing

**[→ Go to ferox2nuclei](#ferox2nuclei-1)**

---

### DastFuzzer

**Dynamic Application Security Testing (DAST) fuzzer for web applications.**

🔥 **Features:**
- Automated parameter fuzzing
- Multiple payload injection points
- Customizable wordlists
- Response analysis & filtering

---

### subenum

**Comprehensive subdomain enumeration toolkit.**

🌍 **Capabilities:**
- Multi-source subdomain discovery
- DNS resolution and validation
- Wildcard detection and filtering
- Output in multiple formats

---

## 📁 All Scripts

### 🕵️ Reconnaissance

| Script | Description | Language |
|--------|-------------|----------|
| `subenum.sh` | Subdomain enumeration | Bash |
| `subburst.sh` | Fast subdomain bruteforcing | Bash |
| `extracturls.sh` | URL extraction from various sources | Bash |
| `WebMiner.js` | JavaScript endpoint miner | JavaScript |
| `Find-Hidden-Endpoints.js` | Hidden endpoint discovery | JavaScript |
| `URLyzer.js` | URL analysis tool | JavaScript |

### 🌐 Web Application Testing

| Script | Description | Language |
|--------|-------------|----------|
| `ferox2nuclei/` | Feroxbuster → Nuclei automation | Bash |
| `DastFuzzer.sh` | DAST fuzzing framework | Bash |
| `exposure.sh` | Sensitive file exposure checker | Bash |
| `ghsqli.sh` | GitHub SQL injection hunter | Bash |
| `vuln-urls-filter.sh` | Vulnerable URL filter | Bash |
| `extract-vulns.sh` | Vulnerability extractor | Bash |
| `filter-wildcard.sh` | Wildcard filtering utility | Bash |

### 🔍 Information Gathering

| Script | Description | Language |
|--------|-------------|----------|
| `collect-bchecks.sh` | Collect BChecks from various sources | Bash |
| `B-Checks/` | Custom BCheck templates | - |
| `downloadjs.py` | JavaScript file downloader | Python |
| `SecretValidator.py` | Secret key validator | Python |
| `endpoint-finder.js` | API endpoint finder | JavaScript |

### 📄 Wordlists & Payloads

| File | Description |
|------|-------------|
| `signup-PATHS.txt` | Signup/Authentication paths |
| `xss-payloads.md` | Comprehensive XSS payloads |
| `subburst.md` | Subdomain bruteforce guide |

---

## 🚀 Quick Start

### Clone the repository

```bash
git clone https://github.com/manojxshrestha/scripts.git
cd scripts
```

### Make scripts executable

```bash
chmod +x *.sh
chmod +x ferox2nuclei/*.sh
```

### Run any script

```bash
# Example: Run ferox2nuclei workflow
./ferox2nuclei/ferox2nuclei.sh
```

---

## 💻 Installation

### Prerequisites

**Required Tools:**
- [feroxbuster](https://github.com/epi052/feroxbuster) - Fast content discovery
- [nuclei](https://github.com/projectdiscovery/nuclei) - Vulnerability scanner
- [httpx](https://github.com/projectdiscovery/httpx) - Fast HTTP prober
- [subfinder](https://github.com/projectdiscovery/subfinder) - Subdomain discovery
- [katana](https://github.com/projectdiscovery/katana) - Web crawler

**Optional Tools:**
- [gau](https://github.com/lc/gau) - GetAllUrls
- [waybackurls](https://github.com/tomnomnom/waybackurls) - Wayback Machine URLs
- [anew](https://github.com/tomnomnom/anew) - Append new lines
- [jq](https://stedolan.github.io/jq/) - JSON processor

### Install All Tools (Kali Linux)

```bash
# Using apt
sudo apt update
sudo apt install -y feroxbuster nuclei httpx subfinder katana

# Or install from source
go install -v github.com/epi052/feroxbuster/v2/cmd/feroxbuster@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
```

---

## 🎯 Usage Examples

### Example 1: Complete Feroxbuster → Nuclei Workflow

```bash
# Step 1: Run feroxbuster scans
cat targets.txt | feroxbuster --stdin -o ferox-output.txt

# Step 2: Clone and enter the automation suite
git clone https://github.com/manojxshrestha/scripts.git
cd scripts/ferox2nuclei

# Step 3: Run processor (auto-detects ferox files!)
./ferox2nuclei.sh                    # Auto-detects ferox-*.txt files
./ferox2nuclei.sh /path/to/files/    # Or specify custom path

# Step 4: Run nuclei scans
./nucleiwithadmin.sh
./nucleiwithsensitive.sh
```

### Example 2: Subdomain Enumeration

```bash
# Enumerate subdomains
./subenum.sh -d target.com -o subs.txt

# Filter live hosts
cat subs.txt | httpx -o live-subs.txt
```

### Example 3: DAST Fuzzing

```bash
# Run DAST fuzzer on target
./DastFuzzer.sh -u https://target.com -w /path/to/wordlist.txt
```

### Example 4: URL Extraction

```bash
# Extract URLs from JavaScript files
./extracturls.sh -i js-files.txt -o endpoints.txt
```

---

## 🏆 CTF/Hackathon Workflow

### Phase 1: Reconnaissance (10 minutes)

```bash
# 1. Subdomain enumeration
./subenum.sh -d target.com -o subs.txt

# 2. Find live hosts
cat subs.txt | httpx -o live.txt

# 3. Directory enumeration (parallel)
cat live.txt | feroxbuster --stdin -o ferox-graphql.txt &
cat live.txt | feroxbuster --stdin -o ferox-admin.txt &
# ... run 7 feroxbuster instances
```

### Phase 2: Processing (5 minutes)

```bash
cd ferox2nuclei
./ferox2nuclei.sh
```

### Phase 3: Vulnerability Scanning (Ongoing)

```bash
# High priority scans first
./nucleiwithadmin.sh &
./nucleiwithsensitive.sh &
./nucleiwithnucleiNorm.sh &

# Monitor results
tail -f nuclei-results-admin/01-admin-panels.txt
```

### Phase 4: Manual Verification

Check the generated reports and manually verify findings:
- `results-*/high-priority.txt`
- `nuclei-results-*/` directories

---

## 🔧 Requirements

### System Requirements

- **OS:** Linux (Kali, Ubuntu, Debian) / macOS / WSL2
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 10GB free space
- **Network:** Stable internet connection

### Tool Versions

- feroxbuster >= 2.10.0
- nuclei >= 3.0.0
- httpx >= 1.3.0
- subfinder >= 2.5.0
- bash >= 4.0
- awk, sed, grep (standard Unix tools)

---

## 📊 Script Performance

| Script | Speed | Memory Usage | Parallel | Best For |
|--------|-------|--------------|----------|----------|
| ferox2nuclei.sh | Fast | Low | Yes | CTF, Bug Bounty |
| DastFuzzer.sh | Medium | Medium | Yes | DAST testing |
| subenum.sh | Fast | Low | Yes | Initial recon |

---

## 🛠️ Troubleshooting

### Common Issues

**Q: Permission denied error**
```bash
chmod +x scriptname.sh
```

**Q: Command not found**
```bash
# Add to PATH or use ./
./scriptname.sh
```

**Q: Nuclei templates not found**
```bash
nuclei -update-templates
```

**Q: Feroxbuster crashes**
```bash
# Remove config file causing issues
rm ~/.config/feroxbuster/ferox-config.toml
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Guidelines

- Test your scripts before submitting
- Add comments for complex logic
- Update README if adding new features
- Follow existing code style

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Manoj Shrestha**

- GitHub: [@manojxshrestha](https://github.com/manojxshrestha)
- Twitter: [@manojxshrestha](https://twitter.com/manojxshrestha)
- Blog: [manojxshrestha.github.io](https://manojxshrestha.github.io)

### Support

If you find these scripts helpful, please consider:

- ⭐ Starring this repository
- 🍴 Forking and improving
- 🐛 Reporting issues
- 💡 Suggesting new features

---

## 🙏 Acknowledgments

- [ProjectDiscovery](https://github.com/projectdiscovery) for amazing tools (nuclei, httpx, subfinder, katana)
- [TomNomNom](https://github.com/tomnomnom) for invaluable security tools
- [Feroxbuster](https://github.com/epi052/feroxbuster) team for the fast content discovery tool
- Bug bounty community for continuous inspiration

---

## 📈 Stats

![GitHub Stats](https://github-readme-stats.vercel.app/api?username=manojxshrestha&show_icons=true&theme=radical)

---

<p align="center">
  <b>Happy Hunting! 🐛💰</b>
</p>

<p align="center">
  <i>"The best defense is a good offense."</i>
</p>

<p align="center">
  <a href="https://github.com/manojxshrestha/scripts/issues">Report Bug</a> •
  <a href="https://github.com/manojxshrestha/scripts/issues">Request Feature</a> •
  <a href="https://github.com/manojxshrestha/scripts/discussions">Discussions</a>
</p>
