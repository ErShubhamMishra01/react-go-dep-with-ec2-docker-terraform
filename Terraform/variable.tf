variable "vpc-cidr" {
default = "10.0.0.0/16"
description = "VPC CIDR BLOCK"
type = string
}
variable "Public_Subnet_1" {
default = "10.0.0.0/24"
description = "Public_Subnet_1"
type = string
}
variable "Private_Subnet_1" {
default = "10.0.2.0/24"
description = "Private_Subnet_1"
type = string
}
variable "ssh-location" {
default = "0.0.0.0/0"
description = "SSH variable for bastion host"
type = string
}
variable "instance_type" {
type        = string
default     = "t2.micro"
}
variable key_name {
default     = "LL-TEST"
type = string
}