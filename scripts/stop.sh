#!/bin/bash

set -e

ROOT_DIR="$HOME/.ec2-cli"

source "$ROOT_DIR/config.sh"

TARGET="$1"

stop_instance() {

  NAME="$1"
  INSTANCE_ID="$2"

  echo ""
  echo "Stopping $NAME..."
  echo "Instance: $INSTANCE_ID"

  aws ec2 stop-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    > /dev/null

  echo "Waiting for $NAME to stop..."

  aws ec2 wait instance-stopped \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID"

  echo "$NAME stopped."
}

case "$TARGET" in

  app)
    stop_instance \
      "APP" \
      "$APP_ID"
    ;;

  mysql)
    stop_instance \
      "MYSQL" \
      "$MYSQL_ID"
    ;;

  postgres)
    stop_instance \
      "POSTGRES" \
      "$POSTGRES_ID"
    ;;

  all)
    stop_instance \
      "APP" \
      "$APP_ID"

    stop_instance \
      "MYSQL" \
      "$MYSQL_ID"

    stop_instance \
      "POSTGRES" \
      "$POSTGRES_ID"
    ;;

  *)
    echo "Unknown target: $TARGET"
    echo "Usage: ec2 stop <app|mysql|postgres|all>"
    exit 1
    ;;

esac