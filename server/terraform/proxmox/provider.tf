terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.10"
    }
  }
}

variable "proxmox_port" {
  type        = string
  description = "The port used by the proxmox management interface."
  default     = "8006"
}

variable "proxmox_password" {
  type        = string
  description = "The password for the proxmox user."
  sensitive   = true
}

provider "proxmox" {
  pm_api_url      = "https://${var.proxmox_ip}:${var.proxmox_port}/api2/json"
  pm_user         = var.proxmox_username
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}
