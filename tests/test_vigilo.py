"""Unit tests for the fault-tolerant Vigilo downloader."""

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

import requests

sys.path.insert(0, str(Path(__file__).parents[1] / "importer"))

import vigilo


class VigiloDownloadTests(unittest.TestCase):
    """Check that individual Vigilo download failures do not abort the run."""

    def response(self, payload, status_code=200, text=None):
        """Build a fake requests.Response object for a controlled test case."""
        r = Mock()
        r.status_code = status_code
        r.text = text if text is not None else json.dumps(payload)
        r.json.return_value = payload
        if status_code >= 400:
            from requests.exceptions import HTTPError
            r.raise_for_status.side_effect = HTTPError(f"HTTP {status_code}")
        return r

    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_failed_city_does_not_stop_other_cities(self, get, print_mock):
        """Keep the successful city when another city has a network failure."""
        city_list = {
            "instances": [
                {"prod": True, "name": "Good city", "scope": "good", "api_path": "https://good.example"},
                {"prod": True, "name": "Broken city", "scope": "broken", "api_path": "https://broken.example"},
            ]
        }
        scope = {"cities": [{"id": 1}]}
        # Calls: check_result.json, good scope, good observations, broken scope (fails)
        get.side_effect = [
            self.response(city_list),
            self.response(scope),
            self.response({"observations": []}),
            requests.exceptions.ConnectionError("offline"),
        ]

        with tempfile.TemporaryDirectory() as directory:
            with patch("vigilo.provider", "vigilo"), patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            scopes = json.loads(Path(directory, "scopes.json").read_text())
            failures = json.loads(Path(directory, "download_failures.json").read_text())

        self.assertEqual(len(scopes), 1)
        self.assertEqual(scopes[0]["name"], "Good city")
        self.assertEqual(len(failures), 1)
        self.assertEqual(failures[0]["name"], "Broken city")
        print_mock.assert_called_once()

    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_invalid_scope_json_is_recorded(self, get, print_mock):
        """Record a malformed scope response and continue without crashing."""
        city_list = {
            "instances": [
                {"prod": True, "name": "Broken city", "scope": "broken", "api_path": "https://broken.example"},
            ]
        }
        invalid_response = self.response(None, text="not json")
        invalid_response.json.side_effect = ValueError("invalid json")
        get.side_effect = [self.response(city_list), invalid_response]

        with tempfile.TemporaryDirectory() as directory:
            with patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            failures = json.loads(Path(directory, "download_failures.json").read_text())

        self.assertEqual(failures[0]["name"], "Broken city")
        self.assertEqual(failures[0]["error"], "ValueError")
        print_mock.assert_called_once()

    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_nonprod_instances_are_skipped(self, get, _print_mock):
        """Instances with prod=False are ignored."""
        city_list = {
            "instances": [
                {"prod": False, "name": "Dev city", "scope": "dev", "api_path": "https://dev.example"},
            ]
        }
        get.side_effect = [self.response(city_list)]

        with tempfile.TemporaryDirectory() as directory:
            with patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            scopes = json.loads(Path(directory, "scopes.json").read_text())

        self.assertEqual(len(scopes), 0)

    @patch("vigilo.print")
    @patch("vigilo.requests.get")
    def test_citylist_failure_writes_empty_results(self, get, _print_mock):
        """A failure fetching check_result.json writes empty scopes and records the failure."""
        get.side_effect = requests.exceptions.ConnectionError("no network")

        with tempfile.TemporaryDirectory() as directory:
            with patch(
                "vigilo.wdalib.writeContentToFile",
                side_effect=lambda filename, content: Path(directory, Path(filename).name).write_text(content),
            ):
                vigilo.download_scopes()

            scopes = json.loads(Path(directory, "scopes.json").read_text())
            failures = json.loads(Path(directory, "download_failures.json").read_text())

        self.assertEqual(scopes, [])
        self.assertEqual(len(failures), 1)
        self.assertEqual(failures[0]["scope"], "citylist")


if __name__ == "__main__":
    unittest.main()
