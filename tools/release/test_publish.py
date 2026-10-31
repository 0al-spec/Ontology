import hashlib
import io
import os
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch

import publish


class PublicationTests(unittest.TestCase):
    tag = "0.3.0"
    sha = "a" * 40

    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.area = Path(scratch.name)
        self.archives = [self.archive(p) for p in publish.PLATFORMS]

    def archive(self, platform, sha=None):
        root = f"ontologyc-{self.tag}-{platform}"
        path = self.area / (root + ".tar.gz")
        with tarfile.open(path, "w:gz") as tar:
            for name, content in [("ontologyc", b"test binary"),
                                  ("BUILD.txt", f"ref={self.tag}\ncommit={sha or self.sha}\nplatform={platform}\n".encode())]:
                info = tarfile.TarInfo(f"{root}/{name}")
                info.size = len(content)
                info.mode = 0o755 if name == "ontologyc" else 0o644
                tar.addfile(info, io.BytesIO(content))
        return path

    def test_checksums_match_downloadable_names_and_bytes(self):
        *archives, sums = publish.expected_files(self.area, self.tag, self.sha)
        self.assertEqual(sums.read_text().splitlines(), [
            f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}" for p in archives])

    def test_repeat_verification_accepts_only_matching_local_checksums(self):
        files = publish.expected_files(self.area, self.tag, self.sha)
        self.assertEqual(files, publish.expected_files(self.area, self.tag, self.sha))
        files[-1].write_text("stale")
        with self.assertRaisesRegex(ValueError, "stale local"):
            publish.expected_files(self.area, self.tag, self.sha)
        self.assertEqual(files[-1].read_text(), "stale")

    def test_wrong_revision_or_absent_platform_does_not_create_checksums(self):
        self.archive("macos-arm64", sha="b"*40)
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            publish.expected_files(self.area, self.tag, self.sha)
        self.archives[1].unlink()
        with self.assertRaisesRegex(ValueError, "exactly one"):
            publish.expected_files(self.area, self.tag, self.sha)
        self.assertFalse((self.area/"ontologyc-SHA256SUMS").exists())

    def test_matching_asset_is_preserved_conflict_refuses_batch(self):
        p = self.archives[1]
        remote = {p.name: {"state": "uploaded", "digest": "sha256:" + publish.sha256(p)}}
        self.assertEqual(publish.missing(self.archives, remote), self.archives[:1])
        remote[p.name]["digest"] = "sha256:wrong"
        with patch.object(publish, "release_identity", return_value=("42", self.sha)), \
             patch.object(publish, "assets", return_value=remote), patch.object(publish, "gh") as upload:
            with self.assertRaisesRegex(ValueError, "existing asset differs"):
                publish.publish(self.tag, "42", self.sha, self.area)
            upload.assert_not_called()

    def test_moved_tag_or_recreated_release_prevents_upload(self):
        for identity in [("42", "b"*40), ("43", self.sha)]:
            with patch.object(publish, "release_identity", return_value=identity), \
                 patch.object(publish, "gh") as upload:
                with self.assertRaisesRegex(ValueError, "changed"):
                    publish.publish(self.tag, "42", self.sha, self.area)
                upload.assert_not_called()

    def test_upload_uses_release_id_and_publishes_manifest_last(self):
        server = {}
        def upload(*args):
            path = Path(args[-1])
            self.assertIn(f"https://uploads.github.com/repos/owner/repo/releases/42/assets?name={path.name}", args)
            server[path.name] = {"state": "uploaded", "digest": "sha256:" + publish.sha256(path)}
        with patch.dict(os.environ, GITHUB_REPOSITORY="owner/repo"), \
             patch.object(publish, "release_identity", return_value=("42", self.sha)), \
             patch.object(publish, "gh", side_effect=upload), patch.object(publish, "assets", return_value=server):
            publish.publish(self.tag, "42", self.sha, self.area)
        self.assertEqual(list(server), [p.name for p in self.archives] + ["ontologyc-SHA256SUMS"])

    def test_annotated_tag_resolves_to_commit(self):
        objects = [{"id": 42, "tag_name": self.tag}, {"object": {"type": "tag", "sha": "b"*40}},
                   {"object": {"type": "commit", "sha": self.sha}}]
        with patch.object(publish, "api", side_effect=objects):
            self.assertEqual(publish.release_identity(self.tag), ("42", self.sha))
        with self.assertRaises(ValueError):
            publish.release_identity("../main")
