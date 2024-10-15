# Required variables.
locals {
  applyStackScriptFilename               = abspath(pathexpand("../bin/applyStack.sh"))
  fetchStackOriginHostnameScriptFilename = abspath(pathexpand("../bin/fetchStackOriginHostname.sh"))
  stackDeploymentsFilename               = abspath(pathexpand("../etc/deployments.yaml"))
  stackServicesFilename                  = abspath(pathexpand("../etc/services.yaml"))
}

# Applies the stack files.
resource "null_resource" "applyStack" {
  # Executes only when a change happened.
  triggers = {
    always_run = "${filemd5(local.applyStackScriptFilename)}|${filemd5(local.stackDeploymentsFilename)}|${filemd5(local.stackServicesFilename)}"
  }

  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG           = local.kubeconfigFilename
      NAMESPACE            = var.settings.cluster.namespace
      ACCESS_KEY           = var.settings.cluster.credentials.accessKey
      SECRET_KEY           = var.settings.cluster.credentials.secretKey
      REPLICAS             = var.settings.cluster.nodes.count
      HOSTNAME             = local.hostname
      ADMIN_HOSTNAME       = local.adminHostname
      STORAGE_DATA_SIZE    = var.settings.cluster.storage.dataSize
      DEPLOYMENTS_FILENAME = local.stackDeploymentsFilename
      SERVICES_FILENAME    = local.stackServicesFilename
    }

    quiet   = true
    command = local.applyStackScriptFilename
  }

  depends_on = [
    local_sensitive_file.kubeconfig,
    local_sensitive_file.certificate,
    local_sensitive_file.certificateKey
  ]
}

# Fetches the stack origin hostname.
data "external" "fetchStackOriginHostname" {
  program = [
    local.fetchStackOriginHostnameScriptFilename,
    local.kubeconfigFilename,
    var.settings.cluster.namespace
  ]

  depends_on = [ null_resource.applyStack ]
}