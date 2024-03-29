variable "project_id" {
  type        = string
  description = "The ID of the project to create resources in"
}

variable "region" {
  type        = string
  description = "The region to use"
}

variable "main_zone" {
  type        = string
  description = "The zone to use as primary"
}

variable "credentials_file_path" {
  type        = string
  description = "The credentials JSON file used to authenticate with GCP"
}

variable "service_account" {
  type        = string
  description = "The GCP service account"
}

variable "bucketname" {
  type        = string
  description = "Bucket name"
}
