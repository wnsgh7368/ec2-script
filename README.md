# EC2 CLI

팀에서 공용으로 사용하는 AWS EC2 인스턴스를 간단한 명령어로 시작하고 종료하기 위한 CLI입니다.

EC2를 시작하면 변경된 Public IP를 자동으로 조회하여 로컬 `~/.ssh/config`의 `HostName`도 자동으로 변경합니다.

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

### 전체 종료

```bash
ec2 stop all
```

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
~/.ssh/config HostName 수정
      ↓
완료
```

따라서 EC2를 다시 시작하면서 Public IP가 변경되더라도 직접 SSH Config를 수정할 필요가 없습니다.

## SSH Config

각 팀원의 `~/.ssh/config`에는 `config.sh`에서 지정한 Host가 존재해야 합니다.

예시:

```text
Host star23-app
    HostName 1.2.3.4
    User ubuntu
    IdentityFile ~/.ssh/example.pem

Host star23-mysql
    HostName 5.6.7.8
    User ubuntu
    IdentityFile ~/.ssh/example.pem

Host star23-postgres
    HostName 5.6.7.8
    User ubuntu
    IdentityFile ~/.ssh/example.pem
```

`HostName`은 EC2를 시작할 때 자동으로 변경되므로 초기 값은 중요하지 않습니다.

단, `Host` 이름은 `config.sh`와 동일해야 합니다. 기본 값은 다음과 같습니다. .ssh/config를 위처럼 작성하셨다면 수정하실 필요 없습니다.

```bash
APP_SSH_HOST="star23-app"
MYSQL_SSH_HOST="star23-mysql"
```

## Configuration

공용 EC2 정보는 `config.sh`에서 관리합니다.

```bash
REGION="ap-northeast-2"

APP_ID="i-xxxxxxxxxxxxxxxxx"
MYSQL_ID="i-xxxxxxxxxxxxxxxxx"

APP_SSH_HOST="app"
MYSQL_SSH_HOST="mysql"
```

해당 EC2들은 팀원 모두 동일한 인스턴스를 사용하므로 Repository에서 공용으로 관리합니다.

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