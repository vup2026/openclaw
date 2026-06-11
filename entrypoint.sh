#!/bin/sh
set -e

CONFIG_FILE="/home/node/.openclaw/openclaw.json"

mkdir -p /home/node/.openclaw

if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"gateway":{"mode":"local"},"gateway.controlui.allowedOrigins":["https://openclaw-production-d1f7.up.railway.app"]}' > "$CONFIG_FILE"
else
  # Patch existing config to add allowedOrigins if missing
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
    cfg['gateway.controlui.allowedOrigins'] = ['https://openclaw-production-d1f7.up.railway.app'];
    fs.writeFileSync('$CONFIG_FILE', JSON.stringify(cfg));
  "
fi

exec "\$@"
