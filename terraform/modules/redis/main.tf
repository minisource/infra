locals {
  labels = merge({
    "app.kubernetes.io/name"       = "redis"
    "app.kubernetes.io/component"  = "cache"
    "app.kubernetes.io/part-of"    = "minisource"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
  }, var.labels)
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "redis" {
  metadata {
    name      = "redis-secrets"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    REDIS_PASSWORD = random_password.redis.result
  }
}

resource "kubernetes_config_map" "redis" {
  metadata {
    name      = "redis-config"
    namespace = var.namespace
    labels    = local.labels
  }

  data = {
    "redis.conf" = <<-EOT
      bind 0.0.0.0
      port 6379
      maxmemory 256mb
      maxmemory-policy allkeys-lru
      appendonly ${var.enable_persistence ? "yes" : "no"}
      appendfsync everysec
      save 900 1
      save 300 10
      save 60 10000
    EOT
  }
}

resource "kubernetes_stateful_set" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    service_name = "redis"
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "redis"
      }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name  = "redis"
          image = "redis:${var.redis_version}-alpine"

          command = ["redis-server", "/etc/redis/redis.conf"]

          port {
            container_port = 6379
            name           = "redis"
          }

          resources {
            requests = {
              cpu    = var.cpu
              memory = var.memory
            }
            limits = {
              cpu    = var.cpu
              memory = var.memory
            }
          }

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
          }

          volume_mount {
            name       = "redis-config"
            mount_path = "/etc/redis"
          }

          liveness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "redis-config"
          config_map {
            name = kubernetes_config_map.redis.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "redis-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "redis"
    }

    port {
      port        = 6379
      target_port = 6379
      name        = "redis"
    }

    type = "ClusterIP"
  }
}
