# Terraform — Olist ELT Pipeline infra

Provisions the GCP infrastructure this pipeline runs on:

| File | Provisions |
|---|---|
| `storage.tf` | GCS bucket for raw CSV extracts |
| `bigquery.tf` | `olist_raw_data` and `olist_analytics` datasets |
| `dataform.tf` | The GCP-managed Dataform repository, linked to this GitHub repo |
| `iam.tf` | Two purpose-built service accounts (Airflow, Cloud Build) scoped to the Dataform repository only, and dataset-level BigQuery access for the Dataform Service Agent — no project-wide roles |
| `cicd.tf` | The Cloud Build GitHub connection + push trigger running `../cloudbuild.yaml` |

## Status: written, not applied

This configuration is hand-written against the documented `hashicorp/google` provider (`~> 5.30`) resource schemas. **It has not been run through `terraform init/plan/apply`** — there's no `terraform` binary in the environment this was authored in, and applying it against a real project is a deliberate, billed action I'm not taking on your behalf without you running it yourself. Treat this as an IaC design you review and apply, not as infrastructure that already exists.

Two things need to happen once, manually, before `apply` will fully succeed:
1. Create the `dataform-github-pat` secret in Secret Manager (a GitHub PAT with `repo` scope) — kept out of Terraform state on purpose.
2. Install the Cloud Build GitHub App on this repo (`gcloud builds connections create github ...`) to get `github_app_installation_id` — see the note at the top of `cicd.tf`.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your real project_id, etc.
terraform init
terraform plan
terraform apply
```
