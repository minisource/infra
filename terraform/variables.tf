# =================================
# Common Variables
# =================================

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "minisource"
}

variable "domain" {
  description = "Base domain for the services"
  type        = string
  default     = "minisource.local"
}

# =================================
# Network Variables
# =================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# =================================
# Database Variables
# =================================

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

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7"
}

# =================================
# Service Configuration
# =================================

variable "services" {
  description = "Configuration for each microservice"
  type = map(object({
    port       = number
    replicas   = number
    cpu        = string
    memory     = string
    database   = string # postgres, mongodb, or none
    grpc_port  = optional(number)
  }))
  default = {
    auth = {
      port     = 9001
      replicas = 2
      cpu      = "200m"
      memory   = "256Mi"
      database = "postgres"
    }
    gateway = {
      port     = 8080
      replicas = 2
      cpu      = "200m"
      memory   = "256Mi"
      database = "none"
    }
    log = {
      port     = 5002
      replicas = 1
      cpu      = "200m"
      memory   = "256Mi"
      database = "postgres"
    }
    notifier = {
      port      = 9002
      grpc_port = 9003
      replicas  = 2
      cpu       = "200m"
      memory    = "256Mi"
      database  = "postgres"
    }
    scheduler = {
      port     = 5003
      replicas = 1
      cpu      = "200m"
      memory   = "256Mi"
      database = "postgres"
    }
    storage = {
      port     = 5004
      replicas = 2
      cpu      = "200m"
      memory   = "512Mi"
      database = "postgres"
    }
    comment = {
      port     = 5010
      replicas = 2
      cpu      = "200m"
      memory   = "256Mi"
      database = "mongodb"
    }
    ticket = {
      port     = 5011
      replicas = 2
      cpu      = "200m"
      memory   = "256Mi"
      database = "mongodb"
    }
    feedback = {
      port     = 5012
      replicas = 2
      cpu      = "200m"
      memory   = "256Mi"
      database = "mongodb"
    }
  }
}

# =================================
# Container Registry
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
# Resource Limits
# =================================

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = false
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

# =================================
# Monitoring
# =================================

variable "enable_monitoring" {
  description = "Enable Prometheus/Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_tracing" {
  description = "Enable OpenTelemetry tracing"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable centralized logging with Loki"
  type        = bool
  default     = true
}
