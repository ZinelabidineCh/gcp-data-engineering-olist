"""
Dataform orchestration DAG — Olist ELT Pipeline (Phase 4).

Orchestrates the Dataform repository (staging tables + incremental
`fact_order_items`) defined under `definitions/` using the real
`apache-airflow-providers-google` Dataform operators, on a daily schedule.

Status
------
This DAG is written against the documented API of
`apache-airflow-providers-google>=10.9.0` and is syntax-consistent with it,
but it has **not** been executed against a live Cloud Composer environment.
There is no Composer environment provisioned for this portfolio project
(cost reasons). It is included as a design reference showing how this
Dataform pipeline *would* be orchestrated on Composer/Airflow in a
production setting, not as a component running in production today.

What it does, conceptually:
1. Trigger a compilation of the Dataform repository against the `main`
   branch (or a fixed release commit, depending on the repo's git
   settings) — equivalent to `dataform compile`.
2. Create a workflow invocation from that compilation result — equivalent
   to `dataform run`, executing the SQLX definitions in dependency order
   (staging tables -> incremental fact_order_items) including the
   assertions defined in each `.sqlx` file.
3. Wait for the workflow invocation to reach a terminal state, surfacing
   failures (including failed assertions) as a failed Airflow task.
"""

from __future__ import annotations

import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.dataform import (
    DataformCreateCompilationResultOperator,
    DataformCreateWorkflowInvocationOperator,
)
from airflow.providers.google.cloud.sensors.dataform import (
    DataformWorkflowInvocationStateSensor,
)
from airflow.utils.trigger_rule import TriggerRule

# --- Configuration -----------------------------------------------------
# Replace with your own values, or wire these to Airflow Variables /
# environment configuration in a real deployment.
GCP_PROJECT_ID = "your-gcp-project-id"
GCP_REGION = "europe-west1"
DATAFORM_REPOSITORY_ID = "olist-elt-pipeline"

# Git ref Dataform compiles from. In this project the repository is linked
# to GitHub (see terraform/dataform.tf), so this maps to a branch name.
GIT_COMMITISH = "workspace-v2"

default_args = {
    "owner": "zinelabidine-chiguer",
    "retries": 1,
    "retry_delay": datetime.timedelta(minutes=5),
}

with DAG(
    dag_id="olist_dataform_orchestration",
    description=(
        "Compiles and runs the Olist Dataform pipeline "
        "(staging -> fact_order_items) on BigQuery."
    ),
    default_args=default_args,
    schedule="0 5 * * *",  # daily at 05:00 UTC, ahead of BI refresh
    start_date=datetime.datetime(2026, 1, 1),
    catchup=False,
    tags=["dataform", "bigquery", "olist", "elt"],
) as dag:

    create_compilation_result = DataformCreateCompilationResultOperator(
        task_id="create_compilation_result",
        project_id=GCP_PROJECT_ID,
        region=GCP_REGION,
        repository_id=DATAFORM_REPOSITORY_ID,
        compilation_result={
            "git_commitish": GIT_COMMITISH,
        },
    )

    create_workflow_invocation = DataformCreateWorkflowInvocationOperator(
        task_id="create_workflow_invocation",
        project_id=GCP_PROJECT_ID,
        region=GCP_REGION,
        repository_id=DATAFORM_REPOSITORY_ID,
        workflow_invocation={
            "compilation_result": (
                "{{ task_instance.xcom_pull("
                "task_ids='create_compilation_result', key='return_value')"
                "['name'] }}"
            )
        },
        asynchronous=True,
    )

    wait_for_workflow_invocation = DataformWorkflowInvocationStateSensor(
        task_id="wait_for_workflow_invocation",
        project_id=GCP_PROJECT_ID,
        region=GCP_REGION,
        repository_id=DATAFORM_REPOSITORY_ID,
        workflow_invocation_id=(
            "{{ task_instance.xcom_pull("
            "task_ids='create_workflow_invocation', key='return_value')"
            "['name'].split('/')[-1] }}"
        ),
        expected_statuses={"SUCCEEDED"},
        failure_statuses={"FAILED", "CANCELLED"},
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    create_compilation_result >> create_workflow_invocation >> wait_for_workflow_invocation
