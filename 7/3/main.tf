resource "docker_image" "nginx" {
  name         = var.containers.nginx.image
  keep_locally = true
}

resource "docker_image" "wordpress" {
  name         = var.containers.wordpress.image
  keep_locally = true
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "our-cool-project-${var.containers.nginx.name}"

  ports {
    internal = var.containers.nginx.ports.internal
    external = var.containers.nginx.ports.external
    ip       = "127.0.0.1"
  }
}

resource "docker_container" "wordpress" {
  image = docker_image.wordpress.image_id
  name  = "our-cool-project-${var.containers.wordpress.name}"

  ports {
    internal = var.containers.wordpress.ports.internal
    external = var.containers.wordpress.ports.external
    ip       = "127.0.0.1"
  }

  network_mode = "bridge"
}

resource "random_password" "any_uniq_name" {
  length = 16
}

resource "local_file" "xxx" {
  content         = "our-cool-project-${random_password.any_uniq_name.result}"
  filename        = "/tmp/xxx.txt"
  file_permission = "0600"
}