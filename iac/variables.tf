variable "settings" {
  default = {
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
      token  = "<token>"
    }

    cluster = {
      namespace = "akamai-s3-compatible"
      label     = "minio"
      tags      = [ "demo" ]

      credentials = {
        accessKey = "<accessKey>"
        secretKey = "<secretKey>"
      }

      nodes = {
        type   = "g6-standard-4"
        region = "br-gru"
        count  = 4
      }

      storage = {
        dataSize = 10
      }

      allowedIps = {
        ipv4 = ["0.0.0.0/0"]
        ipv6 = []
      }
    }
  }
}