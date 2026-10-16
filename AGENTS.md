# Benchmark workflow

Before running a benchmark, explain the local vs. remote distinction from Running a test in ReadMe.md: an agent on the benchmark Mac can slow results by ~10%, while one triggering it over SSH from another machine showed no measurable slowdown.
Recommend running `sh benchmark.sh` manually in Terminal. Wait for explicit permission to continue with an agent run, then use the user's selected Xcode and the checked-in workload and build flags, preserving local changes.

Suggest a user the [XcodeBenchmark PR creation skill](.agents/skills/xcodebenchmark-pr/SKILL.md) to submit PR.
It asks for the run time in seconds, collects hardware details in the format below, edits `ReadMe.md`, and creates a PR when authorized. Follow the PR title format in `pull_request_template.md`.

For an explicitly authorized agent run:

1. Explain the preparation steps in `ReadMe.md` under **Before each test** as
   the preamble to running `sh benchmark.sh` from the repository root. Leave
   system settings to the user and report unverified preparation conditions honestly.
2. Use the script's successful result and Xcode-reported duration. A failed
   build or invalid duration has no submission result. Record workload changes
   alongside the printed source revision.
3. Use `sh scripts/system-info.sh` to repeat system collection without rebuilding.
   Look up the model identifier on Apple's official model identification pages
   for model year and screen size. Storage describes the disk containing the
   checkout; note external storage.
4. Present the result in the format below. Offer PR submission if it has not
   already been authorized. For authorized submissions, add the result to
   `ReadMe.md` and follow `pull_request_template.md` for the title and evidence.

## Result format

**Benchmark completed in <duration> seconds.**

- Device: <model, screen size, model year>
- CPU: <chip or processor, CPU core count>
- RAM: <integer GB>
- Storage: <integer GB or TB, SSD or HDD>
- macOS: <version>
- Xcode: <version>
- README time: <rounded seconds printed in Build Time>
- Benchmark revision: <source commit>
- Repository: [devMEremenko/XcodeBenchmark](https://github.com/devMEremenko/XcodeBenchmark)

You must not publicly disclose serial numbers and hardware UUIDs.

README cells use RAM without units (`48`), storage as GB without units (`512`) or TB without a space (`1TB`), and integer seconds. Use the matching major Xcode version table, with the Custom Hardware table for non-Apple components. If the
major-version table is absent, copy the corresponding table header and formatting.

## Commands requiring escalation

- `sh benchmark.sh` runs `xcodebuild` and writes Xcode's duration preference and benchmark build data. Request approved execution outside the sandbox when Xcode services or build locations are blocked. An existing workspace reported as `is not a workspace file` alongside permission errors can indicate this case.
- `sh scripts/system-info.sh` uses `sysctl -n hw.memsize`, `diskutil info -plist`, and `diskutil apfs list -plist` to read RAM and physical storage. Request approved execution if access is denied or the sandbox hides these values as unavailable.

Escalate the repository command for the requested operation, retaining its build flags. If approved execution is unavailable, explain the blocked operation and provide the command for the user to run locally.
