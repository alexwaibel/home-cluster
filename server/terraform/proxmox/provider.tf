terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.6.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.1.124:8006/api2/json"
  pm_user         = "terraform@pve"
  pm_tls_insecure = true
}
