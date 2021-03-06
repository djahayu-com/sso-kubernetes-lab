resource "digitalocean_ssh_key" "public_key" {
  name       = "sso-kubernetes-public-key"
  public_key = var.do_ssh_key
}

resource "digitalocean_droplet" "keycloak" {
  image  = var.keycloak_vm_images
  name   = var.keycloak_vm_name
  region = var.keycloak_vm_region
  size   = var.keycloak_vm_size
  ssh_keys = [
    digitalocean_ssh_key.public_key.fingerprint
  ]
}

data "template_file" "keycloak_group_vars" {
  template = "${file("./templates/keycloak_group_vars.yaml.tpl")}"
  vars = {
    keycloak_public_ip = digitalocean_droplet.keycloak.ipv4_address
    keycloak_domain = var.keycloak_domain
    keycloak_username = var.keycloak_username
    keycloak_password = var.keycloak_password
  }
}

data "template_file" "keycloak_hosts" {
  template = "${file("./templates/keycloak_hosts.tpl")}"
  vars = {
    keycloak_public_ip = digitalocean_droplet.keycloak.ipv4_address
  }
}

resource "local_file" "keycloak_group_vars" {
  content  = "${data.template_file.keycloak_group_vars.rendered}"
  filename = "ansible/keycloak/group_vars/all.yaml"
}

resource "local_file" "keycloak_hosts" {
  content  = "${data.template_file.keycloak_hosts.rendered}"
  filename = "ansible/keycloak/hosts/hosts"
}

resource "digitalocean_droplet" "kubernetes" {
  image  = var.kubernetes_vm_images
  name   = var.kubernetes_vm_name
  region = var.kubernetes_vm_region
  size   = var.kubernetes_vm_size
  ssh_keys = [
    digitalocean_ssh_key.public_key.fingerprint
  ]
}

data "template_file" "kubernetes_group_vars" {
  template = "${file("./templates/kubernetes_group_vars.yaml.tpl")}"
  vars = {
    kubernetes_public_ip = digitalocean_droplet.kubernetes.ipv4_address
    oidc_domain = var.keycloak_domain
  }
}

data "template_file" "kubernetes_hosts" {
  template = "${file("./templates/kubernetes_hosts.tpl")}"
  vars = {
    kubernetes_public_ip = digitalocean_droplet.kubernetes.ipv4_address
  }
}

resource "local_file" "kubernetes_group_vars" {
  content  = "${data.template_file.kubernetes_group_vars.rendered}"
  filename = "ansible/kubernetes/group_vars/all.yaml"
}

resource "local_file" "kubernetes_hosts" {
  content  = "${data.template_file.kubernetes_hosts.rendered}"
  filename = "ansible/kubernetes/hosts/hosts"
}
