# Two datasets, matching the multi-tier layout described in the README
# and referenced in definitions/sources.js / workflow_settings.yaml.

resource "google_bigquery_dataset" "raw" {
  dataset_id  = var.raw_dataset_id
  project     = var.project_id
  location    = var.region
  description = "Landing zone for raw Olist tables loaded from GCS (orders_raw, items_raw, products_raw)."

  # Staging data — short retention, it's fully reproducible from GCS.
  default_table_expiration_ms = 7776000000 # 90 days

  labels = var.labels
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id  = var.analytics_dataset_id
  project     = var.project_id
  location    = var.region
  description = "Analytics layer: Dataform-built staging views/tables and the fact_order_items incremental table consumed by Looker Studio."

  labels = var.labels
}
