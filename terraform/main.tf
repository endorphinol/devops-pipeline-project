// Созданная сеть
resource "yandex_vpc_network" "network" {
  name = "network"
}

// Созданная подсеть
resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
}

// Создание мастер-узла
resource "yandex_kubernetes_cluster" "master" {
  name        = "kubernetes-master"
  description = "Создание кластера Kubernetes"

  network_id = yandex_vpc_network.network.id

  master {
    version = "1.30"
    zonal {
      zone      = yandex_vpc_subnet.subnet.zone
      subnet_id = yandex_vpc_subnet.subnet.id
    }

    public_ip = true

    security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }

    master_logging {
      enabled                    = true
      log_group_id               = yandex_logging_group.log_group_resoruce_name.id
      kube_apiserver_enabled     = true
      cluster_autoscaler_enabled = true
      events_enabled             = true
      audit_enabled              = true
    }

    scale_policy {
      auto_scale {
        min_resource_preset_id = "s-c4-m16"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.service_account_resource_name.id
  node_service_account_id = yandex_iam_service_account.node_service_account_resource_name.id

  labels = {
    my_key       = "my_value"
    my_other_key = "my_other_value"
  }

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  kms_provider {
    key_id = yandex_kms_symmetric_key.kms_key_resource_name.id
  }

  workload_identity_federation {
    enabled = true
  }
}

// Группа узлов в кластере Kubernetes
resource "yandex_kubernetes_node_group" "node" {
  cluster_id  = yandex_kubernetes_cluster.master.id
  name        = "node"
  description = "Создание узла"
  version     = "1.30"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.subnet.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-e"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }

  workload_identity_federation {
    enabled = true
  }
}

