docker_host = "npipe:////./pipe/docker_engine"

# Пароли (замените на безопасные значения)
clinical_db_password  = "ClinicalDB2024!"
ai_db_password        = "AIDB2024!"
clickhouse_password   = "ClickHouse2024!"
kafka_password        = "Kafka2024!"
grafana_password      = "Grafana2024!"

# MinIO/S3
minio_access_key = "minioadmin"
minio_secret_key = "minioadmin2024"

# Порты
clinical_db_port      = 5432
ai_db_port            = 5433
clickhouse_http_port  = 8123
clickhouse_native_port = 9002
gateway_http_port     = 8080
gateway_https_port    = 8443
kafka_port            = 9092
minio_api_port        = 9000
minio_console_port    = 9001