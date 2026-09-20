#!/bin/bash

set -e

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

INSTALL_DIR="$HOME/.ec2-cli"
BIN_DIR="$HOME/.local/bin"

echo ""
echo "Installing EC2 CLI..."
echo ""

# =====================
# AWS CLI 확인
# =====================

if ! command -v aws &> /dev/null; then
  echo "AWS CLI is not installed."
  echo "Install AWS CLI first."
  exit 1
fi

# =====================
# 설치 디렉토리
# =====================

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

cp -R "$SOURCE_DIR/bin" "$INSTALL_DIR/"
cp -R "$SOURCE_DIR/scripts" "$INSTALL_DIR/"
cp "$SOURCE_DIR/config.sh" "$INSTALL_DIR/config.sh"

# =====================
# 개인 설정 (local.sh)
#  - SSH key(.pem) 경로 등 개인별 값
#  - git 으로 공유하지 않으며, 재설치 시 덮어쓰지 않음
# =====================

if [ ! -f "$INSTALL_DIR/local.sh" ]; then

  echo ""
  echo "SSH 접속에 사용할 key(.pem) 경로를 입력하세요."
  echo "예: ~/.ssh/star23.pem   (없으면 그냥 Enter, 나중에 local.sh 에서 설정 가능)"
  printf "SSH_KEY> "
  read -r KEY_PATH < /dev/tty || KEY_PATH=""

  # ~ 를 실제 홈 경로로 확장
  KEY_PATH="${KEY_PATH/#\~/$HOME}"

  cat > "$INSTALL_DIR/local.sh" <<EOF
#!/bin/bash

# 개인 설정 (git 미포함)
# SSH 접속 계정을 팀 기본값과 다르게 쓰려면 아래 주석을 풀어 override 하세요.
# SSH_USER="ubuntu"

# SSH key(.pem) 경로
SSH_KEY="$KEY_PATH"
EOF

  echo "local.sh 생성됨: $INSTALL_DIR/local.sh"
fi

# =====================
# 실행 권한 부여
# =====================

chmod +x "$INSTALL_DIR/bin/ec2"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# =====================
# ec2 명령어 등록
# =====================

ln -sf "$INSTALL_DIR/bin/ec2" "$BIN_DIR/ec2"

# =====================
# PATH 등록
# =====================

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then

  if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
  else
    SHELL_CONFIG="$HOME/.bashrc"
  fi

  echo "" >> "$SHELL_CONFIG"
  echo '# EC2 CLI' >> "$SHELL_CONFIG"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"

  echo "PATH added to $SHELL_CONFIG"
fi

echo ""
echo "별이삼샾 EC2 on/off CLI 설치가 완료됐습니다."
echo ""
echo "터미널을 재시작 하거나 다음 명령어를 실행하세요"
echo ""
echo "  source ~/.zshrc"
echo ""
echo "명령어:"
echo ""
echo "  ec2 run app"
echo "  ec2 run mysql"
echo "  ec2 run all"
echo ""
echo "  ec2 stop app"
echo "  ec2 stop mysql"
echo "  ec2 stop all"
echo ""