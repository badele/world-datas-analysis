"""Unit tests for the fault-tolerant Vigilo downloader."""

import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, call, patch

import requests


sys.path.insert(0, str(Path(__file__).parents[1] / "importer"))

import vigilo


class VigiloDownloadTests(unittest.TestCase):
    """Check that individual Vigilo download failures do not abort the run."""

    def response(self, payload, status_code=200, text=None):
        """Build a fake requests.Response object for a controlled test case."""
        response = Mock()
        response.status_code = status_code
        response.text = text if text is not None else json.dumps(payload)
        response.json.return_value = payload
        if status_code >= 400:
            from requests.exceptions import HTTPError

            response.raise_for_status.side_effect = HTTPError(
                f"HTTP {status_code}"
            )
        return response

    # Replace the network call so the test does not access Vigilo.
    # Replace print because the failure is expected and is asserted below.
    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_failed_city_does_not_stop_other_cities(self, get, print_mock):
        """Keep the successful city when another city has a network failure."""
        city_list = {
            "Good city": {
                "prod": True,
                "scope": "good",
                "api_path": "https://good.example",
            },
            "Broken city": {
                "prod": True,
                "scope": "broken",
                "api_path": "https://broken.example",
            },
        }
        scope = {"cities": [{"id": 1}]}
        # The first three calls are: city list, successful scope, observations.
        # The fourth call simulates a connection failure for the broken city.
        responses = [
            self.response(city_list),
            self.response(scope),
            self.response({"observations": []}),
        ]
        get.side_effect = responses + [requests.exceptions.ConnectionError("offline")]

        with tempfile.TemporaryDirectory() as directory:
            # Redirect generated files to a temporary directory.
            with patch("vigilo.provider", "vigilo"), patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            scopes = json.loads(Path(directory, "scopes.json").read_text())
            failures = json.loads(
                Path(directory, "download_failures.json").read_text()
            )

        self.assertEqual(len(scopes), 1)
        self.assertEqual(scopes[0]["name"], "Good city")
        self.assertEqual(len(failures), 1)
        self.assertEqual(failures[0]["name"], "Broken city")
        print_mock.assert_called_once()

    # Simulate an invalid API response without producing expected error output.
    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_invalid_scope_json_is_recorded(self, get, print_mock):
        """Record a malformed scope response and continue without crashing."""
        city_list = {
            "Broken city": {
                "prod": True,
                "scope": "broken",
                "api_path": "https://broken.example",
            }
        }
        invalid_response = self.response(None, text="not json")
        # requests raises a JSON decoding error when response.json() is called.
        invalid_response.json.side_effect = ValueError("invalid json")
        get.side_effect = [self.response(city_list), invalid_response]

        with tempfile.TemporaryDirectory() as directory:
            # Redirect generated files to a temporary directory.
            with patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            failures = json.loads(
                Path(directory, "download_failures.json").read_text()
            )

        self.assertEqual(failures[0]["name"], "Broken city")
        self.assertEqual(failures[0]["error"], "ValueError")
        print_mock.assert_called_once()


class VigiloObservationsBackupTests(unittest.TestCase):
    """Test backup and restore of historical observation partitions."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.orig_cwd = os.getcwd()
        os.chdir(self.tmpdir)
        os.makedirs("dataset/vigilo", exist_ok=True)
        os.makedirs("downloaded/vigilo", exist_ok=True)

    def tearDown(self):
        os.chdir(self.orig_cwd)
        shutil.rmtree(self.tmpdir)

    def _make_partition(self, base, scopeid, content=b"fake"):
        p = Path(base) / f"scopeid={scopeid}"
        p.mkdir(parents=True, exist_ok=True)
        (p / "0.parquet").write_bytes(content)

    def test_save_observations_copies_all_partitions(self):
        """All existing scope partitions are copied to the backup location."""
        self._make_partition("dataset/vigilo/observations.parquet", "13_aix")
        self._make_partition("dataset/vigilo/observations.parquet", "44_nantes")

        vigilo._save_observations_historical()

        hist = Path("downloaded/vigilo/observations_historical")
        self.assertTrue((hist / "scopeid=13_aix").exists())
        self.assertTrue((hist / "scopeid=44_nantes").exists())

    def test_save_observations_noop_when_no_current_data(self):
        """No error when observations.parquet does not exist yet (first run)."""
        vigilo._save_observations_historical()
        self.assertFalse(Path("downloaded/vigilo/observations_historical").exists())

    def test_save_observations_replaces_stale_backup(self):
        """A stale backup from a previous run is replaced, not merged."""
        stale = Path("downloaded/vigilo/observations_historical/scopeid=old_stale")
        stale.mkdir(parents=True)
        self._make_partition("dataset/vigilo/observations.parquet", "13_aix")

        vigilo._save_observations_historical()

        hist = Path("downloaded/vigilo/observations_historical")
        self.assertFalse((hist / "scopeid=old_stale").exists())
        self.assertTrue((hist / "scopeid=13_aix").exists())

    def test_restore_copies_inactive_scope_partitions(self):
        """Partitions absent from the new SQL output are restored from backup."""
        self._make_partition(
            "downloaded/vigilo/observations_historical", "13_aix", b"historical"
        )
        self._make_partition(
            "downloaded/vigilo/observations_historical", "44_nantes", b"historical"
        )
        # SQL only wrote nantes (active scope); aix is inactive
        self._make_partition("dataset/vigilo/observations.parquet", "44_nantes", b"new")

        vigilo._restore_historical_observations()

        obs = Path("dataset/vigilo/observations.parquet")
        self.assertTrue((obs / "scopeid=13_aix").exists(), "inactive scope should be restored")
        self.assertEqual(
            (obs / "scopeid=44_nantes" / "0.parquet").read_bytes(),
            b"new",
            "active scope partition must not be overwritten",
        )

    def test_restore_noop_when_no_backup(self):
        """No error when there is no historical backup (first run)."""
        Path("dataset/vigilo/observations.parquet").mkdir(parents=True)
        vigilo._restore_historical_observations()  # must not raise


class VigiloScopesBackupTests(unittest.TestCase):
    """Test that _save_scopes_historical generates the correct DuckDB SQL."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.orig_cwd = os.getcwd()
        os.chdir(self.tmpdir)
        os.makedirs("dataset/vigilo", exist_ok=True)
        os.makedirs("downloaded/vigilo", exist_ok=True)
        os.makedirs("db", exist_ok=True)
        Path("db/wda.duckdb").touch()

    def tearDown(self):
        os.chdir(self.orig_cwd)
        shutil.rmtree(self.tmpdir)

    def _capture_sql_calls(self, returncode_sequence):
        """Return (side_effect, captured) where captured accumulates SQL from temp files."""
        captured = []
        codes = iter(returncode_sequence)

        def _side_effect(cmd, **kwargs):
            if "< " in cmd:
                sql_path = cmd.split("< ")[1]
                try:
                    captured.append(Path(sql_path).read_text())
                except FileNotFoundError:
                    captured.append("")
            return Mock(returncode=next(codes, 0))

        return _side_effect, captured

    def test_empty_parquet_created_when_no_current_scopes(self):
        """An empty historical parquet with the correct schema is created on first run."""
        side_effect, captured = self._capture_sql_calls([0])
        with patch("vigilo.subprocess.run", side_effect=side_effect):
            vigilo._save_scopes_historical()

        self.assertEqual(len(captured), 1)
        self.assertIn("CREATE OR REPLACE TABLE _h", captured[0])
        self.assertIn("is_active BOOLEAN", captured[0])
        self.assertIn("first_seen_at DATE", captured[0])

    def test_migration_adds_tracking_columns_with_default_date(self):
        """Old-schema scopes.parquet gets is_active=false and the migration date."""
        Path("dataset/vigilo/scopes.parquet").write_bytes(b"old_parquet")
        # returncode=1 → schema check fails (old schema); returncode=0 → COPY succeeds
        side_effect, captured = self._capture_sql_calls([1, 0])
        with patch("vigilo.subprocess.run", side_effect=side_effect):
            vigilo._save_scopes_historical()

        copy_sql = captured[-1]
        self.assertIn("false AS is_active", copy_sql)
        self.assertIn(vigilo.MIGRATION_DATE, copy_sql)

    def test_new_schema_passes_tracking_columns_through(self):
        """New-schema scopes.parquet (already has tracking cols) is copied as-is."""
        Path("dataset/vigilo/scopes.parquet").write_bytes(b"new_parquet")
        # returncode=0 → schema check passes (new schema); returncode=0 → COPY succeeds
        side_effect, captured = self._capture_sql_calls([0, 0])
        with patch("vigilo.subprocess.run", side_effect=side_effect):
            vigilo._save_scopes_historical()

        copy_sql = captured[-1]
        self.assertIn("is_active, first_seen_at, last_seen_at", copy_sql)
        self.assertNotIn("false AS is_active", copy_sql)


if __name__ == "__main__":
    unittest.main()
