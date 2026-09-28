#!/bin/bash

# 공통 함수 모음
#  - run.sh / conn.sh 에서 source 하여 사용

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
