#!/bin/bash

set -e

ROOT_DIR="$HOME/.ec2-cli"

source "$ROOT_DIR/config.sh"

TARGET="$1"

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

  # SSH Config HostName 변경
  awk \
    -v host="$SSH_HOST" \
    -v ip="$PUBLIC_IP" '
      $1 == "Host" {
        target = ($2 == host)
      }

      target && $1 == "HostName" {
        sub($2, ip)
      }

      { print }
    ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp"

  mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"

  echo "SSH config updated: $SSH_HOST -> $PUBLIC_IP"
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