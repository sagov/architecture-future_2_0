terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  required_version = ">= 1.0"
}

provider "docker" {
  host = var.docker_host
}

# =============================================================================
# СЕТЕВОЙ СЛОЙ
# =============================================================================

# Основная сеть (аналог VPC)
resource "docker_network" "vpc" {
  name     = "future2-vpc"
  driver   = "bridge"
  ipam_config {
    subnet  = "10.0.0.0/16"
    gateway = "10.0.0.1"
  }
}

# Публичная подсеть для Gateway
resource "docker_network" "public" {
  name     = "future2-public"
  driver   = "bridge"
  ipam_config {
    subnet  = "10.1.0.0/24"
    gateway = "10.1.0.1"
  }
}

# Приватная подсеть для БД и Kafka
resource "docker_network" "private" {
  name     = "future2-private"
  driver   = "bridge"
  internal = true  # Изолированная сеть без доступа в интернет
  ipam_config {
    subnet  = "10.10.0.0/24"
    gateway = "10.10.0.1"
  }
}

# =============================================================================
# ОБЩИЕ РЕСУРСЫ
# =============================================================================

resource "docker_volume" "clinical_data" {
  name = "clinical-postgres-data"
}

resource "docker_volume" "ai_data" {
  name = "ai-postgres-data"
}

resource "docker_volume" "clickhouse_data" {
  name = "clickhouse-data"
}

resource "docker_volume" "kafka_data" {
  name = "kafka-data"
}

resource "docker_volume" "minio_data" {
  name = "minio-s3-data"
}

resource "docker_volume" "backup_data" {
  name = "backup-data"
}

# =============================================================================
# БАЗЫ ДАННЫХ
# =============================================================================

# Клиническая БД (аналог Aurora PostgreSQL)
resource "docker_container" "clinical_db" {
  name  = "clinical-db"
  image = "postgres:15-alpine"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "POSTGRES_USER=clinical_admin",
    "POSTGRES_PASSWORD=${var.clinical_db_password}",
    "POSTGRES_DB=clinical"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    volume_name    = docker_volume.clinical_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U clinical_admin -d clinical"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# БД ИИ-сервисов
resource "docker_container" "ai_db" {
  name  = "ai-db"
  image = "postgres:15-alpine"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "POSTGRES_USER=ai_admin",
    "POSTGRES_PASSWORD=${var.ai_db_password}",
    "POSTGRES_DB=ai_service"
  ]

  ports {
    internal = 5432
    external = 5433
  }

  volumes {
    volume_name    = docker_volume.ai_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ai_admin -d ai_service"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Аналитическая БД (ClickHouse)
resource "docker_container" "clickhouse" {
  name  = "clickhouse-dwh"
  image = "clickhouse/clickhouse-server:23.8-alpine"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "CLICKHOUSE_USER=analytics_user",
    "CLICKHOUSE_PASSWORD=${var.clickhouse_password}",
    "CLICKHOUSE_DB=analytics"
  ]

  ports {
    internal = 8123
    external = 8123
  }

  ports {
    internal = 9000
    external = 9000
  }

  volumes {
    volume_name    = docker_volume.clickhouse_data.name
    container_path = "/var/lib/clickhouse"
  }

  healthcheck {
    test     = ["CMD-SHELL", "clickhouse-client --user analytics_user --password ${var.clickhouse_password} --query 'SELECT 1'"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# =============================================================================
# KAFKA
# =============================================================================

resource "docker_container" "zookeeper" {
  name  = "zookeeper"
  image = "confluentinc/cp-zookeeper:7.5.0"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "ZOOKEEPER_CLIENT_PORT=2181",
    "ZOOKEEPER_TICK_TIME=2000"
  ]

  ports {
    internal = 2181
    external = 2181
  }

  healthcheck {
    test     = ["CMD-SHELL", "echo stat | nc localhost 2181"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

resource "docker_container" "kafka" {
  name  = "kafka-broker"
  image = "confluentinc/cp-kafka:7.5.0"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "KAFKA_BROKER_ID=1",
    "KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181",
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka-broker:9092",
    "KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092",
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1",
    "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1",
    "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1"
  ]

  ports {
    internal = 9092
    external = 9092
  }

  volumes {
    volume_name    = docker_volume.kafka_data.name
    container_path = "/var/lib/kafka/data"
  }

  depends_on = [docker_container.zookeeper]

  healthcheck {
    test     = ["CMD-SHELL", "kafka-broker-api-versions --bootstrap-server localhost:9092 || exit 1"]
    interval = "30s"
    timeout  = "10s"
    retries  = 5
  }
}

# =============================================================================
# MINIO (аналог S3)
# =============================================================================

resource "docker_container" "minio" {
  name  = "minio-s3"
  image = "minio/minio:latest"
  restart = "unless-stopped"
  command = ["server", "/data", "--console-address", ":9001"]

  networks_advanced {
    name = docker_network.public.name
  }

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "MINIO_ROOT_USER=${var.minio_access_key}",
    "MINIO_ROOT_PASSWORD=${var.minio_secret_key}"
  ]

  ports {
    internal = 9000
    external = 9000
  }

  ports {
    internal = 9001
    external = 9001
  }

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }

  healthcheck {
    test     = ["CMD-SHELL", "curl -f http://localhost:9000/minio/health/live || exit 1"]
    interval = "15s"
    timeout  = "5s"
    retries  = 3
  }
}

# =============================================================================
# API GATEWAY — NGINX
# =============================================================================

resource "docker_container" "api_gateway" {
  name  = "api-gateway"
  image = "nginx:alpine"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.public.name
  }

  networks_advanced {
    name = docker_network.private.name
  }

  ports {
    internal = 80
    external = 8080
  }

  ports {
    internal = 443
    external = 8443
  }

  volumes {
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  depends_on = [docker_container.clinical_db, docker_container.ai_db, docker_container.clickhouse]
}

# Создаем конфигурацию Nginx
resource "local_file" "nginx_config" {
  filename = "${path.module}/nginx.conf"
  content  = <<-EOT
    events {
      worker_connections 1024;
    }

    http {
      upstream clinical {
        server clinical-db:5432;
      }

      upstream ai {
        server ai-db:5432;
      }

      upstream analytics {
        server clickhouse-dwh:8123;
      }

      server {
        listen 80;
        server_name localhost;

        location /clinical/ {
          proxy_pass http://clinical/;
        }

        location /ai/ {
          proxy_pass http://ai/;
        }

        location /analytics/ {
          proxy_pass http://analytics/;
        }

        location /health {
          return 200 '{"status":"ok"}';
          add_header Content-Type application/json;
        }
      }
    }
  EOT
}



# =============================================================================
# PARITY S3
# =============================================================================

resource "docker_container" "localstack" {
  name  = "localstack-s3"
  image = "localstack/localstack:2.1"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.private.name
  }

  env = [
    "SERVICES=s3",
    "AWS_ACCESS_KEY_ID=${var.minio_access_key}",
    "AWS_SECRET_ACCESS_KEY=${var.minio_secret_key}",
    "DEFAULT_REGION=us-east-1"
  ]

  ports {
    internal = 4566
    external = 4566
  }

  volumes {
    volume_name    = docker_volume.backup_data.name
    container_path = "/var/lib/localstack"
  }
}

# =============================================================================
# ГЕНЕРАЦИЯ СЛУЧАЙНЫХ ПАРОЛЕЙ
# =============================================================================

resource "random_password" "default_password" {
  length  = 16
  special = true
}