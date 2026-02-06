output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.minisource.metadata[0].name
}

output "gateway_url" {
  description = "API Gateway URL"
  value       = module.gateway.internal_url
}

output "service_urls" {
  description = "All service URLs"
  value = {
    auth      = module.auth.internal_url
    gateway   = module.gateway.internal_url
    log       = module.log.internal_url
    notifier  = module.notifier.internal_url
    scheduler = module.scheduler.internal_url
    storage   = module.storage.internal_url
    comment   = module.comment.internal_url
    ticket    = module.ticket.internal_url
    feedback  = module.feedback.internal_url
  }
}

output "database_urls" {
  description = "Database connection URLs"
  value = {
    postgres = module.database.postgres_internal_url
    mongodb  = module.database.mongodb_internal_url
  }
  sensitive = true
}

output "redis_url" {
  description = "Redis URL"
  value       = module.redis.redis_internal_url
}
