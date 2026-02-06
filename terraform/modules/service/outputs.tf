output "service_name" {
  description = "Service name"
  value       = kubernetes_service.service.metadata[0].name
}

output "service_port" {
  description = "Service HTTP port"
  value       = var.port
}

output "service_grpc_port" {
  description = "Service gRPC port"
  value       = var.grpc_port
}

output "cluster_ip" {
  description = "Service cluster IP"
  value       = kubernetes_service.service.spec[0].cluster_ip
}

output "deployment_name" {
  description = "Deployment name"
  value       = kubernetes_deployment.service.metadata[0].name
}

output "internal_url" {
  description = "Internal service URL"
  value       = "http://${kubernetes_service.service.metadata[0].name}.${var.namespace}.svc.cluster.local:${var.port}"
}

output "internal_grpc_url" {
  description = "Internal gRPC URL"
  value       = var.grpc_port != null ? "${kubernetes_service.service.metadata[0].name}.${var.namespace}.svc.cluster.local:${var.grpc_port}" : null
}
