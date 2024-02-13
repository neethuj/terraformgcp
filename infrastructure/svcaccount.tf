// Dedicated service account for the App Server instance.
resource "google_service_account" "k8snode" {
  account_id   =  "k8s-node-sa"
  display_name = "GKE App Server Service Account"
}

resource "google_storage_bucket_iam_binding" "bucket_admin" {
  bucket = var.bucketname
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.k8snode.email}"
  ]
}

resource "google_project_iam_member" "computeadmin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.k8snode.email}"
}

resource "google_project_iam_member" "computenwadmin" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.k8snode.email}"
}

resource "google_project_iam_member" "lbadmin" {
  project = var.project_id
  role    = "roles/compute.loadBalancerAdmin"
  member  = "serviceAccount:${google_service_account.k8snode.email}"
}

resource "google_project_iam_member" "computeinstanceadmin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.k8snode.email}"
}

resource "google_project_iam_member" "editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.k8snode.email}"
}