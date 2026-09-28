# EC2 CLI

팀에서 공용으로 사용하는 AWS EC2 인스턴스를 간단한 명령어로 시작하고 종료하기 위한 CLI입니다.

EC2를 시작하면 변경된 Public IP를 자동으로 조회하여 로컬 `~/.ssh/config`의 `HostName`을 자동으로 갱신합니다. 해당 Host 블록이 아직 없으면 `User`/`IdentityFile`까지 포함해 새로 만들어 줍니다.

## Architecture

```text
ec2-cli/
├── bin/
│   └── ec2
├── scripts/
│   ├── run.sh
│   └── stop.sh
├── config.sh
├── install.sh
├── uninstall.sh
└── README.md
```

## Requirements

다음 프로그램이 필요합니다.

- AWS CLI
- AWS 계정 접근 권한
- SSH Config

AWS CLI가 정상적으로 인증되어 있어야 합니다.

확인은 다음 명령어로 할 수 있습니다.

```bash
aws sts get-caller-identity
```

정상적으로 AWS Account 정보가 출력되면 사용할 수 있습니다.

## Installation

Repository를 Clone합니다.

```bash
git clone <repository-url>
cd ec2-cli
```

설치 스크립트에 실행 권한을 부여합니다.

```bash
chmod +x install.sh
```

설치합니다.

```bash
./install.sh
```

설치 도중 SSH 접속에 사용할 key(`.pem`) 경로를 물어봅니다.

```text
SSH_KEY> ~/.ssh/star23.pem
```

입력한 경로는 개인 설정 파일 `~/.ec2-cli/local.sh`에 저장되며, Git으로 공유되지 않습니다.
바로 모른다면 그냥 Enter로 넘어간 뒤 나중에 `~/.ec2-cli/local.sh`에서 `SSH_KEY`를 수정하면 됩니다.

설치 후 터미널을 다시 실행하거나 다음 명령어를 실행합니다.

```bash
source ~/.zshrc
```

설치가 완료되면 어디에서든 `ec2` 명령어를 사용할 수 있습니다.

## Usage

### APP 시작

```bash
ec2 run app
```

### MySQL 시작

```bash
ec2 run mysql
```

### PostgreSQL 시작

```bash
ec2 run postgres
```

### 전체 시작

```bash
ec2 run all
```

### APP 종료

```bash
ec2 stop app
```

### MySQL 종료

```bash
ec2 stop mysql
```

### PostgreSQL 종료

```bash
ec2 stop postgres
```

### 전체 종료

```bash
ec2 stop all
```

## SSH Config 갱신 (conn)

`ec2 run`은 **인스턴스를 켠 사람의** `~/.ssh/config`만 갱신합니다.
따라서 이미 다른 팀원이 켜 둔 인스턴스에 접속하려는 사람은,
인스턴스를 다시 켤 필요 없이 `ec2 conn`으로 현재 Public IP만 가져와 자신의 SSH Config를 맞출 수 있습니다.

```bash
ec2 conn app
ec2 conn mysql
ec2 conn postgres
ec2 conn all
```

`ec2 conn`은 인스턴스를 **시작하지 않고**, 실행 중(`running`)인 경우에만 Public IP를 조회해 `~/.ssh/config`를 갱신합니다.
인스턴스가 꺼져 있으면 먼저 `ec2 run`으로 켜야 한다고 안내합니다.

## EC2 Start Process

`ec2 run`을 실행하면 다음 과정이 자동으로 수행됩니다.

```text
ec2 run app
      ↓
EC2 Start
      ↓
Running 상태 대기
      ↓
Public IP 조회
      ↓
~/.ssh/config 갱신 (블록 없으면 생성)
      ↓
완료
```

따라서 EC2를 다시 시작하면서 Public IP가 변경되더라도 직접 SSH Config를 수정할 필요가 없습니다.

## SSH Config

`ec2 run`을 실행하면 `~/.ssh/config`가 자동으로 갱신됩니다.

- 해당 `Host` 블록이 있으면 → `HostName`만 새 Public IP로 교체 (`User`/`IdentityFile` 등 기존 값은 그대로 유지)
- 해당 `Host` 블록이 없으면 → 아래처럼 블록을 새로 생성

```text
Host star23-app
    HostName <자동 입력>
    User ubuntu
    IdentityFile <local.sh 의 SSH_KEY>
```

`User`는 `config.sh`의 `SSH_USER`(기본값 `ubuntu`), `IdentityFile`은 각자 `~/.ec2-cli/local.sh`에 저장한 `SSH_KEY` 경로가 사용됩니다.

따라서 팀원은 `~/.ssh/config`를 미리 손볼 필요가 없습니다. 설치 시 `SSH_KEY`만 지정해 두면 첫 `ec2 run`에서 블록이 알아서 만들어집니다.

`Host` 이름은 `config.sh`의 값과 동일하게 관리되며, 기본값은 다음과 같습니다.

```bash
APP_HOST="star23-app"
MYSQL_HOST="star23-mysql"
POSTGRES_HOST="star23-postgres"
```

> 참고: 팀원 모두 하나의 공용 key(`.pem`)를 사용하는 것을 전제로 합니다. 서비스별로 key가 다르다면 `local.sh`에서 서비스별로 나눠 관리해야 합니다.

## Configuration

설정은 두 파일로 나뉩니다.

### config.sh (팀 공용, Git 관리)

공용 EC2 정보를 관리합니다.

```bash
REGION="ap-northeast-2"

APP_ID="i-xxxxxxxxxxxxxxxxx"
MYSQL_ID="i-xxxxxxxxxxxxxxxxx"
POSTGRES_ID="i-xxxxxxxxxxxxxxxxx"

APP_HOST="star23-app"
MYSQL_HOST="star23-mysql"
POSTGRES_HOST="star23-postgres"

SSH_USER="ubuntu"
```

해당 EC2들은 팀원 모두 동일한 인스턴스를 사용하므로 Repository에서 공용으로 관리합니다.

### local.sh (개인별, Git 미포함)

`~/.ec2-cli/local.sh`에 개인마다 다른 값을 저장합니다. 설치 시 자동 생성되며 Git으로 공유되지 않습니다.

```bash
# SSH key(.pem) 경로
SSH_KEY="$HOME/.ssh/star23.pem"

# 접속 계정을 팀 기본값과 다르게 쓰려면 override
# SSH_USER="ubuntu"
```

AWS Access Key, Secret Access Key 등의 인증 정보는 Repository에 저장하지 않습니다.

각 팀원이 자신의 AWS CLI 환경에서 별도로 인증해야 합니다.

## Update

CLI 코드가 변경되면 Repository를 다시 Pull한 후 설치하면 됩니다.

```bash
git pull
./install.sh
```

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Security

다음 정보는 Repository에 Commit하지 않습니다.

- AWS Access Key
- AWS Secret Access Key
- AWS Session Token
- SSH Private Key (`.pem`)
- 기타 Credential

EC2 Instance ID와 Region은 인증 정보가 아니므로 팀 공용 설정으로 관리합니다.