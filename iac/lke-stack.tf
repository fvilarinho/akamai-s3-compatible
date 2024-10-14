# Required variables.
locals {
  applyStackScriptFilename               = abspath(pathexpand("../bin/minio/applyStack.sh"))
  fetchStackOriginHostnameScriptFilename = abspath(pathexpand("../bin/minio/fetchStackOriginHostname.sh"))
  stackHostname                          = "${var.settings.general.hostname}.${var.settings.general.domain}"
  stackUiHostname                        = "${var.settings.general.hostname}-ui.${var.settings.general.domain}"
  stackNamespacesFilename                = abspath(pathexpand("../etc/minio/namespaces.yaml"))
  stackStoragesFilename                  = abspath(pathexpand("../etc/minio/storages.yaml"))
  stackDeploymentsFilename               = abspath(pathexpand("../etc/minio/deployments.yaml"))
  stackServicesFilename                  = abspath(pathexpand("../etc/minio/services.yaml"))
}

# Applies the stack files.
resource "null_resource" "applyStack" {
  # Executes only when a change happened.
  triggers = {
    always_run = "${filemd5(local.applyStackScriptFilename)}|${filemd5(local.stackNamespacesFilename)}|${filemd5(local.stackStoragesFilename)}|${filemd5(local.stackDeploymentsFilename)}|${filemd5(local.stackServicesFilename)}"
  }

  provisioner "local-exec" {
    # Required variables.
    environment = {
      KUBECONFIG                 = local.kubeconfigFilename
      NAMESPACE                  = var.settings.cluster.namespace
      ACCESS_KEY                 = var.settings.cluster.accessKey
      SECRET_KEY                 = var.settings.cluster.secretKey
      STACK_HOSTNAME             = local.stackHostname
      STACK_UI_HOSTNAME          = local.stackUiHostname
      STACK_NAMESPACES_FILENAME  = local.stackNamespacesFilename
      STACK_STORAGES_FILENAME    = local.stackStoragesFilename
      STACK_DEPLOYMENTS_FILENAME = local.stackDeploymentsFilename
      STACK_SERVICES_FILENAME    = local.stackServicesFilename
      STORAGE_DATA_SIZE          = var.settings.cluster.storage.dataSize
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