output "raw_data_bucket" {
  description = "GCS bucket receiving raw Olist CSV extracts."
  value       = google_storage_bucket.raw_data.name
}

output "raw_dataset_id" {
  value = google_bigquery_dataset.raw.dataset_id
}

output "analytics_dataset_id" {
  value = google_bigquery_dataset.analytics.dataset_id
}

output "dataform_repository_id" {
  value = google_dataform_repository.olist_pipeline.name
}

output "airflow_orchestrator_service_account" {
  description = "Service account email to grant to the Composer environment running orchestration/dataform_orchestration_dag.py."
  value       = google_service_account.airflow_orchestrator.email
}

output "cloud_build_pipeline_service_account" {
  description = "Service account email to set as the Cloud Build trigger's identity (see ../cloudbuild.yaml)."
  value       = google_service_account.cloud_build_pipeline.email
}
