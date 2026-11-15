variable "name_prefix" {
  type    = string
  default = "three-tier"
}

variable "project" {
  type    = string
  default = "three-tier-petclinic-tf"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "db_name" {
  type    = string
  default = "petclinic"
}

variable "db_user" {
  type    = string
  default = "petclinic_user"
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "app_instance_count" {
  type    = number
  default = 2
}

variable "web_instance_count" {
  type    = number
  default = 2
}