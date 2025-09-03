# FAQ

## Table of Contents
- [Q1. Why do I get a "permission denied" error when running `docker pull` on the `mysql-client-vm` instance?](#q1-why-do-i-get-a-permission-denied-error-when-running-docker-pull-on-the-mysql-client-vm-instance)
- [Q2. Why do I get a configuration file load error when running `docker run` on the `mysql-client-vm` instance?](#q2-why-do-i-get-a-configuration-file-load-error-when-running-docker-run-on-the-mysql-client-vm-instance)
- [Q3. Can you provide a Terraform command cheatsheet?](#q3-can-you-provide-a-terraform-command-cheatsheet)
- [Q4. `terraform apply` succeeded, but why weren't the GCS files copied to the VM instance?](#q4-terraform-apply-succeeded-but-why-werent-the-gcs-files-copied-to-the-vm-instance)

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
