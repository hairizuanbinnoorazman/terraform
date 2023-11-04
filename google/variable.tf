variable "datacentre" {
    description = "Define name of application centre to be deployed to"
    type        = string
    default     = "haha"
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

variable "components" {
    description = "List of components to be added to this datacentre"
    type        = list(string)
    default     = ["etcd"]
}