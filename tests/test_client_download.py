import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ClientDownloadTest(unittest.TestCase):
    def run_download(self, failure=0, custom_url=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("client.sh", "client-version.txt"):
                shutil.copyfile(ROOT / name, root / name)
            executable = root / "wget"
            executable.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "log = Path(os.environ['DOWNLOAD_TEST_LOG'])\n"
                "calls = json.loads(log.read_text()) if log.exists() else []\n"
                "calls.append(sys.argv[1:]); log.write_text(json.dumps(calls))\n"
                "if len(calls) == 1: sys.exit(int(os.environ['DOWNLOAD_TEST_FAILURE']))\n"
            )
            executable.chmod(0o755)
            env = dict(os.environ)
            env.update(
                PATH=str(root) + os.pathsep + env["PATH"],
                DOWNLOAD_TEST_LOG=str(root / "calls.json"),
                DOWNLOAD_TEST_FAILURE=str(failure),
                CLIENT_DOWNLOAD_DIR=str(root / "public"),
                WEBLITE_DOWNLOAD_DIR=str(root / "applets"),
            )
            env.pop("CLIENT_RELEASE_URL", None)
            env.pop("WEBLITE_RELEASE_URL", None)
            if custom_url:
                env["CLIENT_RELEASE_URL"] = "https://mirror.example.invalid/releases"
            process = subprocess.run(["sh", str(root / "client.sh")], env=env, capture_output=True)
            return process.returncode, json.loads((root / "calls.json").read_text())

    def test_normal_downloads_have_no_tls_override(self):
        code, calls = self.run_download()
        self.assertEqual(code, 0)
        self.assertEqual(len(calls), 3)
        self.assertTrue(all("--https-only" in call for call in calls))
        self.assertFalse(any("--secure-protocol=TLSv1_2" in call for call in calls))

    def test_network_retry_keeps_exact_official_url_and_target(self):
        code, calls = self.run_download(4)
        self.assertEqual(code, 0)
        self.assertEqual(len(calls), 4)
        self.assertIn("--secure-protocol=TLSv1_2", calls[1])
        self.assertEqual(calls[0][-1], calls[1][-1])
        target = lambda call: next(arg for arg in call if arg.startswith("--output-document="))
        self.assertEqual(target(calls[0]), target(calls[1]))
        self.assertNotIn("--no-check-certificate", calls[1])

    def test_certificate_authentication_and_http_failures_are_not_retried(self):
        for failure in (5, 6, 8):
            with self.subTest(failure=failure):
                code, calls = self.run_download(failure)
                self.assertEqual(code, failure)
                self.assertEqual(len(calls), 1)

    def test_custom_mirror_does_not_get_tls_fallback(self):
        code, calls = self.run_download(4, custom_url=True)
        self.assertEqual(code, 4)
        self.assertEqual(len(calls), 1)


if __name__ == "__main__":
    unittest.main()
