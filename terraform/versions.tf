terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }

  # No remote backend configured on purpose: this is a portfolio project,
  # not a team-operated one. In a real multi-engineer setup this would be
  # a GCS backend (bucket + prefix) to get remote state + locking.
  #
  # backend "gcs" {
  #   bucket = "your-gcp-project-id-tfstate"
  #   prefix = "olist-elt-pipeline"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
