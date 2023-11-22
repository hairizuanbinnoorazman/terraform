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

module "bastion" {
  source           = "./bastion"
  count            = var.enable_bastion ? 1 : 0
  datacentre       = var.datacentre
  gcp_project_id   = var.gcp_project_id
  gcp_zone         = var.gcp_zone
  gcp_region       = var.gcp_region
  vpc_network_name = google_compute_network.custom_vpc_network.name 
  vpc_subnet_name  = data.google_compute_subnetwork.custom_vpc_subnetwork.name
}

module "server" {
    for_each        = toset( var.components )
    source          = "./server"
    component       = each.key
    enable_bastion  = var.enable_bastion
    datacentre      = var.datacentre
    gcp_project_id  = var.gcp_project_id
    gcp_zone        = var.gcp_zone
    gcp_region      = var.gcp_region
    vpc_subnet_name = data.google_compute_subnetwork.custom_vpc_subnetwork.name
}