# --- Configuration Terraform et Provider ---
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
  }
}

provider "docker" {}

# --- 1. Ressource: Base de Données PostgreSQL ---
# Télécharge l'image PostgreSQL depuis Docker Hub
resource "docker_image" "postgres_image" {
  name         = "postgres:latest"
  keep_locally = true
}

# Crée et configure le conteneur PostgreSQL
resource "docker_container" "db_container" {
  name  = "tp-db-postgres"
  image = docker_image.postgres_image.image_id

  ports {
    internal = 5432
    external = 5433
  }

  # Configuration de la DB via les variables d'environnement
  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]
}

# --- 2. Ressource: Application Web Nginx ---
# Construit l'image de l'application à partir du Dockerfile_app local
resource "docker_image" "app_image" {
  name = "tp-web-app:latest"
  build {
    context    = "."
    dockerfile = "Dockerfile_app"
  }
}

# Crée le conteneur de l'application web
resource "docker_container" "app_container" {
  name  = "tp-app-web"
  image = docker_image.app_image.image_id

  # Dépendance explicite: la DB doit être prête avant l'Application
  depends_on = [
    docker_container.db_container
  ]

  # Mappage du port 80 interne au port externe
  ports {
    internal = 80
    external = var.app_port_external
  }
}