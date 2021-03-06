# Home Cluster

My homelab Kubernetes cluster in declarative state. [Flux](https://github.com/fluxcd/flux2) automatically deploys any changes to the `/cluster` directory.

## Overview

- [Architecture](#architecture)
- [Installation](#installation)
- [Thanks](#thanks)

## Architecture

The cluster runs on a single [k3s](https://github.com/k3s-io/k3s) node running in a [k3os](https://github.com/rancher/k3os) VM
on a single [Proxmox](https://pve.proxmox.com/) host. I'm currently running the entire cluster on my previous desktop machine.

### Virtual Hosts

- DNS server (LXC)
- k3s (VM)
- NFS fileserver (VM)

### Hardware

- 4x12TB HDD
- 32GB DDR4 2400MHz RAM
- Intel i7 6700k
- Nvidia 1070
- HUSBZB-1 Zigbee + Z-Wave Adapter
- Arduino Uno + WS2812B LED strip

### Networking

1. This cluster uses a custom Traefik ingress controller to configure hostnames using a subdomain of my registered tld.
1. Traefik uses cert-manager with LetsEncrypt and Cloudflare ACME DNS solver to provide certificates for all my services without exposing any ports on my router to the public internet.
1. The coreDNS server provides DNS for my home network. Using the k8s_gateway plugin it can query the cluster's ingresses.

#### Repository Structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

- **base** directory is the entrypoint to Flux
- **crds** directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists
- **core** directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by Flux
- **apps** directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, Flux will prune resources here if they are not tracked by Git anymore

```text
cluster
├── apps
│   ├── default
│   └── networking
├── base
│   └── flux-system
├── core
│   ├── cert-manager
│   ├── metallb-system
│   └── namespaces
└── crds
    └── cert-manager
```

As well as the following directories under `server` which is used to provision the infrastructure on the Proxmox host.

- **packer** directory contains Packer configs for used to build the custom Proxmox template images
- **terraform** directory contains Terraform templates used to deploy the infrastructure to Proxmox
- **ansible** directory contains Ansible playbooks for configuring the machines once deployed

```text
server
├── ansible
│   ├── inventory
│   ├── playbooks
│   └── requirements.yaml
├── packer
│   ├── images
│   └── templates
└── terraform
    └── proxmox
```

### Storage

I provisioned Proxmox using the ZFS filesystem which provides many benefits including redundancy and snapshots. My current RAID configuration (mirror vdevs, roughly RAID 10) offers 1/2 of my total storage capacity.

Storage for the k3s cluster is provided by the virtualized NFS server. The [NFS Subdirectory External Provisioner Helm chart](https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/) is used to provision persistent volume claims automatically.

## Installation

The below steps will provision the k3s cluster as well as a fileserver and a DNS server.

### Tools

These tools should be installed on the machine you'll be managing the cluster from.

<!-- markdownlint-disable MD013 -->

| Tool                                                                                                                                    | Description                                                                                                                          |
| --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)                                   | Uses the [Proxmox provisioner](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs) to create VMs and LXC containers |
| [Packer](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)                                                          | Creates custom Proxmox template images                                                                                               |
| [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip) | Performs configuration on machines once the OS is installed                                                                          |
| [kubectl](https://kubernetes.io/docs/tasks/tools/)                                                                                      | Runs commands against Kubernetes clusters                                                                                            |
| [flux](https://toolkit.fluxcd.io/)                                                                                                      | Operator that manages cluster resources based on Git repositories                                                                    |
| [SOPS](https://github.com/mozilla/sops)                                                                                                 | Encrypts Kubernetes secrets with GnuPG                                                                                               |
| [GnuPG](https://gnupg.org/)                                                                                                             | Encrypts and signs data                                                                                                              |
| [pre-commit](https://github.com/pre-commit/pre-commit)                                                                                  | Runs checks before `git commit`                                                                                                      |
| [helm](https://helm.sh/)                                                                                                                | Manages Kubernetes applications                                                                                                      |
| [prettier](https://github.com/prettier/prettier)                                                                                        | Formats code                                                                                                                         |
| [go-task](https://taskfile.dev/)                                                                                                        | A task runner comparable to GNU make                                                                                                 |

<!-- markdownlint-enable MD013 -->

### Prerequisites

- You must have a server with Proxmox VE installed
  - Must use ZFS for storage
  - Must have sufficient storage space (I use RAID10 with 4x12tb drives)
- You must have a public/private ssh key-pair generated and added to ssh agent

  ```bash
  # Generate key
  ssh-keygen -t ed25519 -C "your_email@example.com"
  # Add to ssh agent (you may need to enable the agent separately)
  ssh-add ~/.ssh/id_ed25519
  ```

- You must have the SOPS GPG private key imported
- Install the `pre-commit` hooks to ensure linting runs on every commit as well as to ensure unencrypted secrets are not committed

  ```bash
  task pre-commit:init
  ```

- Install Ansible dependencies

  ```bash
  task ansible:install
  ```

### Provisioning cluster

1. Double check the [packer config](./server/packer/variables.auto.pkrvars.hcl),
   [terraform config](./server/terraform/proxmox/variables.auto.tfvars),
   and [cluster settings](./cluster/base/cluster-settings.yaml), then add your secrets to the secrets files

   ```bash
   echo "proxmox_password = \"TERRAFORM ADMIN USER PASSWORD\"" >> server/terraform/proxmox/secrets.auto.tfvars
   echo "proxmox_password = \"TERRAFORM ADMIN USER PASSWORD\"" >> server/packer/images/secrets.auto.pkrvars.hcl
   echo "domain = \"your-domain.com\"" >> server/packer/images/secrets.auto.pkrvars.hcl
   ```

1. Build the template images

   ```bash
   task packer:all
   ```

1. Check the terraform plan and apply it

   ```bash
   task terraform:init
   task terraform:plan
   task terraform:apply
   ```

1. Set your DHCP server to use the new DNS server

## Thanks

This cluster has been heavily inspired by the [k8s@home](https://github.com/k8s-at-home) community.
Thank you to everyone that contributes there as well as to the authors of the open source technologies which operate this cluster.
