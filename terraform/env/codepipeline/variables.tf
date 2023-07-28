variable "env" {
  description = "Deployment environment"
  default     = "dev"
}

variable "repository_branch" {
  description = "Repository branch to connect to"
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "Codestar connection ARN"
  default     = "arn:aws:codestar-connections:us-east-1:625194385885:connection/30b5fdd4-ab18-4b92-a27d-eb4ab6787c0e"
}

variable "repository_ID" {
  description = "GitHub repository"
  default     = "kodjobaah/afriex-webhook-proxy"
}

variable "artifacts_bucket_name" {
  description = "S3 Bucket for storing artifacts"
  default     = "artifacts-bucket"
}
