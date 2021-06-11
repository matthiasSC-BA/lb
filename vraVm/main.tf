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
   # name = "ubuntuTemplate"
    datacenter_id = data.vsphere_datacenter.dc.id
}


data "template_file" "cloud-init" {
  template = file("userdata.yaml")

  vars = {
    hostname = var.vm_name    
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

data "template_file" "meta_init" {
  template = <<EOF
{
        "local-hostname": "$${local_hostname}"
        "instance-id": "$${local_hostname}"
}
EOF
 
  vars = {
    local_hostname = var.vm_name
  }
}
data "template_cloudinit_config" "meta_init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.meta_init.rendered
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
  wait_for_guest_net_timeout    = 5
  
  extra_config = {    
    "guestinfo.metadata" = data.template_file.meta_init.rendered
    "guestinfo.metadata.encoding" = "gzip+base64"
    "guestinfo.userdata" = data.template_file.cloud-init.rendered
    "guestinfo.userdata.encoding" = "gzip+base64"
  }
#   vapp {
#     properties = {
#     "guestinfo.userdata" = base64gzip(data.template_file.cloud-init.rendered)
#         }
#   }
#   extra_config = {
#     "guestinfo.userdata"          = "${data.template_cloudinit_config.cloud-config.rendered}"
#     "guestinfo.userdata.encoding" = "gzip+base64"
#     "guestinfo.metadata"          = <<-EOT
#        { "local-hostname": "${var.vm_name}" }
#     EOT 
#   }
#   vapp {
#     properties = {
#       hostname = var.vm_name
#       user-data = base64gzip(data.template_file.cloud-init.rendered)
#     }
#   }
#   guestinfo = {
#     userdata.encoding = "base64"
#     userdata = base64encode(file("userdata.yaml"))
#   }

#   extra_config = {
#     "guestinfo.metadata"          = base64encode(file("metadata.yaml"))
#     "guestinfo.metadata.encoding" = "base64"
#     "guestinfo.userdata"          = base64encode(file("userdata.yaml"))
#     "guestinfo.userdata.encoding" = "base64"
#   }
  provisioner "remote-exec" {
    inline = [
       "sudo cloud-init status --wait"
    ]
    connection {
      host     = vsphere_virtual_machine.vm.default_ip_address
      type     = "ssh"
      user     = "matthias"
 			password = "VMware1!"
 		} 
  }

}
