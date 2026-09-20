#!/bin/bash

set -e

ROOT_DIR="$HOME/.ec2-cli"

source "$ROOT_DIR/config.sh"

# 개인 설정 (SSH_KEY 등) — git 미포함, 있으면 사용
if [ -f "$ROOT_DIR/local.sh" ]; then
  source "$ROOT_DIR/local.sh"
fi

TARGET="$1"

# ~/.ssh/config 의 Host 블록 HostName 을 갱신하고,
# 블록이 없으면 User/IdentityFile 까지 통째로 새로 만든다.
update_ssh_config() {

  local host="$1"
  local ip="$2"

  # ~/.ssh/config 없으면 생성
  mkdir -p "$(dirname "$SSH_CONFIG")"
  chmod 700 "$(dirname "$SSH_CONFIG")" 2>/dev/null || true
  [ -f "$SSH_CONFIG" ] || { touch "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"; }

  if grep -qE "^[[:space:]]*Host[[:space:]]+$host([[:space:]]|$)" "$SSH_CONFIG"; then

    # 블록 존재: HostName 줄이 있으면 교체, 없으면 Host 줄 아래에 삽입
    awk -v host="$host" -v ip="$ip" '
      function flush() {
        if (in_target && !done) {
          print "    HostName " ip
          done = 1
        }
      }
      $1 == "Host" {
        flush()
        in_target = ($2 == host)
        done = 0
        print
        next
      }
      in_target && $1 == "HostName" {
        print "    HostName " ip
        done = 1
        next
      }
      { print }
      END { flush() }
    ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp"

    mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
    echo "SSH config updated: $host -> $ip"

  else

    # 블록 없음: 새로 추가
    if [ -z "$SSH_KEY" ]; then
      echo "경고: SSH_KEY 가 설정되지 않아 IdentityFile 없이 블록을 만듭니다."
      echo "      ~/.ec2-cli/local.sh 에 SSH_KEY 를 설정하세요."
    fi

    {
      echo ""
      echo "Host $host"
      echo "    HostName $ip"
      echo "    User ${SSH_USER:-ubuntu}"
      [ -n "$SSH_KEY" ] && echo "    IdentityFile $SSH_KEY"
    } >> "$SSH_CONFIG"

    echo "SSH config created: $host -> $ip"
  fi
}

start_instance() {

  NAME="$1"
  INSTANCE_ID="$2"
  SSH_HOST="$3"

  echo ""
  echo "Starting $NAME..."
  echo "Instance: $INSTANCE_ID"

  aws ec2 start-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    > /dev/null

  echo "Waiting for $NAME to enter running state..."

  aws ec2 wait instance-running \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

  echo "$NAME is running."

  PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "Failed to get Public IP."
    exit 1
  fi

  echo "Public IP: $PUBLIC_IP"

  # SSH Config 갱신 (없으면 생성)
  update_ssh_config "$SSH_HOST" "$PUBLIC_IP"

  echo ""
  echo "Done."
  echo "ssh $SSH_HOST"
}

case "$TARGET" in

  app)
    start_instance \
      "APP" \
      "$APP_ID" \
      "$APP_HOST"
    ;;

  mysql)
    start_instance \
      "MYSQL" \
      "$MYSQL_ID" \
      "$MYSQL_HOST"
    ;;

  postgres)
    start_instance \
      "POSTGRES" \
      "$POSTGRES_ID" \
      "$POSTGRES_HOST"
    ;;

  all)
    start_instance \
      "APP" \
      "$APP_ID" \
      "$APP_HOST"

    start_instance \
      "MYSQL" \
      "$MYSQL_ID" \
      "$MYSQL_HOST"

    start_instance \
      "POSTGRES" \
      "$POSTGRES_ID" \
      "$POSTGRES_HOST"
    ;;

  *)
    echo "Unknown target: $TARGET"
    echo "Usage: ec2 run <app|mysql|postgres|all>"
    exit 1
    ;;

esac