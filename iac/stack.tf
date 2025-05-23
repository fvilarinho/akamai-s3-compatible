# Required variables.
locals {
  applyStackManifestsScriptFilename = abspath(pathexpand("../bin/applyStackManifests.sh"))
  fetchStackHostnameScriptFilename  = abspath(pathexpand("../bin/fetchStackHostname.sh"))
  stackDeploymentsFilename          = abspath(pathexpand("../etc/deployments.yaml"))
  stackServicesFilename             = abspath(pathexpand("../etc/services.yaml"))
}

# Applies the stack files.
resource "null_resource" "applyStackManifests" {
  # Executes only when a change happened.
  triggers = {
    always_run = "${filemd5(local.applyStackManifestsScriptFilename)}|${filemd5(local.stackDeploymentsFilename)}|${filemd5(local.stackServicesFilename)}"
  }

  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG           = local.kubeconfigFilename
      NAMESPACE            = var.settings.cluster.namespace
      ACCESS_KEY           = var.settings.cluster.credentials.accessKey
      SECRET_KEY           = var.settings.cluster.credentials.secretKey
      REPLICAS             = var.settings.cluster.nodes.count
      REPLICAS_RANGE       = "0...${(var.settings.cluster.nodes.count - 1)}"
      HOSTNAME             = local.hostname
      ADMIN_HOSTNAME       = local.adminHostname
      WEBHOOKS_HOSTNAME    = local.webhooksHostname
      STORAGE_DATA_SIZE    = var.settings.cluster.storage.dataSize
      DEPLOYMENTS_FILENAME = local.stackDeploymentsFilename
      SERVICES_FILENAME    = local.stackServicesFilename
    }

    quiet   = true
    command = local.applyStackManifestsScriptFilename
  }

  depends_on = [
    linode_lke_cluster.default,
    local_sensitive_file.kubeconfig
  ]
}

# Fetches the stack hostname (Load Balancer).
data "external" "fetchStackHostname" {
  program = [
    local.fetchStackHostnameScriptFilename,
    local.kubeconfigFilename,
    var.settings.cluster.namespace
  ]

  depends_on = [ null_resource.applyStackManifests ]
}