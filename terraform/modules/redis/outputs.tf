output "redis_host" {
  description = "Redis host"
  value       = kubernetes_service.redis.metadata[0].name
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}

output "redis_password" {
  description = "Redis password"
  value       = random_password.redis.result
  sensitive   = true
}

output "redis_url" {
  description = "Redis connection URL"
  value       = "redis://:${random_password.redis.result}@${kubernetes_service.redis.metadata[0].name}.${var.namespace}.svc.cluster.local:6379"
  sensitive   = true
}

output "redis_internal_url" {
  description = "Redis internal URL (without password)"
  value       = "${kubernetes_service.redis.metadata[0].name}.${var.namespace}.svc.cluster.local:6379"
}
