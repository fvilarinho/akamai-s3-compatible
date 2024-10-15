data "http" "myIp" {
  url = "https://ipinfo.io"
}

data "linode_nodebalancers" "default" {}

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

  depends_on = [ data.http.myIp ]
}

resource "null_resource" "test" {
  for_each = { for nodebalancer in data.linode_nodebalancers.default.nodebalancers : nodebalancer.id => nodebalancer }

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    quiet = true
    command = "echo ${each.value.hostname}"
  }
}