
/

Thought for 41s
Thought for 41s
Given the timestamp genuinely says August 6th, and you're telling me this is the newest entry in this log group — that tells me something important: this specific Lambda hasn't been invoked again since August 6th. Today's job failure never reached it.

Look closely at what this Aug 6 event actually is — it's a raw HTTP POST, sent via Python's requests library, originating from inside your Databricks cluster itself (X-Forwarded-For: 48.216.242.208, that's your cluster's outbound IP), with a hardcoded-looking payload: "job_name": "insightops_dbt_demo_pipeline", "run_id": "RunId(601541960971220)".

This isn't coming from Databricks' native failure-notification system at all. This looks like a separate script or notebook — something running inside your workspace that manually captures dbt's output and POSTs it directly to this API Gateway endpoint. And critically: it's using the name insightops_dbt_demo_pipeline — the old, pre-existing job, not InsightOps Demo - Local.

My working theory: the old insightops_dbt_demo_pipeline job (the one we were told to leave alone) has its own separate mechanism that fires this exact webhook call whenever it fails — and it may be scheduled to run automatically, independent of anything we've been doing. Since it also connects to Snowflake and Snowflake is genuinely IP-blocked, it fails the same way every time, sending this same stale-looking payload to Slack — completely disconnected from our InsightOps Demo - Local job's real DuckDB success.

Two things to check:

Does the OLD job "insightops_dbt_demo_pipeline" have a schedule or trigger configured (under its "Schedules & Triggers" section)?
No schedule that I can see

Thought for 22s
Thought for 22s
Good, that rules out my "old job auto-triggering" theory. Let me reconsider what this actually tells us.

Look again at the Slack message for today's failure — it correctly shows today's real Run ID (189891812968188) and today's real timestamp (09:50:22). So something did correctly identify this specific run. It just fetched the wrong log content for it — the metadata is right, but the "logs" text is stale.

That points to a bug in exactly one place: the part of your Databricks Notifier Lambda that fetches the actual dbt output (likely from a DBFS file path) is pulling the wrong content — possibly a hardcoded or non-run-specific path that always returns the first-ever failed run's log (from Aug 6), rather than this run's actual output.

I can't see that Lambda's code from here — could you paste it again? (You shared it once, much earlier in this conversation — the one with DATABRICKS_INSTANCE, a TOKEN, and logic that calls the Databricks REST API to fetch run/task details and DBFS logs.) I want to look specifically at how it constructs the path or query it uses to fetch the log content, since that's almost certainly where this bug lives.

1787133718356_image.png
check


Thought for 20s
Thought for 20s
That's the confirmation I needed: this exact log group hasn't been touched since August 6th. This proves this particular Lambda is not the one producing today's Slack messages at all — something else is.

So there must be a different Lambda actually running today. Let's find it:

Go back to CloudWatch → Log groups (the top-level list, not inside this specific one)
You should see log groups for each of your 4 Lambdas — likely named something like /aws/lambda/insightsops-rca-engine, /aws/lambda/<router-name>, /aws/lambda/<databricks-notifier-name>, /aws/lambda/<snowflake-handler-name>
Click into each one and check its most recent log stream's "Last event time" — we're looking for one with an entry from today, around 09:50 UTC
Open that stream and paste what's in it
The one with today's timestamp is the Lambda that's actually processing your real job failures and posting to Slack — and that's the one with the bug we need to find. This log group you just showed me, despite its name/content looking relevant, simply isn't in today's execution path.

i guess ht eold the old insightops_dbt_demo_pipeline job (the one we were told to leave alone) has its own separate mechanism that fires this exact webhook call whenever it fails —


Thought for 48s
Thought for 48s
That's a very plausible explanation, and worth confirming directly rather than assuming. Even without a schedule, it could still fire if:

You (or someone) manually clicked Run now on insightops_dbt_demo_pipeline at some point today, alongside InsightOps Demo - Local — easy to do by accident since the names are so similar (we almost mixed them up earlier in this exact conversation)
It has its own "on failure" task/notebook (separate from a time-based schedule) that does the actual webhook POST itself — worth opening that job and checking its tasks for anything that looks like it captures dbt output and calls requests.post(...), rather than relying on Databricks' native notification system
Two quick checks:

Did you click Run now on insightops_dbt_demo_pipeline at any point today?
No, I only ran InsightOps Demo - Local

Thought for 12s
Thought for 12s
Good, that rules out the "separate old job" theory. And actually, re-checking the details makes the picture much clearer: the Slack message's Run ID and timestamp were correct for today's real run (189891812968188, 09:50:22) — only the error content inside it was stale. That's an important distinction.

This tells us definitively: it's not a rogue old job. It's one specific Lambda — your Databricks Notifier Lambda (the one with DATABRICKS_INSTANCE and a TOKEN, that calls the Databricks REST API to fetch run details) — correctly identifying which run failed, but then fetching the wrong log content for it. That's a real, specific bug: it's pulling a stale/cached/wrong log source instead of this run's actual DBFS output.

The CloudWatch log group you found is a different Lambda (the router, based on that "Direct notebook payload detected" print line) — that one's genuinely just idle since Aug 6, unrelated to this bug.

Two ways forward — pick whichever's easier:

Option A — find the right logs: Go back to CloudWatch → Log groups, and look for a Lambda whose name suggests it's the one that fetches Databricks run/task details (possibly named something like insightsops-databricks-notifier or similar). Check its most recent log stream — should show activity from today, ~09:50 UTC.

Option B — paste the code (faster): You shared this Lambda's source once, way back near the start — the one with DATABRICKS_INSTANCE = "https://adb-..." and a TOKEN variable, that does something like fetch run info → pull DBFS log path → read log content → forward to RCA engine. Paste that again and I'll read through its log-fetching logic directly and find exactly where it's grabbing the wrong content.

Option B will likely get us to the answer faster since I can inspect the actual logic rather than guessing from log output.

Yes — paste the Databricks Notifier Lambda's code specifically (the one with DATABRICKS_INSTANCE and TOKEN that fetches run details from the Databricks REST API and pulls the dbt log content — the second Lambda you shared way back, separate from the big RCA Engine one). That's the one I need to inspect to find where it's grabbing stale log content instead of today's actual output.


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines insightops_dbt_demo_pipeline Run 750525665209742 run_dbt_demo run Failed Output Exception: dbt failed (exit 2) 0.634s 1 # Cmd 1 import os, subprocess, sys, requests from datetime import datetime, tim

pasted

Message collapsed

Thought for 41s
Thought for 41s
Found it — genuinely, this explains everything. This old notebook does something our new script never does:

python
dbutils.fs.put("/tmp/insightops_dbt_logs.txt", dbt_logs, overwrite=True)
This writes dbt's failure output to a fixed, hardcoded file path on DBFS — not something unique per run, just always the same filename. And your InsightOps Demo - Local job runs on the same persistent cluster (Mohamed.Arshath's Personal Compute Cluster) that this old notebook presumably ran on before.

Here's the real mechanism, now it all fits together:

This old notebook, whenever it last ran and failed against Snowflake, wrote its error text to /tmp/insightops_dbt_logs.txt on that cluster's DBFS
Your Databricks Notifier Lambda — triggered correctly by Databricks' native on-failure webhook, which is why it gets today's correct run ID and timestamp — separately reads the actual log content from that same fixed DBFS path, not from something tied to the specific run
Our new databricks_task.py never writes anything to DBFS at all — so that file just sits there, untouched, still holding the old Snowflake error from whenever this notebook last ran
Every failure since then, regardless of the real cause, gets reported with that same stale content, because the Lambda is reading a file that never gets updated
That's the bug — not really "wrong" so much as an old mechanism our new script doesn't participate in.

The fix: add the same DBFS-write step to our current databricks_task.py, so it overwrites that same file with fresh content on every failure:


Failed
Failed


Your org is out of usage credits. We let your admin know.




Claude is AI and can make mistakes. Please double-check responses.
Artifacts

Databricks ui setup
Document · MD 

Insightops snowflake seed
Code · SQL 

Insightops demo script
Document · MD 

Demo scenario branches
ZIP 

Load duckdb
PY 

Insightops local test
ZIP 

Insightops baseline final
ZIP 

Seed dynamodb history
PY 
Project content
insight
Created by you

Add PDFs, documents, or other text to reference in this project.
Content
1787127049775_image.png
1787129122296_image.png
1787129307577_image.png
1787130592341_image.png
1787131117979_image.png
1787131459481_image.png
1787131544755_image.png
1787131754174_image.png
1787132672131_image.png
1787132703777_image.png
1787133718356_image.png

import boto3 import uuid import requests import json import http.client import base64 import os import hmac import hashlib import time import urllib from datetime import datetime, timedelta import urllib.parse from botocore.exceptions import ClientError import subprocess import re im

pasted


import json import requests import boto3 from datetime import datetime def lambda_handler(event, context): print("FULL EVENT:", json.dumps(event)) # Parse body from API Gateway body = json.loads(event['body']) print("PARSED BODY:", json.dumps(body)) # Use paren

pasted


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines InsightOps Demo - Local Run 173954205057174 Logs — Recent log files search All stdout stderr log4j Auto-fetch logs Log type Size stdout Standard output 164.43 KB Latest log log4j-activ

pasted


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines InsightOps Demo - Local Run 173954205057174 Logs — Recent log files search All stdout stderr log4j Auto-fetch logs Log type Size stdout Standard output 166.05 KB Latest log log4j-activ

pasted


onment Runtime Information Name Value Java Home /usr/lib/jvm/zulu21-ca-amd64 Java Version 21.0.11 (Azul Systems, Inc.) Scala Version version 2.13.16 Spark Properties Name Value databricks.data.unity.enabled true databricks.sqlgateway.history.queryParametersByteLimit 51200 libraryDownload

pasted


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines InsightOps Demo - Local Run 870660847507159 Logs — Recent log files search All stdout stderr log4j Auto-fetch logs Log type Size stdout Standard output 125.90 KB Latest log log4j-activ

pasted


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines InsightOps Demo - Local Run 870660847507159 Logs — Recent log files search All stdout stderr log4j Auto-fetch logs Log type Size stdout Standard output 157.27 KB Latest log log4j-activ

pasted


Databricks Job Failure Alert ━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Job Name:    InsightOps Demo - Local Run ID:      977356642270691 Cluster ID:  N/A Failed At:   2026-08-19 09:42:24 UTC Environment: PRODUCTION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Error Preview:❌ Task 'run_dbt_local' located at None failed with erro

pasted


o = 8 {product} {default} double SweeperThreshold = 15.000000 {product} {default} uintx TLABAllocationWeight = 35

pasted


Job: insightops_dbt_demo_pipeline | Run: demo-001 | Target: local | 2026-08-19 09:49 UTC {"packages": [{"name": "absl-py", "version": "2.3.1", "category": "runtime"}, {"name": "accelerate", "version": "1.11.0", "category": "runtime"}, {"name": "aiohappyeyeballs", "version": "2.4.4", "category": "ru

pasted


No older events at this moment. Retry 2026-08-06T04:25:27.429Z INIT_START Runtime Version: python:3.12.mainlinev2.v14 Runtime Version ARN: arn:aws:lambda:us-east-1::runtime:40182b778d40c8bdb13a6ef86990df74f5066cdb7d40aac1845f6f3fa5a1b20f 2026-08-06T04:25:27.885Z START RequestId: 19cdd3d4-e259-

pasted


2026-08-06T04:25:27.429Z INIT_START Runtime Version: python:3.12.mainlinev2.v14 Runtime Version ARN: arn:aws:lambda:us-east-1::runtime:40182b778d40c8bdb13a6ef86990df74f5066cdb7d40aac1845f6f3fa5a1b20f 2026-08-06T04:25:27.885Z START RequestId: 19cdd3d4-e259-497d-affd-328d0e15033f Version: $LATEST

pasted


Microsoft Azure Search data, notebooks, recents, and more... CTRL + P Jobs & Pipelines insightops_dbt_demo_pipeline Run 750525665209742 run_dbt_demo run Failed Output Exception: dbt failed (exit 2) 0.634s 1 # Cmd 1 import os, subprocess, sys, requests from datetime import datetime, tim

pasted

