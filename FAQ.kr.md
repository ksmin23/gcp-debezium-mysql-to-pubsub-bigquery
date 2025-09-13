# FAQ

## 목차
- [Q1. `mysql-client-vm` 인스턴스에서 `docker pull` 실행 시 권한 거부 오류가 발생합니다.](#q1-mysql-client-vm-인스턴스에서-docker-pull-실행-시-권한-거부-오류가-발생합니다)
- [Q2. `mysql-client-vm` 인스턴스에서 `docker run` 실행 시 설정 파일 로드 오류가 발생합니다.](#q2-mysql-client-vm-인스턴스에서-docker-run-실행-시-설정-파일-로드-오류가-발생합니다)
- [Q3. Terraform 명령어 치트시트(cheatsheet)를 알려주세요.](#q3-terraform-명령어-치트시트cheatsheet를-알려주세요)
- [Q4. `terraform apply`는 성공했는데, 왜 VM 인스턴스에 GCS 파일이 복사되지 않았나요?](#q4-terraform-apply는-성공했는데-왜-vm-인스턴스에-gcs-파일이-복사되지-않았나요)
- [Q5. `debezium-server`를 사용하여 MySQL에서 Pub/Sub로 데이터를 전송할 때, 왜 두 개의 Pub/Sub 토픽이 필요한가요?](#q5-debezium-server를-사용하여-mysql에서-pubsub로-데이터를-전송할-때-왜-두-개의-pubsub-토픽이-필요한가요)
- [Q6. Debezium Server에서 Datetime/Timestamp 컬럼의 형식을 특정 포맷으로 변환하려면 어떻게 하나요?](#q6-debezium-server에서-datetimetimestamp-컬럼의-형식을-특정-포맷으로-변환하려면-어떻게-하나요)
- [Q7. Debezium Server에서 특정 데이터베이스의 특정 테이블만 읽도록 설정하려면 어떻게 하나요?](#q7-debezium-server에서-특정-데이터베이스의-특정-테이블만-읽도록-설정하려면-어떻게-하나요)
- [Q8. Debezium Server에서 `database.include.list`를 사용할 경우, `debezium.source.database.dbname` 설정이 필요한가요?](#q8-debezium-server에서-databaseincludelist를-사용할-경우-debeziumsourcedatabasedbname-설정이-필요한가요)

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

---

## Q5. `debezium-server`를 사용하여 MySQL에서 Pub/Sub로 데이터를 전송할 때, 왜 두 개의 Pub/Sub 토픽이 필요한가요?

`application.properties` 파일에 다음과 같이 설정했습니다.

```properties
debezium.sink.type=pubsub
...
debezium.source.topic.prefix=debezium-topic
debezium.source.database.dbname=testdb
...
```

이 설정으로 실행했을 때, `debezim-topic`과 `debezium-topic.testdb.retail_trans` 두 개의 토픽이 필요한 이유를 프로젝트 코드를 기반으로 설명해주세요.

---

**답변:**

두 토픽은 각각 '데이터 변경 이벤트'와 '커넥터 상태 관리(하트비트)'라는 다른 목적을 위해 사용됩니다.

결론적으로, Debezium은 실제 데이터 변경 내용과 시스템의 메타데이터를 분리하여 관리하며, 각 토픽의 역할은 다음과 같습니다.

1.  **`debezium-topic.testdb.retail_trans`**: 실제 데이터 변경 이벤트(CDC)를 위한 토픽입니다.
2.  **`debezium-topic`**: 커넥터의 동작 상태를 확인하는 하트비트(Heartbeat) 메시지를 위한 토픽입니다.

### 1. 데이터 변경 이벤트 토픽 (`debezium-topic.testdb.retail_trans`)

Debezium의 핵심 기능은 데이터베이스 테이블의 변경(INSERT, UPDATE, DELETE)을 캡처하여 메시지 큐로 보내는 것입니다. 어떤 테이블에서 변경이 발생했는지 식별하기 위해 Debezium은 기본적으로 다음과 같은 토픽 이름 규칙을 사용합니다.

**`<topic.prefix>.<database_name>.<table_name>`**

`application.properties` 파일의 설정값들이 이 규칙에 적용됩니다.

-   `debezium.source.topic.prefix=debezium-topic`
-   `debezium.source.database.dbname=testdb`
-   (예시 테이블 이름: `retail_trans`)

이 설정에 따라 `testdb` 데이터베이스의 `retail_trans` 테이블에서 발생하는 모든 데이터 변경 이벤트는 `debezium-topic.testdb.retail_trans` 토픽으로 전송됩니다.

### 2. 하트비트(Heartbeat) 토픽 (`debezium-topic`)

데이터 변경이 자주 발생하지 않는 테이블을 모니터링할 경우, Debezium 커넥터는 오랫동안 아무 메시지도 보내지 않을 수 있습니다. 이 경우 커넥터가 여전히 살아있는지, 그리고 소스 데이터베이스의 트랜잭션 로그를 어디까지 읽었는지(오프셋)를 추적하기 어려워집니다.

이 문제를 해결하기 위해 Debezium은 **하트비트(Heartbeat)** 기능을 사용합니다. 주기적으로 "나 아직 살아있어"라는 의미의 간단한 메시지를 보내 오프셋을 계속 갱신하고 연결 상태를 유지합니다.

중요한 점은, Debezium은 별도의 하트비트 토픽 설정을 하지 않으면 **`debezium.source.topic.prefix` 값을 하트비트 토픽의 이름으로 사용한다**는 것입니다.

따라서 `debezium.source.topic.prefix=debezium-topic` 설정 때문에 모든 하트비트 메시지는 `debezium-topic` 토픽으로 전송됩니다.

### 코드 레벨 분석

이러한 토픽 라우팅 로직은 Debezium Server의 Pub/Sub Sink 모듈이 아닌, Debezium Core 엔진 레벨에서 결정됩니다. `debezium-server-pubsub` 모듈의 `PubSubChangeConsumer.java` 클래스를 살펴보면, Debezium 엔진이 지정한 목적지(destination) 토픽으로 메시지를 그대로 전달하는 역할만 수행함을 알 수 있습니다.

```java
// PubSubChangeConsumer.java 내 handleBatch 메소드
@Override
public void handleBatch(List<ChangeEvent<Object, Object>> records, ...) {
    for (ChangeEvent<Object, Object> record : records) {
        // Debezium 엔진이 이미 결정한 목적지 토픽 이름을 가져옵니다.
        final String topicName = streamNameMapper.map(record.destination());

        // 해당 토픽으로 메시지를 전송합니다.
        Publisher publisher = publishers.computeIfAbsent(topicName, ...);
        PubsubMessage message = buildPubSubMessage(record);
        deliveries.add(publisher.publish(message));
    }
    // ...
}
```

`PubSubChangeConsumer`는 `record.destination()` 값을 읽어 해당 이름의 Pub/Sub 토픽으로 메시지를 전송할 뿐, 스스로 토픽 이름을 결정하는 로직을 포함하고 있지 않습니다.

### 최종 정리

-   **토픽 이름 결정 주체**: 토픽 이름은 Pub/Sub Sink가 아닌, 상위의 Debezium 소스 커넥터(`MySqlConnector`)가 `application.properties` 설정을 기반으로 결정합니다.
-   **두 토픽의 명확한 역할 구분**:
    -   **`debezium-topic.testdb.retail_trans`**: `retail_trans` 테이블의 데이터 변경 이벤트를 수신합니다.
    -   **`debezium-topic`**: 데이터 변경이 없을 때도 커넥터의 생존 여부와 오프셋을 꾸준히 기록하기 위한 하트비트(Heartbeat) 메시지를 수신합니다.

이처럼 데이터와 메타데이터(하트비트)를 위한 토픽을 분리함으로써, Debezium은 안정적으로 데이터 변경을 추적하고 시스템의 상태를 관리할 수 있습니다.

---

## Q6. Debezium Server에서 Datetime/Timestamp 컬럼의 형식을 특정 포맷으로 변환하려면 어떻게 하나요?

**질문:**
Debezium Server에서 `Datetime` 또는 `Timestamp` 타입의 컬럼에서 캡처된 CDC(Change Data Capture) 데이터를 `"yyyy-MM-dd'T'HH:mm:ss'Z'"` 형식의 문자열로 변환하고 싶습니다. 어떻게 설정해야 하나요?

**답변:**
이 변환 작업은 Debezium의 **SMT(Single Message Transform)** 기능을 사용하여 처리할 수 있습니다. 구체적으로는 Kafka Connect에 내장된 `TimestampConverter`를 활용합니다.

`application.properties` 설정 파일에 다음과 같이 SMT 관련 설정을 추가하거나 수정하면 됩니다.

### 1. SMT 체인 정의 (Define SMT Chain)
먼저, 어떤 SMT를 어떤 순서로 적용할지 정의합니다. 일반적으로 Debezium의 복잡한 이벤트 구조(`envelope`)를 단순화하는 `unwrap`을 먼저 실행한 후, 타임스탬프 형식을 변환하는 `format_ts`를 실행합니다.

```properties
# 쉼표로 SMT 실행 순서를 정의합니다. ('unwrap' 실행 후 'format_ts' 실행)
debezium.source.transforms=unwrap,format_ts
```

### 2. `unwrap` SMT 설정 (ExtractNewRecordState)
Debezium 이벤트에서 실제 데이터 변경이 일어난 `after` 부분만 추출하는 단계입니다. 이 과정을 거쳐야 `TimestampConverter`가 변환할 필드에 쉽게 접근할 수 있습니다.

```properties
# --- SMT A: ExtractNewRecordState (unwrap) 설정 ---
debezium.source.transforms.unwrap.type=io.debezium.transforms.ExtractNewRecordState
# op(c,u,d), table(테이블명) 같은 메타데이터 필드를 추가로 포함시킬 수 있습니다.
debezium.source.transforms.unwrap.add.fields=op,table,source.ts_ms
# 삭제(delete) 이벤트 처리 방식을 설정합니다.
debezium.source.transforms.unwrap.delete.handling.mode=rewrite
```

### 3. `format_ts` SMT 설정 (TimestampConverter) - 핵심
이 부분이 실제로 타임스탬프 형식을 변환하는 설정입니다.

```properties
# --- SMT B: TimestampConverter (format_ts) 설정 ---
debezium.source.transforms.format_ts.type=org.apache.kafka.connect.transforms.TimestampConverter$Value
# 변환 후의 데이터 타입을 'string'으로 지정합니다.
debezium.source.transforms.format_ts.target.type=string
# 변환을 적용할 실제 컬럼(필드) 이름을 지정합니다. 이 부분을 실제 컬럼명으로 바꿔주세요.
debezium.source.transforms.format_ts.field=<your-datetime-or-timestamp-column> # e.g., trans_datetime
# 최종적으로 변환될 날짜/시간 형식을 지정합니다.
debezium.source.transforms.format_ts.format=yyyy-MM-dd'T'HH:mm:ss'Z'
```

### 전체 설정 예시
`application.properties` 파일에 아래와 같이 SMT 관련 설정을 통합하여 적용할 수 있습니다.

```properties
# SMT (Single Message Transform)
# --- 1. Define SMT Chain Order ---
debezium.source.transforms=unwrap,format_ts

# --- 2. SMT A: Configure ExtractNewRecordState (unwrap) ---
debezium.source.transforms.unwrap.type=io.debezium.transforms.ExtractNewRecordState
debezium.source.transforms.unwrap.add.fields=op,table,source.ts_ms
debezium.source.transforms.unwrap.delete.handling.mode=rewrite

# --- 3. SMT B: Configure TimestampConverter (format_ts) ---
debezium.source.transforms.format_ts.type=org.apache.kafka.connect.transforms.TimestampConverter$Value
debezium.source.transforms.format_ts.target.type=string
# 중요: 이 값을 실제 타임스탬프 컬럼 이름으로 변경하세요.
debezium.source.transforms.format_ts.field=<your-datetime-or-timestamp-column> # e.g., trans_datetime
debezium.source.transforms.format_ts.format=yyyy-MM-dd'T'HH:mm:ss'Z'
```

### 참고 자료
- **Debezium 공식 문서 (Single Message Transforms - SMTs):** [Debezium SMTs Documentation](https://debezium.io/documentation/reference/stable/transformations/index.html)
- **Apache Kafka 공식 문서 (TimestampConverter):** [Apache Kafka Connect - TimestampConverter](https://kafka.apache.org/documentation/#org.apache.kafka.connect.transforms.TimestampConverter)

---

## Q7. Debezium Server에서 특정 데이터베이스의 특정 테이블만 읽도록 설정하려면 어떻게 하나요?

**질문:**
Debezium Server가 특정 데이터베이스의 특정 테이블에서만 변경 데이터 캡처(CDC)를 수행하도록 제한하고 싶습니다. 예를 들어, `testdb` 데이터베이스의 `orders`와 `customers` 테이블만 모니터링하고 싶습니다.

**답변:**
`application.properties` 설정 파일에서 `database.include.list`와 `table.include.list` 속성을 사용하여 이 요구사항을 구현할 수 있습니다.

### 설정 방법

1.  **모니터링할 데이터베이스 지정 (`database.include.list`)**
    먼저, Debezium이 스키마 변경 히스토리를 추적하고 연결할 데이터베이스 목록을 명시적으로 지정합니다. 이렇게 하면 관련 없는 다른 데이터베이스는 무시됩니다.

2.  **모니터링할 테이블 지정 (`table.include.list`)**
    다음으로, 실제 변경 이벤트를 캡처할 테이블 목록을 `데이터베이스명.테이블명` 형식으로 지정합니다. 여러 테이블은 쉼표(`,`)로 구분합니다.

### 전체 설정 예시
`application.properties` 파일에 아래와 같이 설정을 추가합니다.

```properties
# --- 데이터베이스 및 테이블 필터링 설정 ---

# 1. 모니터링할 데이터베이스를 명시적으로 지정합니다. (권장)
debezium.source.database.include.list=testdb

# 2. 변경 데이터를 캡처할 테이블 목록을 지정합니다.
# 형식: <데이터베이스명>.<테이블명>,<데이터베이스명>.<다른_테이블명>
debezium.source.table.include.list=testdb.orders,testdb.customers
```

이 설정을 적용하고 Debezium Server를 재시작하면, 서버는 오직 `testdb` 데이터베이스의 `orders`와 `customers` 테이블에서 발생하는 변경 사항만 감지하여 Pub/Sub 토픽으로 전송하게 됩니다. 다른 데이터베이스나 다른 테이블의 변경은 모두 무시됩니다.

---

## Q8. Debezium Server에서 `database.include.list`를 사용할 경우, `debezium.source.database.dbname` 설정이 필요한가요?

**질문:**
`debezium.source.database.include.list`를 사용하여 모니터링할 데이터베이스를 지정했습니다. 이 경우에도 `debezium.source.database.dbname` 속성을 설정해야 하나요?

**답변:**
결론부터 말하자면, **필요 없으며 오히려 사용하지 않는 것을 권장**합니다.

`database.include.list`를 사용하는 것이 더 명확하고 유연한 방법이며, 두 설정을 함께 사용할 경우 혼란을 야기하거나 예기치 않은 동작을 유발할 수 있습니다.

### 두 설정의 차이점

| 속성                               | 목적                                                               | 특징                                       |
| ---------------------------------- | ------------------------------------------------------------------ | ------------------------------------------ |
| `debezium.source.database.dbname`  | Debezium 커넥터가 연결할 **단일** 데이터베이스를 지정합니다.       | 하나의 데이터베이스만 지정할 수 있습니다.  |
| `debezium.source.database.include.list` | 모니터링할 데이터베이스의 **목록**을 쉼표(`,`)로 구분하여 지정합니다. | 여러 데이터베이스를 유연하게 관리할 수 있습니다. |

### 권장하는 설정 방법

`database.include.list`를 사용하여 모니터링 대상을 명시적으로 관리하는 것이 가장 좋습니다.

```properties
# 1. dbname 설정은 주석 처리하거나 삭제합니다.
# debezium.source.database.dbname=<your-database-name>

# 2. include.list를 사용하여 모니터링할 데이터베이스를 명시적으로 지정합니다.
debezium.source.database.include.list=testdb

# 3. 이제 include.list에 지정된 데이터베이스 내에서 원하는 테이블을 선택합니다.
debezium.source.table.include.list=testdb.orders,testdb.customers
```

이렇게 설정하면 "오직 `testdb` 데이터베이스만 살펴보고, 그중에서도 `orders`와 `customers` 테이블의 변경 사항만 캡처하라"는 명확하고 일관된 구성이 됩니다.
