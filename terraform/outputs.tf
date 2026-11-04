output "artifact_registry_url" {
  description = "Docker image registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.assessment.repository_id}"
}

output "backend_service_account" {
  description = "Backend runtime service account"
  value       = google_service_account.backend.email
}

output "worker_service_account" {
  description = "Celery worker runtime service account"
  value       = google_service_account.worker.email
}

output "backend_service_name" {
  value = google_cloud_run_v2_service.backend.name
}

output "worker_pool_name" {
  value = google_cloud_run_v2_worker_pool.worker.name
}

output "frontend_service_name" {
  description = "Cloud Run frontend service name"
  value       = google_cloud_run_v2_service.frontend.name
}

output "frontend_url" {
  description = "Public frontend URL"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "redis_host" {
  description = "Private Redis IP address"
  value       = google_redis_instance.assessment.host
}

output "redis_port" {
  description = "Redis port"
  value       = google_redis_instance.assessment.port
}
