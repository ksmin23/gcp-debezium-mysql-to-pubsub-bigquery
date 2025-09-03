resource "google_compute_instance" "mysql_client_vm" {
  project      = var.project_id
  zone         = var.zone
  name         = var.instance_name
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
    # No access_config block, so no public IP will be assigned.
  }

  # Startup script to install necessary client tools and services.
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update package lists
    apt-get update

    # --- Install MySQL Client ---
    # Used to connect to the Cloud SQL instance.
    apt-get install -y mariadb-client

    # --- Install and Configure Redis ---
    # Used as a sink for Debezium and for storing schema history.
    apt-get install -y redis
    # Modify redis.conf to allow external connections for Debezium.
    sed -i '.bak' \
        -e 's/^protected-mode yes$/protected-mode no/' \
        -e 's/^# maxmemory-policy noeviction$/maxmemory-policy volatile-ttl/' \
        -e 's/^bind 127.0.0.1 ::1$/#bind 127.0.0.1 ::1/' \
        /etc/redis/redis.conf
    # Apply the new configuration.
    systemctl restart redis

    # --- Install Docker Engine ---
    # Required to run the Debezium server container.
    apt-get install -y docker.io

    # --- Copy Debezium Server config files from GCS ---
    # The gcloud CLI is installed by default on Debian images.
    mkdir -p /opt/debezium-server
    gcloud storage cp --recursive gs://${google_storage_bucket.debezium_files_bucket.name}/debezium-server /opt/

    # --- Pull Debezium Server Docker Image ---
    # Downloads the Debezium server image for later use.
    docker pull --quiet debezium/server:3.0.0.Final

    # --- (Optional) Install Java 21 ---
    # Useful for any Java-based development or tooling on the VM.
    wget --output-document=/tmp/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz \
      https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz
    mkdir -p /usr/lib/jvm
    tar -xzf /tmp/OpenJDK21U-jdk_x64_linux_hotspot_21.0.4_7.tar.gz -C /usr/lib/jvm
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-21.0.4+7/bin/java 2100
    update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-21.0.4+7/bin/javac 2100
    echo "JAVA_HOME=/usr/lib/jvm/jdk-21.0.4+7" >> /etc/environment
  EOT

  service_account {
    # Allows access to APIs, including logging and storage.
    scopes = ["cloud-platform"]
  }
  tags = ["mysql-client", "ssh-iap"]

  # Add a dependency to ensure the VM is created only after the GCS file upload is complete.
  depends_on = [
    google_storage_bucket_object.debezium_server_files
  ]
}