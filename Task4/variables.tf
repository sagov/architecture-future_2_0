variable "docker_host" {
  description = "Docker daemon host npipe:////./pipe/docker_engine или tcp://localhost:2375"
  type        = string
  default     = "npipe:////./pipe/docker_engine"
}

# Пароли для баз данных
variable "clinical_db_password" {
  description = "Пароль для клинической БД"
  type        = string
  sensitive   = true
  default     = "ClinicalDB2024!"
}

variable "ai_db_password" {
  description = "Пароль для БД ИИ-сервисов"
  type        = string
  sensitive   = true
  default     = "AIDB2024!"
}

variable "clickhouse_password" {
  description = "Пароль для ClickHouse"
  type        = string
  sensitive   = true
  default     = "ClickHouse2024!"
}

# S3/MinIO
variable "minio_access_key" {
  description = "Access Key для MinIO/S3"
  type        = string
  sensitive   = true
  default     = "minioadmin"
}

variable "minio_secret_key" {
  description = "Secret Key для MinIO/S3"
  type        = string
  sensitive   = true
  default     = "minioadmin2024"
}

# Kafka
variable "kafka_password" {
  description = "Пароль для Kafka"
  type        = string
  sensitive   = true
  default     = "Kafka2024!"
}

# Мониторинг
variable "grafana_password" {
  description = "Пароль администратора Grafana"
  type        = string
  sensitive   = true
  default     = "Grafana2024!"
}

# Порты
variable "clinical_db_port" {
  description = "Внешний порт клинической БД"
  type        = number
  default     = 5432
}

variable "ai_db_port" {
  description = "Внешний порт БД ИИ-сервисов"
  type        = number
  default     = 5433
}

variable "clickhouse_http_port" {
  description = "HTTP порт ClickHouse"
  type        = number
  default     = 8123
}

variable "clickhouse_native_port" {
  description = "Native порт ClickHouse"
  type        = number
  default     = 9002
}

variable "gateway_http_port" {
  description = "HTTP порт API Gateway"
  type        = number
  default     = 8080
}

variable "gateway_https_port" {
  description = "HTTPS порт API Gateway"
  type        = number
  default     = 8443
}

variable "kafka_port" {
  description = "Порт Kafka"
  type        = number
  default     = 9092
}

variable "minio_api_port" {
  description = "API порт MinIO"
  type        = number
  default     = 9000
}

variable "minio_console_port" {
  description = "Console порт MinIO"
  type        = number
  default     = 9001
}