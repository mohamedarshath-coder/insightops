import os, subprocess, sys
from datetime import datetime, timezone

REPO_URL = "https://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@github.com/mohamedarshath-coder/insightops.git"
WORK_DIR = "/tmp/insightops_demo_run"
DBT_DIR  = f"{WORK_DIR}/lv_insightops/dbt_demo"
JOB_NAME = "insightops_dbt_demo_pipeline"

# Set env var DBT_TARGET=local on the Databricks job to run entirely on
# DuckDB (no Snowflake network access needed at all). Leave unset (or "dev")
# to use the original Snowflake path.
DBT_TARGET = os.environ.get("DBT_TARGET", "dev")

def run(cmd, cwd=None, env=None):
    merged = {**os.environ, **(env or {})}
    proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=merged,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            universal_newlines=True)
    lines = []
    for line in proc.stdout:
        print(line, end="")
        lines.append(line)
    proc.wait()
    return proc.returncode, "".join(lines)

run_id     = os.environ.get("DATABRICKS_RUN_ID",     "demo-001")
cluster_id = os.environ.get("DATABRICKS_CLUSTER_ID", "demo-cluster")
now_str    = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
print(f"Job: {JOB_NAME} | Run: {run_id} | Target: {DBT_TARGET} | {now_str}")

if DBT_TARGET == "local":
    print("Installing dbt-duckdb (no Snowflake network access required)...")
    rc, out = run(f"{sys.executable} -m pip install dbt-duckdb==1.11.* faker duckdb --quiet")
else:
    print("Installing dbt-snowflake...")
    rc, out = run(f"{sys.executable} -m pip install dbt-snowflake==1.7.* --quiet")
if rc != 0:
    raise RuntimeError("dbt/adapter install failed")

print("Cloning repo (depth=2)...")
run(f"rm -rf {WORK_DIR}")
rc, out = run(f"git clone --depth=2 {REPO_URL} {WORK_DIR}/lv_insightops")
if rc != 0:
    raise RuntimeError("git clone failed")

if DBT_TARGET == "local":
    print("Seeding local DuckDB warehouse with synthetic data...")
    rc, out = run(f"{sys.executable} load_duckdb.py", cwd=DBT_DIR)
    if rc != 0:
        raise RuntimeError("DuckDB seed step failed")

print("Running dbt...")
rc, _ = run(
    f"{sys.executable} -m dbt run --profiles-dir . --project-dir . --target {DBT_TARGET}",
    cwd=DBT_DIR,
    env={"SNOWFLAKE_PASSWORD": os.environ.get("SNOWFLAKE_PASSWORD", ""),
         "DBT_PROFILES_DIR": DBT_DIR}
)
if rc != 0:
    raise RuntimeError(f"dbt failed -- exit code {rc}")
print("dbt run complete")
