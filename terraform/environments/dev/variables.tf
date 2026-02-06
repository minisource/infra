# =================================
# Registry Configuration
# =================================

variable "registry_url" {
  description = "Container registry URL"
  type        = string
  default     = "ghcr.io/minisource"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

# =================================
# Database Passwords
# =================================

variable "postgres_auth_password" {
  description = "PostgreSQL password for auth database"
  type        = string
  sensitive   = true
}

variable "postgres_log_password" {
  description = "PostgreSQL password for log database"
  type        = string
  sensitive   = true
}

variable "postgres_notifier_password" {
  description = "PostgreSQL password for notifier database"
  type        = string
  sensitive   = true
}

variable "postgres_scheduler_password" {
  description = "PostgreSQL password for scheduler database"
  type        = string
  sensitive   = true
}

variable "postgres_storage_password" {
  description = "PostgreSQL password for storage database"
  type        = string
  sensitive   = true
}

# =================================
# Security
# =================================

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}
