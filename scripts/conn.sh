#!/bin/bash

set -e

ROOT_DIR="$HOME/.ec2-cli"

source "$ROOT_DIR/config.sh"

# 개인 설정 (SSH_KEY 등) — git 미포함, 있으면 사용
if [ -f "$ROOT_DIR/local.sh" ]; then
  source "$ROOT_DIR/local.sh"
fi

# 공통 함수 (update_ssh_config 등)
source "$ROOT_DIR/scripts/lib.sh"

TARGET="$1"

# 인스턴스를 켜지 않고, 현재 상태/Public IP 만 조회해서
# 내 ~/.ssh/config 를 갱신한다.
#  - 다른 사람이 이미 켜둔 인스턴스에 나도 ssh config 를 맞출 때 사용
sync_instance() {

  NAME="$1"
  INSTANCE_ID="$2"
  SSH_HOST="$3"

  echo ""
  echo "Syncing $NAME..."
  echo "Instance: $INSTANCE_ID"

  STATE=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].State.Name" \
    --output text)

  if [ "$STATE" != "running" ]; then
    echo "$NAME 은(는) 실행 중이 아닙니다. (state: $STATE)"
    echo "먼저 실행하세요: ec2 run ${TARGET}"
    return 1
  fi

  PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "Failed to get Public IP."
    return 1
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
    sync_instance \
      "APP" \
      "$APP_ID" \
      "$APP_HOST"
    ;;

  mysql)
    sync_instance \
      "MYSQL" \
      "$MYSQL_ID" \
      "$MYSQL_HOST"
    ;;

  postgres)
    sync_instance \
      "POSTGRES" \
      "$POSTGRES_ID" \
      "$POSTGRES_HOST"
    ;;

  all)
    sync_instance \
      "APP" \
      "$APP_ID" \
      "$APP_HOST" || true

    sync_instance \
      "MYSQL" \
      "$MYSQL_ID" \
      "$MYSQL_HOST" || true

    sync_instance \
      "POSTGRES" \
      "$POSTGRES_ID" \
      "$POSTGRES_HOST" || true
    ;;

  *)
    echo "Unknown target: $TARGET"
    echo "Usage: ec2 conn <app|mysql|postgres|all>"
    exit 1
    ;;

esac
