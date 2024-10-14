# Required variables.
locals {
  applyStackScriptFilename               = abspath(pathexpand("../bin/minio/applyStack.sh"))
  fetchStackOriginHostnameScriptFilename = abspath(pathexpand("../bin/minio/fetchStackOriginHostname.sh"))
  stackHostname                          = "${var.settings.general.hostname}.${var.settings.general.domain}"
  stackDeploymentsFilename               = abspath(pathexpand("../etc/minio/deployments.yaml"))
  stackServicesFilename                  = abspath(pathexpand("../etc/minio/services.yaml"))
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
      HOSTNAME             = local.stackHostname
      STORAGE_DATA_SIZE    = var.settings.cluster.storage.dataSize
      REPLICAS             = var.settings.cluster.nodes.maxCount
      ACCESS_KEY           = var.settings.cluster.credentials.accessKey
      SECRET_KEY           = var.settings.cluster.credentials.secretKey
      DEPLOYMENTS_FILENAME = local.stackDeploymentsFilename
      SERVICES_FILENAME    = local.stackServicesFilename
    }

    quiet   = true
    command = local.applyStackScriptFilename
  }

  depends_on = [ local_sensitive_file.kubeconfig ]
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