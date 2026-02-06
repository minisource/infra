variable "name" {
  description = "Service name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "image" {
  description = "Docker image"
  type        = string
}

variable "port" {
  description = "Service HTTP port"
  type        = number
}

variable "grpc_port" {
  description = "Service gRPC port (optional)"
  type        = number
  default     = null
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret environment variables"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "health_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "ready_path" {
  description = "Readiness check path"
  type        = string
  default     = "/ready"
}

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "min_replicas" {
  description = "Minimum replicas for autoscaling"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas for autoscaling"
  type        = number
  default     = 5
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 70
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Deployment annotations"
  type        = map(string)
  default     = {}
}
