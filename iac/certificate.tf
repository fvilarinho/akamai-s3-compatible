# Required variables.
locals {
  certificateIssuanceScript = abspath(pathexpand("../bin/tls/certificateIssuance.sh"))
  certificateFilename       = abspath(pathexpand("../etc/tls/certs/fullchain.pem"))
  certificateKeyFilename    = abspath(pathexpand("../etc/tls/private/privkey.pem"))
}

# Creates the certificate issuance credentials used to add the DNS validation entries in the DNS server.
resource "linode_token" "certificateIssuance" {
  label  = "certificate-issuance"
  scopes = "domains:read_write"
}

# Issues the certificate using Certbot.
resource "null_resource" "certificateIssuance" {
  provisioner "local-exec" {
    # Required variables.
    environment = {
      CERTIFICATE_ISSUANCE_CREDENTIALS_FILENAME = local.certificateIssuanceCredentialsFilename
      CERTIFICATE_ISSUANCE_PROPAGATION_DELAY    = 600 // in seconds.
      DOMAIN                                    = var.settings.general.domain
      EMAIL                                     = var.settings.general.email
    }

    quiet   = true
    command = local.certificateIssuanceScript
  }

  depends_on = [
    local_sensitive_file.certificateIssuanceCredentials,
    linode_token.certificateIssuance
  ]
}

# Saves the issued certificate locally to enable HTTPs traffic in Gitea.
resource "local_sensitive_file" "certificate" {
  count      = (fileexists("/etc/letsencrypt/live/${var.settings.general.domain}/fullchain.pem") ? 1 : 0)
  filename   = local.certificateFilename
  content    = file("/etc/letsencrypt/live/${var.settings.general.domain}/fullchain.pem")
  depends_on = [ null_resource.certificateIssuance ]
}

# Saves the issued certificate key locally to enable HTTPs traffic in Gitea.
resource "local_sensitive_file" "certificateKey" {
  count      = (fileexists("/etc/letsencrypt/live/${var.settings.general.domain}/privkey.pem") ? 1 : 0)
  filename   = local.certificateKeyFilename
  content    = file("/etc/letsencrypt/live/${var.settings.general.domain}/privkey.pem")
  depends_on = [ null_resource.certificateIssuance ]
}