variable "region" {
  default = "us-east-1"
}

variable "VPC_CIDR" {
  default = "10.0.100.0/22"
}

variable "env" {
  default = "dev"
}

variable "VPCName" {
  default = "dev-vpc"
}

variable "privateCIDR1" {
  default = "10.0.100.0/24"
}

variable "privateCIDR2" {
  default = "10.0.101.0/24"
}

variable "publicCIDR1" {
  default = "10.0.102.0/24"
}

variable "publicCIDR2" {
  default = "10.0.103.0/24"
}

variable "AZId1" {
  default = "use1-az1"
}

variable "AZId2" {
  default = "use1-az2"
}