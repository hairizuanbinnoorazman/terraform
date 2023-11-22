resource "google_service_account" "bastion" {
  account_id   = "${var.datacentre}-bastion"
  display_name = "Bastion service account for ${var.datacentre}"
}

resource "google_compute_instance" "bastion" {
  zone = "${var.gcp_zone}"

  boot_disk {
    auto_delete = true
    device_name = "bastion"

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
  name         = "bastion"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    # subnetwork = data.google_compute_subnetwork.custom_vpc_subnetwork.name
    subnetwork = var.vpc_subnet_name
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
}

resource "google_compute_router" "router" {
  project = var.gcp_project_id
  name    = "${var.datacentre}-router"
  network = var.vpc_network_name
  region  = var.gcp_region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.datacentre}-nat"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}