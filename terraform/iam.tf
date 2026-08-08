# --------------------------------------------------------------------
# Least-privilege IAM: two dedicated service accounts (one per caller
# of the Dataform API — Airflow and Cloud Build) scoped to the Dataform
# *repository* only, plus the Dataform Service Agent, which is the
# identity Dataform actually uses to run BigQuery jobs, scoped to the
# two datasets it needs. Nobody gets project-wide Editor/Owner.
# --------------------------------------------------------------------

# --- Caller 1: Composer/Airflow -----------------------------------------
# Identity the DAG in orchestration/dataform_orchestration_dag.py would
# run as, if deployed on a real Cloud Composer environment.
resource "google_service_account" "airflow_orchestrator" {
  account_id   = "airflow-dataform-trigger"
  display_name = "Airflow -> Dataform orchestration (Composer worker identity)"
  project      = var.project_id
}

resource "google_dataform_repository_iam_member" "airflow_can_run_dataform" {
  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.olist_pipeline.name
  role       = "roles/dataform.editor" # needed to create compilation results & workflow invocations
  member     = "serviceAccount:${google_service_account.airflow_orchestrator.email}"
}

# --- Caller 2: Cloud Build -----------------------------------------------
# Identity the CI/CD pipeline in ../cloudbuild.yaml runs as. Kept
# separate from the default Cloud Build SA so this permission doesn't
# leak into unrelated builds in the same project.
resource "google_service_account" "cloud_build_pipeline" {
  account_id   = "cloudbuild-dataform-deploy"
  display_name = "Cloud Build -> Dataform validate & deploy"
  project      = var.project_id
}

resource "google_dataform_repository_iam_member" "cloud_build_can_run_dataform" {
  project    = var.project_id
  region     = var.region
  repository = google_dataform_repository.olist_pipeline.name
  role       = "roles/dataform.editor"
  member     = "serviceAccount:${google_service_account.cloud_build_pipeline.email}"
}

# Cloud Build's own logs bucket / build execution needs the standard
# Cloud Build Service Account role to run as a build actor.
resource "google_project_iam_member" "cloud_build_can_act_as_build_agent" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cloud_build_pipeline.email}"
}

# Required for a *custom* build service account to write build logs
# (see options.logging in ../cloudbuild.yaml) — without this the build
# fails immediately with a permission error on the logs bucket.
resource "google_project_iam_member" "cloud_build_can_write_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_build_pipeline.email}"
}

# --- Execution identity: the Dataform Service Agent ----------------------
# Dataform runs the compiled BigQuery jobs (staging tables + the
# incremental fact_order_items table, including assertions) as its own
# per-project service agent, not as the caller that triggered the
# workflow invocation. That agent is what needs BigQuery access —
# scoped to the two datasets this pipeline touches, nothing project-wide.
resource "google_bigquery_dataset_iam_member" "dataform_agent_edits_raw" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_bigquery_dataset_iam_member" "dataform_agent_edits_analytics" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "dataform_agent_runs_jobs" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}
