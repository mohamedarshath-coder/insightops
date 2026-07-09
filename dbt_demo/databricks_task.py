import os, subprocess, sys
from datetime import datetime, timezone

REPO_URL = "https://<GITHUB_TOKEN>@github.com/mohamedarshath-coder/insightops.git"
WORK_DIR = "/tmp/insightops_demo_run"
DBT_DIR  = f"{WORK_DIR}/lv_insightops/dbt_demo"
JOB_NAME = "insightops_dbt_demo_pipeline"

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
print(f"Job: {JOB_NAME} | Run: {run_id} | {datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")}")

print("Installing dbt-snowflake...")
rc, out = run(f"{sys.executable} -m pip install dbt-snowflake==1.7.* --quiet")
if rc != 0:
    raise RuntimeError("dbt install failed")

print("Cloning repo (depth=2)...")
run(f"rm -rf {WORK_DIR}")
rc, out = run(f"git clone --depth=2 {REPO_URL} {WORK_DIR}/lv_insightops")
if rc != 0:
    raise RuntimeError("git clone failed")

print("Running dbt...")
rc, _ = run(
    f"{sys.executable} -m dbt run --profiles-dir . --project-dir .",
    cwd=DBT_DIR,
    env={"SNOWFLAKE_PASSWORD": os.environ.get("SNOWFLAKE_PASSWORD", ""),
         "DBT_PROFILES_DIR": DBT_DIR}
)
if rc != 0:
    raise RuntimeError(f"dbt failed — exit code {rc}")
print("dbt run complete")
