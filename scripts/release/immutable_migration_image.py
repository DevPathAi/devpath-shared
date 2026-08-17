#!/usr/bin/env python3
"""Fail-closed publisher/verifier for the immutable migration image."""

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
from typing import Any, Mapping, NamedTuple
import urllib.error
import urllib.parse
import urllib.request


REPOSITORY = "DevPathAi/devpath-shared"
SOURCE_LABEL = "https://github.com/DevPathAi/devpath-shared"
IMAGE_REPOSITORY = "ghcr.io/devpathai/devpath-migration"
REGISTRY_REPOSITORY = "devpathai/devpath-migration"
SCHEMA_VERSION = "leva.mission-spine.immutable-migration-image.v1"

BUILDER_BASE_INDEX_DIGEST = (
    "sha256:1ff763083f2993d57d0bf374ab10bb3e2cb873af6c13a04458ebbd3e0337dc76"
)
BUILDER_BASE_AMD64_DIGEST = (
    "sha256:4ec2402e5ebb803add08b063b9e5e52e7c11961caaae1f490479d925753f0d92"
)
RUNTIME_BASE_INDEX_DIGEST = (
    "sha256:df06535dfd6559ae5f0628c4761013dfa4ea6a30cf6e34294931d8091f55a18f"
)
RUNTIME_BASE_AMD64_DIGEST = (
    "sha256:aa01d87052ace414b7fb33ddabbdabb056a1e603a8bb5831dd516176718227e1"
)

BUILDER_INDEX_LABEL = "ai.devpath.migration.builder-base.index-digest"
BUILDER_AMD64_LABEL = "ai.devpath.migration.builder-base.amd64-digest"
RUNTIME_INDEX_LABEL = "ai.devpath.migration.runtime-base.index-digest"
RUNTIME_AMD64_LABEL = "ai.devpath.migration.runtime-base.amd64-digest"

EVIDENCE_KEYS = (
    "schema_version",
    "status",
    "repository",
    "source_sha",
    "producer_run_id",
    "producer_run_attempt",
    "image_repository",
    "image_tag",
    "image_digest",
    "publish_mode",
    "source_label",
    "revision_label",
    "builder_base_index_digest",
    "builder_base_amd64_digest",
    "runtime_base_index_digest",
    "runtime_base_amd64_digest",
)

SHA40 = re.compile(r"^[0-9a-f]{40}$")
DIGEST = re.compile(r"^sha256:[0-9a-f]{64}$")
MAX_MANIFEST_BYTES = 4 * 1024 * 1024
MAX_CONFIG_BYTES = 4 * 1024 * 1024
MAX_TOKEN_BYTES = 64 * 1024
MAX_ERROR_BYTES = 8192
MAX_EVIDENCE_BYTES = 8192
MANIFEST_MEDIA_TYPES = {
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
}
CONFIG_MEDIA_TYPES = {
    "application/vnd.oci.image.config.v1+json",
    "application/vnd.docker.container.image.v1+json",
}


class ImageError(ValueError):
    """Raised when an immutable image trust check fails."""


class RemoteImage(NamedTuple):
    digest: str
    config_digest: str


class RejectRedirect(urllib.request.HTTPRedirectHandler):
    """Registry and token APIs are expected to return bytes directly."""

    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: object,
        code: int,
        msg: str,
        headers: Mapping[str, str],
        newurl: str,
    ) -> None:
        return None


def _valid_source_sha(value: object) -> bool:
    return isinstance(value, str) and bool(SHA40.fullmatch(value)) and value != "0" * 40


def _valid_digest(value: object) -> bool:
    return (
        isinstance(value, str)
        and bool(DIGEST.fullmatch(value))
        and value != "sha256:" + "0" * 64
    )


def _positive_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def _expected_labels(source_sha: str) -> dict[str, str]:
    return {
        "org.opencontainers.image.source": SOURCE_LABEL,
        "org.opencontainers.image.revision": source_sha,
        BUILDER_INDEX_LABEL: BUILDER_BASE_INDEX_DIGEST,
        BUILDER_AMD64_LABEL: BUILDER_BASE_AMD64_DIGEST,
        RUNTIME_INDEX_LABEL: RUNTIME_BASE_INDEX_DIGEST,
        RUNTIME_AMD64_LABEL: RUNTIME_BASE_AMD64_DIGEST,
    }


def _canonical_json(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n").encode(
        "utf-8"
    )


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ImageError(f"JSON contains duplicate key {key!r}")
        result[key] = value
    return result


def _reject_constant(value: str) -> None:
    raise ImageError(f"JSON contains non-finite number {value}")


def _parse_json(raw: bytes, label: str) -> object:
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        raise ImageError(f"{label} is not strict UTF-8") from exc
    if text.startswith("\ufeff"):
        raise ImageError(f"{label} must not contain a UTF-8 BOM")
    try:
        return json.loads(
            text,
            object_pairs_hook=_unique_object,
            parse_constant=_reject_constant,
        )
    except json.JSONDecodeError as exc:
        raise ImageError(f"{label} is not valid JSON") from exc


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


def validate_ci_context(
    env: Mapping[str, str],
    source_sha: str,
    head_sha: str,
    remote_main_sha: str,
    status: str,
) -> None:
    expected = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "push",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_RUN_ATTEMPT": "1",
    }
    for key, value in expected.items():
        if env.get(key) != value:
            raise ImageError(f"{key} must equal {value}")
    if not _valid_source_sha(source_sha) or env.get("GITHUB_SHA") != source_sha:
        raise ImageError("GITHUB_SHA must equal one nonzero lowercase source SHA")
    run_id = env.get("GITHUB_RUN_ID", "")
    if not run_id.isdecimal() or str(int(run_id)) != run_id or int(run_id) <= 0:
        raise ImageError("GITHUB_RUN_ID must be one positive canonical integer")
    if head_sha != source_sha:
        raise ImageError("checked-out HEAD does not equal GITHUB_SHA")
    if remote_main_sha != source_sha:
        raise ImageError("GITHUB_SHA is not the current origin/main head")
    if status:
        raise ImageError("migration image checkout is not clean")


def verify_ci_source(root: Path) -> str:
    source_sha = os.environ.get("GITHUB_SHA", "")
    _git(
        root,
        "fetch",
        "--no-tags",
        "origin",
        "main:refs/remotes/origin/main",
    )
    validate_ci_context(
        os.environ,
        source_sha,
        _git(root, "rev-parse", "HEAD"),
        _git(root, "rev-parse", "refs/remotes/origin/main"),
        _git(root, "status", "--porcelain=v1", "--untracked-files=all"),
    )
    return source_sha


def validate_remote_image(
    manifest_bytes: bytes,
    manifest_digest_header: str,
    config_bytes: bytes,
    source_sha: str,
) -> RemoteImage:
    if not _valid_source_sha(source_sha):
        raise ImageError("image source SHA is invalid")
    if not _valid_digest(manifest_digest_header):
        raise ImageError("registry manifest digest header is invalid")
    actual_manifest_digest = "sha256:" + hashlib.sha256(manifest_bytes).hexdigest()
    if manifest_digest_header != actual_manifest_digest:
        raise ImageError("registry manifest bytes do not match Docker-Content-Digest")

    manifest = _parse_json(manifest_bytes, "image manifest")
    if not isinstance(manifest, dict):
        raise ImageError("image manifest root must be an object")
    if manifest.get("schemaVersion") != 2:
        raise ImageError("image manifest schemaVersion must equal 2")
    if manifest.get("mediaType") not in MANIFEST_MEDIA_TYPES:
        raise ImageError("image reference must resolve to one image manifest, not an index")
    if not isinstance(manifest.get("layers"), list):
        raise ImageError("image manifest layers must be an array")
    config_descriptor = manifest.get("config")
    if not isinstance(config_descriptor, dict):
        raise ImageError("image manifest config descriptor is missing")
    if config_descriptor.get("mediaType") not in CONFIG_MEDIA_TYPES:
        raise ImageError("image config descriptor mediaType is invalid")
    config_digest = config_descriptor.get("digest")
    if not _valid_digest(config_digest):
        raise ImageError("image config descriptor digest is invalid")
    config_size = config_descriptor.get("size")
    if not _positive_int(config_size) or config_size != len(config_bytes):
        raise ImageError("image config descriptor size does not match config bytes")
    if "sha256:" + hashlib.sha256(config_bytes).hexdigest() != config_digest:
        raise ImageError("image config bytes do not match the manifest descriptor")

    config = _parse_json(config_bytes, "image config")
    if not isinstance(config, dict):
        raise ImageError("image config root must be an object")
    if config.get("architecture") != "amd64" or config.get("os") != "linux":
        raise ImageError("image config must describe linux/amd64")
    runtime_config = config.get("config")
    if not isinstance(runtime_config, dict):
        raise ImageError("image runtime config is missing")
    labels = runtime_config.get("Labels")
    if not isinstance(labels, dict):
        raise ImageError("image provenance labels are missing")
    for key, value in _expected_labels(source_sha).items():
        if labels.get(key) != value:
            raise ImageError(f"image provenance label {key} drifted")
    return RemoteImage(manifest_digest_header, config_digest)


def require_candidate_config(image: RemoteImage, candidate_config_digest: str) -> None:
    if not _valid_digest(candidate_config_digest):
        raise ImageError("local candidate config digest is invalid")
    if image.config_digest != candidate_config_digest:
        raise ImageError("remote image config/rootfs does not equal the local candidate")


def require_local_candidate_config(
    local_config_digest: str, candidate_config_digest: str
) -> None:
    if not _valid_digest(local_config_digest):
        raise ImageError("loaded local candidate config digest is invalid")
    if not _valid_digest(candidate_config_digest):
        raise ImageError("build action candidate config digest is invalid")
    if local_config_digest != candidate_config_digest:
        raise ImageError("build action image ID does not equal the loaded local candidate")


def validate_local_image_document(document: object, source_sha: str) -> str:
    if not _valid_source_sha(source_sha):
        raise ImageError("local candidate source SHA is invalid")
    if not isinstance(document, dict):
        raise ImageError("local candidate inspect root must be an object")
    config_digest = document.get("Id")
    if not _valid_digest(config_digest):
        raise ImageError("local candidate config digest is invalid")
    if document.get("Architecture") != "amd64" or document.get("Os") != "linux":
        raise ImageError("local candidate must be linux/amd64")
    repo_tags = document.get("RepoTags")
    expected_tag = f"{IMAGE_REPOSITORY}:{source_sha}"
    if not isinstance(repo_tags, list) or expected_tag not in repo_tags:
        raise ImageError("local candidate does not have the exact source-SHA tag")
    config = document.get("Config")
    if not isinstance(config, dict) or not isinstance(config.get("Labels"), dict):
        raise ImageError("local candidate provenance labels are missing")
    labels = config["Labels"]
    for key, value in _expected_labels(source_sha).items():
        if labels.get(key) != value:
            raise ImageError(f"local candidate provenance label {key} drifted")
    return config_digest


def inspect_local_image(image_ref: str, source_sha: str) -> str:
    expected_ref = f"{IMAGE_REPOSITORY}:{source_sha}"
    if image_ref != expected_ref:
        raise ImageError("local candidate image reference drifted")
    result = subprocess.run(
        ["docker", "image", "inspect", image_ref],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if len(result.stdout) > MAX_CONFIG_BYTES:
        raise ImageError("local candidate inspect response exceeded its byte limit")
    document = _parse_json(result.stdout, "local candidate inspect response")
    if not isinstance(document, list) or len(document) != 1:
        raise ImageError("local candidate inspect must return exactly one image")
    return validate_local_image_document(document[0], source_sha)


def resolve_recheck(
    preflight_publish_needed: str,
    preflight_digest: str,
    current: RemoteImage | None,
    candidate_config_digest: str,
) -> tuple[bool, str]:
    if not _valid_digest(candidate_config_digest):
        raise ImageError("recheck local candidate config digest is invalid")
    if preflight_publish_needed == "true":
        if preflight_digest:
            raise ImageError("absent preflight unexpectedly carried an image digest")
        if current is None:
            return True, ""
        require_candidate_config(current, candidate_config_digest)
        return False, current.digest
    if preflight_publish_needed == "false":
        if not _valid_digest(preflight_digest):
            raise ImageError("present preflight image digest is invalid")
        if current is None:
            raise ImageError("present preflight image disappeared before push boundary")
        if current.digest != preflight_digest:
            raise ImageError("present preflight manifest digest drifted before push boundary")
        require_candidate_config(current, candidate_config_digest)
        return False, current.digest
    raise ImageError("preflight publish_needed must equal true or false")


class RegistryClient:
    def __init__(self, actor: str, token: str) -> None:
        if (
            not actor
            or not token
            or "\n" in actor
            or "\r" in actor
            or "\n" in token
            or "\r" in token
        ):
            raise ImageError("GitHub registry credentials are missing or malformed")
        self.actor = actor
        self.token = token
        self._opener = urllib.request.build_opener(RejectRedirect())

    @staticmethod
    def manifest_url(source_sha: str) -> str:
        if not _valid_source_sha(source_sha):
            raise ImageError("manifest source SHA is invalid")
        return f"https://ghcr.io/v2/{REGISTRY_REPOSITORY}/manifests/{source_sha}"

    @staticmethod
    def config_url(config_digest: str) -> str:
        if not _valid_digest(config_digest):
            raise ImageError("config digest is invalid")
        return f"https://ghcr.io/v2/{REGISTRY_REPOSITORY}/blobs/{config_digest}"

    def _request(
        self, url: str, headers: Mapping[str, str], max_bytes: int
    ) -> tuple[bytes, dict[str, str]]:
        request_headers = {
            key: value for key, value in headers.items() if key.lower() != "accept-encoding"
        }
        requested_encodings = [
            value for key, value in headers.items() if key.lower() == "accept-encoding"
        ]
        if requested_encodings and (
            len(requested_encodings) != 1
            or requested_encodings[0].strip().lower() != "identity"
        ):
            raise ImageError("registry request Accept-Encoding is invalid")
        request_headers["Accept-Encoding"] = "identity"
        request = urllib.request.Request(url, headers=request_headers, method="GET")
        try:
            with self._opener.open(request, timeout=30) as response:
                if response.status != 200:
                    raise ImageError(f"registry API returned HTTP {response.status}")
                if response.geturl() != url:
                    raise ImageError("registry API response URL drifted")
                content_encoding = response.headers.get("Content-Encoding")
                if (
                    content_encoding is not None
                    and content_encoding.strip().lower() != "identity"
                ):
                    raise ImageError("registry response Content-Encoding is invalid")
                content_length = response.headers.get("Content-Length")
                if content_length is not None:
                    if (
                        not content_length.isdecimal()
                        or str(int(content_length)) != content_length
                        or int(content_length) > max_bytes
                    ):
                        raise ImageError("registry response Content-Length is invalid")
                raw = response.read(max_bytes + 1)
                if len(raw) > max_bytes:
                    raise ImageError("registry response exceeded its byte limit")
                if content_length is not None and len(raw) != int(content_length):
                    raise ImageError(
                        "registry response bytes do not match Content-Length"
                    )
                response_headers = {
                    key.lower(): value.strip() for key, value in response.headers.items()
                }
                return raw, response_headers
        except urllib.error.HTTPError:
            raise
        except urllib.error.URLError as exc:
            raise ImageError("registry API request failed") from exc

    def _bearer_token(self) -> str:
        scope = f"repository:{REGISTRY_REPOSITORY}:pull"
        query = urllib.parse.urlencode({"service": "ghcr.io", "scope": scope})
        token_url = f"https://ghcr.io/token?{query}"
        basic = base64.b64encode(f"{self.actor}:{self.token}".encode("utf-8")).decode(
            "ascii"
        )
        try:
            raw, headers = self._request(
                token_url,
                {
                    "Authorization": f"Basic {basic}",
                    "Accept": "application/json",
                    "User-Agent": "devpath-shared-immutable-image/1",
                },
                MAX_TOKEN_BYTES,
            )
        except urllib.error.HTTPError as exc:
            raise ImageError(f"registry token API returned HTTP {exc.code}") from exc
        if headers.get("content-type") != "application/json":
            raise ImageError("registry token response Content-Type is invalid")
        document = _parse_json(raw, "registry token response")
        if not isinstance(document, dict):
            raise ImageError("registry token response root must be an object")
        bearer = document.get("token")
        if not isinstance(bearer, str) or not bearer or len(bearer) > 8192:
            raise ImageError("registry bearer token is missing or malformed")
        return bearer

    @staticmethod
    def _storage_redirect(
        exc: urllib.error.HTTPError, config_url: str, config_digest: str
    ) -> str:
        try:
            if exc.code != 307 or exc.geturl() != config_url:
                raise ImageError(
                    f"registry config request returned HTTP {exc.code}"
                ) from exc
            if exc.headers is None or exc.headers.get("Content-Length") != "0":
                raise ImageError("registry config redirect body length is invalid") from exc
            content_encoding = exc.headers.get("Content-Encoding")
            if (
                content_encoding is not None
                and content_encoding.strip().lower() != "identity"
            ):
                raise ImageError(
                    "registry config redirect Content-Encoding is invalid"
                ) from exc
            if exc.read(1):
                raise ImageError("registry config redirect body must be empty") from exc
            location = exc.headers.get("Location")
            if not isinstance(location, str):
                raise ImageError("registry config redirect Location is missing") from exc
            parsed = urllib.parse.urlsplit(location)
            path = re.fullmatch(
                r"/ghcrblobs[0-9]+/blobs/(sha256:[0-9a-f]{64})", parsed.path
            )
            if (
                parsed.scheme != "https"
                or parsed.hostname != "pkg-containers.githubusercontent.com"
                or parsed.port not in (None, 443)
                or parsed.username is not None
                or parsed.password is not None
                or path is None
                or path.group(1) != config_digest
                or not parsed.query
                or parsed.fragment
            ):
                raise ImageError("registry config redirect target is not allowlisted") from exc
            return location
        finally:
            exc.close()

    def _fetch_config_blob(self, config_digest: str, bearer: str) -> bytes:
        config_url = self.config_url(config_digest)
        try:
            config_bytes, _ = self._request(
                config_url,
                {
                    "Authorization": f"Bearer {bearer}",
                    "Accept": ", ".join(sorted(CONFIG_MEDIA_TYPES)),
                    "User-Agent": "devpath-shared-immutable-image/1",
                },
                MAX_CONFIG_BYTES,
            )
            return config_bytes
        except urllib.error.HTTPError as exc:
            storage_url = self._storage_redirect(exc, config_url, config_digest)
        try:
            config_bytes, _ = self._request(
                storage_url,
                {
                    "Accept": "application/octet-stream",
                    "User-Agent": "devpath-shared-immutable-image/1",
                },
                MAX_CONFIG_BYTES,
            )
            return config_bytes
        except urllib.error.HTTPError as exc:
            raise ImageError(
                f"registry config storage request returned HTTP {exc.code}"
            ) from exc

    @staticmethod
    def _is_exact_manifest_absence(
        exc: urllib.error.HTTPError, manifest_url: str
    ) -> bool:
        try:
            if exc.code != 404 or exc.geturl() != manifest_url:
                return False
            content_type = exc.headers.get("Content-Type") if exc.headers else None
            if content_type not in {"application/json", "application/json; charset=utf-8"}:
                return False
            content_encoding = (
                exc.headers.get("Content-Encoding") if exc.headers else None
            )
            if (
                content_encoding is not None
                and content_encoding.strip().lower() != "identity"
            ):
                return False
            content_length = exc.headers.get("Content-Length") if exc.headers else None
            if content_length is not None:
                if (
                    not content_length.isdecimal()
                    or int(content_length) <= 0
                    or int(content_length) > MAX_ERROR_BYTES
                ):
                    return False
            raw = exc.read(MAX_ERROR_BYTES + 1)
            if not raw or len(raw) > MAX_ERROR_BYTES:
                return False
            if content_length is not None and int(content_length) != len(raw):
                return False
            expected = {
                "errors": [
                    {"code": "MANIFEST_UNKNOWN", "message": "manifest unknown"}
                ]
            }
            document = _parse_json(raw, "registry manifest absence response")
            return document == expected and raw == _canonical_json(expected)
        except (ImageError, OSError):
            return False
        finally:
            exc.close()

    def inspect(self, source_sha: str, *, allow_absent: bool) -> RemoteImage | None:
        manifest_url = self.manifest_url(source_sha)
        bearer = self._bearer_token()
        try:
            manifest_bytes, headers = self._request(
                manifest_url,
                {
                    "Authorization": f"Bearer {bearer}",
                    "Accept": ", ".join(sorted(MANIFEST_MEDIA_TYPES)),
                    "User-Agent": "devpath-shared-immutable-image/1",
                },
                MAX_MANIFEST_BYTES,
            )
        except urllib.error.HTTPError as exc:
            if allow_absent and self._is_exact_manifest_absence(exc, manifest_url):
                return None
            exc.close()
            raise ImageError(f"registry manifest request returned HTTP {exc.code}") from exc

        digest_header = headers.get("docker-content-digest", "")
        manifest = _parse_json(manifest_bytes, "image manifest")
        if not isinstance(manifest, dict) or not isinstance(manifest.get("config"), dict):
            raise ImageError("image manifest config descriptor is missing")
        config_digest = manifest["config"].get("digest")
        if not _valid_digest(config_digest):
            raise ImageError("image config descriptor digest is invalid")
        config_bytes = self._fetch_config_blob(config_digest, bearer)
        return validate_remote_image(
            manifest_bytes, digest_header, config_bytes, source_sha
        )


def _write_github_outputs(path: Path, values: Mapping[str, str]) -> None:
    if path.is_symlink() or not path.is_file():
        raise ImageError("GITHUB_OUTPUT must already exist as one regular file")
    for key, value in values.items():
        if not re.fullmatch(r"[a-z_]+", key) or "\n" in value or "\r" in value:
            raise ImageError("GitHub output key or value is malformed")
    with path.open("a", encoding="utf-8", newline="\n") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")


def _evidence_document(
    source_sha: str,
    run_id: int,
    run_attempt: int,
    image_digest: str,
    publish_mode: str,
) -> dict[str, object]:
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "passed",
        "repository": REPOSITORY,
        "source_sha": source_sha,
        "producer_run_id": run_id,
        "producer_run_attempt": run_attempt,
        "image_repository": IMAGE_REPOSITORY,
        "image_tag": source_sha,
        "image_digest": image_digest,
        "publish_mode": publish_mode,
        "source_label": SOURCE_LABEL,
        "revision_label": source_sha,
        "builder_base_index_digest": BUILDER_BASE_INDEX_DIGEST,
        "builder_base_amd64_digest": BUILDER_BASE_AMD64_DIGEST,
        "runtime_base_index_digest": RUNTIME_BASE_INDEX_DIGEST,
        "runtime_base_amd64_digest": RUNTIME_BASE_AMD64_DIGEST,
    }


def _validate_evidence(document: object) -> dict[str, object]:
    if not isinstance(document, dict) or tuple(document) != EVIDENCE_KEYS:
        raise ImageError("migration image evidence exact key order drifted")
    source_sha = document["source_sha"]
    expected = {
        "schema_version": SCHEMA_VERSION,
        "status": "passed",
        "repository": REPOSITORY,
        "image_repository": IMAGE_REPOSITORY,
        "image_tag": source_sha,
        "source_label": SOURCE_LABEL,
        "revision_label": source_sha,
        "builder_base_index_digest": BUILDER_BASE_INDEX_DIGEST,
        "builder_base_amd64_digest": BUILDER_BASE_AMD64_DIGEST,
        "runtime_base_index_digest": RUNTIME_BASE_INDEX_DIGEST,
        "runtime_base_amd64_digest": RUNTIME_BASE_AMD64_DIGEST,
    }
    for key, value in expected.items():
        if document.get(key) != value:
            raise ImageError(f"migration image evidence {key} drifted")
    if not _valid_source_sha(source_sha):
        raise ImageError("migration image evidence source_sha is invalid")
    if not _positive_int(document["producer_run_id"]):
        raise ImageError("migration image evidence producer_run_id is invalid")
    if document["producer_run_attempt"] != 1:
        raise ImageError("migration image evidence producer_run_attempt must equal 1")
    if not _valid_digest(document["image_digest"]):
        raise ImageError("migration image evidence image_digest is invalid")
    if document["publish_mode"] not in {"published", "reused"}:
        raise ImageError("migration image evidence publish_mode is invalid")
    return document


def write_evidence(
    root: Path,
    *,
    source_sha: str,
    run_id: int,
    run_attempt: int,
    image_digest: str,
    publish_mode: str,
) -> Path:
    document = _validate_evidence(
        _evidence_document(
            source_sha, run_id, run_attempt, image_digest, publish_mode
        )
    )
    root.mkdir(mode=0o700, parents=False, exist_ok=False)
    evidence = root / "evidence.json"
    raw = _canonical_json(document)
    if len(raw) > MAX_EVIDENCE_BYTES:
        raise ImageError("migration image evidence exceeded its byte limit")
    with evidence.open("xb") as output:
        output.write(raw)
    return evidence


def validate_evidence_directory(root: Path) -> dict[str, object]:
    if root.is_symlink() or not root.is_dir():
        raise ImageError("migration image evidence root is not one regular directory")
    entries = list(root.iterdir())
    if [entry.name for entry in entries] != ["evidence.json"]:
        raise ImageError("migration image evidence root must contain only evidence.json")
    evidence = entries[0]
    if evidence.is_symlink() or not evidence.is_file():
        raise ImageError("migration image evidence is not one regular file")
    size = evidence.stat().st_size
    if size <= 0 or size > MAX_EVIDENCE_BYTES:
        raise ImageError("migration image evidence size is invalid")
    raw = evidence.read_bytes()
    document = _validate_evidence(_parse_json(raw, "migration image evidence"))
    if raw != _canonical_json(document):
        raise ImageError("migration image evidence is not canonical LF UTF-8 JSON")
    return document


def _registry_client() -> RegistryClient:
    return RegistryClient(
        os.environ.get("GITHUB_ACTOR", ""), os.environ.get("GITHUB_TOKEN", "")
    )


def preflight(
    root: Path,
    image_ref: str,
    candidate_config_digest: str,
    github_output: Path,
) -> None:
    source_sha = verify_ci_source(root)
    require_local_candidate_config(
        inspect_local_image(image_ref, source_sha), candidate_config_digest
    )
    image = _registry_client().inspect(source_sha, allow_absent=True)
    if image is not None:
        require_candidate_config(image, candidate_config_digest)
    publish_needed = image is None
    _write_github_outputs(
        github_output,
        {
            "publish_needed": str(publish_needed).lower(),
            "image_digest": "" if image is None else image.digest,
            "candidate_config_digest": candidate_config_digest,
        },
    )
    state = "absent" if image is None else f"present-and-exact {image.digest}"
    print(f"verified immutable migration image preflight: {state}")


def recheck(
    root: Path,
    image_ref: str,
    github_output: Path,
    *,
    candidate_config_digest: str,
    preflight_publish_needed: str,
    preflight_digest: str,
) -> None:
    source_sha = verify_ci_source(root)
    require_local_candidate_config(
        inspect_local_image(image_ref, source_sha), candidate_config_digest
    )
    current = _registry_client().inspect(source_sha, allow_absent=True)
    push_needed, image_digest = resolve_recheck(
        preflight_publish_needed,
        preflight_digest,
        current,
        candidate_config_digest,
    )
    _write_github_outputs(
        github_output,
        {
            "push_needed": str(push_needed).lower(),
            "image_digest": image_digest,
            "candidate_config_digest": candidate_config_digest,
        },
    )
    state = "still-absent" if push_needed else f"reuse-exact {image_digest}"
    print(f"verified immutable migration image pre-push recheck: {state}")


def postflight(
    root: Path,
    image_ref: str,
    evidence_dir: Path,
    *,
    candidate_config_digest: str,
    push_needed: str,
    prepush_digest: str,
    retries: int,
    delay_seconds: float,
) -> None:
    source_sha = verify_ci_source(root)
    require_local_candidate_config(
        inspect_local_image(image_ref, source_sha), candidate_config_digest
    )
    if push_needed == "true":
        if prepush_digest:
            raise ImageError("published postflight unexpectedly carried a pre-push digest")
        expected_digest = ""
        publish_mode = "published"
    elif push_needed == "false":
        if not _valid_digest(prepush_digest):
            raise ImageError("reused postflight digest inputs are inconsistent")
        expected_digest = prepush_digest
        publish_mode = "reused"
    else:
        raise ImageError("push_needed must equal true or false")
    if retries < 1 or retries > 30 or delay_seconds < 0 or delay_seconds > 30:
        raise ImageError("postflight retry arguments are invalid")

    client = _registry_client()
    last_error: ImageError | None = None
    image: RemoteImage | None = None
    for attempt in range(1, retries + 1):
        try:
            image = client.inspect(source_sha, allow_absent=False)
            if image is None:
                raise ImageError("postflight registry image is absent")
            require_candidate_config(image, candidate_config_digest)
            if expected_digest and image.digest != expected_digest:
                raise ImageError("reused registry digest drifted after the push boundary")
            break
        except ImageError as exc:
            last_error = exc
            if attempt == retries:
                raise
            time.sleep(delay_seconds)
    if image is None:
        assert last_error is not None
        raise last_error

    run_id_text = os.environ.get("GITHUB_RUN_ID", "")
    run_attempt_text = os.environ.get("GITHUB_RUN_ATTEMPT", "")
    write_evidence(
        evidence_dir,
        source_sha=source_sha,
        run_id=int(run_id_text),
        run_attempt=int(run_attempt_text),
        image_digest=image.digest,
        publish_mode=publish_mode,
    )
    print(f"verified immutable migration image postflight: {image.digest}")


def verify_evidence_cli(evidence_dir: Path) -> None:
    document = validate_evidence_directory(evidence_dir)
    expected_env = {
        "repository": os.environ.get("GITHUB_REPOSITORY", ""),
        "source_sha": os.environ.get("GITHUB_SHA", ""),
        "producer_run_id": os.environ.get("GITHUB_RUN_ID", ""),
        "producer_run_attempt": os.environ.get("GITHUB_RUN_ATTEMPT", ""),
    }
    if document["repository"] != expected_env["repository"]:
        raise ImageError("evidence repository does not equal the producer context")
    if document["source_sha"] != expected_env["source_sha"]:
        raise ImageError("evidence source_sha does not equal the producer context")
    if str(document["producer_run_id"]) != expected_env["producer_run_id"]:
        raise ImageError("evidence producer_run_id does not equal the producer context")
    if str(document["producer_run_attempt"]) != expected_env["producer_run_attempt"]:
        raise ImageError("evidence run attempt does not equal the producer context")
    print(f"verified migration image evidence {document['image_digest']}")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    preflight_parser = subparsers.add_parser("preflight")
    preflight_parser.add_argument("--root", type=Path, required=True)
    preflight_parser.add_argument("--image-ref", required=True)
    preflight_parser.add_argument("--candidate-config-digest", required=True)
    preflight_parser.add_argument("--github-output", type=Path, required=True)

    source_parser = subparsers.add_parser("verify-source")
    source_parser.add_argument("--root", type=Path, required=True)

    recheck_parser = subparsers.add_parser("recheck")
    recheck_parser.add_argument("--root", type=Path, required=True)
    recheck_parser.add_argument("--image-ref", required=True)
    recheck_parser.add_argument("--candidate-config-digest", required=True)
    recheck_parser.add_argument("--github-output", type=Path, required=True)
    recheck_parser.add_argument("--preflight-publish-needed", required=True)
    recheck_parser.add_argument("--preflight-digest", required=True)

    postflight_parser = subparsers.add_parser("postflight")
    postflight_parser.add_argument("--root", type=Path, required=True)
    postflight_parser.add_argument("--image-ref", required=True)
    postflight_parser.add_argument("--candidate-config-digest", required=True)
    postflight_parser.add_argument("--evidence-dir", type=Path, required=True)
    postflight_parser.add_argument("--push-needed", required=True)
    postflight_parser.add_argument("--prepush-digest", required=True)
    postflight_parser.add_argument("--retries", type=int, default=12)
    postflight_parser.add_argument("--delay-seconds", type=float, default=5.0)

    evidence_parser = subparsers.add_parser("verify-evidence")
    evidence_parser.add_argument("--evidence-dir", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "preflight":
            preflight(
                args.root.resolve(),
                args.image_ref,
                args.candidate_config_digest,
                args.github_output.resolve(),
            )
        elif args.command == "verify-source":
            source_sha = verify_ci_source(args.root.resolve())
            print(f"verified current clean main source {source_sha}")
        elif args.command == "recheck":
            recheck(
                args.root.resolve(),
                args.image_ref,
                args.github_output.resolve(),
                candidate_config_digest=args.candidate_config_digest,
                preflight_publish_needed=args.preflight_publish_needed,
                preflight_digest=args.preflight_digest,
            )
        elif args.command == "postflight":
            postflight(
                args.root.resolve(),
                args.image_ref,
                args.evidence_dir.resolve(),
                candidate_config_digest=args.candidate_config_digest,
                push_needed=args.push_needed,
                prepush_digest=args.prepush_digest,
                retries=args.retries,
                delay_seconds=args.delay_seconds,
            )
        elif args.command == "verify-evidence":
            verify_evidence_cli(args.evidence_dir.resolve())
        else:  # pragma: no cover
            raise ImageError("unsupported immutable image command")
    except (ImageError, OSError, subprocess.CalledProcessError) as exc:
        print(f"immutable migration image verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
