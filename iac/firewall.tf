# Fetches the local IP.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches the stack node balancers.
data "linode_nodebalancers" "default" {
  filter {
    name   = "ipv4"
    values = [ data.external.fetchStackOriginHostname.result.ip ]
  }

  depends_on = [ data.external.fetchStackOriginHostname ]
}

# Definition of the firewall rules.
resource "linode_firewall" "default" {
  label           = "${var.settings.cluster.label}-firewall"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    action   = "ACCEPT"
    label    = "allow-icmp"
    protocol = "ICMP"
    ipv4     = [ "0.0.0.0/0" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "TCP"
    ports    = "80,443"
    ipv4     = concat(var.settings.cluster.allowedIps.ipv4, [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])
    ipv6     = var.settings.cluster.allowedIps.ipv6
  }

  nodebalancers = [ for nodeBalancer in data.linode_nodebalancers.default.nodebalancers : nodeBalancer.id ]

  depends_on = [
    data.http.myIp,
    data.external.fetchStackOriginHostname,
    data.linode_nodebalancers.default,
    null_resource.applyStack
  ]
}