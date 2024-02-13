variable "bucketname" {
  type        = string
  description = "Name of the bucket"
}

variable "location" {
  type        = string
  description = "The location to use."
}

variable "storageclass" {
  type        = string
  description = "The location to use."
  default     = "STANDARD"
}