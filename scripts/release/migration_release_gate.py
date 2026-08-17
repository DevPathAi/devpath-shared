#!/usr/bin/env python3
"""Fail-closed gate for the sealed ET9 migration GitOps update."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Mapping


REPOSITORY = "DevPathAi/devpath-shared"
SHARED_VERSION = "0.0.1-et9.20260816"
SHARED_JAR_SHA256 = (
    "94e2adb769790d813a872163347ede20ad4c75ae88e5811df2ec6625a340f21f"
)
IMAGE_REPOSITORY = "ghcr.io/devpathai/devpath-migration"
FLYWAY_TARGET = "202608161011"
REQUIRED_MIGRATION = "V202608161011__validate_lcs_mentor_snapshot_contract.sql"
ROLLBACK_POLICY = "additive-retained"
RELEASE_ID = re.compile(r"^ms-[0-9]{8}-[a-z0-9][a-z0-9-]{2,40}$")
SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA64 = re.compile(r"^[0-9a-f]{64}$")
DIGEST = re.compile(r"^sha256:[0-9a-f]{64}$")


class GateError(ValueError):
    """Raised when a migration release trust check fails."""


def _nonzero(pattern: re.Pattern[str], value: object, label: str) -> str:
    if not isinstance(value, str) or pattern.fullmatch(value) is None:
        raise GateError(f"{label} has an invalid format")
    hex_value = value.removeprefix("sha256:")
    if set(hex_value) == {"0"}:
        raise GateError(f"{label} must not be all zeroes")
    return value


def _json_object(raw: bytes, label: str) -> dict[str, object]:
    try:
        document = json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateError(f"{label} is not valid UTF-8 JSON") from exc
    if not isinstance(document, dict):
        raise GateError(f"{label} root must be an object")
    return document


def _exact_keys(value: object, expected: set[str], label: str) -> dict[str, object]:
    if not isinstance(value, dict) or set(value) != expected:
        raise GateError(f"{label} keys must be exactly {sorted(expected)}")
    return value


def validate_dispatch_context(
    env: Mapping[str, str],
    head_sha: str,
    remote_main_sha: str,
    status: str,
    expected_source_sha: str,
) -> None:
    expected = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "workflow_dispatch",
        "GITHUB_REF": "refs/heads/main",
        "GITHUB_RUN_ATTEMPT": "1",
    }
    for key, value in expected.items():
        if env.get(key) != value:
            raise GateError(f"{key} must equal {value}")
    source_sha = _nonzero(SHA40, env.get("GITHUB_SHA"), "GITHUB_SHA")
    _nonzero(SHA40, expected_source_sha, "source_sha")
    if source_sha != expected_source_sha:
        raise GateError("source_sha input does not equal GITHUB_SHA")
    if head_sha != source_sha:
        raise GateError("checked-out HEAD does not equal GITHUB_SHA")
    if remote_main_sha != source_sha:
        raise GateError("GITHUB_SHA is not the current origin/main head")
    if status:
        raise GateError("migration release checkout is not clean")


def validate_sealed_release(
    *,
    release_id: str,
    source_sha: str,
    release_sha256: str,
    release_raw: bytes,
    candidate_raw: bytes,
) -> dict[str, str]:
    if RELEASE_ID.fullmatch(release_id) is None:
        raise GateError("release_id has an invalid format")
    _nonzero(SHA40, source_sha, "source_sha")
    expected_release_sha = _nonzero(
        SHA64, release_sha256, "release_manifest_sha256"
    )
    actual_release_sha = hashlib.sha256(release_raw).hexdigest()
    if actual_release_sha != expected_release_sha:
        raise GateError("release-manifest raw SHA-256 does not match the dispatch input")

    release = _json_object(release_raw, "release-manifest")
    if release.get("document_type") != "release-manifest":
        raise GateError("document_type must be release-manifest")
    if release.get("release_id") != release_id:
        raise GateError("release-manifest release_id does not match")
    candidate_ref = _exact_keys(
        release.get("candidate_spec"), {"path", "sha256"}, "candidate_spec"
    )
    expected_candidate_path = (
        f"release-manifests/candidates/{release_id}.candidate-spec.json"
    )
    if candidate_ref["path"] != expected_candidate_path:
        raise GateError("candidate_spec path is not the canonical release path")
    candidate_sha = _nonzero(
        SHA64, candidate_ref["sha256"], "candidate_spec.sha256"
    )
    if hashlib.sha256(candidate_raw).hexdigest() != candidate_sha:
        raise GateError("candidate-spec raw SHA-256 does not match release-manifest")

    candidate = _json_object(candidate_raw, "candidate-spec")
    if candidate.get("document_type") != "candidate-spec":
        raise GateError("candidate document_type must be candidate-spec")
    if candidate.get("release_id") != release_id:
        raise GateError("candidate-spec release_id does not match")
    gitops = candidate.get("gitops")
    if not isinstance(gitops, dict):
        raise GateError("candidate-spec gitops object is missing")
    base_sha = _nonzero(SHA40, gitops.get("base_sha"), "gitops.base_sha")

    migration = _exact_keys(
        candidate.get("shared_migration"),
        {
            "repository",
            "source_sha",
            "shared_version",
            "shared_jar_sha256",
            "image_repository",
            "image_digest",
            "flyway_target",
            "required_migration",
            "rollback_policy",
        },
        "shared_migration",
    )
    expected = {
        "repository": REPOSITORY,
        "source_sha": source_sha,
        "shared_version": SHARED_VERSION,
        "shared_jar_sha256": SHARED_JAR_SHA256,
        "image_repository": IMAGE_REPOSITORY,
        "flyway_target": FLYWAY_TARGET,
        "required_migration": REQUIRED_MIGRATION,
        "rollback_policy": ROLLBACK_POLICY,
    }
    for key, value in expected.items():
        if migration.get(key) != value:
            raise GateError(f"shared_migration.{key} must equal {value}")
    image_digest = _nonzero(
        DIGEST, migration.get("image_digest"), "shared_migration.image_digest"
    )
    return {
        "candidate_spec_sha256": candidate_sha,
        "gitops_base_sha": base_sha,
        "image_digest": image_digest,
    }


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


def verify_dispatch(root: Path, source_sha: str) -> None:
    validate_dispatch_context(
        os.environ,
        _git(root, "rev-parse", "HEAD"),
        _git(root, "rev-parse", "refs/remotes/origin/main"),
        _git(root, "status", "--porcelain=v1", "--untracked-files=all"),
        source_sha,
    )
    print(f"verified protected migration dispatch source {source_sha}")


def _write_outputs(path: Path, values: Mapping[str, str]) -> None:
    if path.is_symlink() or not path.is_file():
        raise GateError("GITHUB_OUTPUT must already exist as one regular file")
    with path.open("a", encoding="utf-8", newline="\n") as output:
        for key, value in values.items():
            if "\n" in key or "\n" in value:
                raise GateError("GitHub output values must be single-line")
            output.write(f"{key}={value}\n")


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    dispatch = subparsers.add_parser("verify-dispatch")
    dispatch.add_argument("--root", type=Path, required=True)
    dispatch.add_argument("--source-sha", required=True)

    release = subparsers.add_parser("validate-sealed-release")
    release.add_argument("--release-id", required=True)
    release.add_argument("--source-sha", required=True)
    release.add_argument("--release", type=Path, required=True)
    release.add_argument("--candidate", type=Path, required=True)
    release.add_argument("--expected-release-sha256", required=True)
    release.add_argument("--github-output", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "verify-dispatch":
            verify_dispatch(args.root.resolve(), args.source_sha)
        elif args.command == "validate-sealed-release":
            values = validate_sealed_release(
                release_id=args.release_id,
                source_sha=args.source_sha,
                release_sha256=args.expected_release_sha256,
                release_raw=args.release.read_bytes(),
                candidate_raw=args.candidate.read_bytes(),
            )
            _write_outputs(args.github_output, values)
            print("verified sealed release and exact migration image digest")
        else:  # pragma: no cover
            raise GateError("unsupported migration gate command")
    except (GateError, OSError, subprocess.CalledProcessError) as exc:
        print(f"migration release verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
