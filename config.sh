#!/bin/bash

# =====================
# AWS
# =====================

REGION="ap-northeast-2"

# =====================
# EC2 INSTANCE IDs
# =====================
APP_ID="i-0ede319af23529a49"
MYSQL_ID="i-0d1efa9c134c5d1b8"
POSTGRES_ID="i-0a05f6077977fd3a6"

# =====================
# SSH HOST
# =====================

APP_HOST="star23-app"
MYSQL_HOST="star23-mysql"
POSTGRES_HOST="star23-postgres"

# SSH 접속 계정 (필요시 local.sh 에서 override)
SSH_USER="ubuntu"

SSH_CONFIG="$HOME/.ssh/config"