output "clinical_db" {
  description = "Информация о клинической БД"
  value = {
    host        = "localhost"
    port        = var.clinical_db_port
    user        = "clinical_admin"
    password    = var.clinical_db_password
    database    = "clinical"
    container   = docker_container.clinical_db.name
    network     = docker_network.private.name
  }
  sensitive = true
}

output "ai_db" {
  description = "Информация о БД ИИ-сервисов"
  value = {
    host        = "localhost"
    port        = var.ai_db_port
    user        = "ai_admin"
    password    = var.ai_db_password
    database    = "ai_service"
    container   = docker_container.ai_db.name
  }
  sensitive = true
}

output "clickhouse" {
  description = "Информация о ClickHouse"
  value = {
    http_url    = "http://localhost:${var.clickhouse_http_port}"
    native_port = var.clickhouse_native_port
    user        = "analytics_user"
    password    = var.clickhouse_password
    container   = docker_container.clickhouse.name
  }
  sensitive = true
}

output "kafka" {
  description = "Информация о Kafka"
  value = {
    bootstrap_servers = "localhost:${var.kafka_port}"
    container         = docker_container.kafka.name
    zookeeper_container = docker_container.zookeeper.name
  }
}

output "minio" {
  description = "Информация о MinIO/S3"
  value = {
    api_url        = "http://localhost:${var.minio_api_port}"
    console_url    = "http://localhost:${var.minio_console_port}"
    access_key     = var.minio_access_key
    secret_key     = var.minio_secret_key
    container      = docker_container.minio.name
  }
  sensitive = true
}

output "api_gateway" {
  description = "Информация об API Gateway"
  value = {
    http_url    = "http://localhost:${var.gateway_http_port}"
    https_url   = "https://localhost:${var.gateway_https_port}"
    container   = docker_container.api_gateway.name
  }
}

output "monitoring" {
  description = "Информация о мониторинге"
  value = {
    prometheus_url = "http://localhost:9090"
    grafana_url    = "http://localhost:3000"
    grafana_user   = "admin"
    grafana_password = var.grafana_password
  }
  sensitive = true
}

output "networks" {
  description = "Созданные Docker-сети"
  value = {
    vpc     = docker_network.vpc.name
    public  = docker_network.public.name
    private = docker_network.private.name
  }
}

output "volumes" {
  description = "Созданные Docker-тома"
  value = {
    clinical_data     = docker_volume.clinical_data.name
    ai_data           = docker_volume.ai_data.name
    clickhouse_data   = docker_volume.clickhouse_data.name
    kafka_data        = docker_volume.kafka_data.name
    minio_data        = docker_volume.minio_data.name
    backup_data       = docker_volume.backup_data.name
  }
}

output "localstack" {
  description = "Информация о LocalStack (эмулятор S3)"
  value = {
    url       = "http://localhost:4566"
    container = docker_container.localstack.name
  }
}