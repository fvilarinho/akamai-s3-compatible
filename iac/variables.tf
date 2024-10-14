variable "settings" {
  default = {
    general = {
      email    = "<your-email>"
      domain   = "<your-domain>"
      hostname = "<hostname>"
    }

    cluster = {
      namespace = "akamai-s3-compatible"
      label     = "akamai-s3-compatible"
      tags      = [ "storage" ]

      credentials = {
        accessKey = "<accessKey>"
        secretKey = "<secretKey>"
      }

      nodes = {
        type         = "g6-standard-4"
        region       = "br-gru"
        defaultCount = 4
        minCount     = 4
        maxCount     = 4
      }

      storage = {
        dataSize = 10
      }
    }
  }
}