locals {
  labels = merge({
    "app.kubernetes.io/name"       = var.name
    "app.kubernetes.io/instance"   = "${var.name}-${var.environment}"
    "app.kubernetes.io/component"  = "microservice"
    "app.kubernetes.io/part-of"    = "minisource"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
  }, var.labels)
}

# =================================
# Kubernetes Deployment
# =================================

resource "kubernetes_deployment" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
    annotations = var.annotations
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = var.name
        "app.kubernetes.io/instance" = "${var.name}-${var.environment}"
      }
    }

    template {
      metadata {
        labels = local.labels
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = tostring(var.port)
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = var.name
          image = var.image

          # HTTP Port
          port {
            container_port = var.port
            name           = "http"
            protocol       = "TCP"
          }

          # gRPC Port (if specified)
          dynamic "port" {
            for_each = var.grpc_port != null ? [var.grpc_port] : []
            content {
              container_port = port.value
              name           = "grpc"
              protocol       = "TCP"
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          # Environment variables
          dynamic "env" {
            for_each = var.env_vars
            content {
              name  = env.key
              value = env.value
            }
          }

          # Secret environment variables
          dynamic "env" {
            for_each = var.secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = "${var.name}-secrets"
                  key  = env.key
                }
              }
            }
          }

          # Liveness probe
          liveness_probe {
            http_get {
              path = var.health_path
              port = var.port
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Readiness probe
          readiness_probe {
            http_get {
              path = var.ready_path
              port = var.port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Security context
          security_context {
            read_only_root_filesystem = true
            run_as_non_root          = true
            run_as_user              = 1000
            allow_privilege_escalation = false
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          volume_mount {
            name       = "logs"
            mount_path = "/app/logs"
          }
        }

        volume {
          name = "tmp"
          empty_dir {}
        }

        volume {
          name = "logs"
          empty_dir {}
        }

        # Pod disruption budget-friendly settings
        termination_grace_period_seconds = 30
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
  }
}

# =================================
# Kubernetes Service
# =================================

resource "kubernetes_service" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = var.name
      "app.kubernetes.io/instance" = "${var.name}-${var.environment}"
    }

    # HTTP Port
    port {
      name        = "http"
      port        = var.port
      target_port = var.port
      protocol    = "TCP"
    }

    # gRPC Port (if specified)
    dynamic "port" {
      for_each = var.grpc_port != null ? [var.grpc_port] : []
      content {
        name        = "grpc"
        port        = port.value
        target_port = port.value
        protocol    = "TCP"
      }
    }

    type = "ClusterIP"
  }
}

# =================================
# Kubernetes Secret
# =================================

resource "kubernetes_secret" "secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-secrets"
    namespace = var.namespace
    labels    = local.labels
  }

  data = var.secrets
}

# =================================
# Horizontal Pod Autoscaler
# =================================

resource "kubernetes_horizontal_pod_autoscaler_v2" "hpa" {
  count = var.enable_autoscaling ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.service.metadata[0].name
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.target_cpu_utilization
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy               = "Min"
        policy {
          type          = "Pods"
          value         = 1
          period_seconds = 60
        }
      }
      scale_up {
        stabilization_window_seconds = 0
        select_policy               = "Max"
        policy {
          type          = "Pods"
          value         = 4
          period_seconds = 15
        }
        policy {
          type          = "Percent"
          value         = 100
          period_seconds = 15
        }
      }
    }
  }
}

# =================================
# Pod Disruption Budget
# =================================

resource "kubernetes_pod_disruption_budget_v1" "pdb" {
  count = var.replicas > 1 ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = local.labels
  }

  spec {
    min_available = "1"
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = var.name
        "app.kubernetes.io/instance" = "${var.name}-${var.environment}"
      }
    }
  }
}
