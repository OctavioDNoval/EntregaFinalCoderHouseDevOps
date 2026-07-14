#!/bin/bash
set -euxo pipefail

dnf install -y git docker
systemctl enable --now docker

if [ -d /opt/app/.git ]; then
  cd /opt/app
  git pull
else
  rm -rf /opt/app
  git clone ${app_repo_url} /opt/app
fi

cd /opt/app
docker compose build

cat > /etc/systemd/system/app.service <<'UNITEOF'
[Unit]
Description=Todo API (Docker Compose)
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/opt/app
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNITEOF

systemctl daemon-reload
systemctl enable --now app
