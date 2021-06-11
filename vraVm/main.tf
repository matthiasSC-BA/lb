variable "vm_name" {
  type        = string
  description = "VM Name"
}

variable "hostname" {
  type        = string
  description = "hostname"
}

variable "domain" {
  type        = string
  description = "domain"
}


provider "vsphere" {

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Noris"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "WLD01"
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

# Configure the cloud-init data you're going to use
data "template_cloudinit_config" "cloud-config" {
    gzip          = true
    base64_encode = true
 
    # This is your actual cloud-config document.  You can actually have more than
    # one, but I haven't much bothered with it.
    part {
      content_type = "text/cloud-config"
      content      = <<-EOT
                     #cloud-config
                     groups:
                       - group: sudo
                     users:
                       - name: '${input.username}'
                         plain_text_passwd: '${input.password}'
                         lock_passwd: false
                         ssh_pwauth: 'yes'
                         sudo:
                           - 'ALL=(ALL) NOPASSWD:ALL'
                         groups: sudo
                         shell: /bin/bash
                     EOT
    }
} 

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name

  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  num_cpus = 1
  memory   = 1024
  guest_id = "other3xLinux64Guest"

  disk {
    label = "disk0"
    size  = 10
  }
  wait_for_guest_net_timeout    = -1
  
  extra_config = {
    "guestinfo.userdata"          = "${data.template_cloudinit_config.cloud-config.rendered}"
    "guestinfo.userdata.encoding" = "gzip+base64"
    "guestinfo.metadata"          = <<-EOT
       { "local-hostname": "${var.hostname}.${var.domain}" }
    EOT
  }

}
