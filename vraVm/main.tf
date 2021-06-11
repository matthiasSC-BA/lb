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
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "DemoDS"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "DominikProjekt"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Get data about the image you're going to clone from.
data "vsphere_virtual_machine" "image" {
    name = "ubuntuTemplate"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# # Configure the cloud-init data you're going to use
# data "template_cloudinit_config" "cloud-config" {
#     gzip          = true
#     base64_encode = true
 
#     # This is your actual cloud-config document.  You can actually have more than
#     # one, but I haven't much bothered with it.
#     part {
#       content_type = "text/cloud-config"
#       content      = <<-EOT
#                      #cloud-config
#                      users:
#                        - name: "${var.username}"
#                          plain_text_passwd: "${var.password}"
#                          lock_passwd: false
#                          ssh_pwauth: "yes"
#                          sudo:
#                            - "ALL=(ALL) NOPASSWD:ALL"
#                          groups: sudo
#                          shell: /bin/bash
#                      EOT
#     }
# } 

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name

  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  num_cpus = 1
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.image.guest_id}"
  clone {
    template_uuid = "${data.vsphere_virtual_machine.image.id}"
  }
  cdrom {
    client_device = true
  }

  disk {
    label = "disk0"
    size  = 10
  }
  wait_for_guest_net_timeout    = -1
  
#   extra_config = {
#     "guestinfo.userdata"          = "${data.template_cloudinit_config.cloud-config.rendered}"
#     "guestinfo.userdata.encoding" = "gzip+base64"
#     "guestinfo.metadata"          = <<-EOT
#        { "local-hostname": "${var.vm_name}" }
#     EOT
#   }
  vapp {
    properties = {
      hostname = var.vm_name
      user-data = base64encode(file("userdata.yaml"))
    }
  }
  extra_config = {
    "guestinfo.metadata"          = base64encode(file("metadata.yaml"))
    "guestinfo.metadata.encoding" = "base64"
    "guestinfo.userdata"          = base64encode(file("userdata.yaml"))
    "guestinfo.userdata.encoding" = "base64"
  }
  provisioner "remote-exec" {
    inline = [
       "sudo cloud-init status --wait"
    ]
    connection {
# 			host = vsphere_virtual_machine.vm.ip
# 			type     = "ssh"
 			user     = "matthias"
 			password = "VMware1!"
 		} 
  }

}
