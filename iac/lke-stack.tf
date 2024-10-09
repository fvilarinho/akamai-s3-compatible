# Required variables.
locals {
  applyStackScriptFilename               = abspath(pathexpand("../bin/cloudserver/applyStack.sh"))
  fetchStackOriginHostnameScriptFilename = abspath(pathexpand("../bin/cloudserver/fetchStackOriginHostname.sh"))
  stackHostname                          = "${var.settings.cluster.label}.${var.settings.general.domain}"
  stackNamespacesFilename                = abspath(pathexpand("../etc/cloudserver/namespaces.yaml"))
  stackStoragesFilename                  = abspath(pathexpand("../etc/cloudserver/storages.yaml"))
  stackDeploymentsFilename               = abspath(pathexpand("../etc/cloudserver/deployments.yaml"))
  stackServicesFilename                  = abspath(pathexpand("../etc/cloudserver/services.yaml"))
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
      STACK_NAMESPACES_FILENAME  = local.stackNamespacesFilename
      STACK_STORAGES_FILENAME    = local.stackStoragesFilename
      STACK_DEPLOYMENTS_FILENAME = local.stackDeploymentsFilename
      STACK_SERVICES_FILENAME    = local.stackServicesFilename
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