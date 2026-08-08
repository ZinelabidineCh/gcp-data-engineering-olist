# Cloud Build trigger wiring ../cloudbuild.yaml to pushes on this GitHub
# repo. Uses the 2nd-gen GitHub connection (Cloud Build GitHub App).
#
# Known bootstrap limitation: Terraform cannot fully automate the GitHub
# App OAuth handshake. Before `google_cloudbuildv2_connection` below can
# be created, the Cloud Build GitHub App must be installed on this repo
# once, manually:
#   gcloud builds connections create github olist-github-connection \
#     --project=<project_id> --region=<region>
# (follow the printed URL to authorize). This is a one-time, one-command
# manual step — everything downstream of it is declarative.

resource "google_cloudbuildv2_connection" "github" {
  project  = var.project_id
  location = var.region
  name     = "olist-github-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = "projects/${var.project_id}/secrets/${var.github_pat_secret_id}/versions/latest"
    }
  }
}

resource "google_cloudbuildv2_repository" "olist_pipeline" {
  project           = var.project_id
  location          = var.region
  name              = "olist-elt-pipeline-gcp-looker"
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = var.github_repo_url
}

resource "google_cloudbuild_trigger" "on_push" {
  project  = var.project_id
  location = var.region
  name     = "olist-dataform-validate-deploy"

  service_account = google_service_account.cloud_build_pipeline.id

  repository_event_config {
    repository = google_cloudbuildv2_repository.olist_pipeline.id
    push {
      branch = "^${var.github_default_branch}$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _REGION               = var.region
    _DATAFORM_REPOSITORY  = var.dataform_repository_id
  }
}
