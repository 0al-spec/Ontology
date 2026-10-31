"""Publish only the two archives built for a specific GitHub Release."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tarfile
from urllib.parse import quote


PLATFORMS = ("macos-arm64", "linux-x86_64")


def gh(*args):
    return subprocess.check_output(["gh", *args], text=True)


def api(path, *flags):
    return json.loads(gh("api", *flags, f"repos/{os.environ['GITHUB_REPOSITORY']}/{path}"))


def release_identity(tag):
    if not re.fullmatch(r"v?[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z]+(?:[.+-][0-9A-Za-z]+)*)?", tag):
        raise ValueError("expected a numeric release version, optionally v-prefixed")
    release = api(f"releases/tags/{tag}")
    obj = api(f"git/ref/tags/{tag}")["object"]
    while obj["type"] == "tag":
        obj = api("git/tags/" + obj["sha"])["object"]
    if obj["type"] != "commit" or release["tag_name"] != tag:
        raise ValueError("release tag must resolve to a commit")
    return str(release["id"]), obj["sha"]


def sha256(path):
    with path.open("rb") as data:
        digest = hashlib.sha256()
        for block in iter(lambda: data.read(1024 * 1024), b""):
            digest.update(block)
        return digest.hexdigest()


def verify_archive(path, tag, commit, platform):
    root = path.name.removesuffix(".tar.gz")
    with tarfile.open(path, "r:gz") as archive:
        binary = archive.getmember(root + "/ontologyc")
        manifest = archive.getmember(root + "/BUILD.txt")
        if not binary.isfile() or not binary.size or not binary.mode & 0o111:
            raise ValueError(f"missing executable in {path.name}")
        if not manifest.isfile() or manifest.size > 4096:
            raise ValueError(f"invalid build metadata in {path.name}")
        with archive.extractfile(manifest) as data:
            identity = data.read().decode().splitlines()[:3]
    if identity != [f"ref={tag}", f"commit={commit}", f"platform={platform}"]:
        raise ValueError(f"archive identity mismatch: {path.name}")


def expected_files(directory, tag, commit):
    archives = [directory / f"ontologyc-{tag}-{p}.tar.gz" for p in PLATFORMS]
    if set(directory.iterdir()) != set(archives) or any(p.stat().st_size == 0 for p in archives):
        raise ValueError("expected exactly one nonempty archive per platform")
    for archive, platform in zip(archives, PLATFORMS):
        verify_archive(archive, tag, commit, platform)
    sums = directory / "ontologyc-SHA256SUMS"
    sums.write_text("".join(f"{sha256(p)}  {p.name}\n" for p in archives), encoding="ascii")
    return [*archives, sums]


def assets(release_id):
    pages = api(f"releases/{release_id}/assets?per_page=100", "--paginate", "--slurp")
    return {a["name"]: a for page in pages for a in page}


def missing(files, remote):
    absent = []
    for path in files:
        asset = remote.get(path.name)
        if asset is None:
            absent.append(path)
        elif asset["state"] != "uploaded" or asset.get("digest") != "sha256:" + sha256(path):
            raise ValueError(f"existing asset differs or is incomplete: {path.name}")
    return absent


def publish(tag, release_id, commit, directory):
    if release_identity(tag) != (release_id, commit):
        raise ValueError("release or tagged commit changed during the build")
    files = expected_files(directory, tag, commit)
    for path in missing(files, assets(release_id)):
        # Address the inspected release ID, including when a release is recreated.
        url = f"https://uploads.github.com/repos/{os.environ['GITHUB_REPOSITORY']}/releases/{release_id}/assets"
        gh("api", "--method", "POST", f"{url}?name={quote(path.name)}",
           "-H", "Content-Type: application/octet-stream", "--input", str(path))
    if missing(files, assets(release_id)) or release_identity(tag) != (release_id, commit):
        raise ValueError("release identity or uploaded files failed verification")


if __name__ == "__main__":
    if sys.argv[1] == "resolve":
        release_id, sha = release_identity(sys.argv[2])
        print(f"release_id={release_id}\nsha={sha}\nlabel={sys.argv[2]}")
    elif sys.argv[1] == "verify":
        expected_files(Path(sys.argv[4]), sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "publish":
        publish(*sys.argv[2:5], Path(sys.argv[5]))
    else:
        raise SystemExit("expected resolve, verify or publish")
