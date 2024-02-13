variable "project_id" {
  type        = string
  description = "The project ID to host the network in."
}

variable "region" {
  type        = string
  description = "The region to use"
}

variable "zone" {
  type        = string
  description = "The zone where the App Server host is located in."
}

variable "server_name" {
  type        = string
  description = "The name to use for the appserver instance."
}

variable "network_name" {
  type        = string
  description = "The name of the network that should be used."
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet that should be used."
}

variable "kubeadmsetup_script" {
  type        = string
  description = "Script to set up ku8s cluster using kubeadm"
}

variable "bucketname" {
  type        = string
  description = "Bucket name"
}

variable "sa_email" {
  type        = string
  description = "service account email"
}