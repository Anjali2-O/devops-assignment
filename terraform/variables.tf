variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "testing-508709"
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "asia-south1"
}

variable "repository_name" {
  description = "Artifact Registry repository for the DevOps assessment"
  type        = string
  default     = "devops-assignment"
}

variable "container_image" {
  description = "Full Artifact Registry image URI, including tag"
  type        = string
}

variable "frontend_image" {
  description = "Full Artifact Registry frontend image URI, including tag"
  type        = string
}
