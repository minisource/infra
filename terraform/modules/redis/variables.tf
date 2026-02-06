variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7"
}

variable "storage_size" {
  description = "Redis storage size"
  type        = string
  default     = "5Gi"
}

variable "cpu" {
  description = "CPU resources"
  type        = string
  default     = "200m"
}

variable "memory" {
  description = "Memory resources"
  type        = string
  default     = "256Mi"
}

variable "enable_persistence" {
  description = "Enable Redis persistence"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
