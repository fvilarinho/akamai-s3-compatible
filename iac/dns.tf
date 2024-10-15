# Required variables.
locals {
  hostname      = var.settings.general.domain
  adminHostname = "admin.${var.settings.general.domain}"
}

# Definition of the default DNS domain.
resource "linode_domain" "default" {
  domain    = var.settings.general.domain
  type      = "master"
  soa_email = var.settings.general.email
  ttl_sec   = 30
}

# Definition of the default DNS entry.
resource "linode_domain_record" "default" {
  domain_id   = linode_domain.default.id
  name        = local.hostname
  record_type = "A"
  target      = data.external.fetchStackOriginHostname.result.ip
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackOriginHostname
  ]
}

# Definition of the DNS entry for the admin UI.
resource "linode_domain_record" "admin" {
  domain_id   = linode_domain.default.id
  name        = local.adminHostname
  record_type = "A"
  target      = data.external.fetchStackOriginHostname.result.ip
  ttl_sec     = 30
  depends_on  = [
    linode_domain.default,
    data.external.fetchStackOriginHostname
  ]
}