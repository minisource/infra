locals {
  common_labels = merge({
    "app.kubernetes.io/component"  = "database"
    "app.kubernetes.io/part-of"    = "minisource"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
  }, var.labels)
}

# =================================
# PostgreSQL
# =================================

resource "random_password" "postgres_root" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secrets"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    POSTGRES_PASSWORD = random_password.postgres_root.result
  }
}

resource "kubernetes_config_map" "postgres_init" {
  metadata {
    name      = "postgres-init"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    "init.sql" = join("\n", [
      for db in var.postgres_databases : <<-EOT
        CREATE DATABASE ${db.name};
        CREATE USER ${db.user} WITH ENCRYPTED PASSWORD '${db.password}';
        GRANT ALL PRIVILEGES ON DATABASE ${db.name} TO ${db.user};
        \c ${db.name}
        GRANT ALL ON SCHEMA public TO ${db.user};
      EOT
    ])
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      "app.kubernetes.io/name" = "postgres"
    })
  }

  spec {
    service_name = "postgres"
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "postgres"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          "app.kubernetes.io/name" = "postgres"
        })
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:${var.postgres_version}"

          port {
            container_port = 5432
            name           = "postgres"
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          resources {
            requests = {
              cpu    = var.postgres_cpu
              memory = var.postgres_memory
            }
            limits = {
              cpu    = var.postgres_cpu
              memory = var.postgres_memory
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "postgres-init"
            mount_path = "/docker-entrypoint-initdb.d"
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", "postgres"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "postgres"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "postgres-init"
          config_map {
            name = kubernetes_config_map.postgres_init.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.postgres_storage_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      "app.kubernetes.io/name" = "postgres"
    })
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
      name        = "postgres"
    }

    type = "ClusterIP"
  }
}

# =================================
# MongoDB
# =================================

resource "random_password" "mongodb_root" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb-secrets"
    namespace = var.namespace
    labels    = local.common_labels
  }

  data = {
    MONGO_INITDB_ROOT_USERNAME = "root"
    MONGO_INITDB_ROOT_PASSWORD = random_password.mongodb_root.result
  }
}

resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      "app.kubernetes.io/name" = "mongodb"
    })
  }

  spec {
    service_name = "mongodb"
    replicas     = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "mongodb"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          "app.kubernetes.io/name" = "mongodb"
        })
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:${var.mongodb_version}"

          port {
            container_port = 27017
            name           = "mongodb"
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb.metadata[0].name
                key  = "MONGO_INITDB_ROOT_USERNAME"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb.metadata[0].name
                key  = "MONGO_INITDB_ROOT_PASSWORD"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.mongodb_cpu
              memory = var.mongodb_memory
            }
            limits = {
              cpu    = var.mongodb_cpu
              memory = var.mongodb_memory
            }
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/data/db"
          }

          liveness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.mongodb_storage_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      "app.kubernetes.io/name" = "mongodb"
    })
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "mongodb"
    }

    port {
      port        = 27017
      target_port = 27017
      name        = "mongodb"
    }

    type = "ClusterIP"
  }
}
