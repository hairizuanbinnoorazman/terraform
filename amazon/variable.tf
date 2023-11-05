variable "datacentre" {
    description = "Define name of application centre to be deployed to"
    type        = string
    default     = "haha"
}

variable "instance_type" {
    description = "Instance type of EC2 instances"
    type        = string
    default     = "t2.micro"
}

variable "ssh_key_pair_name" {
    description = "Define name of ssh key pair to allow ssh into instances"
    type        = string
}