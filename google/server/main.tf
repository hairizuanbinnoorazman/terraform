resource "google_service_account" "service_account" {
  account_id   = "${var.datacentre}-${var.component}"
  display_name = "${var.component} service account for ${var.datacentre}"
}

resource "google_compute_instance" "server" {
  count = var.service_meta[var.component].server_count
  zone  = var.gcp_zone

  boot_disk {
    auto_delete = true
    device_name = var.component

    initialize_params {
      image = "${var.image_name}"
      size  = 50
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-medium"
  name         = "${var.component}-${count.index}"
  
  network_interface {
    subnetwork = var.vpc_subnet_name

    dynamic "access_config" {
      for_each = var.enable_bastion ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
}