variable "containers" {
  description = "Configuration of demo Docker containers"

  type = map(object({
    name  = string
    image = string
    ports = object({
      external = number
      internal = number
    })
  }))

  default = {
    nginx = {
      name  = "reverse-proxy-nginx"
      image = "nginx:1.21.1"
      ports = {
        internal = 80
        external = 1080
      }
    }

    wordpress = {
      name  = "web-wordpress"
      image = "wordpress:latest"
      ports = {
        internal = 80
        external = 2080
      }
    }
  }
}