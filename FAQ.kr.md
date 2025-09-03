# FAQ

## 목차
- [Q1. `mysql-client-vm` 인스턴스에서 `docker pull` 실행 시 권한 거부 오류가 발생합니다.](#q1-mysql-client-vm-인스턴스에서-docker-pull-실행-시-권한-거부-오류가-발생합니다)
- [Q2. `mysql-client-vm` 인스턴스에서 `docker run` 실행 시 설정 파일 로드 오류가 발생합니다.](#q2-mysql-client-vm-인스턴스에서-docker-run-실행-시-설정-파일-로드-오류가-발생합니다)
- [Q3. Terraform 명령어 치트시트(cheatsheet)를 알려주세요.](#q3-terraform-명령어-치트시트cheatsheet를-알려주세요)
- [Q4. `terraform apply`는 성공했는데, 왜 VM 인스턴스에 GCS 파일이 복사되지 않았나요?](#q4-terraform-apply는-성공했는데-왜-vm-인스턴스에-gcs-파일이-복사되지-않았나요)

---

## Q1. `mysql-client-vm` 인스턴스에서 `docker pull` 실행 시 권한 거부 오류가 발생합니다.

**에러 메시지:**
```
$ docker pull debezium/server:3.0.0.Final
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/images/create?fromImage=debezium%2Fserver&tag=3.0.0.Final": dial unix /var/run/docker.sock: connect: permission denie
```

**답변:**
해당 오류는 현재 로그인된 사용자가 Docker 데몬 소켓 파일(`/var/run/docker.sock`)에 접근할 권한이 없어서 발생합니다.

### 1. 임시 해결 방법: `sudo` 사용하기
가장 간단한 방법은 `docker` 명령어 앞에 `sudo`를 붙여서 관리자 권한으로 실행하는 것입니다.
```bash
sudo docker pull debezium/server:3.0.0.Final
```
이 방법은 매번 `docker` 명령을 실행할 때마다 `sudo`를 입력해야 합니다.

### 2. 영구적인 해결 방법: 사용자를 `docker` 그룹에 추가하기 (권장)
매번 `sudo`를 사용하는 불편함을 없애려면 현재 사용자를 `docker` 그룹에 추가하면 됩니다.

1.  **현재 사용자를 `docker` 그룹에 추가합니다.**
    ```bash
    sudo usermod -aG docker $USER
    ```

2.  **변경 사항을 적용하기 위해 로그아웃 후 다시 로그인하거나, 새 터미널을 열어주세요.**
    또는 아래 명령어를 실행하여 새 셸에서 그룹 멤버십을 바로 활성화할 수도 있습니다.
    ```bash
    newgrp docker
    ```
이제 `sudo` 없이 `docker` 명령어를 바로 실행할 수 있습니다.

---

## Q2. `mysql-client-vm` 인스턴스에서 `docker run` 실행 시 설정 파일 로드 오류가 발생합니다.

**에러 메시지:**
```
$ sudo docker run -it --name debezium -p 8080:8080 -v $PWD/config:/debezium/config debezium/server:3.0.0.Final 

Failed to load mandatory config value 'debezium.sink.type'. Please check you have a correct Debezium server config in /debezium/conf/application.properties or required properties are defined via system or environment variables.
```

**답변:**
해당 오류는 Debezium 서버가 실행될 때 필요한 필수 설정 값(`debezium.sink.type`)을 찾지 못해서 발생합니다. `docker run` 명령어에서 마운트한 `conf` 폴더 안에 `application.properties` 파일이 없거나, 파일 내에 필수 설정이 정의되지 않았기 때문입니다.

**해결 방법:**

1.  **`debezium` 디렉토리로 이동합니다.**
    ```bash
    cd debezium
    ```

2.  **설정 파일을 담을 `conf` 디렉토리를 생성합니다.**
    ```bash
    mkdir conf
    ```

3.  **예제 설정 파일을 `conf` 디렉토리로 복사합니다.**
    ```bash
    cp application.properties.example conf/application.properties
    ```

4.  **`conf/application.properties` 파일을 열어 본인의 GCP 및 데이터베이스 환경에 맞게 필수 값들을 수정합니다.**
    *   `debezium.sink.type=pubsub`
    *   `debezium.sink.pubsub.project.id=` (GCP 프로젝트 ID)
    *   `debezium.source.database.hostname=` (Cloud SQL MySQL의 Private IP 주소)
    *   `debezium.source.database.user=` (DB 사용자)
    *   `debezium.source.database.password=` (DB 비밀번호)
    *   `debezium.source.database.dbname=` (DB 이름)
    *   `debezium.source.topic.prefix=` (Debezium 서버 논리적 이름)

5.  **`debezium` 디렉토리 안에서 Docker 컨테이너를 다시 실행합니다.**
    ```bash
    sudo docker run -it --name debezium -p 8080:8080 -v $PWD/conf:/debezium/conf debezium/server:3.0.0.Final
    ```

---

## Q3. Terraform 명령어 치트시트(cheatsheet)를 알려주세요.

**답변:**

### Terraform 주요 명령어 치트시트 (Cheatsheet)

---

#### **1. 프로젝트 초기화 (Initializing)**

Terraform 작업을 시작하기 위해 작업 디렉토리를 초기화합니다. 플러그인과 모듈을 다운로드하고 백엔드를 설정합니다.

```bash
# 현재 디렉토리 초기화
terraform init

# 백엔드 설정 변경 후 재설정
terraform init -reconfigure
```

---

#### **2. 계획 및 검증 (Planning & Validation)**

코드를 인프라에 적용하기 전에 변경 사항을 미리 확인하고 문법을 검증합니다.

```bash
# 코드 문법 및 유효성 검사
terraform validate

# 실행 계획 생성 (어떤 리소스가 생성/수정/삭제될지 미리 보기)
terraform plan

# 실행 계획을 파일로 저장
terraform plan -out="tfplan"
```

---

#### **3. 적용 및 삭제 (Applying & Destroying)**

계획된 변경 사항을 실제 인프라에 적용하거나, 관리 중인 모든 인프라를 삭제합니다.

```bash
# 계획된 변경 사항을 적용
terraform apply

# 저장된 계획 파일로 적용 (사용자 확인 없이 바로 적용됨)
terraform apply "tfplan"

# Terraform으로 관리되는 모든 리소스 삭제
terraform destroy
```

---

#### **4. 코드 서식 맞춤 (Formatting)**

Terraform 코드 스타일을 표준에 맞게 자동으로 정리합니다.

```bash
# 현재 디렉토리의 .tf 파일 서식 정리
terraform fmt

# 하위 디렉토리까지 모두 포함하여 서식 정리
terraform fmt -recursive
```

---

#### **5. 상태 관리 (State Management)**

Terraform이 관리하는 리소스의 상태(State)를 확인하고 관리합니다.

```bash
# 현재 상태(State)에 있는 모든 리소스 목록 출력
terraform state list

# 특정 리소스의 상세 정보 출력
# 예시: terraform state show 'module.network.google_compute_network.vpc'
terraform state show '<RESOURCE_ADDRESS>'

# 현재 상태 파일의 내용을 사람이 읽기 쉬운 형태로 출력
terraform show

# Terraform 구성에 정의된 출력(output) 변수들의 값을 확인
terraform output
```

---

#### **6. 워크스페이스 관리 (Workspace Management)**

동일한 구성 파일로 여러 환경(dev, staging, prod 등)을 분리하여 관리할 때 사용합니다.

```bash
# 모든 워크스페이스 목록 보기
terraform workspace list

# 'dev'라는 이름의 새 워크스페이스 생성
terraform workspace new dev

# 'staging' 워크스페이스로 전환
terraform workspace select staging
```

---

### **일반적인 작업 흐름 (Typical Workflow)**

1.  **`terraform init`**: 프로젝트 시작 시 한 번 실행합니다. (모듈이나 프로바이더 변경 시 다시 실행)
2.  **`terraform fmt -recursive`**: 코드를 수정한 후 항상 실행하여 서식을 맞춥니다.
3.  **`terraform validate`**: 코드 문법에 오류가 없는지 확인합니다.
4.  **`terraform plan`**: 어떤 변경이 일어날지 눈으로 확인합니다.
5.  **`terraform apply`**: 계획된 변경 사항을 실제 인프라에 적용합니다.
6.  (필요시) **`terraform destroy`**: 생성했던 모든 리소스를 정리합니다.

---

## Q4. `terraform apply`는 성공했는데, 왜 VM 인스턴스에 GCS 파일이 복사되지 않았나요?

**답변:**

### 가장 유력한 원인: 타이밍 문제 (권한 부여 시점)

가장 가능성이 높은 원인은 **VM이 생성되고 시작 스크립트가 실행된 시점**과 **서비스 계정에 GCS 권한을 부여한 시점**이 다르기 때문입니다.

VM이 부팅되면서 시작 스크립트(`metadata_startup_script`)가 즉시 실행되었지만, 그 당시 VM의 서비스 계정에는 아직 GCS에 접근할 권한이 없었습니다. 따라서 `gcloud storage cp` 명령어는 권한 오류로 실패하게 됩니다.

시작 스크립트는 VM이 최초로 부팅될 때 단 한 번만 실행되므로, 나중에 서비스 계정에 권한을 부여하더라도 스크립트가 자동으로 재실행되지 않아 파일이 복사되지 않은 것입니다.

---

### 해결 방법

#### 해결 방법 1: Terraform으로 VM만 재생성하기 (가장 권장)

문제가 있는 VM 리소스만 타겟으로 지정하여 파괴하고 다시 생성하는 가장 깔끔한 방법입니다. 이렇게 하면 VM이 부팅될 때 이미 서비스 계정에 올바른 권한이 부여된 상태이므로, 시작 스크립트가 성공적으로 실행됩니다.

1.  **`gce-client` 모듈만 타겟으로 지정하여 파괴합니다.**
    ```bash
    terraform destroy -target="module.gce-client"
    ```
    (실행 계획을 확인하고 `yes`를 입력하여 승인합니다.)

2.  **다시 `terraform apply`를 실행하여 VM을 생성합니다.**
    ```bash
    terraform apply
    ```

#### 해결 방법 2: VM에 직접 접속하여 수동으로 명령어 재실행

VM을 재성성하고 싶지 않거나, 권한이 올바르게 적용되었는지 먼저 확인하고 싶을 때 사용하는 방법입니다.

1.  **IAP를 통해 VM에 SSH로 접속합니다.**
    ```bash
    gcloud compute ssh mysql-client-vm --zone <your-zone>
    ```

2.  **VM 안에서 직접 파일 복사 명령어를 실행합니다.**
    먼저, 아래 명령어로 GCS 버킷 이름을 확인합니다.
    ```bash
    terraform state show 'module.gce-client.google_storage_bucket.debezium_files_bucket'
    ```
    출력된 내용 중 `name` 속성의 값을 복사한 후, SSH로 접속한 VM 터미널에서 아래 명령어를 실행합니다.
    ```bash
    # /root/debezium-server 디렉토리가 없다면 생성합니다.
    mkdir -p /root/debezium-server

    # 위에서 확인한 GCS 버킷 이름을 사용하여 파일을 복사합니다.
    gcloud storage cp --recursive gs://<YOUR_BUCKET_NAME>/debezium-server /root/
    ```

---

### 팁: 시작 스크립트 로그 확인

향후 비슷한 문제가 발생하면, VM의 **직렬 콘솔 로그**를 확인하여 시작 스크립트 실행 중 발생한 오류를 직접 확인할 수 있습니다.

```bash
gcloud compute instances get-serial-port-output mysql-client-vm --zone <your-zone> --port 1
```
