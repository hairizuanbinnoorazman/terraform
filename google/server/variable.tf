variable "vpc_subnet_name" {
    description = "Define name of subnet to add instance to"
    type        = string
}

variable "datacentre" {
    description = "Define name of application centre to be deployed to"
    type        = string
    default     = "haha"
}

variable "enable_bastion" {
    description = "Enable bastion host setup"
    type        = bool
    default     = false
}

variable "gcp_project_id" {
    description = "Define the GCP Project ID that we will interacting with"
    type        = string
    sensitive   = true
}

variable "gcp_region" {
    description = "Region to deploy the zone to"
    type        = string
    default     = "us-central1"
}

variable "gcp_zone" {
    description = "Zone to deploy the cluster to"
    type        = string
    default     = "us-central1-a"
}

variable "image_name" {
    description = "Name of image to be used for deployments"
    type        = string
    default     = "projects/debian-cloud/global/images/debian-11-bullseye-v20231010"
}

variable "component" {
    description = "Name of component to be deployed"
    type        = string
}

variable "service_meta" {
  type = map(object({
    server_count = number
  }))
  default = {
    docker = {
      server_count = 1
    }
    etcd = {
      server_count = 3
    }
    mariadb = {
      server_count = 1
    }
    nginx = {
      server_count = 1
    }
    redis = {
      server_count = 1
    }
    mongodb = {
      server_count = 1
    }
    memcached = {
      server_count = 1
    }
    cassandra = {
      server_count = 1
    }
    jenkins = {
      server_count = 1
    }
    vault = {
      server_count = 1
    }
    postgresql = {
      server_count = 1
    }
    appuser = {
      server_count = 1
    }
  }
}