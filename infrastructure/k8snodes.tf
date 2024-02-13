module "master" {
  source = "./compute"

  project_id          = var.project_id
  region              = var.region
  zone                = var.main_zone
  server_name         = "master"
  network_name        = module.google_networks.network.name
  subnet_name         = module.google_networks.subnet.name
  kubeadmsetup_script = "templates/master.tpl"
  bucketname = module.k8sconfstorage.bucketname
  sa_email = google_service_account.k8snode.email
}

module "worker" {
  source = "./compute"
  count = 2
  project_id          = var.project_id
  region              = var.region
  zone                = var.main_zone
  server_name         = "worker${count.index}"
  network_name        = module.google_networks.network.name
  subnet_name         = module.google_networks.subnet.name
  kubeadmsetup_script = "templates/worker.tpl"
  bucketname = module.k8sconfstorage.bucketname
  sa_email = google_service_account.k8snode.email
}

// Allow access to nodes
resource "google_compute_firewall" "k8s_ingress" {
  name          = "kubernetes-ingress"
  network       = module.google_networks.network.name
  direction     = "INGRESS"
  project       = var.project_id
  source_ranges = ["0.0.0.0/0"] // TODO: Restrict further.

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "443", "10250", "30000-32767"]
  }

  target_tags = ["app-server"]
}

// Allow access to nodes
resource "google_compute_firewall" "k8s-node-internal" {
  name          = "kubernetes-internal"
  network       = module.google_networks.network.name
  direction     = "INGRESS"
  project       = var.project_id
  source_tags = ["app-server"]

  allow {
    protocol = "all"
  }

  target_tags = ["app-server"]
}