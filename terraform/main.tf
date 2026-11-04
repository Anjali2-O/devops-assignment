# Backend can read Redis password
resource "google_secret_manager_secret_iam_member" "backend_password" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backend.email}"
}

# Backend can read Redis CA certificate
resource "google_secret_manager_secret_iam_member" "backend_ca" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_ca.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backend.email}"
}

# Worker can read Redis password
resource "google_secret_manager_secret_iam_member" "worker_password" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.worker.email}"
}

# Worker can read Redis CA certificate
resource "google_secret_manager_secret_iam_member" "worker_ca" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_ca.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.worker.email}"
}


resource "google_artifact_registry_repository" "assessment" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_name
  description   = "Docker images for the DevOps assessment application"
  format        = "DOCKER"

  labels = {
    application = "devops-assignment"
    managed_by  = "terraform"
  }
}

resource "google_service_account" "backend" {
  project      = var.project_id
  account_id   = "devops-backend-sa"
  display_name = "DevOps Assessment Backend"
  description  = "Runtime identity for the FastAPI backend"
}

resource "google_service_account" "worker" {
  project      = var.project_id
  account_id   = "devops-worker-sa"
  display_name = "DevOps Assessment Worker"
  description  = "Runtime identity for the Celery worker"
}

resource "google_service_account" "frontend" {
  project      = var.project_id
  account_id   = "devops-frontend-sa"
  display_name = "DevOps Assessment Frontend"
  description  = "Runtime identity for the NGINX frontend"
}


# FastAPI backend
resource "google_cloud_run_v2_service" "backend" {
  project             = var.project_id
  name                = "devops-backend"
  location            = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.backend.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = google_compute_network.assessment.id
        subnetwork = google_compute_subnetwork.assessment.id
      }
    }

    # Mount the Redis CA certificate from Secret Manager
    volumes {
      name = "redis-ca"

      secret {
        secret = google_secret_manager_secret.redis_ca.secret_id

        items {
          version = google_secret_manager_secret_version.redis_ca.version
          path    = "ca.crt"
          mode    = 0444
        }
      }
    }


    containers {
      image = var.container_image

      ports {
        container_port = 8000
      }
      volume_mounts {
        name       = "redis-ca"
        mount_path = "/secrets/redis"
      }

      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.assessment.host
      }
      env {
        name  = "REDIS_PORT"
        value = tostring(google_redis_instance.assessment.port)
      }

      env {
        name = "REDIS_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_password.secret_id
            version = google_secret_manager_secret_version.redis_password.version
          }
        }
      }

      env {
        name  = "REDIS_CA_PATH"
        value = "/secrets/redis/ca.crt"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }
  # Ensure secret permissions exist before deploying the backend
  depends_on = [
    google_secret_manager_secret_iam_member.backend_password,
    google_secret_manager_secret_iam_member.backend_ca
  ]
}


# Celery background worker
resource "google_cloud_run_v2_worker_pool" "worker" {
  project             = var.project_id
  name                = "devops-worker"
  location            = var.region
  deletion_protection = false
  template {
    service_account = google_service_account.worker.email
    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = google_compute_network.assessment.id
        subnetwork = google_compute_subnetwork.assessment.id
      }
    }
    # Mount the Redis CA certificate from Secret Manager
    volumes {
      name = "redis-ca"

      secret {
        secret = google_secret_manager_secret.redis_ca.secret_id

        items {
          version = google_secret_manager_secret_version.redis_ca.version
          path    = "ca.crt"
          mode    = 0444
        }
      }
    }

    containers {
      image   = var.container_image
      command = ["celery"]
      args    = ["-A", "worker", "worker", "--loglevel=info"]
      volume_mounts {
        name       = "redis-ca"
        mount_path = "/secrets/redis"
      }

      env {
        name  = "REDIS_HOST"
        value = google_redis_instance.assessment.host
      }
      env {
        name  = "REDIS_PORT"
        value = tostring(google_redis_instance.assessment.port)
      }

      env {
        name = "REDIS_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_password.secret_id
            version = google_secret_manager_secret_version.redis_password.version
          }
        }
      }

      env {
        name  = "REDIS_CA_PATH"
        value = "/secrets/redis/ca.crt"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
  }

  scaling {
    scaling_mode          = "MANUAL"
    manual_instance_count = 0
  }

  depends_on = [
    google_secret_manager_secret_iam_member.worker_password,
    google_secret_manager_secret_iam_member.worker_ca
  ]
}

# NGINX frontend
resource "google_cloud_run_v2_service" "frontend" {
  project             = var.project_id
  name                = "devops-frontend"
  location            = var.region
  deletion_protection = false
  template {
    service_account = google_service_account.frontend.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = var.frontend_image

      ports {
        container_port = 80
      }

      env {
        name  = "BACKEND_URL"
        value = google_cloud_run_v2_service.backend.uri
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "256Mi"
        }
      }
    }
  }
}
# Dedicated VPC for the application
resource "google_compute_network" "assessment" {
  project                 = var.project_id
  name                    = "devops-assessment-vpc"
  auto_create_subnetworks = false
}

# Subnet used by Cloud Run Direct VPC egress
resource "google_compute_subnetwork" "assessment" {
  project                  = var.project_id
  name                     = "devops-assessment-subnet"
  region                   = var.region
  network                  = google_compute_network.assessment.id
  ip_cidr_range            = "10.10.0.0/24"
  private_ip_google_access = true
}

# Reserve a separate IP range for Google-managed private services
resource "google_compute_global_address" "private_services" {
  project       = var.project_id
  name          = "devops-assessment-private-services"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = google_compute_network.assessment.id
}

# Establish Private Service Access with Google
resource "google_service_networking_connection" "private_services" {
  network = google_compute_network.assessment.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_services.name
  ]
}

# Managed Redis instance with private network connectivity
resource "google_redis_instance" "assessment" {
  project        = var.project_id
  name           = "devops-assessment-redis"
  region         = var.region
  tier           = "BASIC"
  memory_size_gb = 1
  # Enable password authentication
  auth_enabled = true

  # Enable TLS encryption
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  authorized_network = google_compute_network.assessment.id

  depends_on = [
    google_service_networking_connection.private_services
  ]
}

# Store the Redis AUTH password in Secret Manager
resource "google_secret_manager_secret" "redis_password" {
  project   = var.project_id
  secret_id = "devops-redis-password"

  replication {
    auto {}
  }

  depends_on = [
    google_redis_instance.assessment
  ]
}

# Store the generated Redis password as a secret version
resource "google_secret_manager_secret_version" "redis_password" {
  secret = google_secret_manager_secret.redis_password.id

  secret_data_wo         = google_redis_instance.assessment.auth_string
  secret_data_wo_version = 1
}

# Store the Redis TLS CA certificate in Secret Manager
resource "google_secret_manager_secret" "redis_ca" {
  project   = var.project_id
  secret_id = "devops-redis-ca"

  replication {
    auto {}
  }
}

# Store the generated CA certificate
resource "google_secret_manager_secret_version" "redis_ca" {
  secret = google_secret_manager_secret.redis_ca.id

  secret_data_wo = join(
    "\n",
    [
      for ca in google_redis_instance.assessment.server_ca_certs : ca.cert
    ]
  )

  secret_data_wo_version = 1
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.frontend.location
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  project  = var.project_id
  location = google_cloud_run_v2_service.backend.location
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
