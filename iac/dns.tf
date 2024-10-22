# Required variables.
locals {
  hostname      = var.settings.general.domain
  adminHostname = "admin.${var.settings.general.domain}"
  webhooksHostname = "webhooks.${var.settings.general.domain}"
}

# Definition of the default DNS domain.
resource "linode_domain" "default" {
  domain    = var.settings.general.domain
  type      = "master"
  tags      = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace ])
  soa_email = var.settings.general.email
  ttl_sec   = 30
}

# Definition of the default DNS entry.
resource "linode_domain_record" "default" {
  domain_id   = linode_domain.default.id
  name        = local.hostname
  record_type = "A"
  target      = data.external.fetchStackHostname.result.ip
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackHostname
  ]
}

# Definition of the DNS entry for the admin UI.
resource "linode_domain_record" "admin" {
  domain_id   = linode_domain.default.id
  name        = local.adminHostname
  record_type = "CNAME"
  target      = data.external.fetchStackHostname.result.hostname
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackHostname
  ]
}

# Definition of the DNS entry for the webhooks
resource "linode_domain_record" "webhooks" {
  domain_id   = linode_domain.default.id
  name        = local.webhooksHostname
  record_type = "CNAME"
  target      = data.external.fetchStackHostname.result.hostname
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackHostname
  ]
}