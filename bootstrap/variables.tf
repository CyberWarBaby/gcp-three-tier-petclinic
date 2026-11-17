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

variable "github_repo" {
  type        = string
  description = "owner/repo, exact spelling and case"
}

variable "state_bucket" {
  type    = string
  default = "habeeb-tf-state"
}
