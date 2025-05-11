---
title: "CIS-Hardened Debian 12 AMI with Packer and Ansible"
date: 2025-05-11
description: "How I built a CIS-hardened Debian 12 AMI using Packer and Ansible, with notes on IAM permissions and automation for reproducibility."
tags: ["packer", "ansible", "aws", "cis", "devops"]
categories: ["DevOps", "Security", "AWS", "CIS"]
author: ["Reza Behzadan", "ChatGPT"]
cover:
  image: "img/post-0004-cover.jpg"
  hidden: false
showToc: true
tocOpen: false
---

As part of my infrastructure hardening and automation efforts, I built a **CIS-hardened Debian 12 AMI** using [Packer](https://www.packer.io/) and the [ansible-lockdown/DEBIAN12-CIS](https://github.com/ansible-lockdown/DEBIAN12-CIS) Ansible role.

For reference or reuse, I’ve made the AMI **publicly available**:

> **AMI ID**: `ami-0ded45c1c47569084`  
> **Region**: `us-east-1`

This post documents how I did it from scratch.

---

## 🛠️ Tools Used

- **Packer**
- **Ansible**
- **Ansible Lockdown Role**
- **AWS EC2**
- **Debian 12 (Official AMI)**

---

## 📁 Project Structure

```text
cis-debian-ami/
├── packer.pkr.hcl
├── ansible/
│   ├── playbook.yml
│   └── roles/
│       └── DEBIAN12-CIS/  # added via git submodule
````

To add the Ansible role:

```bash
git submodule add https://github.com/ansible-lockdown/DEBIAN12-CIS.git ansible/roles/DEBIAN12-CIS
```

---

## 🧱 Packer Template

`packer.pkr.hcl`:

```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "debian" {
  ami_name        = "cis-hardened-debian12-amd64-{{timestamp}}"
  instance_type   = "t3.micro"
  region          = var.region
  ssh_username    = "admin"

  source_ami_filter {
    filters = {
      name                = "debian-12-amd64-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["136693071363"]
    most_recent = true
  }
}

build {
  name    = "cis-debian12-ami"
  sources = ["source.amazon-ebs.debian"]

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
  }
}
```

---

## 🧩 Ansible Playbook

`ansible/playbook.yml`:

```yaml
- name: Harden Debian 12 with CIS Benchmark
  hosts: all
  become: yes

  vars:
    setup_audit: true
    run_audit: true
    audit_run_heavy_tests: true
    deb12cis_rule_5_2_4: false          # Skip: user 'admin' is locked (uses SSH keys)
    deb12cis_rule_5_4_1_1: false        # Skip: password expiration policy
    deb12cis_rule_5_4_2_4: false        # Skip: root password must be set (root is disabled)
    deb12cis_sshd:
      allow_users: "admin"
      allow_groups: "admin"
      client_alive_interval: 900
    deb12cis_ufw_allow_out_ports:
      - 53
      - 80
      - 443

  roles:
    - DEBIAN12-CIS
```

---

## 🔐 IAM Policy

The Packer build requires extensive EC2 permissions. I created a dedicated IAM policy (`PackerEC2BuildPolicy`) with these actions:

```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:Describe*",
    "ec2:RunInstances",
    "ec2:StopInstances",
    "ec2:StartInstances",
    "ec2:TerminateInstances",
    "ec2:CreateTags",
    "ec2:CreateImage",
    "ec2:DeregisterImage",
    "ec2:CreateSnapshot",
    "ec2:DeleteVolume",
    "ec2:CreateVolume",
    "ec2:AttachVolume",
    "ec2:Modify*",
    "ec2:CreateKeyPair",
    "ec2:DeleteKeyPair",
    "ec2:ImportKeyPair",
    "ec2:CreateSecurityGroup",
    "ec2:DeleteSecurityGroup",
    "ec2:AuthorizeSecurityGroupIngress",
    "ec2:RevokeSecurityGroupIngress"
  ],
  "Resource": "*"
}
```

You can define this in the AWS Console, CLI, or Terraform.

---

## 🧪 Build the AMI

```bash
packer init .
packer build packer.pkr.hcl
```

After provisioning, Packer automatically deletes temporary security groups, key pairs, and the instance.

---

## 🔄 Why Some CIS Rules Were Disabled

To ensure the build works with AWS cloud-init and SSH key authentication, I disabled these rules:

* `deb12cis_rule_5_2_4`: Requires user account not be locked — not compatible with key-based SSH.
* `deb12cis_rule_5_4_1_1`: Password expiration — unnecessary in AMIs.
* `deb12cis_rule_5_4_2_4`: Requires root to have a password — Debian disables root login by default.

These don’t reduce the hardened posture when SSH is key-only and root login is disabled.

---

## 🪄 Result

This build applies the majority of Level 1 CIS controls for Debian 12, with a few carefully disabled for compatibility with cloud-init and SSH key-based access (e.g., rules requiring local passwords). Level 2 controls were not applied.


To launch an EC2 instance from this AMI:

```bash
aws ec2 run-instances \
  --image-id ami-0ded45c1c47569084 \
  --instance-type t3.micro \
  --key-name your-keypair-name \
  --region us-east-1
````

Replace `your-keypair-name` with an EC2 key pair you’ve already created in that region. After the instance starts, you can SSH into it using:

```bash
ssh -i your-key.pem admin@<public-ip>
```
