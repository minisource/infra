output "postgres_host" {
  description = "PostgreSQL host"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = 5432
}

output "postgres_root_password" {
  description = "PostgreSQL root password"
  value       = random_password.postgres_root.result
  sensitive   = true
}

output "postgres_internal_url" {
  description = "PostgreSQL internal URL"
  value       = "${kubernetes_service.postgres.metadata[0].name}.${var.namespace}.svc.cluster.local:5432"
}

output "mongodb_host" {
  description = "MongoDB host"
  value       = kubernetes_service.mongodb.metadata[0].name
}

output "mongodb_port" {
  description = "MongoDB port"
  value       = 27017
}

output "mongodb_root_password" {
  description = "MongoDB root password"
  value       = random_password.mongodb_root.result
  sensitive   = true
}

output "mongodb_internal_url" {
  description = "MongoDB internal URL"
  value       = "mongodb://${kubernetes_service.mongodb.metadata[0].name}.${var.namespace}.svc.cluster.local:27017"
}
