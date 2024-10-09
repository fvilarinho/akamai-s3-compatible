variable "settings" {
  default = {
    general = {
      email  = "<your-email>"
      domain = "<your-domain>"
    }

    cluster = {
      namespace = "akamai-s3-compatible"
      label     = "akamai-s3-compatible"
      tags      = [ "storage" ]
      region    = "br-gru"
      type      = "g6-standard-4"
      count     = 1
      accessKey = "<accessKey>"
      secretKey = "<secretKey>"
      storage   = {
        dataSize     = 10
        metaDataSize = 10
      }
    }
  }
}