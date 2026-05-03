#!/bin/bash
# 快速渗透测试扫描脚本
# 使用前请确保已获得授权

TARGET="${1:-target.com}"
OUTPUT_DIR="scan-$(date +%Y%m%d-%H%M%S)-${TARGET}"
mkdir -p "$OUTPUT_DIR"

echo "[*] Starting reconnaissance on $TARGET"
echo "[*] Output directory: $OUTPUT_DIR"

# 1. 子域名发现
echo "[+] Step 1: Subdomain enumeration"
subfinder -d "$TARGET" -o "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo "[!] subfinder failed"
amass enum -d "$TARGET" -o "$OUTPUT_DIR/amass-subs.txt" 2>/dev/null || echo "[!] amass failed"
assetfinder "$TARGET" >> "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo "[!] assetfinder failed"
sort -u "$OUTPUT_DIR/subdomains.txt" -o "$OUTPUT_DIR/subdomains.txt"

# 2. 存活验证
echo "[+] Step 2: Probing alive hosts"
cat "$OUTPUT_DIR/subdomains.txt" | httpx -silent -timeout 5000 -o "$OUTPUT_DIR/alive.txt" 2>/dev/null || echo "[!] httpx failed"

# 3. 端口扫描
echo "[+] Step 3: Port scanning"
nmap -sV -sC -O --top-ports 1000 "$TARGET" -oA "$OUTPUT_DIR/nmap-scan" 2>/dev/null || echo "[!] nmap failed"

# 4. Web 扫描
echo "[+] Step 4: Web vulnerability scanning"
nuclei -u "https://$TARGET" -o "$OUTPUT_DIR/nuclei-results.txt" 2>/dev/null || echo "[!] nuclei failed"

# 5. 目录发现
echo "[+] Step 5: Directory enumeration"
ffuf -w /usr/share/wordlists/dirb/common.txt -u "https://$TARGET/FUZZ" -o "$OUTPUT_DIR/ffuf-results.txt" 2>/dev/null || echo "[!] ffuf failed"

echo "[*] Scan complete! Results in $OUTPUT_DIR/"
echo "[*] Key files:"
echo "    - subdomains.txt"
echo "    - alive.txt"
echo "    - nmap-scan.xml"
echo "    - nuclei-results.txt"
echo "    - ffuf-results.txt"
