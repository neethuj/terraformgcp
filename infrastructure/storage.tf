module "k8sconfstorage" {
  source       = "./storage"
  bucketname   = var.bucketname
  location     = "US"
  storageclass = "STANDARD"
}



