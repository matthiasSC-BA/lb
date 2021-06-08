terraform {
  required_providers {
    vra = {
      source = "vmware/vra"
      version = "0.3.5"
    }
  }
}

variable "deployment_name" {
  type        = string
  description = "VM Name"
}  
variable "project_id" {
  type        = string
  description = "VM Name"
}  
variable "blueprint_id" {
  type        = string
  description = "VM Name"
}  
variable "blueprint_version" {
  type        = string
  description = "VM Name"
}

provider "vra" {
  insecure = true
}

resource "vra_deployment" "this" {
  name        = var.deployment_name
  description = "Deployment description"

  blueprint_id      = var.blueprint_id
  blueprint_version = var.blueprint_version
  project_id        = var.project_id

  inputs = {
    flavor = "Test-Flavor-Small"
    image  = "Ubuntu"
    count  = 1
    flag   = true
    arrayProp = jsonencode(["foo", "bar", "baz"])
    objectProp = jsonencode({ "key": "value", "key2": [1, 2, 3] })
  }

  timeouts {
    create = "30m"
    delete = "30m"
    update = "30m"
  }
}
