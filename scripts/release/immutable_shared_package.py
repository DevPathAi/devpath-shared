#!/usr/bin/env python3
"""Fail-closed verifier for the one-shot ET9 Shared Maven publication."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Callable, Mapping, NamedTuple
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


GROUP_ID = "ai.devpath"
ARTIFACT_ID = "devpath-shared"
VERSION = "0.0.1-et11.20260822"
REPOSITORY = "DevPathAi/devpath-shared"
MAVEN_BASE_URL = (
    "https://maven.pkg.github.com/DevPathAi/devpath-shared/"
    "ai/devpath/devpath-shared/0.0.1-et11.20260822"
)
SHA40 = re.compile(r"^[0-9a-f]{40}$")


class VerificationError(ValueError):
    """Raised when an immutable publication trust check fails."""


class ArtifactSpec(NamedTuple):
    name: str
    size: int
    sha256: str


ARTIFACTS = {
    f"{ARTIFACT_ID}-{VERSION}.jar": ArtifactSpec(
        f"{ARTIFACT_ID}-{VERSION}.jar",
        1_229_362,
        "4ea08b9f6451a166313c72283c5fac29a8b34cb54d4591c8c93e52b1adc2e1dd",
    ),
    f"{ARTIFACT_ID}-{VERSION}.pom": ArtifactSpec(
        f"{ARTIFACT_ID}-{VERSION}.pom",
        1_547,
        "67786fc16d3a87c15cb5dfce32bce6973d2bab32b4f35c105fd81c3f37d188f0",
    ),
    f"{ARTIFACT_ID}-{VERSION}.module": ArtifactSpec(
        f"{ARTIFACT_ID}-{VERSION}.module",
        2_893,
        "951b43fbaf45b472db538fb54dc20d765fbc37091462bf941b68de1ee2acd3b9",
    ),
}


class SafePackageRedirect(urllib.request.HTTPRedirectHandler):
    """Allow GitHub's one storage redirect without forwarding credentials."""

    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: object,
        code: int,
        msg: str,
        headers: Mapping[str, str],
        newurl: str,
    ) -> urllib.request.Request | None:
        source = urllib.parse.urlsplit(req.full_url)
        target = urllib.parse.urlsplit(newurl)
        if (
            source.scheme != "https"
            or source.hostname != "maven.pkg.github.com"
            or source.port not in (None, 443)
        ):
            raise VerificationError("package redirect source is not allowlisted")
        if (
            target.scheme != "https"
            or target.hostname != "github-registry-files.githubusercontent.com"
            or target.port not in (None, 443)
            or target.username is not None
            or target.password is not None
        ):
            raise VerificationError("package redirect target is not allowlisted")
        redirected = super().redirect_request(req, fp, code, msg, headers, newurl)
        if redirected is not None:
            redirected.remove_header("Authorization")
        return redirected


def is_absent_package_response(url: str, status: int) -> bool:
    parsed = urllib.parse.urlsplit(url)
    return (
        status == 404
        and parsed.scheme == "https"
        and parsed.hostname == "maven.pkg.github.com"
        and parsed.port in (None, 443)
        and parsed.username is None
        and parsed.password is None
    )


def validate_artifact_bytes(spec: ArtifactSpec, raw: bytes) -> None:
    if len(raw) != spec.size:
        raise VerificationError(
            f"{spec.name} size drifted: expected {spec.size}, got {len(raw)}"
        )
    actual = hashlib.sha256(raw).hexdigest()
    if actual != spec.sha256:
        raise VerificationError(
            f"{spec.name} SHA-256 drifted: expected {spec.sha256}, got {actual}"
        )


def validate_pom_semantics(raw: bytes) -> None:
    try:
        root = ET.fromstring(raw)
    except (ET.ParseError, UnicodeDecodeError) as exc:
        raise VerificationError("publication POM is not valid UTF-8 XML") from exc
    namespace = {"m": "http://maven.apache.org/POM/4.0.0"}
    expected = {
        "groupId": GROUP_ID,
        "artifactId": ARTIFACT_ID,
        "version": VERSION,
    }
    for key, value in expected.items():
        nodes = root.findall(f"m:{key}", namespace)
        if len(nodes) != 1 or nodes[0].text != value:
            raise VerificationError(f"publication POM {key} does not equal {value}")


def validate_module_semantics(raw: bytes) -> None:
    try:
        document = json.loads(raw)
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise VerificationError("Gradle module metadata is not valid UTF-8 JSON") from exc
    if not isinstance(document, dict):
        raise VerificationError("Gradle module metadata root must be an object")
    component = document.get("component")
    if not isinstance(component, dict):
        raise VerificationError("Gradle module metadata component is missing")
    expected = {"group": GROUP_ID, "module": ARTIFACT_ID, "version": VERSION}
    if {key: component.get(key) for key in expected} != expected:
        raise VerificationError("Gradle module metadata coordinate drifted")


def validate_local_artifacts(jar: Path, pom: Path, module: Path) -> None:
    paths = {
        f"{ARTIFACT_ID}-{VERSION}.jar": jar,
        f"{ARTIFACT_ID}-{VERSION}.pom": pom,
        f"{ARTIFACT_ID}-{VERSION}.module": module,
    }
    for name, path in paths.items():
        if path.is_symlink() or not path.is_file():
            raise VerificationError(f"{name} is not one regular local file")
        raw = path.read_bytes()
        validate_artifact_bytes(ARTIFACTS[name], raw)
        if name.endswith(".pom"):
            validate_pom_semantics(raw)
        elif name.endswith(".module"):
            validate_module_semantics(raw)
        print(f"verified {name} {len(raw)} bytes {ARTIFACTS[name].sha256}")


def classify_remote_artifacts(
    fetch: Callable[[str], tuple[int, bytes]],
    specs: Mapping[str, ArtifactSpec] = ARTIFACTS,
    *,
    require_present: bool = False,
) -> bool:
    """Return True when publication is absent and therefore must be uploaded."""
    statuses: dict[str, int] = {}
    payloads: dict[str, bytes] = {}
    for name in specs:
        status, raw = fetch(name)
        statuses[name] = status
        payloads[name] = raw
        if status not in (200, 404):
            raise VerificationError(f"remote {name} returned HTTP {status}")

    present = [name for name, status in statuses.items() if status == 200]
    if not present:
        if require_present:
            raise VerificationError("immutable package is still missing after publication")
        return True
    if len(present) != len(specs):
        raise VerificationError("immutable package is partial; refusing publication")

    for name, spec in specs.items():
        validate_artifact_bytes(spec, payloads[name])
    return False


def validate_source_identity(
    env: Mapping[str, str], head_sha: str, remote_main_sha: str, status: str
) -> None:
    expected = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "push",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_RUN_ATTEMPT": "1",
    }
    for key, value in expected.items():
        if env.get(key) != value:
            raise VerificationError(f"{key} must equal {value}")
    source_sha = env.get("GITHUB_SHA", "")
    if not SHA40.fullmatch(source_sha) or source_sha == "0" * 40:
        raise VerificationError("GITHUB_SHA must be one nonzero lowercase SHA-1")
    if head_sha != source_sha:
        raise VerificationError("checked-out HEAD does not equal GITHUB_SHA")
    if remote_main_sha != source_sha:
        raise VerificationError("GITHUB_SHA is not the current origin/main head")
    if status:
        raise VerificationError("publication checkout is not clean")


def _git(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )
    return result.stdout.strip()


def verify_source(root: Path) -> None:
    validate_source_identity(
        os.environ,
        _git(root, "rev-parse", "HEAD"),
        _git(root, "rev-parse", "refs/remotes/origin/main"),
        _git(root, "status", "--porcelain=v1", "--untracked-files=all"),
    )
    print(f"verified current clean main source {os.environ['GITHUB_SHA']}")


def _authenticated_fetch(actor: str, token: str) -> Callable[[str], tuple[int, bytes]]:
    if not actor or not token:
        raise VerificationError("GitHub package credentials are missing")
    auth = base64.b64encode(f"{actor}:{token}".encode("utf-8")).decode("ascii")

    opener = urllib.request.build_opener(SafePackageRedirect())

    def fetch(name: str) -> tuple[int, bytes]:
        if name not in ARTIFACTS:
            raise VerificationError("unexpected remote artifact name")
        request = urllib.request.Request(
            f"{MAVEN_BASE_URL}/{name}",
            headers={
                "Authorization": f"Basic {auth}",
                "Accept": "application/octet-stream",
                "User-Agent": "devpath-shared-immutable-publisher/1",
            },
        )
        try:
            with opener.open(request, timeout=30) as response:
                limit = ARTIFACTS[name].size + 1
                raw = response.read(limit)
                return response.status, raw
        except urllib.error.HTTPError as exc:
            if is_absent_package_response(exc.geturl(), exc.code):
                return 404, b""
            raise VerificationError(f"remote {name} returned HTTP {exc.code}") from exc
        except urllib.error.URLError as exc:
            raise VerificationError(f"remote {name} could not be fetched") from exc

    return fetch


def verify_remote(*, require_present: bool, retries: int, delay_seconds: float) -> bool:
    fetch = _authenticated_fetch(
        os.environ.get("GITHUB_ACTOR", ""), os.environ.get("GITHUB_TOKEN", "")
    )
    last_error: VerificationError | None = None
    for attempt in range(1, retries + 1):
        try:
            publish_needed = classify_remote_artifacts(
                fetch, require_present=require_present
            )
            state = "absent" if publish_needed else "present-and-exact"
            print(f"verified remote immutable package state: {state}")
            return publish_needed
        except VerificationError as exc:
            last_error = exc
            if attempt == retries:
                break
            time.sleep(delay_seconds)
    assert last_error is not None
    raise last_error


def _write_github_output(path: Path, key: str, value: str) -> None:
    if not path.is_file():
        raise VerificationError("GITHUB_OUTPUT must already exist as one regular file")
    with path.open("a", encoding="utf-8", newline="\n") as output:
        output.write(f"{key}={value}\n")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    source = subparsers.add_parser("verify-source")
    source.add_argument("--root", type=Path, required=True)

    local = subparsers.add_parser("verify-local")
    local.add_argument("--jar", type=Path, required=True)
    local.add_argument("--pom", type=Path, required=True)
    local.add_argument("--module", type=Path, required=True)

    preflight = subparsers.add_parser("preflight-remote")
    preflight.add_argument("--github-output", type=Path, required=True)

    postflight = subparsers.add_parser("postflight-remote")
    postflight.add_argument("--retries", type=int, default=12)
    postflight.add_argument("--delay-seconds", type=float, default=5.0)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "verify-source":
            verify_source(args.root.resolve())
        elif args.command == "verify-local":
            validate_local_artifacts(args.jar, args.pom, args.module)
        elif args.command == "preflight-remote":
            publish_needed = verify_remote(
                require_present=False, retries=1, delay_seconds=0
            )
            _write_github_output(
                args.github_output, "publish_needed", str(publish_needed).lower()
            )
        elif args.command == "postflight-remote":
            if args.retries < 1 or args.delay_seconds < 0:
                raise VerificationError("postflight retry arguments are invalid")
            verify_remote(
                require_present=True,
                retries=args.retries,
                delay_seconds=args.delay_seconds,
            )
        else:  # pragma: no cover
            raise VerificationError("unsupported verifier command")
    except (OSError, subprocess.CalledProcessError, VerificationError) as exc:
        print(f"immutable publication verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
