module "google_networks" {
  source = "./networks"

  project_id = var.project_id
  region     = var.region
}
