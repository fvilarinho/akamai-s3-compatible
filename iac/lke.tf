# Required variables.
locals {
  kubeconfigFilename = abspath(pathexpand("../etc/.kubeconfig"))
}

# Definition of the K8S cluster to deploy the stack.
resource "linode_lke_cluster" "default" {
  k8s_version = "1.30"
  label       = var.settings.cluster.label
  tags        = var.settings.cluster.tags
  region      = var.settings.cluster.region

  pool {
    type  = var.settings.cluster.type
    count = var.settings.cluster.count
  }
}

# Saves the K8S cluster configuration file used to connect into it.
resource "local_sensitive_file" "kubeconfig" {
  filename        = local.kubeconfigFilename
  content_base64  = linode_lke_cluster.default.kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.default ]
}