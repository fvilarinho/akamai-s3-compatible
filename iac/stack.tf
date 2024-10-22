# Required variables.
locals {
  applyStackManifestsScriptFilename     = abspath(pathexpand("../bin/applyStackManifests.sh"))
  applyStackLabelsAndTagsScriptFilename = abspath(pathexpand("../bin/applyStackLabelsAndTags.sh"))
  fetchStackHostnameScriptFilename      = abspath(pathexpand("../bin/fetchStackHostname.sh"))
  stackDeploymentsFilename              = abspath(pathexpand("../etc/deployments.yaml"))
  stackServicesFilename                 = abspath(pathexpand("../etc/services.yaml"))
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
    local_sensitive_file.kubeconfig,
    local_sensitive_file.certificate,
    local_sensitive_file.certificateKey
  ]
}

# Applies the stack labels and tags.
resource "null_resource" "applyStackLabelsAndTags" {
  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfigFilename
      NAMESPACE  = var.settings.cluster.namespace
      TAGS       = join(" ", var.settings.cluster.tags)
    }

    quiet   = true
    command = local.applyStackLabelsAndTagsScriptFilename
  }

  depends_on = [ null_resource.applyStackManifests ]
}

# Fetches the stack hostname.
data "external" "fetchStackHostname" {
  program = [
    local.fetchStackHostnameScriptFilename,
    local.kubeconfigFilename,
    var.settings.cluster.namespace
  ]

  depends_on = [ null_resource.applyStackManifests ]
}