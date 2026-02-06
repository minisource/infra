# =================================
# Service Endpoints
# =================================

output "service_endpoints" {
  description = "Endpoints for all services"
  value = {
    for name, config in var.services : name => {
      http = "http://${var.project_name}-${name}.${var.domain}:${config.port}"
      grpc = config.grpc_port != null ? "${var.project_name}-${name}.${var.domain}:${config.grpc_port}" : null
    }
  }
}

# =================================
# Database Connection Strings
# =================================

output "postgres_connection_strings" {
  description = "PostgreSQL connection strings for services"
  value = {
    auth      = "postgres://auth_user:password@postgres:5432/auth_db?sslmode=disable"
    log       = "postgres://log_user:password@postgres:5432/log_db?sslmode=disable"
    notifier  = "postgres://notifier_user:password@postgres:5432/notifier_db?sslmode=disable"
    scheduler = "postgres://scheduler_user:password@postgres:5432/scheduler_db?sslmode=disable"
    storage   = "postgres://storage_user:password@postgres:5432/storage_db?sslmode=disable"
  }
  sensitive = true
}

output "mongodb_connection_strings" {
  description = "MongoDB connection strings for services"
  value = {
    comment  = "mongodb://mongodb:27017/comment_db"
    ticket   = "mongodb://mongodb:27017/ticket_db"
    feedback = "mongodb://mongodb:27017/feedback_db"
  }
  sensitive = true
}

# =================================
# Redis
# =================================

output "redis_url" {
  description = "Redis connection URL"
  value       = "redis://redis:6379"
  sensitive   = true
}

# =================================
# Gateway
# =================================

output "gateway_url" {
  description = "API Gateway URL"
  value       = "http://${var.project_name}-gateway.${var.domain}:8080"
}

# =================================
# Monitoring
# =================================

output "monitoring_endpoints" {
  description = "Monitoring service endpoints"
  value = var.enable_monitoring ? {
    prometheus = "http://prometheus.${var.domain}:9090"
    grafana    = "http://grafana.${var.domain}:3000"
    jaeger     = var.enable_tracing ? "http://jaeger.${var.domain}:16686" : null
    loki       = var.enable_logging ? "http://loki.${var.domain}:3100" : null
  } : null
}
