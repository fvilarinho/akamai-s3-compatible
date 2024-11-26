# Required variables.
locals {
  kubeconfigFilename = abspath(pathexpand("../etc/.kubeconfig"))
}

# Definition of the K8S cluster to deploy the stack.
resource "linode_lke_cluster" "default" {
  k8s_version = "1.31"
  label       = var.settings.cluster.label
  tags        = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace ] )
  region      = var.settings.cluster.nodes.region

  pool {
    type  = var.settings.cluster.nodes.type
    count = var.settings.cluster.nodes.count
  }

  control_plane {
    high_availability = true

    acl {
      enabled = true

      addresses {
        ipv4 = [ "${jsondecode(data.http.myIp.response_body).ip}/32" ]
      }
    }
  }

  depends_on = [
    data.http.myIp,
    null_resource.certificateIssuance,
    local_sensitive_file.certificate,
    local_sensitive_file.certificateKey
  ]
}

# Saves the K8S cluster configuration file used to connect into it.
resource "local_sensitive_file" "kubeconfig" {
  filename        = local.kubeconfigFilename
  content_base64  = linode_lke_cluster.default.kubeconfig
  file_permission = "600"
  depends_on      = [ linode_lke_cluster.default ]
}