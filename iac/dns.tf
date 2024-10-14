# Definition of the DNS zone.
data "linode_domain" "default" {
  domain = var.settings.general.domain
}

# Definition of the default DNS entry.
resource "linode_domain_record" "default" {
  domain_id   = data.linode_domain.default.id
  name        = local.stackHostname
  record_type = "A"
  target      = data.external.fetchStackOriginHostname.result.ip
  ttl_sec     = 30
  depends_on  = [
    data.linode_domain.default,
    data.external.fetchStackOriginHostname
  ]
}

# Definition of the DNS entry for the UI.
resource "linode_domain_record" "ui" {
  domain_id   = data.linode_domain.default.id
  name        = local.stackUiHostname
  record_type = "A"
  target      = data.external.fetchStackOriginHostname.result.ip
  ttl_sec     = 30
  depends_on  = [
    data.linode_domain.default,
    data.external.fetchStackOriginHostname
  ]
}