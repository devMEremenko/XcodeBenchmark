"""Check nominal capacities and physical disk selection with macOS plist fixtures."""

import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SystemInfoTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")
        self.command("sw_vers", "echo 26.3")
        self.command("xcodebuild", "echo Xcode 26.3")
        self.command("system_profiler", "printf 'Model Name: MacBook Pro\\nModel Identifier: Mac16,8\\nChip: Apple M4 Pro\\nTotal Number of Cores: 12\\n'")
        self.command("sysctl", "echo ${RAM_BYTES:-51539607552}")
        self.command("df", "printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\\n/dev/disk3s1 100 10 90 10%% /\\n'")
        self.command("diskutil", """
if [ "$1" = apfs ]; then cat apfs.plist; exit 0; fi
case "$3" in
    /dev/disk3s1) cat volume.plist ;;
    disk0s2) cat store.plist ;;
    disk0) cat disk.plist ;;
    *) exit 1 ;;
esac
""")
        self.fixture("volume", {"APFSContainerReference": "disk3", "TotalSize": 100})
        self.fixture("apfs", {"Containers": [{"PhysicalStores": [{"DeviceIdentifier": "disk0s2"}]}]})
        self.fixture("store", {"ParentWholeDisk": "disk0", "TotalSize": 200})
        self.disk(494_384_795_648)

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def fixture(self, name, data):
        (self.work / f"{name}.plist").write_bytes(plistlib.dumps(data))

    def disk(self, size, media="APPLE SSD AP0512", solid_state=True):
        self.fixture("disk", {"TotalSize": size, "MediaName": media,
                              "SolidState": solid_state, "Internal": True})

    def collect(self, **variables):
        result = subprocess.run(["sh", str(ROOT / "scripts/system-info.sh")],
                                cwd=self.work, env=dict(self.env, **variables),
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def test_integer_ram_and_nominal_apple_capacities(self):
        for ram in (36, 48):
            # Simulate fractional reported capacity, without truncating to 35 GB.
            ram_bytes = str(int((ram - 0.05) * 1073741824))
            for size, label in ((494_384_795_648, "512 GB"),
                                (994_662_584_320, "1 TB"),
                                (2_000_398_934_016, "2 TB"),
                                (4_000_787_030_016, "4 TB")):
                with self.subTest(ram=ram, size=size):
                    self.disk(size)
                    output = self.collect(RAM_BYTES=ram_bytes)
                    self.assertIn(f"Memory: {ram} GB\n", output)
                    self.assertIn(f"Storage Capacity: {label}\n", output)
                    self.assertIn("Storage Type: SSD", output)

    def test_custom_500_gb_disk_is_not_mislabeled_512(self):
        self.disk(500_107_862_016, media="Third-party SSD")
        self.assertIn("Storage Capacity: 500 GB\n", self.collect())

    def test_device_cpu_and_versions_are_reported(self):
        output = self.collect()
        for line in ("macOS: 26.3", "Xcode 26.3", "Model Name: MacBook Pro",
                     "Model Identifier: Mac16,8", "Chip: Apple M4 Pro",
                     "Total Number of Cores: 12", "Storage Device: disk0",
                     "Storage Location: internal"):
            self.assertIn(line, output)

    def test_external_hdd_is_identified(self):
        self.fixture("disk", {"TotalSize": 2_000_398_934_016,
                              "MediaName": "External HDD", "SolidState": False,
                              "Internal": False})
        output = self.collect()
        self.assertIn("Storage Capacity: 2 TB", output)
        self.assertIn("Storage Type: HDD", output)
        self.assertIn("Storage Location: external", output)

    def test_unknown_storage_type_and_location_are_explicit(self):
        self.fixture("disk", {"TotalSize": 500_107_862_016})
        output = self.collect()
        self.assertIn("Storage Type: unknown", output)
        self.assertIn("Storage Location: unknown", output)

    def test_multiple_physical_stores_require_verification(self):
        self.fixture("apfs", {"Containers": [{"PhysicalStores": [
            {"DeviceIdentifier": "disk0s2"}, {"DeviceIdentifier": "disk1s2"}]}]})
        output = self.collect()
        self.assertIn("multiple physical stores", output)
        self.assertNotIn("Storage Capacity: 512 GB", output)

    def test_non_apfs_partition_uses_whole_disk(self):
        self.fixture("volume", {"ParentWholeDisk": "disk0", "TotalSize": 100})
        self.assertIn("Storage Capacity: 512 GB\n", self.collect())

    def test_missing_disk_and_ram_are_explicit(self):
        self.command("diskutil", "exit 1")
        output = self.collect(RAM_BYTES="unknown")
        self.assertIn("Memory: unavailable", output)
        self.assertIn("Storage Capacity: unavailable", output)


if __name__ == "__main__":
    unittest.main()
