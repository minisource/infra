terraform {
  required_version = ">= 1.0.0"

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop" # or minikube, kind, etc.
}

locals {
  environment = "dev"
  namespace   = "minisource-dev"
  domain      = "minisource.local"
}

# =================================
# Namespace
# =================================

resource "kubernetes_namespace" "minisource" {
  metadata {
    name = local.namespace
    labels = {
      "app.kubernetes.io/part-of"    = "minisource"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = local.environment
    }
  }
}

# =================================
# Databases
# =================================

module "database" {
  source = "../../modules/database"

  environment           = local.environment
  namespace             = kubernetes_namespace.minisource.metadata[0].name
  postgres_version      = "16"
  mongodb_version       = "7"
  postgres_storage_size = "5Gi"
  mongodb_storage_size  = "5Gi"

  postgres_databases = [
    { name = "auth_db", user = "auth_user", password = var.postgres_auth_password },
    { name = "log_db", user = "log_user", password = var.postgres_log_password },
    { name = "notifier_db", user = "notifier_user", password = var.postgres_notifier_password },
    { name = "scheduler_db", user = "scheduler_user", password = var.postgres_scheduler_password },
    { name = "storage_db", user = "storage_user", password = var.postgres_storage_password },
  ]
}

# =================================
# Redis
# =================================

module "redis" {
  source = "../../modules/redis"

  environment        = local.environment
  namespace          = kubernetes_namespace.minisource.metadata[0].name
  redis_version      = "7"
  storage_size       = "1Gi"
  enable_persistence = true
}

# =================================
# Services
# =================================

module "auth" {
  source = "../../modules/service"

  name        = "auth"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/auth:${var.image_tag}"
  port        = 9001
  replicas    = 1

  env_vars = {
    SERVER_PORT     = "9001"
    ENVIRONMENT     = local.environment
    POSTGRES_HOST   = module.database.postgres_host
    POSTGRES_PORT   = "5432"
    POSTGRES_DB     = "auth_db"
    POSTGRES_USER   = "auth_user"
    REDIS_HOST      = module.redis.redis_host
    REDIS_PORT      = "6379"
  }

  secrets = {
    POSTGRES_PASSWORD = var.postgres_auth_password
    JWT_SECRET        = var.jwt_secret
  }
}

module "gateway" {
  source = "../../modules/service"

  name        = "gateway"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/gateway:${var.image_tag}"
  port        = 8080
  replicas    = 1

  env_vars = {
    SERVER_PORT      = "8080"
    ENVIRONMENT      = local.environment
    AUTH_SERVICE_URL = "http://${module.auth.service_name}:${module.auth.service_port}"
    REDIS_HOST       = module.redis.redis_host
    REDIS_PORT       = "6379"
  }
}

module "log" {
  source = "../../modules/service"

  name        = "log"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/log:${var.image_tag}"
  port        = 5002
  replicas    = 1

  env_vars = {
    SERVER_PORT   = "5002"
    ENVIRONMENT   = local.environment
    POSTGRES_HOST = module.database.postgres_host
    POSTGRES_PORT = "5432"
    POSTGRES_DB   = "log_db"
    POSTGRES_USER = "log_user"
  }

  secrets = {
    POSTGRES_PASSWORD = var.postgres_log_password
  }
}

module "notifier" {
  source = "../../modules/service"

  name        = "notifier"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/notifier:${var.image_tag}"
  port        = 9002
  grpc_port   = 9003
  replicas    = 1

  env_vars = {
    SERVER_PORT      = "9002"
    GRPC_PORT        = "9003"
    ENVIRONMENT      = local.environment
    POSTGRES_HOST    = module.database.postgres_host
    POSTGRES_PORT    = "5432"
    POSTGRES_DB      = "notifier_db"
    POSTGRES_USER    = "notifier_user"
    REDIS_HOST       = module.redis.redis_host
    REDIS_PORT       = "6379"
    AUTH_SERVICE_URL = "http://${module.auth.service_name}:${module.auth.service_port}"
  }

  secrets = {
    POSTGRES_PASSWORD = var.postgres_notifier_password
  }
}

module "scheduler" {
  source = "../../modules/service"

  name        = "scheduler"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/scheduler:${var.image_tag}"
  port        = 5003
  replicas    = 1

  env_vars = {
    SERVER_PORT   = "5003"
    ENVIRONMENT   = local.environment
    POSTGRES_HOST = module.database.postgres_host
    POSTGRES_PORT = "5432"
    POSTGRES_DB   = "scheduler_db"
    POSTGRES_USER = "scheduler_user"
    REDIS_HOST    = module.redis.redis_host
    REDIS_PORT    = "6379"
  }

  secrets = {
    POSTGRES_PASSWORD = var.postgres_scheduler_password
  }
}

module "storage" {
  source = "../../modules/service"

  name        = "storage"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/storage:${var.image_tag}"
  port        = 5004
  replicas    = 1

  env_vars = {
    SERVER_PORT      = "5004"
    ENVIRONMENT      = local.environment
    POSTGRES_HOST    = module.database.postgres_host
    POSTGRES_PORT    = "5432"
    POSTGRES_DB      = "storage_db"
    POSTGRES_USER    = "storage_user"
    AUTH_SERVICE_URL = "http://${module.auth.service_name}:${module.auth.service_port}"
  }

  secrets = {
    POSTGRES_PASSWORD = var.postgres_storage_password
  }
}

module "comment" {
  source = "../../modules/service"

  name        = "comment"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/comment:${var.image_tag}"
  port        = 5010
  replicas    = 1

  env_vars = {
    SERVER_PORT      = "5010"
    ENVIRONMENT      = local.environment
    MONGODB_URI      = "mongodb://${module.database.mongodb_host}:27017"
    MONGODB_DATABASE = "comment_db"
    AUTH_SERVICE_URL = "http://${module.auth.service_name}:${module.auth.service_port}"
    REDIS_HOST       = module.redis.redis_host
    REDIS_PORT       = "6379"
  }
}

module "ticket" {
  source = "../../modules/service"

  name        = "ticket"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/ticket:${var.image_tag}"
  port        = 5011
  replicas    = 1

  env_vars = {
    SERVER_PORT        = "5011"
    ENVIRONMENT        = local.environment
    MONGODB_URI        = "mongodb://${module.database.mongodb_host}:27017"
    MONGODB_DATABASE   = "ticket_db"
    AUTH_SERVICE_URL   = "http://${module.auth.service_name}:${module.auth.service_port}"
    COMMENT_SERVICE_URL = "http://${module.comment.service_name}:${module.comment.service_port}"
    REDIS_HOST         = module.redis.redis_host
    REDIS_PORT         = "6379"
  }
}

module "feedback" {
  source = "../../modules/service"

  name        = "feedback"
  environment = local.environment
  namespace   = kubernetes_namespace.minisource.metadata[0].name
  image       = "${var.registry_url}/feedback:${var.image_tag}"
  port        = 5012
  replicas    = 1

  env_vars = {
    SERVER_PORT         = "5012"
    ENVIRONMENT         = local.environment
    MONGODB_URI         = "mongodb://${module.database.mongodb_host}:27017"
    MONGODB_DATABASE    = "feedback_db"
    AUTH_SERVICE_URL    = "http://${module.auth.service_name}:${module.auth.service_port}"
    COMMENT_SERVICE_URL = "http://${module.comment.service_name}:${module.comment.service_port}"
    REDIS_HOST          = module.redis.redis_host
    REDIS_PORT          = "6379"
  }
}
