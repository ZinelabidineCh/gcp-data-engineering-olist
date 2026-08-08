variable "project_id" {
  description = "GCP project ID hosting the pipeline. Set your own in terraform.tfvars — do not commit a real project ID."
  type        = string
  default     = "your-gcp-project-id"
}

variable "region" {
  description = "Region for regional resources (Dataform repository, Cloud Build triggers). Matches workflow_settings.yaml's defaultLocation."
  type        = string
  default     = "europe-west1"
}

variable "raw_data_bucket_name" {
  description = "GCS bucket receiving the raw Olist CSV extracts before they land in BigQuery (olist_raw_data)."
  type        = string
  default     = "your-gcp-project-id-olist-raw-data"
}

variable "raw_dataset_id" {
  description = "BigQuery dataset for raw/staged data (matches definitions/sources.js schema)."
  type        = string
  default     = "olist_raw_data"
}

variable "analytics_dataset_id" {
  description = "BigQuery dataset for the analytics layer (matches workflow_settings.yaml defaultDataset)."
  type        = string
  default     = "olist_analytics"
}

variable "dataform_repository_id" {
  description = "Dataform repository resource ID (matches orchestration/dataform_orchestration_dag.py's DATAFORM_REPOSITORY_ID)."
  type        = string
  default     = "olist-elt-pipeline"
}

variable "github_repo_url" {
  description = "HTTPS URL of this GitHub repository, used to link the Dataform repository to source control."
  type        = string
  default     = "https://github.com/ZinelabidineCh/olist-elt-pipeline-gcp-looker.git"
}

variable "github_default_branch" {
  description = "Branch Dataform compiles from by default."
  type        = string
  default     = "workspace-v2"
}

variable "github_pat_secret_id" {
  description = <<-EOT
    Name of the Secret Manager secret holding a GitHub Personal Access
    Token (repo scope) that Dataform uses to read this repository.
    The secret itself is NOT managed by this Terraform config on purpose —
    create it out-of-band (`gcloud secrets create ...`) so the token is
    never in state or in this repo.
  EOT
  type        = string
  default     = "dataform-github-pat"
}

variable "github_app_installation_id" {
  description = <<-EOT
    Installation ID of the Cloud Build GitHub App on this repository.
    Obtained from the one-time manual connection step (see cicd.tf) —
    `gcloud builds connections describe` after installing the app.
  EOT
  type        = string
  default     = ""
}

variable "labels" {
  description = "Common labels applied to resources that support them."
  type        = map(string)
  default = {
    project = "olist-elt-pipeline"
    phase   = "phase-4"
    managed = "terraform"
  }
}
