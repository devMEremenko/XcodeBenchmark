---
name: xcodebenchmark-pr
description: Prepare an XcodeBenchmark result submission by collecting system information and editing ReadMe.md, then ask whether to create a GitHub PR.
---

# XcodeBenchmark PR creation

1. Ask only for the benchmark duration in seconds if it was not provided. The only other question allowed is whether to create a PR with the current diff in step 4.
2. Run `sh scripts/system-info.sh` from the repository root to collect system information using [system-info.sh](../../../scripts/system-info.sh).
3. Add the time and system details to the appropriate table in [ReadMe.md](../../../ReadMe.md), preserving its formatting and time ordering.
4. Show the current diff and ask whether the user wants to create a PR with it. If the user agrees, create a regular PR to `devMEremenko/XcodeBenchmark` (https://github.com/devMEremenko/XcodeBenchmark) with that diff, following [pull_request_template.md](../../../pull_request_template.md).
