#!/usr/bin/env python3
"""
GitHub API PUT for proposals-manager/data/proposals.json

正确做法：Python urllib + gh auth token
⚠️ 不要用 content@file.json 语法（gh api 不支持）
⚠️ 不要把 token 直接放在 URL 里（会 401 Bad Credentials）
"""
import urllib.request, json, base64, subprocess, sys

REPO = "YeLuo45/proposals-manager"
FILE_PATH = "data/proposals.json"
COMMIT_MSG = sys.argv[1] if len(sys.argv) > 1 else "chore: sync proposals.json"

# 1. 获取当前 SHA
url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
req = urllib.request.Request(url, headers={"Accept": "application/vnd.github.v3+json"})
with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.loads(resp.read().decode())
    sha = data['sha']

# 2. 读取本地 JSON 文件
local_path = "/home/hermes/.hermes/scripts/proposals.json"
with open(local_path, 'r', encoding='utf-8') as f:
    new_content = f.read()

# 3. base64 编码
new_content_b64 = base64.b64encode(new_content.encode('utf-8')).decode()

# 4. 获取 gh token
token = subprocess.check_output(['gh', 'auth', 'token']).decode().strip()

# 5. PUT 到 GitHub
payload = json.dumps({
    "message": COMMIT_MSG,
    "content": new_content_b64,
    "sha": sha
}).encode('utf-8')

update_req = urllib.request.Request(
    url,
    data=payload,
    headers={
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}"
    },
    method='PUT'
)

try:
    with urllib.request.urlopen(update_req, timeout=30) as resp:
        result = json.loads(resp.read().decode())
        print(f"SUCCESS: {result['commit']['sha']}")
        print(f"URL: {result['commit']['html_url']}")
except urllib.error.HTTPError as e:
    error_body = e.read().decode()
    print(f"HTTP Error {e.code}: {error_body[:500]}", file=sys.stderr)
    sys.exit(1)
