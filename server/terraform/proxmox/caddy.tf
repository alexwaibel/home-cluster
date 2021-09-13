variable "caddy_ip_address" {
  description = "The IP address to be used for Caddy reverse proxy."
  type        = string
}

variable "cloudflare_token" {
  description = "The access token used by Caddy to communicate with Cloudflare for DNS cert validation."
  type        = string
  sensitive   = true
}

resource "random_password" "password" {
  length  = 32
  special = true
}

resource "proxmox_lxc" "caddy" {
  hostname    = "caddy"
  target_node = "server"

  ostemplate   = "local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz"
  unprivileged = true
  onboot       = true
  start        = true

  ssh_public_keys = file(var.ssh_public_key)
  password        = random_password.password.result

  cores  = 1
  memory = 512

  rootfs {
    storage = "local-zfs"
    size    = "10G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.caddy_ip_address}/24"
    ip6    = "auto"
    gw     = "192.168.1.1"
  }

  provisioner "remote-exec" {
    inline = ["echo provisioned"]

    connection {
      host  = var.caddy_ip_address
      type  = "ssh"
      user  = "root"
      agent = true
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --user root --inventory '../../ansible/inventory' --extra-vars cloudflare_token=\"${var.cloudflare_token}\" ../../ansible/playbooks/proxy/caddy.yaml"
  }
}
