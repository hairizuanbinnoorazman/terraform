terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.3.0"
    }
  }
}

provider "google" {
  project = "${var.gcp_project_id}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

resource "google_compute_network" "custom_vpc_network" {
  name                    = var.datacentre
  auto_create_subnetworks = true
}

data "google_compute_subnetwork" "custom_vpc_subnetwork" {
  name   = google_compute_network.custom_vpc_network.name
  region = var.gcp_region
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.datacentre}-allow-ssh"
  network = google_compute_network.custom_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_tags   = ["${var.datacentre}-allow-ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.datacentre}-allow-http"
  network = google_compute_network.custom_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_tags   = ["${var.datacentre}-allow-http"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.datacentre}-allow-https"
  network = google_compute_network.custom_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  direction     = "INGRESS"
  source_tags   = ["${var.datacentre}-allow-https"]
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "allow_icmp" {
  name    = "${var.datacentre}-allow-icmp"
  network = google_compute_network.custom_vpc_network.name

  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.datacentre}-allow-internal"
  network = google_compute_network.custom_vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  direction     = "INGRESS"
  source_ranges = ["10.128.0.0/9"]
}

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

    subnetwork = data.google_compute_subnetwork.custom_vpc_subnetwork.name
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
  network = google_compute_network.custom_vpc_network.name
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

module "server" {
    for_each       = toset( var.components )
    source         = "./server"
    component      = each.key
    datacentre     = var.datacentre
    gcp_project_id = var.gcp_project_id
    gcp_zone       = var.gcp_zone
    gcp_region     = var.gcp_region
    vpc_subnet_name = google_compute_network.custom_vpc_network.name
}