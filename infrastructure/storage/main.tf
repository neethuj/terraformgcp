resource "google_storage_bucket" "storage" {
  name          = var.bucketname
  location      = var.location
  force_destroy = true
  storage_class = var.storageclass

  uniform_bucket_level_access = true
  #   public_access_prevention = "enforced"
}