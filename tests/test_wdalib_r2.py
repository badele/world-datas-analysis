"""Unit tests for wdalib.uploadToR2 and wdalib.downloadFromR2."""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, call, patch

sys.path.insert(0, str(Path(__file__).parents[1] / "importer"))

import wdalib

_R2_CREDS = {
    "CF_ACCOUNT_ID": "test-account",
    "CF_R2_ACCESS_KEY_ID": "test-key",
    "CF_R2_SECRET_ACCESS_KEY": "test-secret",
}


def _make_boto_client(r2_objects=None):
    """Return a mock boto3 client with an empty or given R2 object listing."""
    client = MagicMock()
    paginator = MagicMock()
    client.get_paginator.return_value = paginator
    contents = [{"Key": k, "Size": s} for k, s in (r2_objects or {}).items()]
    paginator.paginate.return_value = [{"Contents": contents}]
    return client


# ---------------------------------------------------------------------------
# uploadToR2
# ---------------------------------------------------------------------------


class UploadToR2Tests(unittest.TestCase):
    def _run_upload(self, dataset, mock_client, extra_env=None):
        env = {**_R2_CREDS, **(extra_env or {})}
        with patch("boto3.client", return_value=mock_client), patch.dict(os.environ, env):
            wdalib.uploadToR2(dataset)

    def test_flattening_slash_to_double_underscore(self):
        """raw/observations.parquet → {dataset}/raw__observations.parquet"""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                parquet = Path("dataset/vigilo/raw/observations.parquet")
                parquet.parent.mkdir(parents=True)
                parquet.write_bytes(b"PAR1fake")

                client = _make_boto_client()
                self._run_upload("vigilo", client)

                put_calls = [c for c in client.put_object.call_args_list]
                keys = [c.kwargs["Key"] for c in put_calls]
                self.assertIn("vigilo/raw__observations.parquet", keys)
            finally:
                os.chdir(orig)

    def test_equals_replaced_by_dot_in_hive_partition(self):
        """raw/section_id=A/data.parquet → vigilo/raw__section_id.A__data.parquet"""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                parquet = Path("dataset/vigilo/raw/section_id=A/data.parquet")
                parquet.parent.mkdir(parents=True)
                parquet.write_bytes(b"PAR1fake")

                client = _make_boto_client()
                self._run_upload("vigilo", client)

                keys = [c.kwargs["Key"] for c in client.put_object.call_args_list]
                self.assertIn("vigilo/raw__section_id.A__data.parquet", keys)
            finally:
                os.chdir(orig)

    def test_manifest_uploaded_after_files(self):
        """manifest-{dataset}.json is uploaded and contains correct flat→rel mapping."""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                parquet = Path("dataset/vigilo/raw/scopes.parquet")
                parquet.parent.mkdir(parents=True)
                parquet.write_bytes(b"PAR1fake")

                client = _make_boto_client()
                self._run_upload("vigilo", client)

                manifest_call = next(
                    c for c in client.put_object.call_args_list
                    if c.kwargs["Key"] == "vigilo/manifest-vigilo.json"
                )
                manifest = json.loads(manifest_call.kwargs["Body"])
                self.assertEqual(manifest["raw__scopes.parquet"], "raw/scopes.parquet")
            finally:
                os.chdir(orig)

    def test_skip_file_when_r2_size_matches(self):
        """A file whose size already matches R2 is not re-uploaded."""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                parquet = Path("dataset/vigilo/raw/scopes.parquet")
                parquet.parent.mkdir(parents=True)
                parquet.write_bytes(b"PAR1fake")

                r2_objects = {"vigilo/raw__scopes.parquet": len(b"PAR1fake")}
                client = _make_boto_client(r2_objects)
                self._run_upload("vigilo", client)

                keys = [c.kwargs["Key"] for c in client.put_object.call_args_list]
                self.assertNotIn("vigilo/raw__scopes.parquet", keys)
                self.assertIn("vigilo/manifest-vigilo.json", keys)
            finally:
                os.chdir(orig)

    def test_stale_r2_keys_deleted(self):
        """R2 keys that no longer exist locally trigger delete_objects."""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                parquet = Path("dataset/vigilo/raw/scopes.parquet")
                parquet.parent.mkdir(parents=True)
                parquet.write_bytes(b"PAR1fake")

                r2_objects = {
                    "vigilo/raw__scopes.parquet": 0,
                    "vigilo/raw__old_file.parquet": 9999,
                }
                client = _make_boto_client(r2_objects)
                self._run_upload("vigilo", client)

                client.delete_objects.assert_called_once()
                deleted = client.delete_objects.call_args.kwargs["Delete"]["Objects"]
                deleted_keys = [d["Key"] for d in deleted]
                self.assertIn("vigilo/raw__old_file.parquet", deleted_keys)
                self.assertNotIn("vigilo/raw__scopes.parquet", deleted_keys)
            finally:
                os.chdir(orig)

    def test_missing_credentials_raises(self):
        """Raises RuntimeError when R2 credentials are absent."""
        env = {k: v for k, v in os.environ.items()
               if k not in ("CF_ACCOUNT_ID", "CF_R2_ACCESS_KEY_ID", "CF_R2_SECRET_ACCESS_KEY")}
        with patch.dict(os.environ, env, clear=True):
            with self.assertRaises(RuntimeError, msg="should raise without credentials"):
                wdalib.uploadToR2("vigilo")

    def test_no_parquet_files_returns_early(self):
        """Returns without calling boto3 if no parquet files exist."""
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                Path("dataset/vigilo/raw").mkdir(parents=True)

                with patch("boto3.client") as mock_boto3_client, \
                     patch.dict(os.environ, _R2_CREDS):
                    wdalib.uploadToR2("vigilo")
                    mock_boto3_client.assert_not_called()
            finally:
                os.chdir(orig)


# ---------------------------------------------------------------------------
# downloadFromR2
# ---------------------------------------------------------------------------


class DownloadFromR2Tests(unittest.TestCase):
    _ENV = {"WDA_PUBLIC_DATASET_URL": "https://pub.example.r2.dev"}

    def _manifest_response(self, manifest):
        r = MagicMock()
        r.status_code = 200
        r.raise_for_status = MagicMock()
        r.json.return_value = manifest
        return r

    def _file_response(self, content=b"PAR1fake"):
        r = MagicMock()
        r.status_code = 200
        r.raise_for_status = MagicMock()
        r.iter_content.return_value = [content]
        return r

    def test_files_written_to_from_r2_subdir(self):
        """Parquet files are written to downloaded/{dataset}/from_r2/raw/."""
        manifest = {
            "raw__scopes.parquet": "raw/scopes.parquet",
            "raw__observations.parquet": "raw/observations.parquet",
        }
        responses = [
            self._manifest_response(manifest),
            self._file_response(),
            self._file_response(),
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                with patch("requests.get", side_effect=responses), \
                     patch.dict(os.environ, self._ENV):
                    wdalib.downloadFromR2("vigilo", subdir="raw")

                self.assertTrue(Path("downloaded/vigilo/from_r2/raw/scopes.parquet").exists())
                self.assertTrue(Path("downloaded/vigilo/from_r2/raw/observations.parquet").exists())
            finally:
                os.chdir(orig)

    def test_manifest_url_constructed_correctly(self):
        """Manifest URL uses WDA_PUBLIC_DATASET_URL + dataset prefix."""
        r404 = MagicMock()
        r404.status_code = 404
        r404.raise_for_status = MagicMock()

        with patch("requests.get", return_value=r404) as mock_get, \
             patch.dict(os.environ, self._ENV):
            wdalib.downloadFromR2("vigilo")

        mock_get.assert_called_once_with(
            "https://pub.example.r2.dev/vigilo/manifest-vigilo.json",
            timeout=30,
        )

    def test_observable_files_excluded_when_subdir_raw(self):
        """observable/ files are not downloaded when subdir='raw'."""
        manifest = {
            "raw__scopes.parquet": "raw/scopes.parquet",
            "observable__map.parquet": "observable/map.parquet",
        }
        responses = [self._manifest_response(manifest), self._file_response()]
        with tempfile.TemporaryDirectory() as tmpdir:
            orig = os.getcwd()
            os.chdir(tmpdir)
            try:
                with patch("requests.get", side_effect=responses), \
                     patch.dict(os.environ, self._ENV):
                    wdalib.downloadFromR2("vigilo", subdir="raw")

                self.assertTrue(Path("downloaded/vigilo/from_r2/raw/scopes.parquet").exists())
                self.assertFalse(Path("downloaded/vigilo/from_r2/observable/map.parquet").exists())
            finally:
                os.chdir(orig)

    def test_missing_manifest_404_returns_gracefully(self):
        """A 404 on the manifest does not raise, just prints a warning."""
        r = MagicMock()
        r.status_code = 404
        r.raise_for_status = MagicMock()

        with patch("requests.get", return_value=r), \
             patch.dict(os.environ, self._ENV):
            wdalib.downloadFromR2("vigilo")  # must not raise

    def test_missing_env_var_raises(self):
        """Raises RuntimeError when WDA_PUBLIC_DATASET_URL is not set."""
        env = {k: v for k, v in os.environ.items() if k != "WDA_PUBLIC_DATASET_URL"}
        with patch.dict(os.environ, env, clear=True):
            with self.assertRaises(RuntimeError):
                wdalib.downloadFromR2("vigilo")


if __name__ == "__main__":
    unittest.main()
