resource "kubernetes_storage_class" "mongo_storage" {
  metadata {
    name = "mongodb-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

resource "kubernetes_persistent_volume" "mongo_data_volume" {
  metadata {
    name = "mongodb-data"
  }
  
  spec {
    storage_class_name = "mongodb-storage"
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "2Gi"
    }
    persistent_volume_source {
      local {
        path = "/data"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "In"
            values = ["minikube"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mongodb_data_claim" {
  metadata {
    name = "mongodb-data"
  }
  spec {
    storage_class_name = "mongodb-storage"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_service" "mongodb_service" {
  metadata {
    name = var.mongodb_service_name
    labels = {
      app = "mongodb"
    }
  }
  spec {
    port {
      port = 27017
      target_port = "27017"
    }
    cluster_ip = "None"
    selector = {
      app = "mongodb"
    }
  }
}

resource "kubernetes_stateful_set" "mongodb_set" {
  metadata {
    name = var.mongodb_set_name
  }
  spec {
    service_name = var.mongodb_service_name
    replicas = 1
    
    selector {
      match_labels = {
        app = "mongodb"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }
      spec {
        container {
          name = "mongodb"
          image = "mongo:4.4.6"
          port {
            name = "mongodb"
            container_port = 27017
          }
          volume_mount {
            name = "mongodb-data"
            mount_path = "/data/db"
          }
        }
        volume {
          name = "mongodb-data"
          persistent_volume_claim {
            claim_name = "mongodb-data"
          }
        }
      }
    }
  }
}