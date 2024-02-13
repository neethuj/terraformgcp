locals {
  hostname = format("k8s-%s-node", var.server_name)
}

// The user-data script on App Server instance provisioning.
data "template_file" "kubeadm_script" {
  template = file(var.kubeadmsetup_script)
}

// The App Server host.
resource "google_compute_instance" "appserver" {
  name         = local.hostname
  machine_type = "e2-standard-2"
  zone         = var.zone
  project      = var.project_id
  tags         = ["app-server", local.hostname]

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20231213a" #"debian-cloud/debian-10" 
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  // Install tinyproxy on startup.
  metadata_startup_script = data.template_file.kubeadm_script.rendered

  network_interface {
    subnetwork = var.subnet_name


    access_config {
      // Not setting "nat_ip", use an ephemeral external IP.
      network_tier = "STANDARD"
    }
  }

  // Allow the instance to be stopped by Terraform when updating configuration.
  allow_stopping_for_update = true

  service_account {
    email  = var.sa_email
    scopes = ["cloud-platform"]
  }

  /* local-exec providers may run before the host has fully initialized.
  However, they are run sequentially in the order they were defined.
  This provider is used to block the subsequent providers until the instance is available. */
  #   provisioner "local-exec" {
  #     command = <<EOF
  #         READY=""
  #         for i in $(seq 1 30); do
  #           if [ -f /tmp/SetupDone ]; then
  #             READY="yes"
  #             break;
  #           fi
  #           echo "Waiting for ${local.hostname} to initialize..."
  #           sleep 10;
  #         done
  #         if [[ -z $READY ]]; then
  #           echo "${local.hostname} failed to start in time."
  #           echo "Please verify that the instance starts and then re-run `terraform apply`"
  #           exit 1
  #         fi
  # EOF
  #   }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}