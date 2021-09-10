source "proxmox" "k3os_cloudinit" {
  proxmox_url              = "https://${var.proxmox_ip}:${var.proxmox_port}/api2/json"
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  iso_url                  = "https://github.com/rancher/k3os/releases/latest/download/k3os-amd64.iso"
  iso_storage_pool         = var.proxmox_iso_storage_pool
  iso_checksum             = "sha256:85a560585bc5520a793365d70e6ce984f3fb2ce5a43b31f0f7833dc347487e69"
  insecure_skip_tls_verify = true

  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"
  cores                   = 2
  disks {
    disk_size         = "50G"
    storage_pool      = "local-zfs"
    storage_pool_type = "zfspool"
  }
  memory = 8192
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  onboot           = true
  qemu_agent       = true
  scsi_controller  = "virtio-scsi-pci"
  ssh_username     = "rancher"
  ssh_agent_auth   = true
  ssh_wait_timeout = "10000s"
  template_name    = "k3os-cloudinit"
  unmount_iso      = true
  vm_name          = "provisioning-k3os-template"

  boot_command = [
    "<wait><tab>",
    "<down>",
    "<wait>",
    "e",
    "<down>",
    "<down>",
    "<down>",
    "<down>",
    "<down>",
    "<down>",
    "<end>",
    "<spacebar>",
    "k3os.install.config_url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/config.yaml",
    "<spacebar>",
    "k3os.fallback_mode=install",
    "<spacebar>",
    "k3os.install.silent=true",
    "<spacebar>",
    "k3os.install.device=/dev/sda",
    "<spacebar>",
    "k3os.install.debug=true",
    "<F10>"
  ]
  boot_wait      = "10s"
  http_directory = "packer/http"
}

build {
  sources = ["source.proxmox.k3os_cloudinit"]
}
