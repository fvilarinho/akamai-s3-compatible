# Required variables.
locals {
  certificateIssuanceCredentialsFilename = abspath(pathexpand("../etc/tls/.certificateIssuance.credentials"))
  storageCredentialsFilename             = abspath(pathexpand("../etc/minio/.credentials"))
  webhooksCredentialsFilename            = abspath(pathexpand("../etc/nginx/conf.d/.htpasswd"))
}

# Creates the certificate issuance credentials filename.
resource "local_sensitive_file" "certificateIssuanceCredentials" {
  filename = local.certificateIssuanceCredentialsFilename
  content  = <<EOT
dns_linode_key = ${linode_token.certificateIssuance.token}
EOT
  depends_on = [ linode_token.certificateIssuance ]
}

# Creates the stack credentials filename.
resource "local_sensitive_file" "storageCredentials" {
  filename = local.storageCredentialsFilename
  content = <<EOT
[default]
aws_access_key_id=${var.settings.cluster.credentials.accessKey}
aws_secret_access_key=${var.settings.cluster.credentials.secretKey}
region=us-east-1
output=json
EOT
}

resource "local_sensitive_file" "webhooksCredentials" {
  filename = local.webhooksCredentialsFilename
  content = <<EOT
${var.settings.cluster.credentials.accessKey}:${bcrypt(var.settings.cluster.credentials.secretKey)}
EOT
}