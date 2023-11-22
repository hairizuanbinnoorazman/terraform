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
    startup_script = string
  }))
  default = {
    docker = {
      server_count = 1
      startup_script = <<EOF
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker hairizuan
EOF
    }
    etcd = {
      server_count = 3
      startup_script = ""
    }
    mariadb = {
      server_count = 1
      startup_script = <<EOF
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
EOF
    }
    nginx = {
      server_count = 1
      startup_script = <<EOF
sudo apt-get update
sudo apt-get install -y nginx
EOF
    }
    redis = {
      server_count = 1
      startup_script = <<EOF
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt-get update
sudo apt-get -y install redis
EOF
    }
    appuser = {
      server_count = 1
      startup_script = ""
    }
  }
}