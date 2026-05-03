---
name: defensive-security-tools
description: 防御性安全工具集 — 适用于授权渗透测试、安全研究和 CTF。包含信息收集、Web扫描、代码审计、漏洞框架等分类。严禁未经授权使用。
category: security
---

# Defensive Security Tools

防御性安全工具集，适用于授权渗透测试、安全研究和 CTF 比赛。

## 使用场景

- ✅ 授权的安全测试和渗透评估（需书面授权）
- ✅ 扫描自己的基础设施和代码库
- ✅ CTF 比赛和安全研究
- ✅ Bug Bounty（遵循目标平台规则）
- ✅ 安全研究和漏洞验证
- ❌ 未经授权的扫描和测试

## 免责声明

使用前请确保：
1. 你拥有目标的书面授权
2. 或者这是你自己拥有的系统
3. 或者在 Bug Bounty 规则允许范围内

---

## 信息收集（Reconnaissance）

### 网络扫描
```bash
# Nmap 端口扫描
nmap -sV -sC -O target.com -oA scan_results

# 快速扫描
nmap -F target.com

# 全面扫描
nmap -A -p- target.com -oA full_scan

# Masscan 高速扫描
masscan -p1-65535 target.com --rate=10000

# RustScan 现代扫描器
rustscan -a target.com -- -sV
```

### 子域名发现
```bash
# Subfinder
subfinder -d target.com -o subdomains.txt

# Amass
amass enum -d target.com -o amass_results.txt

# Assetfinder
assetfinder target.com | tee subdomains.txt

# shosigsubdomains (curl)
curl -s "https://api.sublist3r.com/?domains=target.com"

# 验证存活
cat subdomains.txt | httpx -silent -timeout 5000 | tee alive.txt
```

### Git 秘密扫描
```bash
# TruffleHog - 扫描 Git 历史中的密钥
trufflehog git https://github.com/user/repo

# GitLeaks - 扫描 commit 中的密钥
gitLeaks detect --source .

# gitleaks (CI集成)
gitleaks detect --source . --verbose
```

### DNS 枚举
```bash
# dig 查询
dig +short target.com NS
dig +short target.com MX
dig +short target.com TXT

# DNSRecon
dnsrecon -d target.com -t std

# DNSdumpster
curl -s "https://dnsdumpster.com/domainip/<target.com>/"
```

### 网络空间搜索引擎
```bash
# shodan
shodan host target.com
shodan search 'ssl:"target.com"'

# censys
censys search "parsed.names: target.com"
```

### 信息聚合
```bash
# theHarvester - 邮件和子域名收集
theHarvester -d target.com -b all

# SpiderFoot
spiderfoot -s target.com

# Maigret - 用户名枚举
maigret username
```

---

## Web 安全扫描

### 漏洞扫描
```bash
# Nuclei - 模板化漏洞扫描
nuclei -u https://target.com -t ~/nuclei-templates/

# Nikto
nikto -h https://target.com

# OWASP ZAP (CLI)
zap-baseline.py -t https://target.com

# testssl.sh - SSL/TLS 检测
testssl.sh https://target.com

# WAFW00F - WAF 检测
wafw00f -a https://target.com
```

### 目录/文件发现
```bash
# ffuf
ffuf -w wordlist.txt -u https://target.com/FUZZ

# Gobuster
gobuster dir -u https://target.com -w wordlist.txt

# Dirsearch
python3 dirsearch.py -u https://target.com -e php,html,js

# feroxbuster
feroxbuster -u https://target.com -x php,html

# Arjun - URL 参数发现
arjun -u https://target.com
```

### Web 爬虫
```bash
# Katana
katana -u https://target.com

# gau - 获取所有 URL
 gau target.com | tee urls.txt

# waybackurls
curl -s "https://web.archive.org/cdx/search/cdx?url=target.com/*&output=text" | tee urls.txt
```

### 交互式安全测试
```bash
# mitmproxy
mitmproxy

# Burp Suite (CLI)
# 需要手动操作，主要用于：
# - Proxy + 重放
# - Intruder 暴力破解
# - Repeater 请求修改
```

---

## 代码安全审计

### SAST 静态分析
```bash
# Semgrep
semgrep --config=auto .

# Bandit - Python 安全
bandit -r ./python_project/

# Gosec - Go 安全
gosec ./...

# CodeQL (GitHub)
# 需要在 GitHub Actions 或本地配置

# SonarQube
docker run -d -p 9000:9000 sonarqube
```

### 依赖扫描
```bash
# npm audit
npm audit

# Snyk
snyk test

# Dependabot (GitHub)
# 自动依赖更新和漏洞警报

# Grype - 容器镜像扫描
grype image:tag

# Trivy - 容器和文件系统扫描
trivy fs .
trivy image image:tag
```

### 密钥/凭证检测
```bash
# detect-secrets
detect-secrets scan . > secrets_audit.json

# secretlint
secretlint "**/*"

# cloud，木马检测
# 注意：不要执行来源不明的工具
```

---

## 漏洞利用框架（防御性）

### Metasploit（授权测试）
```bash
# 启动
msfconsole

# 辅助扫描模块
use auxiliary/scanner/http/dir_scanner
set RHOSTS target.com
run

# 搜索漏洞模块
search type:exploit name:linux
```

### 社会工程学框架
```bash
# SET (Social Engineering Toolkit)
# 仅用于授权钓鱼安全测试
setoolkit

# BeEF (Browser Exploitation Framework)
# 仅用于 XSS 漏洞验证
beef-xss
```

---

## 密码安全审计

### 密码破解（仅限授权）
```bash
# Hashcat - 哈希破解（需授权）
hashcat -m 0 -a 3 hash.txt wordlist.txt

# John the Ripper - 密码破解（需授权）
john --wordlist=wordlist.txt hashes.txt

# Hydra - 在线暴力破解（需授权）
hydra -l admin -P passwords.txt target.com ssh
```

### 密码强度检测
```bash
# zxcvbn (在线)
# https://lowe.github.io/tryzxcvbn/

# cracklib
echo "password123" | cracklib-check
```

---

## 取证与逆向（CTF/研究）

### 逆向工程
```bash
# Ghidra
ghidra

# Radare2
r2 binary

# JadX - APK 反编译
jadx app.apk

# Androguard
python3 -c "from androguard import *; a = apk.APK('app.apk')"
```

### 取证分析
```bash
# Volatility - 内存取证
volatility -f memory.dmp windows.pslist

# Binwalk - 二进制分析
binwalk firmware.bin

# strings
strings suspicious.bin | grep -i password

# Autopsy (GUI)
autopsy
```

### 网络分析
```bash
# Wireshark
wireshark capture.pcap

# tshark (CLI)
tshark -r capture.pcap -Y "http.request" -T fields

# pcap 处理
tcpdump -r capture.pcap "tcp port 80"

# pspy - 进程监控
./pspy64
```

---

## 云安全

### AWS 安全
```bash
# Pacu - AWS 利用框架
python3 pacu.py

# ScoutSuite - 云安全态势评估
scoutsuite

# Prowler - AWS 安全检查
prowler <provider>

# aws-cli 枚举
aws ec2 describe-instances
aws s3 ls
```

### 容器安全
```bash
# Trivy
trivy image image:tag

# dockle
dockle image:tag

# docker-bench-security
docker-bench-security
```

---

## CTF 专用

### Web 漏洞
```bash
# SQLMap（CTF/授权测试）
sqlmap -u "https://target.com/?id=1" --batch

# XSS
# 使用 browser skill 配合手动测试

# 命令注入
# 手动测试和脚手架脚本
```

### 隐写术
```bash
# steghide
steghide extract -sf image.jpg

# zsteg
zsteg image.png

# binwalk
binwalk image.png

# strings
strings image.bin
```

### 密码攻击
```bash
# John
john hash.txt --wordlist=rockyou.txt

# hashcat
hashcat -m 1000 -a 0 hash.txt rockyou.txt

# base64 解码
cat encoded.txt | base64 -d > output
```

---

## 工具安装

### 快速安装（Kali/Parrot）
```bash
# 更新
sudo apt update && sudo apt upgrade -y

# 安装工具集
sudo apt install nmap masscan git masscan ffuf gobuster dirb nikto zaproxy hydra john binwalk volatility steghide
```

### Go 工具安装
```bash
# nuclei
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

# subfinder
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# httpx
go install github.com/projectdiscovery/httpx/cmd/httpx@latest

# gau
go install github.com/lc/gau@latest

# amass
go install github.com/owasp-amass/amass/v3/...@latest
```

### Python 工具安装
```bash
pip install sqlmap
pip install theHarvester
pip install dirsearch
pip install Bandit
pip install Semgrep
```

---

## 常用命令速查

| 任务 | 命令 |
|------|------|
| 快速端口扫描 | `nmap -F target.com` |
| 子域名发现 | `subfinder -d target.com` |
| 存活验证 | `cat subs.txt \| httpx -silent` |
| Web 漏洞扫描 | `nuclei -u https://target.com` |
| 目录发现 | `ffuf -w wordlist.txt -u https://target.com/FUZZ` |
| Git 秘密扫描 | `trufflehog git https://github.com/user/repo` |
| SSL 检测 | `testssl.sh target.com` |
| 依赖漏洞 | `npm audit` / `snyk test` |
| 密码破解 | `john --wordlist=rockyou.txt hash.txt` |
| 内存取证 | `volatility -f mem.dmp windows.pslist` |

---

## 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PTES 渗透测试标准](http://www.pentest-standard.org/)
- [Kali Linux 工具列表](https://tools.kali.org/)
- [Awesome Penetration Testing](https://github.com/enaqx/awesome-pentest)
