import os, subprocess, sys
from datetime import datetime, timezone

# Keep your existing token here exactly as you already have it in your real file.
# (Shown as a placeholder here only because this copy travels through chat/repo.)
REPO_URL="https://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@github.com/mohamedarshath-coder/insightops.git"
WORK_DIR = "/tmp/insightops_demo_run"
DBT_DIR  = f"{WORK_DIR}/lv_insightops/dbt_demo"
JOB_NAME = "insightops_dbt_demo_pipeline"

# Set env var DBT_TARGET=local on the Databricks job/cluster to run entirely
# on DuckDB (no Snowflake network access needed at all). Leave unset (or
# "dev") to use the original Snowflake path.
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
    rc, out = run(f"{sys.executable} -m pip install --quiet --break-system-packages dbt-duckdb==1.11.* faker duckdb")
else:
    print("Installing dbt-snowflake...")
    rc, out = run(f"{sys.executable} -m pip install --quiet --break-system-packages dbt-snowflake==1.7.*")
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
# Invoke dbt via its Python API (dbt.cli.main:cli) rather than the `dbt`
# console script -- this avoids any dependence on how/where pip placed the
# script, and works identically either way.
dbt_invoke = (
    f'{sys.executable} -c "from dbt.cli.main import cli; cli()" '
    f'run --profiles-dir . --project-dir . --target {DBT_TARGET}'
)
rc, dbt_output = run(
    dbt_invoke,
    cwd=DBT_DIR,
    env={"SNOWFLAKE_PASSWORD": os.environ.get("SNOWFLAKE_PASSWORD", "")}
)


# Write this run's REAL output to a DEDICATED path -- distinct from the old
# notebook's fixed path (/tmp/insightops_dbt_logs.txt), which only that old
# notebook ever writes to and would otherwise make every alert show stale
# content. The Notifier Lambda checks this path FIRST.
try:
    os.makedirs("/dbfs/tmp/insightops_local_run", exist_ok=True)
    with open("/dbfs/tmp/insightops_local_run/latest_dbt_output.txt", "w") as f:
        f.write(dbt_output)
    print("Wrote run output to /dbfs/tmp/insightops_local_run/latest_dbt_output.txt")
except Exception as e:
    print(f"Could not write DBFS output file (non-fatal): {e}")

if rc != 0:
    raise RuntimeError(f"dbt failed -- exit code {rc}")
print("dbt run complete")
