# Dataform repository, linked directly to this GitHub repo so both the
# Cloud Build pipeline (../cloudbuild.yaml) and the Airflow DAG
# (../orchestration/dataform_orchestration_dag.py) compile/run against
# the same managed repository instead of code copied at build time.

resource "google_dataform_repository" "olist_pipeline" {
  provider = google

  name         = var.dataform_repository_id
  display_name = "Olist ELT Pipeline"
  project      = var.project_id
  region       = var.region

  git_remote_settings {
    url            = var.github_repo_url
    default_branch = var.github_default_branch

    # Points at a secret version holding a GitHub PAT. The secret is
    # created out-of-band (see variables.tf), this only references it.
    authentication_token_secret_version = "projects/${var.project_id}/secrets/${var.github_pat_secret_id}/versions/latest"
  }

  labels = var.labels

  depends_on = [google_secret_manager_secret_iam_member.dataform_reads_github_pat]
}

# Dataform's service agent needs read access to the secret holding the
# GitHub PAT to clone this repository. The secret resource itself is not
# created here (see variables.tf note) — only the IAM binding, assuming
# it already exists.
resource "google_secret_manager_secret_iam_member" "dataform_reads_github_pat" {
  project   = var.project_id
  secret_id = var.github_pat_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

data "google_project" "current" {
  project_id = var.project_id
}
