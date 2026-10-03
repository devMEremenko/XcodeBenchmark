"""Exercise the benchmark contract without running a real Xcode build."""

import os
from pathlib import Path
import shutil
import signal
import subprocess
import time
import sys
import pty
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class BenchmarkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / "bin"
        self.bin.mkdir()
        (self.work / "XcodeBenchmark.xcworkspace").mkdir()
        shutil.copy(ROOT / "benchmark.sh", self.work)
        if (ROOT / "scripts").exists():
            shutil.copytree(ROOT / "scripts", self.work / "scripts")
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")
        self.command("defaults", "exit 0")
        self.command("sw_vers", "echo 27.2")
        self.command("system_profiler", "echo 'Model Name: MacBook Pro'")
        self.command("sysctl", "echo 51539607552")
        self.command("diskutil", "exit 1")
        self.command("git", "echo fixture-revision")
        self.command("xcodebuild", """
if [ "$1" = -version ]; then echo 'Xcode 27.0'; exit 0; fi
while [ "$#" -gt 0 ]; do
    if [ "$1" = -derivedDataPath ]; then derived=$2; break; fi
    shift
done
if [ -e "$derived" ]; then echo 'Reused build data'; exit 99; fi
printf '%s\n' "$derived" >> build-paths
mkdir "$derived"
echo compiled > "$derived/product"
count=0
if [ -f count ]; then count=$(cat count); fi
count=$((count + 1))
echo "$count" > count
if [ "${FAIL_RUN:-0}" = "$count" ]; then exit 65; fi
duration=${BUILD_DURATION:-178.4}
if [ "${MISSING_TIME:-0}" = "$count" ]; then
    echo '** BUILD SUCCEEDED **'
else
    echo "** BUILD SUCCEEDED ** [$duration sec]"
    if [ "${DUPLICATE_TIME:-0}" = "$count" ]; then
        echo "** BUILD SUCCEEDED ** [$duration sec]"
    fi
fi
""")

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def run_benchmark(self, **variables):
        result = subprocess.run(
            ["sh", "benchmark.sh"], cwd=self.work,
            env=dict(self.env, **variables), capture_output=True, text=True,
            timeout=20,
        )
        self.assertEqual(list(self.work.glob(".xcodebenchmark.*")), [])
        return result

    def test_fresh_build_and_result_summary(self):
        (self.work / "DerivedData").mkdir()
        (self.work / "DerivedData" / "stale").touch()
        result = self.run_benchmark()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.work / "count").read_text().strip(), "1")
        self.assertTrue((self.work / "DerivedData" / "stale").exists())
        derived = Path((self.work / "build-paths").read_text().strip())
        self.assertEqual(derived.parent.parent.resolve(), self.work.resolve())
        self.assertTrue(derived.parent.name.startswith(".xcodebenchmark."))
        for line in ("Build Time: 178 sec (178.4 sec)",
                     "Benchmark revision: fixture-revision",
                     "Repository: https://github.com/devMEremenko/XcodeBenchmark",
                     "Memory: 48 GB", "macOS: 27.2", "Xcode 27.0"):
            self.assertIn(line, result.stdout)
        self.assertNotIn("Time(sec) for ReadMe.md:", result.stdout)
        self.assertLess(result.stdout.index("Benchmark revision: fixture-revision"),
                        result.stdout.index("✅ XcodeBenchmark has completed"))
        self.assertLess(result.stdout.index("✅ XcodeBenchmark has completed"),
                        result.stdout.index("Build Time: 178 sec (178.4 sec)"))
        self.assertLess(result.stdout.index("Build Time: 178 sec (178.4 sec)"),
                        result.stdout.index("Started:"))

    def test_duration_rounds_up_at_half_a_second(self):
        result = self.run_benchmark(BUILD_DURATION="178.5")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Build Time: 179 sec (178.5 sec)", result.stdout)

    def test_runs_use_distinct_build_directories(self):
        self.assertEqual(self.run_benchmark().returncode, 0)
        self.assertEqual(self.run_benchmark().returncode, 0)
        paths = (self.work / "build-paths").read_text().splitlines()
        self.assertEqual(len(set(paths)), 2)

    def test_failure_stops_without_reporting_result(self):
        result = self.run_benchmark(FAIL_RUN="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.work / "count").read_text().strip(), "1")
        self.assertNotIn("Time: ", result.stdout)

    def test_missing_duration_stops_without_reporting_result(self):
        result = self.run_benchmark(MISSING_TIME="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Time: ", result.stdout)

    def test_zero_duration_is_rejected(self):
        result = self.run_benchmark(BUILD_DURATION="0")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Time: ", result.stdout)

    def test_ambiguous_duration_stops_without_reporting_result(self):
        result = self.run_benchmark(DUPLICATE_TIME="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Time: ", result.stdout)

    def test_log_capture_failure_stops_without_reporting_result(self):
        self.command("tee", 'cat > "$1"; exit 1')
        result = self.run_benchmark()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Time: ", result.stdout)

    def test_terminal_ctrl_c_reaches_build_as_sigint(self):
        self.command("xcodebuild", f'''trap '' TERM
trap 'echo stopped > stopped; exit 130' INT
echo $$ > child-pid
"{sys.executable}" -c 'import os; assert os.isatty(0); assert os.tcgetpgrp(0) == os.getpgrp()' || exit 99
echo foreground > foreground
while :; do sleep 0.1; done
''')
        pid, terminal = pty.fork()
        if pid == 0:
            os.chdir(self.work)
            os.environ.update(self.env)
            os.execv('/bin/zsh', ['zsh', '-i', '-c', 'sh benchmark.sh; exit'])
        try:
            deadline = time.monotonic() + 5
            while not (self.work / "child-pid").exists():
                self.assertLess(time.monotonic(), deadline)
                time.sleep(0.02)
            deadline = time.monotonic() + 3
            while not (self.work / "foreground").exists() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue((self.work / "foreground").exists(), "build is not in terminal foreground")
            os.write(terminal, b'\x03')
            deadline = time.monotonic() + 2
            while not (self.work / "stopped").exists() and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue((self.work / "stopped").exists(), "Ctrl+C did not send SIGINT to build")
            deadline = time.monotonic() + 3
            while list(self.work.glob(".xcodebenchmark.*")) and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertEqual(list(self.work.glob(".xcodebenchmark.*")), [])
        finally:
            if (self.work / "child-pid").exists():
                try:
                    os.kill(int((self.work / "child-pid").read_text()), signal.SIGKILL)
                except ProcessLookupError:
                    pass
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)
            os.close(terminal)

    def test_missing_workspace_does_not_delete_existing_data(self):
        (self.work / "XcodeBenchmark.xcworkspace").rmdir()
        (self.work / "DerivedData").mkdir()
        result = subprocess.run(["sh", "benchmark.sh"], cwd=self.work,
                                env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.work / "DerivedData").exists())


if __name__ == "__main__":
    unittest.main()
