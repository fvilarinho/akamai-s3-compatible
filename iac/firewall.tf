locals {
  nodeBalancersToBeProtected = [ for nodeBalancer in data.linode_nodebalancers.toBeProtected.nodebalancers : nodeBalancer.id ]
  nodesToBeProtected         = flatten([ for pool in linode_lke_cluster.default.pool : [ for node in pool.nodes : node.instance_id ] ])
  allowedPublicIps           = concat([ for node in data.linode_instances.toBeProtected.instances : "${node.ip_address}/32" ], [ "${jsondecode(data.http.myIp.response_body).ip}/32" ])
  allowedPrivateIps          = [ for node in data.linode_instances.toBeProtected.instances : "${node.private_ip_address}/32" ]
  allowedIpv4                = concat(var.settings.cluster.allowedIps.ipv4, concat(local.allowedPublicIps, local.allowedPrivateIps))
}

# Fetches the local IP.
data "http" "myIp" {
  url = "https://ipinfo.io"
}

# Fetches all nodes to be protected in the Cloud Firewall.
data "linode_instances" "toBeProtected" {
  filter {
    name   = "id"
    values = local.nodesToBeProtected
  }

  depends_on = [ linode_lke_cluster.default ]
}

# Fetches all stack Node Balancers to be protected in the Cloud Firewall.
data "linode_nodebalancers" "toBeProtected" {
  filter {
    name   = "hostname"
    values = [ data.external.fetchStackHostname.result.hostname ]
  }

  depends_on = [ data.external.fetchStackHostname ]
}

# Definition of the firewall rules.
resource "linode_firewall" "default" {
  label           = "${var.settings.cluster.label}-firewall"
  tags            = concat(var.settings.cluster.tags, [ var.settings.cluster.namespace] )
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
    label    = "allowed-cluster-nodeports-udp"
    protocol = "IPENCAP"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-kubelet-health-checks"
    protocol = "TCP"
    ports    = "10250, 10256"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-lke-wireguard"
    protocol = "UDP"
    ports    = "51820"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-tcp"
    protocol = "TCP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-cluster-dns-udp"
    protocol = "UDP"
    ports    = "53"
    ipv4     = [ "192.168.128.0/17" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-tcp"
    protocol = "TCP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-nodebalancers-udp"
    protocol = "UDP"
    ports    = "30000-32767"
    ipv4     = [ "192.168.255.0/24" ]
  }

  inbound {
    action   = "ACCEPT"
    label    = "allowed-ips"
    protocol = "TCP"
    ipv4     = local.allowedIpv4
    ipv6     = var.settings.cluster.allowedIps.ipv6
  }

  nodebalancers = local.nodeBalancersToBeProtected
  linodes       = local.nodesToBeProtected

  depends_on = [
    data.http.myIp,
    data.linode_nodebalancers.toBeProtected,
    data.linode_instances.toBeProtected
  ]
}