# GCS bucket that receives the raw Olist CSV extracts (the "ingestion"
# layer referenced in the README) before BigQuery load jobs pick them up.

resource "google_storage_bucket" "raw_data" {
  name     = var.raw_data_bucket_name
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  # Raw extracts are a portfolio dataset (public Olist Kaggle data), not
  # PII — 30 days is enough to keep a short recovery window without
  # holding data indefinitely.
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = var.labels
}
