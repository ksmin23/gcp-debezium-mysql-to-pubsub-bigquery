# FAQ

## Table of Contents
- [Q1. Why do I get a "permission denied" error when running `docker pull` on the `mysql-client-vm` instance?](#q1-why-do-i-get-a-permission-denied-error-when-running-docker-pull-on-the-mysql-client-vm-instance)
- [Q2. Why do I get a configuration file load error when running `docker run` on the `mysql-client-vm` instance?](#q2-why-do-i-get-a-configuration-file-load-error-when-running-docker-run-on-the-mysql-client-vm-instance)
- [Q3. Can you provide a Terraform command cheatsheet?](#q3-can-you-provide-a-terraform-command-cheatsheet)
- [Q4. `terraform apply` succeeded, but why weren't the GCS files copied to the VM instance?](#q4-terraform-apply-succeeded-but-why-werent-the-gcs-files-copied-to-the-vm-instance)
- [Q5. When using `debezium-server` to send data from MySQL to Pub/Sub, why are two Pub/Sub topics required?](#q5-when-using-debezium-server-to-send-data-from-mysql-to-pubsub-why-are-two-pubsub-topics-required)
- [Q6. How do I format a Datetime/Timestamp column to a specific string format in Debezium Server?](#q6-how-do-i-format-a-datetimetimestamp-column-to-a-specific-string-format-in-debezium-server)
- [Q7. How do I configure Debezium Server to read data only from specific tables in a specific database?](#q7-how-do-i-configure-debezium-server-to-read-data-only-from-specific-tables-in-a-specific-database)
- [Q8. If I use `database.include.list` in Debezium Server, is the `debezium.source.database.dbname` setting still necessary?](#q8-if-i-use-databaseincludelist-in-debezium-server-is-the-debeziumsourcedatabasedbname-setting-still-necessary)

---

## Q1. Why do I get a "permission denied" error when running `docker pull` on the `mysql-client-vm` instance?

**Error Message:**
```
$ docker pull debezium/server:3.0.0.Final
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/images/create?fromImage=debezium%2Fserver&tag=3.0.0.Final": dial unix /var/run/docker.sock: connect: permission denied
```

**Answer:**
This error occurs because the currently logged-in user does not have the necessary permissions to access the Docker daemon socket file (`/var/run/docker.sock`).

### 1. Temporary Solution: Use `sudo`
The simplest way to resolve this is to run the `docker` command with administrative privileges by prepending `sudo`.
```bash
sudo docker pull debezium/server:3.0.0.Final
```
However, this requires you to type `sudo` every time you run a `docker` command.

### 2. Permanent Solution: Add User to the `docker` Group (Recommended)
To avoid the inconvenience of using `sudo` every time, you can add the current user to the `docker` group.

1.  **Add the current user to the `docker` group.**
    ```bash
    sudo usermod -aG docker $USER
    ```

2.  **To apply the changes, you can either log out and log back in, or open a new terminal.**
    Alternatively, you can activate the new group membership immediately in a new shell by running:
    ```bash
    newgrp docker
    ```
Now you can run `docker` commands without `sudo`.

---

## Q2. Why do I get a configuration file load error when running `docker run` on the `mysql-client-vm` instance?

**Error Message:**
```
$ sudo docker run -it --name debezium -p 8080:8080 -v $PWD/config:/debezium/config debezium/server:3.0.0.Final 

Failed to load mandatory config value 'debezium.sink.type'. Please check you have a correct Debezium server config in /debezium/conf/application.properties or required properties are defined via system or environment variables.
```

**Answer:**
This error occurs because the Debezium server cannot find the mandatory configuration property `debezium.sink.type` upon startup. This is likely because the `application.properties` file is missing from the `conf` directory mounted in the `docker run` command, or the property is not defined within the file.

**Solution:**

1.  **Navigate to the `debezium` directory.**
    ```bash
    cd debezium
    ```

2.  **Create a `conf` directory to hold the configuration file.**
    ```bash
    mkdir conf
    ```

3.  **Copy the example configuration file into the `conf` directory.**
    ```bash
    cp application.properties.example conf/application.properties
    ```

4.  **Open `conf/application.properties` and update the required values to match your GCP and database environment.**
    *   `debezium.sink.type=pubsub`
    *   `debezium.sink.pubsub.project.id=` (Your GCP Project ID)
    *   `debezium.source.database.hostname=` (The Private IP of your Cloud SQL MySQL instance)
    *   `debezium.source.database.user=` (Database user)
    *   `debezium.source.database.password=` (Database password)
    *   `debezium.source.database.dbname=` (Database name)
    *   `debezium.source.topic.prefix=` (Logical name for the Debezium server)

5.  **Run the Docker container again from within the `debezium` directory.**
    ```bash
    sudo docker run -it --name debezium -p 8080:8080 -v $PWD/conf:/debezium/conf debezium/server:3.0.0.Final
    ```

---

## Q3. Can you provide a Terraform command cheatsheet?

**Answer:**

### Terraform Command Cheatsheet

---

#### **1. Initializing a Project**

Initializes a working directory to begin a Terraform project. This downloads plugins, modules, and sets up the backend.

```bash
# Initialize the current directory
terraform init

# Reconfigure after changing backend settings
terraform init -reconfigure
```

---

#### **2. Planning & Validation**

Previews changes before applying them to the infrastructure and validates the syntax.

```bash
# Check code for syntax and validity
terraform validate

# Create an execution plan (preview what resources will be created/modified/deleted)
terraform plan

# Save the execution plan to a file
terraform plan -out="tfplan"
```

---

#### **3. Applying & Destroying**

Applies the planned changes to the actual infrastructure or destroys all managed infrastructure.

```bash
# Apply the planned changes
terraform apply

# Apply with a saved plan file (applies immediately without user confirmation)
terraform apply "tfplan"

# Destroy all resources managed by Terraform
terraform destroy
```

---

#### **4. Formatting Code**

Automatically formats Terraform code to the standard style.

```bash
# Format .tf files in the current directory
terraform fmt

# Format files in the current directory and all subdirectories
terraform fmt -recursive
```

---

#### **5. State Management**

Inspects and manages the state of resources managed by Terraform.

```bash
# List all resources in the current state
terraform state list

# Show detailed information about a specific resource
# Example: terraform state show 'module.network.google_compute_network.vpc'
terraform state show '<RESOURCE_ADDRESS>'

# Show the current state file in a human-readable format
terraform show

# Display the values of output variables defined in the configuration
terraform output
```

---

#### **6. Workspace Management**

Used to manage multiple environments (e.g., dev, staging, prod) with the same configuration files.

```bash
# List all workspaces
terraform workspace list

# Create a new workspace named 'dev'
terraform workspace new dev

# Switch to the 'staging' workspace
terraform workspace select staging
```

---

### **Typical Workflow**

1.  **`terraform init`**: Run once at the start of a project (or again if modules/providers change).
2.  **`terraform fmt -recursive`**: Run after modifying code to ensure consistent formatting.
3.  **`terraform validate`**: Check for syntax errors in your code.
4.  **`terraform plan`**: Review the changes that will be made.
5.  **`terraform apply`**: Apply the planned changes to your infrastructure.
6.  (If needed) **`terraform destroy`**: Clean up all created resources.

---

## Q4. `terraform apply` succeeded, but why weren't the GCS files copied to the VM instance?

**Answer:**

### Most Likely Cause: Timing Issue (Permission Granting)

The most probable reason is a timing mismatch between **when the VM was created and its startup script ran** and **when the service account was granted GCS permissions**.

The startup script (`metadata_startup_script`) executes as soon as the VM boots. At that moment, the VM's service account might not have had the necessary permissions to access GCS yet. Consequently, the `gcloud storage cp` command would fail due to a permission error.

Since the startup script only runs once on the first boot, granting permissions later will not automatically re-run the script, leaving the files uncopied.

---

### Solutions

#### Solution 1: Recreate Only the VM with Terraform (Most Recommended)

This is the cleanest approach. Target only the problematic VM resource for destruction and recreation. This ensures that when the new VM boots, its service account will already have the correct permissions, allowing the startup script to execute successfully.

1.  **Destroy only the `gce-client` module.**
    ```bash
    terraform destroy -target="module.gce-client"
    ```
    (Review the plan and type `yes` to approve.)

2.  **Run `terraform apply` again to recreate the VM.**
    ```bash
    terraform apply
    ```

#### Solution 2: Manually Re-run the Commands on the VM

Use this method if you don't want to recreate the VM or if you want to verify that the permissions are now correct.

1.  **SSH into the VM using IAP.**
    ```bash
    gcloud compute ssh mysql-client-vm --zone <your-zone>
    ```

2.  **Manually run the file copy command inside the VM.**
    First, get the GCS bucket name from your Terraform state:
    ```bash
    terraform state show 'module.gce-client.google_storage_bucket.debezium_files_bucket'
    ```
    Copy the `name` attribute from the output. Then, in the VM's SSH terminal, run the following commands:
    ```bash
    # Create the directory if it doesn't exist
    mkdir -p /root/debezium-server

    # Copy the files using the bucket name you retrieved
    gcloud storage cp --recursive gs://<YOUR_BUCKET_NAME>/debezium-server /root/
    ```

---

### Tip: Check Startup Script Logs

For future troubleshooting, you can check the VM's **serial console logs** to see any errors that occurred during the startup script's execution.

```bash
gcloud compute instances get-serial-port-output mysql-client-vm --zone <your-zone> --port 1
```

---

## Q5. When using `debezium-server` to send data from MySQL to Pub/Sub, why are two Pub/Sub topics required?

I have the following configuration in my `application.properties` file:

```properties
debezium.sink.type=pubsub
...
debezium.source.topic.prefix=debezium-topic
debezium.source.database.dbname=testdb
...
```

Based on the project code, please explain why two topics, `debezium-topic` and `debezium-topic.testdb.retail_trans`, are needed with this setup.

---

**Answer:**

The two topics are used for different purposes: one for 'data change events' and the other for 'connector state management (heartbeat)'.

In short, Debezium separates the actual data changes from the system's metadata. The role of each topic is as follows:

1.  **`debezium-topic.testdb.retail_trans`**: This topic is for the actual data change events (CDC).
2.  **`debezium-topic`**: This topic is for heartbeat messages that monitor the connector's status.

### 1. Data Change Event Topic (`debezium-topic.testdb.retail_trans`)

Debezium's core function is to capture database table changes (INSERT, UPDATE, DELETE) and send them to a message queue. To identify which table the change occurred in, Debezium uses the following default topic naming convention:

**`<topic.prefix>.<database_name>.<table_name>`**

The settings from your `application.properties` file are applied to this rule:

-   `debezium.source.topic.prefix=debezium-topic`
-   `debezium.source.database.dbname=testdb`
-   (Example table name: `retail_trans`)

According to this configuration, all data change events from the `retail_trans` table in the `testdb` database are sent to the `debezium-topic.testdb.retail_trans` topic.

### 2. Heartbeat Topic (`debezium-topic`)

When monitoring a table with infrequent changes, the Debezium connector might not send any messages for a long time. This makes it difficult to track whether the connector is still alive and to what point it has read the source database's transaction log (the offset).

To solve this, Debezium uses a **heartbeat** feature. It periodically sends a simple "I'm still alive" message to continuously update the offset and maintain the connection status.

The important point is that if a separate heartbeat topic is not configured, **Debezium uses the value of `debezium.source.topic.prefix` as the name for the heartbeat topic.**

Therefore, because of the `debezium.source.topic.prefix=debezium-topic` setting, all heartbeat messages are sent to the `debezium-topic` topic.

### Code-Level Analysis

This topic routing logic is determined at the Debezium Core engine level, not within the Debezium Server's Pub/Sub Sink module. If you look at the `PubSubChangeConsumer.java` class in the `debezium-server-pubsub` module, you can see that it simply passes messages to the destination topic specified by the Debezium engine.

```java
// Inside the handleBatch method of PubSubChangeConsumer.java
@Override
public void handleBatch(List<ChangeEvent<Object, Object>> records, ...) {
    for (ChangeEvent<Object, Object> record : records) {
        // Get the destination topic name already determined by the Debezium engine.
        final String topicName = streamNameMapper.map(record.destination());

        // Send the message to that topic.
        Publisher publisher = publishers.computeIfAbsent(topicName, ...);
        PubsubMessage message = buildPubSubMessage(record);
        deliveries.add(publisher.publish(message));
    }
    // ...
}
```

The `PubSubChangeConsumer` reads the `record.destination()` value and sends the message to the corresponding Pub/Sub topic; it does not contain logic to decide the topic name itself.

### Summary

-   **Who Decides the Topic Name?**: The topic name is determined by the upstream Debezium source connector (`MySqlConnector`) based on the `application.properties` configuration, not by the Pub/Sub Sink.
-   **Clear Separation of Roles for the Two Topics**:
    -   **`debezium-topic.testdb.retail_trans`**: Receives data change events for the `retail_trans` table.
    -   **`debezium-topic`**: Receives heartbeat messages to consistently record the connector's liveness and offset, even when there are no data changes.

By separating topics for data and metadata (heartbeats), Debezium can reliably track data changes and manage the system's state.

---

## Q6. How do I format a Datetime/Timestamp column to a specific string format in Debezium Server?

**Question:**
I want to convert Change Data Capture (CDC) data from a `Datetime` or `Timestamp` column to a string with the format `"yyyy-MM-dd'T'HH:mm:ss'Z'"`. How can I configure this in Debezium Server?

**Answer:**
This transformation can be handled using Debezium's **Single Message Transform (SMT)** feature. Specifically, you will use the `TimestampConverter` built into Kafka Connect.

You can add or modify the SMT-related configurations in your `application.properties` file as follows.

### 1. Define the SMT Chain
First, you need to define which SMTs to apply and in what order. It is common practice to first run `unwrap` to simplify Debezium's complex event envelope, and then run `format_ts` to convert the timestamp format.

```properties
# Defines the execution order of SMTs, separated by commas. ('unwrap' runs before 'format_ts')
debezium.source.transforms=unwrap,format_ts
```

### 2. Configure the `unwrap` SMT (ExtractNewRecordState)
This step extracts only the `after` state from the Debezium event, which contains the data after the change. This makes it easier for the `TimestampConverter` to access the field you want to transform.

```properties
# --- SMT A: Configure ExtractNewRecordState (unwrap) ---
debezium.source.transforms.unwrap.type=io.debezium.transforms.ExtractNewRecordState
# You can include additional metadata fields like op (c,u,d) and table name.
debezium.source.transforms.unwrap.add.fields=op,table,source.ts_ms
# Configures how delete events are handled.
debezium.source.transforms.unwrap.delete.handling.mode=rewrite
```

### 3. Configure the `format_ts` SMT (TimestampConverter) - The Core Step
This is where the actual timestamp formatting happens.

```properties
# --- SMT B: Configure TimestampConverter (format_ts) ---
debezium.source.transforms.format_ts.type=org.apache.kafka.connect.transforms.TimestampConverter$Value
# Set the target data type for the converted field to 'string'.
debezium.source.transforms.format_ts.target.type=string
# Specify the actual column (field) name to be transformed.
debezium.source.transforms.format_ts.field=<your-datetime-or-timestamp-column> # e.g., trans_datetime
# Define the final date/time format.
debezium.source.transforms.format_ts.format=yyyy-MM-dd'T'HH:mm:ss'Z'
```

### Complete Configuration Example
You can integrate these settings into your `application.properties` file as shown below.

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
# IMPORTANT: Replace this with the actual name of your timestamp column.
debezium.source.transforms.format_ts.field=<your-datetime-or-timestamp-column> # e.g., trans_datetime
debezium.source.transforms.format_ts.format=yyyy-MM-dd'T'HH:mm:ss'Z'
```

### References
- **Debezium Official Documentation (Single Message Transforms - SMTs):** [Debezium SMTs Documentation](https://debezium.io/documentation/reference/stable/transformations/index.html)
- **Apache Kafka Official Documentation (TimestampConverter):** [Apache Kafka Connect - TimestampConverter](https://kafka.apache.org/documentation/#org.apache.kafka.connect.transforms.TimestampConverter)

---

## Q7. How do I configure Debezium Server to read data only from specific tables in a specific database?

**Question:**
I want to restrict Debezium Server to perform Change Data Capture (CDC) only on specific tables within a specific database. For example, I only want to monitor the `orders` and `customers` tables in the `testdb` database.

**Answer:**
You can achieve this by using the `database.include.list` and `table.include.list` properties in your `application.properties` configuration file.

### Configuration Steps

1.  **Specify the Database to Monitor (`database.include.list`)**
    First, explicitly list the databases that Debezium should connect to and track for schema history. This ensures that other irrelevant databases are ignored.

2.  **Specify the Tables to Monitor (`table.include.list`)**
    Next, provide a comma-separated list of the tables from which you want to capture change events. The format for each entry should be `database.table_name`.

### Complete Configuration Example
Add the following settings to your `application.properties` file:

```properties
# --- Database and Table Filtering Configuration ---

# 1. Explicitly specify the database(s) to monitor. (Recommended)
debezium.source.database.include.list=testdb

# 2. Specify the list of tables to capture change data from.
# Format: <database_name>.<table_name>,<database_name>.<another_table_name>
debezium.source.table.include.list=testdb.orders,testdb.customers
```

After applying these settings and restarting Debezium Server, it will only detect and send change events from the `orders` and `customers` tables in the `testdb` database to the Pub/Sub topic. All changes in other databases or tables will be ignored.

---

## Q8. If I use `database.include.list` in Debezium Server, is the `debezium.source.database.dbname` setting still necessary?

**Question:**
I have specified the database to monitor using `debezium.source.database.include.list`. Do I still need to set the `debezium.source.database.dbname` property?

**Answer:**
In short, **it is not necessary, and it is recommended not to use it.**

Using `database.include.list` is a more explicit and flexible approach. Using both properties together can cause confusion or lead to unexpected behavior.

### Difference Between the Two Settings

| Property                           | Purpose                                                                    | Characteristics                                    |
| ---------------------------------- | -------------------------------------------------------------------------- | -------------------------------------------------- |
| `debezium.source.database.dbname`  | Specifies a **single** database for the Debezium connector to connect to.  | Can only specify one database.                     |
| `debezium.source.database.include.list` | Specifies a comma-separated **list** of databases to monitor.              | Allows for flexible management of multiple databases. |

### Recommended Configuration

The best practice is to explicitly manage the monitoring scope using `database.include.list`.

```properties
# 1. Comment out or remove the dbname setting.
# debezium.source.database.dbname=<your-database-name>

# 2. Explicitly specify the database(s) to monitor using include.list.
debezium.source.database.include.list=testdb

# 3. Now, select the desired tables from within the database(s) specified in the include.list.
debezium.source.table.include.list=testdb.orders,testdb.customers
```

This configuration creates a clear and consistent instruction: "Only look at the `testdb` database, and within it, only capture changes from the `orders` and `customers` tables."
