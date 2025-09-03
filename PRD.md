# PRD: GCP CDC Pipeline with Debezium, Pub/Sub, and BigQuery

## 1. Overview

### 1.1. Objective
To provision a scalable, real-time data analytics pipeline on Google Cloud Platform using Infrastructure as Code (IaC). This project automates the deployment of a Change Data Capture (CDC) system that streams changes from a Cloud SQL for MySQL source to a Cloud Pub/Sub topic, which are then ingested directly into a BigQuery table. The pipeline utilizes a Debezium Server running in a Docker container on a Google Compute Engine (GCE) VM, with the entire infrastructure managed by Terraform.

### 1.2. Background
This project implements a modern, serverless-first CDC architecture for streaming database changes to a data warehouse. Instead of relying on intermediate caching layers or complex ETL services, this solution combines the open-source Debezium project with Google Cloud's managed services. A Debezium Server, running on a GCE instance, reads the change log from Cloud SQL and streams the events to a Pub/Sub topic. A BigQuery subscription then writes these events directly into a BigQuery table, making it ideal for real-time analytics and data warehousing with minimal operational overhead.

## 2. Functional Requirements

### 2.1. Core Data Pipeline Components
The Terraform configuration must provision and configure the following GCP services to work in concert:

| Component | Service | Requirement |
| :--- | :--- | :--- |
| **Data Source** | Cloud SQL for MySQL | A Cloud SQL instance, accessible only via a private network (no public IP), to act as the transactional database source. Must have an `rdsadmin` user for management and a dedicated `datastream` user for CDC. |
| **CDC Engine Host** | GCE VM | A Google Compute Engine (GCE) instance to host the Debezium Server in a Docker container. This instance must be located within the private network. |
| **CDC Engine** | Debezium Server (Docker) | A Debezium Server running as a Docker container on the GCE VM. It captures change logs from Cloud SQL and publishes them as messages to a Cloud Pub/Sub topic. |
| **Messaging & Ingestion** | Cloud Pub/Sub | A Pub/Sub topic to receive CDC events from Debezium. It decouples the source from the sink and provides a scalable, durable buffer. |
| **Data Sink / Warehouse** | BigQuery & BigQuery Subscription | A BigQuery dataset and table to store the raw CDC events. A **BigQuery subscription** connects the Pub/Sub topic directly to the BigQuery table for serverless ingestion. |
| **Networking** | VPC, Subnets, PSC, Cloud NAT | Secure private networking using a custom VPC. A **Private Service Connect (PSC) endpoint** provides a stable internal IP for the Cloud SQL instance. A Cloud NAT gateway is required for the GCE instance to download software packages and the Debezium Docker image. |
| **Provisioning Helper** | Google Cloud Storage | A temporary GCS bucket is created and deleted during the `terraform apply` and `destroy` processes. It is used to copy Debezium configuration files from the local machine to the GCE VM. |

### 2.2. Key Architectural Features
- **Debezium-based CDC:** Utilizes the open-source Debezium engine, providing flexibility and reducing vendor lock-in.
- **Serverless Sink with Pub/Sub and BigQuery:** CDC events are streamed to Pub/Sub and ingested into BigQuery via a direct subscription, creating a highly scalable, low-maintenance, and cost-effective data sink.
- **Decoupled Architecture:** Pub/Sub acts as a message bus, decoupling the Debezium producer from the BigQuery consumer. This allows for greater resilience and flexibility.
- **Secure by Default:** All components operate within a private VPC, with no public IPs for the database or the main GCE VM, enhancing security. Cloud SQL is accessed via a secure PSC endpoint.

## 3. Non-Functional Requirements

### 3.1. Infrastructure as Code (IaC)
- The entire infrastructure must be defined in HashiCorp Configuration Language (HCL) for Terraform.
- The code must be modular and reusable, with separate modules for networking, data source, GCE host, and the data sink.
- A GCS bucket must be used as the backend for storing the Terraform state file (`terraform.tfstate`), ensuring state is managed remotely and securely.

### 3.2. Security
- **Principle of Least Privilege:** All service accounts must be granted only the IAM permissions necessary for their function.
    - The `datastream` database user should have the minimal required permissions for replication (`REPLICATION SLAVE`, `SELECT`, `REPLICATION CLIENT`).
    - The GCE instance's service account requires `pubsub.publisher` rights to send messages.
    - The Pub/Sub service agent requires `bigquery.dataEditor` rights to write to the sink table.
- **Private Networking:** All communication between GCP services must occur over the private network. The Cloud SQL instance must have its public IP disabled.
- **Firewall Rules:** VPC firewall rules must be configured to:
    - Allow all internal traffic within the VPC's private subnet (`10.1.0.0/16`).
    - Allow SSH traffic (`tcp:22`) only from Google's Identity-Aware Proxy (IAP) service range (`35.235.240.0/20`), ensuring no direct external SSH access.
- **Secrets Management:** Database credentials for the `rdsadmin` and `datastream` users should be generated at runtime by Terraform and passed securely.

### 3.3. Configurability
- The Terraform project must be highly configurable through variables (`.tfvars`).
- Key parameters such as `project_id`, `region`, instance names, and database settings must be externalized from the core logic.
- Performance and cost-related parameters (e.g., Cloud SQL `db_tier`, GCE `machine_type`) must be configurable.
- **Core Input Variables:** The root module must accept the following core variables to define the environment:
    - `project_id`: The target GCP project ID.
    - `region`: The GCP region for resource deployment.
    - `zone`: The GCP zone for the GCE VM.
    - `db_name`: The name of the database to be monitored for changes.
    - `debezium_server_name`: A logical name for the Debezium server, used as a prefix for Pub/Sub topics.

### 3.4. Naming Conventions
- All resources should follow a consistent naming convention to ensure clarity and manageability.
- **Format**: Resource names are typically composed of a prefix and a resource-specific name.

### 3.5. Monitoring and Alerting
> **Note:** This is a functional requirement that is not yet implemented in the current Terraform code.

- Basic monitoring and alerting must be configured to ensure pipeline reliability.
- **GCE VM Health:** Alerts should be created if the GCE instance's CPU utilization exceeds a defined threshold or if the instance becomes unhealthy.
- **Pub/Sub & BigQuery:** A Cloud Monitoring alert should be configured for the BigQuery subscription to detect a growing backlog of unacknowledged messages or a high number of messages being sent to the Dead Letter Queue (DLQ).

## 4. Terraform Structure & Implementation Details

### 4.1. Component Configuration Details

#### 4.1.1. Cloud SQL for MySQL
- **MySQL Version:** `MYSQL_8_0`
- **Tier:** Must be a configurable variable (e.g., `db-n1-standard-2`).
- **CDC Configuration:** The instance must be configured to support CDC through `backup_configuration.binary_log_enabled` and appropriate `database_flags` (e.g., `binlog_row_image = "full"`).
- **PSC Enabled**: The instance must be configured to allow Private Service Connect, and a PSC endpoint is created to provide a stable internal IP.
- **Database Users**: `root`, `rdsadmin`, and `datastream` users must be created with unique, randomly generated passwords.

#### 4.1.2. GCE VM (`mysql-client-vm`)
- **Startup Script:** A comprehensive startup script automates the installation of:
    - **MySQL Client**: For database interaction.
    - **Docker Engine**: To run the Debezium server.
- **Debezium Configuration:** Configuration files from the local `debezium-server/config` directory are uploaded to a temporary GCS bucket and then copied to `/opt/debezium-server` on the VM during provisioning.
- **Debezium Image:** The `debezium/server:3.0.0.Final` Docker image is pulled on startup.
- **Debezium Persistence:** To ensure Debezium can resume from its last position after a restart, its state must be persisted on the GCE VM.
    - `debezium.source.offset.storage.file.filename`: CDC offsets will be stored in a local file at `data/offset.dat` inside the container.
    - `debezium.source.schema.history.internal.file.filename`: Schema history will be stored in a local file at `data/schema_history.dat` inside the container.
    - These container paths must be mounted as volumes to a persistent directory on the GCE host (e.g., `$HOME/data`).

#### 4.1.3. Cloud Pub/Sub
- **Topic Creation:** A Pub/Sub topic is created to receive all CDC events for a specific table, following the naming convention `{topic-prefix}.{db-name}.{table-name}`.
- **Dead Letter Queue (DLQ):** A DLQ topic and subscription are created to capture messages that fail to be written to BigQuery after a set number of retries, allowing for manual inspection and reprocessing.

#### 4.1.4. BigQuery Sink
- **Dataset and Table:** A BigQuery dataset (`debezium_sink`) and a table (`cdc_events`) are created to store the incoming data.
- **Table Schema:** The table schema is predefined to accept the standard format from a BigQuery subscription, including `data` (JSON), `attributes` (JSON), `message_id`, `publish_time`, and `subscription_name`.
- **Partitioning:** The table is partitioned by `publish_time` (Day) to optimize queries and manage costs.
- **BigQuery Subscription:** A `google_pubsub_subscription` is configured with a `bigquery_config` block to write messages directly from the Pub/Sub topic to the target table.

### 4.2. Required Resources (High-Level)
- `google_sql_database_instance`
- `google_sql_user`
- `google_compute_instance`
- `google_storage_bucket`
- `google_project_iam_member`
- `google_compute_network`
- `google_compute_subnetwork`
- `google_compute_firewall`
- `google_compute_forwarding_rule` (for PSC)
- `google_compute_router`
- `google_compute_router_nat`
- `google_pubsub_topic`
- `google_pubsub_subscription`
- `google_bigquery_dataset`
- `google_bigquery_table`
- `google_bigquery_dataset_iam_member`
- `google_monitoring_alert_policy` (*Note: Not yet implemented*)

## 5. Deliverables

1.  A complete set of Terraform files (`.tf`) to provision the entire pipeline.
2.  A `variables.tf` file defining all configurable parameters.
3.  An example `terraform.tfvars.example` file showing users how to configure the project with sensible defaults.
4.  A `README.md` file with detailed instructions on how to initialize, plan, and apply the Terraform configuration.
5.  **Required Outputs**: The root Terraform module must output the following values after a successful `apply` for operational purposes:
    -   Cloud SQL Instance Name & Private IP
    -   Cloud SQL PSC Endpoint IP
    -   GCE VM Instance Name & Private IP
    -   Admin User Name (`rdsadmin`) & Password (sensitive)
    -   Debezium User Name (`datastream`) & Password (sensitive)
    -   Pub/Sub Topic Name
    -   BigQuery Dataset ID & Table ID
    -   BigQuery Subscription Name
    -   Dead Letter Queue (DLQ) Topic & Subscription Names
6.  **Acceptance Criteria**: A successful deployment is defined by the following conditions being met:
    1.  Users can connect to the Cloud SQL instance via Cloud SQL Studio using the `rdsadmin` credentials and successfully execute SQL commands.
    2.  The Debezium Server Docker container is running on the GCE VM, confirmed via `docker ps`.
    3.  An `INSERT` statement executed in Cloud SQL results in a corresponding record appearing in the BigQuery `cdc_events` table within minutes.
    4.  The `data` field of the BigQuery record contains the complete JSON payload from Debezium, including the before/after state of the changed row.

## 6. Out of Scope

-   Custom Debezium connector development.
-   CI/CD automation for deploying the Terraform infrastructure.
-   Complex data transformations (the pipeline is designed for raw ingestion).
-   Automated schema evolution handling in BigQuery.
-   Creation of applications that consume data from the BigQuery table.