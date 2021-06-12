variable "vm_name" {
  type        = string
  description = "VM Name"
}

variable "username" {
  type        = string
  description = "username"
}
variable "password" {
  type        = string
  description = "password"
}


provider "vsphere" {
  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Noris"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Workload_Cluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = "DemoDS"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "DominikProjekt"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Get data about the image you're going to clone from.
data "vsphere_virtual_machine" "image" {
    name = "k8s-play-tmpl"
  #  name = "ubuntuTemplate"
    datacenter_id = data.vsphere_datacenter.dc.id
}


data "template_file" "cloud-init" {
  template = file("userdata.yaml")

  vars = {
    hostname = var.vm_name    
    username = var.username  
    password = var.password  
  }
}
data "template_cloudinit_config" "cloud-init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-init.rendered
  }
}

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name

  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  num_cpus = 1
  memory   = 1024
  guest_id = data.vsphere_virtual_machine.image.guest_id
  clone {
    template_uuid = data.vsphere_virtual_machine.image.id
  }
  cdrom {
    client_device = true
  }

  disk {
    label = "disk0"
    size  = 10
  }
  wait_for_guest_net_timeout    = 10
  
  vapp {
    properties = {
      hostname = var.vm_name
      user-data = base64gzip(data.template_file.cloud-init.rendered)
    }
  }
}
