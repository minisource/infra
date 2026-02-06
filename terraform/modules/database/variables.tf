variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
  default     = "7"
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "10Gi"
}

variable "mongodb_storage_size" {
  description = "MongoDB storage size"
  type        = string
  default     = "10Gi"
}

variable "postgres_databases" {
  description = "PostgreSQL databases to create"
  type = list(object({
    name     = string
    user     = string
    password = string
  }))
  default = [
    { name = "auth_db", user = "auth_user", password = "auth_password" },
    { name = "log_db", user = "log_user", password = "log_password" },
    { name = "notifier_db", user = "notifier_user", password = "notifier_password" },
    { name = "scheduler_db", user = "scheduler_user", password = "scheduler_password" },
    { name = "storage_db", user = "storage_user", password = "storage_password" },
  ]
  sensitive = true
}

variable "mongodb_databases" {
  description = "MongoDB databases to create"
  type        = list(string)
  default     = ["comment_db", "ticket_db", "feedback_db"]
}

variable "postgres_cpu" {
  description = "PostgreSQL CPU resources"
  type        = string
  default     = "500m"
}

variable "postgres_memory" {
  description = "PostgreSQL memory resources"
  type        = string
  default     = "512Mi"
}

variable "mongodb_cpu" {
  description = "MongoDB CPU resources"
  type        = string
  default     = "500m"
}

variable "mongodb_memory" {
  description = "MongoDB memory resources"
  type        = string
  default     = "512Mi"
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
