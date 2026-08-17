#!/usr/bin/env python3
"""Fail-closed gate for the sealed ET9 migration GitOps update."""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
from typing import Mapping, Sequence


REPOSITORY = "DevPathAi/devpath-shared"
GITOPS_REPOSITORY = "DevPathAi/devpath-gitops"
GITOPS_WRITE_APP_SLUG = "devpath-gitops-release"
GITOPS_BRANCH = "main"
GITOPS_REF = "refs/heads/main"
INTEGRITY_RULESET_NAME = "mission-spine-main-integrity"
GOVERNANCE_RULESET_NAME = "mission-spine-main-governance"
GITHUB_ACTIONS_INTEGRATION_ID = 15368
REQUIRED_STATUS_CHECKS = ("mission-spine-release-contract", "kustomize")
WORKFLOW_PATH = ".github/workflows/mission-spine-migration-release.yml"
WORKFLOW_REF = f"{REPOSITORY}/{WORKFLOW_PATH}@refs/heads/main"
ENVIRONMENT_NAME = "mission-spine-migration-release"
JOB_NAME = "deploy"
MIGRATION_PATH = "apps/devpath-migration/base/kustomization.yaml"
MIGRATION_JOB_PREFIX = "devpath-flyway-migrate-"
MIGRATION_JOB_BASE_NAME = "devpath-flyway-migrate"
BOT_NAME = f"{GITOPS_WRITE_APP_SLUG}[bot]"
RESULT_DOCUMENT_TYPE = "mission-spine-migration-result"
RESULT_FILENAME = "evidence.json"
RESULT_SCHEMA_VERSION = 1
MAX_API_DOCUMENT_BYTES = 262_144
MAX_WORKFLOW_BYTES = 131_072
MAX_EVIDENCE_BYTES = 16_384
MAX_KUSTOMIZATION_BYTES = 65_536
MAX_RENDER_BYTES = 2_000_000
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
POSITIVE_INTEGER = re.compile(r"^[1-9][0-9]{0,19}$")
LOGIN = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$")
UTC_Z = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")
PUBLISH_MODES = {"published", "reused"}


class GateError(ValueError):
    """Raised when a migration release trust check fails."""


def _nonzero(pattern: re.Pattern[str], value: object, label: str) -> str:
    if not isinstance(value, str) or pattern.fullmatch(value) is None:
        raise GateError(f"{label} has an invalid format")
    hex_value = value.removeprefix("sha256:")
    if set(hex_value) == {"0"}:
        raise GateError(f"{label} must not be all zeroes")
    return value


def _reject_json_constant(value: str) -> object:
    raise GateError(f"JSON constant {value} is not permitted")


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise GateError(f"JSON contains duplicate key {key}")
        result[key] = value
    return result


def _json_value(raw: bytes, label: str, maximum: int) -> object:
    if not raw or len(raw) > maximum:
        raise GateError(f"{label} size is outside the allowed bound")
    try:
        text = raw.decode("utf-8")
        if text.startswith("\ufeff"):
            raise GateError(f"{label} must not contain a UTF-8 BOM")
        document = json.loads(
            text,
            object_pairs_hook=_reject_duplicate_keys,
            parse_constant=_reject_json_constant,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GateError(f"{label} is not valid UTF-8 JSON") from exc
    return document


def _json_object(
    raw: bytes, label: str, maximum: int = MAX_API_DOCUMENT_BYTES
) -> dict[str, object]:
    document = _json_value(raw, label, maximum)
    if not isinstance(document, dict):
        raise GateError(f"{label} root must be an object")
    return document


def _json_array(
    raw: bytes, label: str, maximum: int = MAX_API_DOCUMENT_BYTES
) -> list[object]:
    document = _json_value(raw, label, maximum)
    if not isinstance(document, list):
        raise GateError(f"{label} root must be an array")
    return document


def _exact_keys(value: object, expected: set[str], label: str) -> dict[str, object]:
    if not isinstance(value, dict) or set(value) != expected:
        raise GateError(f"{label} keys must be exactly {sorted(expected)}")
    return value


def _ordered_keys(
    value: object, expected: Sequence[str], label: str
) -> dict[str, object]:
    if not isinstance(value, dict) or list(value) != list(expected):
        raise GateError(f"{label} keys must be exactly ordered as {list(expected)}")
    return value


def _exact_json_value(actual: object, expected: object, label: str) -> None:
    if type(actual) is not type(expected):
        raise GateError(f"{label} has an invalid JSON type")
    if isinstance(expected, dict):
        if not isinstance(actual, dict) or set(actual) != set(expected):
            raise GateError(f"{label} keys are not exact")
        for key, value in expected.items():
            _exact_json_value(actual[key], value, f"{label}.{key}")
        return
    if isinstance(expected, list):
        if not isinstance(actual, list) or len(actual) != len(expected):
            raise GateError(f"{label} array is not exact")
        for index, value in enumerate(expected):
            _exact_json_value(actual[index], value, f"{label}[{index}]")
        return
    if actual != expected:
        raise GateError(f"{label} value is not exact")


def _positive_integer(value: object, label: str) -> int:
    if type(value) is not int or value <= 0:
        raise GateError(f"{label} must be a positive integer")
    return value


def _positive_integer_string(value: object, label: str) -> int:
    if not isinstance(value, str) or POSITIVE_INTEGER.fullmatch(value) is None:
        raise GateError(f"{label} must be a positive decimal integer")
    return int(value)


def _login(value: object, label: str) -> str:
    if not isinstance(value, str) or LOGIN.fullmatch(value) is None:
        raise GateError(f"{label} is not a canonical GitHub login")
    return value


def _utc_z_seconds(value: object, label: str) -> str:
    if not isinstance(value, str) or UTC_Z.fullmatch(value) is None:
        raise GateError(f"{label} must be UTC-Z seconds")
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")
    except ValueError as exc:
        raise GateError(f"{label} is not a real UTC timestamp") from exc
    return value


def _canonical_json(value: object) -> bytes:
    return (json.dumps(value, separators=(",", ":")) + "\n").encode("utf-8")


def _read_regular_file(path: Path, label: str, maximum: int) -> bytes:
    if path.is_symlink():
        raise GateError(f"{label} must be one regular non-symlink file")
    flags = os.O_RDONLY
    flags |= getattr(os, "O_BINARY", 0)
    flags |= getattr(os, "O_CLOEXEC", 0)
    flags |= getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as exc:
        raise GateError(f"{label} must be one regular non-symlink file") from exc
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode):
            raise GateError(f"{label} must be one regular non-symlink file")
        if before.st_size <= 0 or before.st_size > maximum:
            raise GateError(f"{label} size is outside the allowed bound")
        chunks: list[bytes] = []
        remaining = before.st_size + 1
        while remaining > 0:
            chunk = os.read(descriptor, min(remaining, 65_536))
            if not chunk:
                break
            chunks.append(chunk)
            remaining -= len(chunk)
        raw = b"".join(chunks)
        after = os.fstat(descriptor)
        identity_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
        )
        identity_after = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
        )
        if len(raw) != before.st_size or identity_after != identity_before:
            raise GateError(f"{label} changed while it was read")
        return raw
    finally:
        os.close(descriptor)


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
        "GITHUB_WORKFLOW_REF": WORKFLOW_REF,
        "GITHUB_WORKFLOW_SHA": expected_source_sha,
        "GITHUB_JOB": JOB_NAME,
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
    _positive_integer_string(env.get("GITHUB_RUN_ID"), "GITHUB_RUN_ID")


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
        raise GateError(
            "release-manifest raw SHA-256 does not match the dispatch input"
        )

    release = _json_object(release_raw, "release-manifest")
    if release.get("document_type") != "release-manifest":
        raise GateError("document_type must be release-manifest")
    if release.get("release_id") != release_id:
        raise GateError("release-manifest release_id does not match")
    attestation = release.get("validation_attestation")
    if not isinstance(attestation, dict):
        raise GateError("release-manifest validation_attestation is missing")
    validator_head_sha = _nonzero(
        SHA40,
        attestation.get("validator_head_sha"),
        "validation_attestation.validator_head_sha",
    )
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
        "validator_head_sha": validator_head_sha,
    }


def derived_migration_job_name(image_digest: str) -> str:
    digest = _nonzero(DIGEST, image_digest, "migration image digest")
    return MIGRATION_JOB_PREFIX + digest.removeprefix("sha256:")[:24]


def _validate_lf_text(raw: bytes, label: str, maximum: int) -> str:
    if not raw or len(raw) > maximum:
        raise GateError(f"{label} size is outside the allowed bound")
    if b"\x00" in raw or b"\r" in raw or not raw.endswith(b"\n"):
        raise GateError(f"{label} must be NUL-free LF-terminated UTF-8")
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise GateError(f"{label} must be UTF-8") from exc


def _migration_release_patch(image_digest: str) -> bytes:
    job_name = derived_migration_job_name(image_digest)
    return (
        "patches:\n"
        "- target:\n"
        "    group: batch\n"
        "    version: v1\n"
        "    kind: Job\n"
        f"    name: {MIGRATION_JOB_BASE_NAME}\n"
        "  patch: |-\n"
        "    - op: replace\n"
        "      path: /metadata/name\n"
        f"      value: {job_name}\n"
        "    - op: replace\n"
        "      path: /spec/suspend\n"
        "      value: false\n"
    ).encode("utf-8")


def add_migration_release_patch(kustomization_raw: bytes, image_digest: str) -> bytes:
    text = _validate_lf_text(
        kustomization_raw, "migration kustomization", MAX_KUSTOMIZATION_BYTES
    )
    if re.search(
        r"(?m)^patches(?:Json6902|StrategicMerge)?\s*:", text
    ) is not None:
        raise GateError("base migration kustomization contains a patch collection")
    forbidden = (
        "argocd.argoproj.io/sync-options",
        "Force=true",
        "Replace=true",
        "/metadata/name",
        "/spec/suspend",
    )
    for literal in forbidden:
        if literal in text:
            raise GateError(
                f"base migration kustomization contains forbidden {literal}"
            )
    digest = _nonzero(DIGEST, image_digest, "migration image digest")
    if text.count(f"digest: {digest}") != 1:
        raise GateError("migration kustomization must contain the exact digest once")
    if "newTag:" in text:
        raise GateError("migration kustomization must not retain a mutable newTag")
    result = kustomization_raw + _migration_release_patch(digest)
    validate_migration_kustomization(result, digest)
    return result


def validate_migration_kustomization(raw: bytes, image_digest: str) -> None:
    text = _validate_lf_text(raw, "migration kustomization", MAX_KUSTOMIZATION_BYTES)
    digest = _nonzero(DIGEST, image_digest, "migration image digest")
    if "argocd.argoproj.io/sync-options" in text:
        raise GateError("migration kustomization must not set Argo sync options")
    if "Force=true" in text or "Replace=true" in text:
        raise GateError("migration kustomization must not force or replace Jobs")
    if "newTag:" in text:
        raise GateError("migration kustomization must not retain a mutable newTag")
    if text.count(f"digest: {digest}") != 1:
        raise GateError("migration kustomization must contain the exact digest once")
    patch = _migration_release_patch(digest)
    if not raw.endswith(patch) or raw.count(patch) != 1:
        raise GateError("migration release patch bytes are not exact")
    prefix = raw[: -len(patch)]
    prefix_text = prefix.decode("utf-8")
    if re.search(
        r"(?m)^patches(?:Json6902|StrategicMerge)?\s*:", prefix_text
    ) is not None:
        raise GateError("migration kustomization contains an extra patch collection")


def validate_migration_render(render_raw: bytes, image_digest: str) -> str:
    text = _validate_lf_text(render_raw, "migration render", MAX_RENDER_BYTES)
    digest = _nonzero(DIGEST, image_digest, "migration image digest")
    job_name = derived_migration_job_name(digest)
    if "argocd.argoproj.io/sync-options" in text:
        raise GateError("migration render must not contain Argo sync options")
    if "Force=true" in text or "Replace=true" in text:
        raise GateError("migration render must not contain force/replace options")
    documents = re.split(r"(?m)^---\s*$\n?", text)
    jobs = [
        document
        for document in documents
        if re.search(r"(?m)^kind:\s*Job\s*$", document) is not None
    ]
    if len(jobs) != 1:
        raise GateError("migration render must contain exactly one Job")
    job = jobs[0]
    names = re.findall(r"(?m)^  name:\s*([^\s#]+)\s*$", job)
    if names != [job_name]:
        raise GateError("migration Job name is not the exact digest-derived name")
    image_line = f"image: {IMAGE_REPOSITORY}@{digest}"
    migration_images = [
        line.strip()
        for line in job.splitlines()
        if line.strip().startswith(f"image: {IMAGE_REPOSITORY}")
    ]
    if migration_images != [image_line]:
        raise GateError("migration Job does not contain the exact immutable image once")
    if len(re.findall(r"(?m)^  suspend:\s*false\s*$", job)) != 1:
        raise GateError("migration Job must be unsuspended exactly once")
    if re.search(r"(?m)^  suspend:\s*true\s*$", job) is not None:
        raise GateError("migration Job must not remain suspended")
    return job_name


def validate_base_migration_render(render_raw: bytes) -> None:
    text = _validate_lf_text(render_raw, "base migration render", MAX_RENDER_BYTES)
    if "argocd.argoproj.io/sync-options" in text:
        raise GateError("base migration render must not contain Argo sync options")
    if "Force=true" in text or "Replace=true" in text:
        raise GateError("base migration render must not contain force/replace options")
    documents = re.split(r"(?m)^---\s*$\n?", text)
    jobs = [
        document
        for document in documents
        if re.search(r"(?m)^kind:\s*Job\s*$", document) is not None
    ]
    if len(jobs) != 1:
        raise GateError("base migration render must contain exactly one Job")
    job = jobs[0]
    names = re.findall(r"(?m)^  name:\s*([^\s#]+)\s*$", job)
    if names != [MIGRATION_JOB_BASE_NAME]:
        raise GateError("base migration Job name is not exact")
    if len(re.findall(r"(?m)^  suspend:\s*true\s*$", job)) != 1:
        raise GateError("base migration Job must be suspended exactly once")
    if re.search(r"(?m)^  suspend:\s*false\s*$", job) is not None:
        raise GateError("base migration Job must not be runnable")


def validate_protected_approval(
    *,
    env: Mapping[str, str],
    environment_raw: bytes,
    approvals_raw: bytes,
    jobs_raw: bytes,
) -> dict[str, object]:
    source_sha = _nonzero(SHA40, env.get("GITHUB_SHA"), "GITHUB_SHA")
    expected_context = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "workflow_dispatch",
        "GITHUB_REF": GITOPS_REF,
        "GITHUB_WORKFLOW_REF": WORKFLOW_REF,
        "GITHUB_WORKFLOW_SHA": source_sha,
        "GITHUB_RUN_ATTEMPT": "1",
        "GITHUB_JOB": JOB_NAME,
    }
    for key, expected in expected_context.items():
        if env.get(key) != expected:
            raise GateError(f"{key} must equal {expected}")
    _positive_integer_string(env.get("GITHUB_RUN_ID"), "GITHUB_RUN_ID")
    actor = _login(env.get("GITHUB_ACTOR"), "GITHUB_ACTOR")
    triggering_actor = _login(
        env.get("GITHUB_TRIGGERING_ACTOR"), "GITHUB_TRIGGERING_ACTOR"
    )

    environment = _json_object(environment_raw, "protected environment")
    environment_id = _positive_integer(environment.get("id"), "environment.id")
    if environment.get("name") != ENVIRONMENT_NAME:
        raise GateError("protected environment name is not exact")
    rules = environment.get("protection_rules")
    if not isinstance(rules, list):
        raise GateError("environment protection_rules must be an array")
    reviewer_rules = [
        rule
        for rule in rules
        if isinstance(rule, dict) and rule.get("type") == "required_reviewers"
    ]
    if len(reviewer_rules) != 1:
        raise GateError("environment must have exactly one required-reviewers rule")
    rule = reviewer_rules[0]
    if rule.get("prevent_self_review") is not True:
        raise GateError("environment must prevent self review")
    configured = rule.get("reviewers")
    if not isinstance(configured, list) or len(configured) != 1:
        raise GateError("environment must have exactly one configured reviewer")
    configured_entry = configured[0]
    if not isinstance(configured_entry, dict) or configured_entry.get("type") != "User":
        raise GateError("environment reviewer must be one direct User")
    configured_user = configured_entry.get("reviewer")
    if not isinstance(configured_user, dict) or configured_user.get("type") != "User":
        raise GateError("environment reviewer identity is invalid")
    configured_login = _login(
        configured_user.get("login"), "environment reviewer login"
    )
    configured_id = _positive_integer(
        configured_user.get("id"), "environment reviewer id"
    )

    approvals = _json_array(approvals_raw, "workflow approval history")
    if len(approvals) != 1 or not isinstance(approvals[0], dict):
        raise GateError("workflow must have exactly one approval record")
    approval = approvals[0]
    if approval.get("state") != "approved":
        raise GateError("workflow approval state must be approved")
    approval_environments = approval.get("environments")
    if not isinstance(approval_environments, list) or len(approval_environments) != 1:
        raise GateError("approval must cover exactly one environment")
    approved_environment = approval_environments[0]
    if not isinstance(approved_environment, dict):
        raise GateError("approved environment identity is invalid")
    _exact_json_value(
        approved_environment.get("id"), environment_id, "approved environment id"
    )
    _exact_json_value(
        approved_environment.get("name"),
        ENVIRONMENT_NAME,
        "approved environment name",
    )
    reviewer = approval.get("user")
    if not isinstance(reviewer, dict) or reviewer.get("type") != "User":
        raise GateError("approval reviewer must be a User")
    reviewer_login = _login(reviewer.get("login"), "approval reviewer login")
    reviewer_id = _positive_integer(reviewer.get("id"), "approval reviewer id")
    if reviewer_login != configured_login or reviewer_id != configured_id:
        raise GateError("approval reviewer is not the configured direct User")
    if reviewer_login.casefold() in {actor.casefold(), triggering_actor.casefold()}:
        raise GateError("approval reviewer must be independent from run initiators")

    jobs = _json_object(jobs_raw, "attempt-one jobs")
    if type(jobs.get("total_count")) is not int or jobs.get("total_count") != 1:
        raise GateError("workflow attempt must contain exactly one job")
    job_values = jobs.get("jobs")
    if not isinstance(job_values, list) or len(job_values) != 1:
        raise GateError("workflow attempt jobs array must contain exactly one job")
    job = job_values[0]
    if not isinstance(job, dict):
        raise GateError("workflow job identity is invalid")
    _positive_integer(job.get("id"), "workflow job id")
    expected_job = {
        "name": JOB_NAME,
        "run_attempt": 1,
        "head_sha": source_sha,
        "status": "in_progress",
        "conclusion": None,
    }
    for key, expected in expected_job.items():
        _exact_json_value(job.get(key), expected, f"workflow job {key}")
    started_at = _utc_z_seconds(job.get("started_at"), "workflow job started_at")
    return {
        "environment_id": environment_id,
        "reviewer_login": reviewer_login,
        "reviewer_id": reviewer_id,
        "reviewer_type": "User",
        "state": "approved",
        "approval_effective_at": started_at,
    }


def _validate_ruleset_header(
    ruleset: dict[str, object], expected_name: str, expected_id: int
) -> None:
    expected = {
        "id": expected_id,
        "name": expected_name,
        "target": "branch",
        "source_type": "Repository",
        "source": GITOPS_REPOSITORY,
        "enforcement": "active",
    }
    for key, value in expected.items():
        _exact_json_value(
            ruleset.get(key), value, f"ruleset {expected_name} {key}"
        )
    conditions = _exact_keys(ruleset.get("conditions"), {"ref_name"}, "conditions")
    ref_name = _exact_keys(
        conditions.get("ref_name"), {"include", "exclude"}, "ref_name condition"
    )
    if ref_name.get("include") != [GITOPS_REF] or ref_name.get("exclude") != []:
        raise GateError(f"ruleset {expected_name} must target only refs/heads/main")


def _rules_by_type(
    ruleset: dict[str, object], expected: set[str]
) -> dict[str, dict[str, object]]:
    values = ruleset.get("rules")
    if not isinstance(values, list) or len(values) != len(expected):
        raise GateError(f"ruleset rules must be exactly {sorted(expected)}")
    result: dict[str, dict[str, object]] = {}
    for value in values:
        if not isinstance(value, dict) or not isinstance(value.get("type"), str):
            raise GateError("ruleset contains an invalid rule")
        rule_type = value["type"]
        if rule_type in result:
            raise GateError(f"ruleset contains duplicate {rule_type} rule")
        result[rule_type] = value
    if set(result) != expected:
        raise GateError(f"ruleset rules must be exactly {sorted(expected)}")
    return result


def _validate_integrity_ruleset(ruleset: dict[str, object], ruleset_id: int) -> None:
    _validate_ruleset_header(ruleset, INTEGRITY_RULESET_NAME, ruleset_id)
    if ruleset.get("bypass_actors") != []:
        raise GateError("integrity ruleset must have no bypass actors")
    rules = _rules_by_type(
        ruleset, {"deletion", "non_fast_forward", "required_linear_history"}
    )
    for rule_type, rule in rules.items():
        if set(rule) != {"type"}:
            raise GateError(f"integrity {rule_type} rule must not have parameters")


def _validate_governance_ruleset(
    ruleset: dict[str, object], ruleset_id: int, app_id: int
) -> None:
    _validate_ruleset_header(ruleset, GOVERNANCE_RULESET_NAME, ruleset_id)
    bypass = ruleset.get("bypass_actors")
    if not isinstance(bypass, list) or len(bypass) != 1:
        raise GateError("governance ruleset must expose exactly one bypass actor")
    _exact_json_value(
        bypass[0],
        {
            "actor_id": app_id,
            "actor_type": "Integration",
            "bypass_mode": "always",
        },
        "governance ruleset bypass",
    )
    rules = _rules_by_type(ruleset, {"pull_request", "required_status_checks"})
    pull_request = _exact_keys(
        rules["pull_request"], {"type", "parameters"}, "pull_request rule"
    )
    expected_pull_request = {
        "allowed_merge_methods": ["squash"],
        "dismiss_stale_reviews_on_push": True,
        "dismissal_restriction": {"enabled": False, "allowed_actors": []},
        "require_code_owner_review": False,
        "require_last_push_approval": True,
        "required_approving_review_count": 1,
        "required_review_thread_resolution": True,
        "required_reviewers": [],
    }
    _exact_json_value(
        pull_request.get("parameters"),
        expected_pull_request,
        "governance pull-request parameters",
    )
    checks_rule = _exact_keys(
        rules["required_status_checks"],
        {"type", "parameters"},
        "required_status_checks rule",
    )
    expected_checks = {
        "do_not_enforce_on_create": False,
        "required_status_checks": [
            {
                "context": REQUIRED_STATUS_CHECKS[0],
                "integration_id": GITHUB_ACTIONS_INTEGRATION_ID,
            },
            {
                "context": REQUIRED_STATUS_CHECKS[1],
                "integration_id": GITHUB_ACTIONS_INTEGRATION_ID,
            },
        ],
        "strict_required_status_checks_policy": True,
    }
    _exact_json_value(
        checks_rule.get("parameters"),
        expected_checks,
        "governance required status checks",
    )


def validate_gitops_authorization(
    *,
    app_slug: str,
    app_id: str,
    installation_id: str,
    repositories_raw: bytes,
    classic_protection_status: str,
    rulesets_raw: bytes,
    ruleset_details_raw: Sequence[bytes],
) -> dict[str, object]:
    if app_slug != GITOPS_WRITE_APP_SLUG:
        raise GateError(f"GitOps write App slug must equal {GITOPS_WRITE_APP_SLUG}")
    expected_app_id = _positive_integer_string(app_id, "GitOps App id")
    expected_installation_id = _positive_integer_string(
        installation_id, "GitOps App installation id"
    )

    repositories = _json_object(repositories_raw, "installation repositories")
    repository_values = repositories.get("repositories")
    if (
        type(repositories.get("total_count")) is not int
        or repositories.get("total_count") != 1
        or not isinstance(repository_values, list)
        or len(repository_values) != 1
        or not isinstance(repository_values[0], dict)
        or repository_values[0].get("full_name") != GITOPS_REPOSITORY
    ):
        raise GateError("GitOps App token is not scoped to exactly devpath-gitops")
    if classic_protection_status != "404":
        raise GateError("classic GitOps main branch protection must be absent")

    pages = _json_array(rulesets_raw, "effective GitOps rulesets")
    flattened: list[dict[str, object]] = []
    for page in pages:
        if not isinstance(page, list):
            raise GateError("effective ruleset page must be an array")
        for value in page:
            if not isinstance(value, dict):
                raise GateError("effective ruleset summary is invalid")
            flattened.append(value)
    if len(flattened) != 2:
        raise GateError("exactly two effective GitOps main rulesets are required")
    summaries: dict[str, dict[str, object]] = {}
    for summary in flattened:
        name = summary.get("name")
        if not isinstance(name, str) or name in summaries:
            raise GateError("effective GitOps ruleset names are not unique")
        summaries[name] = summary
    if set(summaries) != {INTEGRITY_RULESET_NAME, GOVERNANCE_RULESET_NAME}:
        raise GateError("effective GitOps ruleset names are not exact")
    summary_ids: dict[str, int] = {}
    for name, summary in summaries.items():
        summary_id = _positive_integer(summary.get("id"), f"{name} ruleset id")
        expected_summary = {
            "source_type": "Repository",
            "source": GITOPS_REPOSITORY,
            "enforcement": "active",
        }
        for key, expected in expected_summary.items():
            if summary.get(key) != expected:
                raise GateError(f"effective ruleset {name} {key} is not exact")
        summary_ids[name] = summary_id
    if len(set(summary_ids.values())) != 2:
        raise GateError("effective GitOps ruleset ids are not unique")
    if len(ruleset_details_raw) != 2:
        raise GateError("exactly two detailed ruleset documents are required")
    details: dict[str, dict[str, object]] = {}
    for index, raw in enumerate(ruleset_details_raw):
        detail = _json_object(raw, f"ruleset detail {index + 1}")
        name = detail.get("name")
        if not isinstance(name, str) or name in details:
            raise GateError("detailed ruleset names are invalid")
        details[name] = detail
    if set(details) != set(summaries):
        raise GateError("detailed rulesets do not match effective summaries")
    _validate_integrity_ruleset(
        details[INTEGRITY_RULESET_NAME], summary_ids[INTEGRITY_RULESET_NAME]
    )
    _validate_governance_ruleset(
        details[GOVERNANCE_RULESET_NAME],
        summary_ids[GOVERNANCE_RULESET_NAME],
        expected_app_id,
    )
    return {
        "write_app_slug": GITOPS_WRITE_APP_SLUG,
        "write_app_id": expected_app_id,
        "write_app_installation_id": expected_installation_id,
    }


def validate_migration_facts(
    *,
    release_id: str,
    release_manifest_sha256: str,
    gitops_base_sha: str,
    pre_push_main_sha: str,
    migration_commit_sha: str,
    migration_parent_sha: str,
    migration_tree_sha: str,
    expected_tree_sha: str,
    changed_paths: Sequence[str],
    commit_subject: str,
    commit_author_name: str,
    commit_committer_name: str,
    publish_mode: str,
) -> dict[str, object]:
    if RELEASE_ID.fullmatch(release_id) is None:
        raise GateError("release_id has an invalid format")
    release_sha = _nonzero(
        SHA64, release_manifest_sha256, "release_manifest_sha256"
    )
    base_sha = _nonzero(SHA40, gitops_base_sha, "gitops base SHA")
    pre_push_sha = _nonzero(SHA40, pre_push_main_sha, "pre-push main SHA")
    migration_sha = _nonzero(SHA40, migration_commit_sha, "migration commit SHA")
    parent_sha = _nonzero(SHA40, migration_parent_sha, "migration parent SHA")
    tree_sha = _nonzero(SHA40, migration_tree_sha, "migration tree SHA")
    expected_tree = _nonzero(SHA40, expected_tree_sha, "expected migration tree SHA")
    if migration_sha == base_sha:
        raise GateError("migration commit must be a distinct child of the GitOps base")
    if parent_sha != base_sha:
        raise GateError("migration commit parent does not equal the sealed GitOps base")
    if tree_sha != expected_tree:
        raise GateError("migration commit tree does not equal the reconstructed tree")
    if list(changed_paths) != [MIGRATION_PATH]:
        raise GateError(
            "migration commit must change exactly the sole kustomization path"
        )
    expected_subject = f"deploy(devpath-migration): {release_id} sealed {release_sha}"
    if commit_subject != expected_subject:
        raise GateError("migration commit subject is not exact")
    if commit_author_name != BOT_NAME or commit_committer_name != BOT_NAME:
        raise GateError(
            "migration commit author and committer must be the release App bot"
        )
    if not isinstance(publish_mode, str) or publish_mode not in PUBLISH_MODES:
        raise GateError("migration publish mode is invalid")
    expected_pre_push = base_sha if publish_mode == "published" else migration_sha
    if pre_push_sha != expected_pre_push:
        raise GateError("pre-push main SHA does not match the publish mode")
    return {
        "pre_push_main_sha": pre_push_sha,
        "migration_commit_sha": migration_sha,
        "migration_tree_sha": tree_sha,
        "publish_mode": publish_mode,
        "sole_changed_path": MIGRATION_PATH,
        "commit_subject": expected_subject,
        "commit_author_name": BOT_NAME,
        "commit_committer_name": BOT_NAME,
    }


def validate_pre_reconstruction_source_facts(
    *,
    release_id: str,
    release_manifest_sha256: str,
    gitops_base_sha: str,
    supplied_source_sha: str,
    current_head_sha: str,
    current_parent_shas: Sequence[str],
    changed_paths: Sequence[str],
    commit_subject: str,
    commit_author_name: str,
    commit_committer_name: str,
) -> str:
    if RELEASE_ID.fullmatch(release_id) is None:
        raise GateError("release_id has an invalid format")
    release_sha = _nonzero(
        SHA64, release_manifest_sha256, "release_manifest_sha256"
    )
    base_sha = _nonzero(SHA40, gitops_base_sha, "gitops base SHA")
    supplied_sha = _nonzero(
        SHA40, supplied_source_sha, "supplied GitOps source SHA"
    )
    head_sha = _nonzero(SHA40, current_head_sha, "current GitOps main SHA")
    if head_sha != supplied_sha:
        raise GateError("supplied GitOps source is not the fetched current main")

    if head_sha == base_sha:
        if (
            list(current_parent_shas)
            or list(changed_paths)
            or commit_subject
            or commit_author_name
            or commit_committer_name
        ):
            raise GateError("base source must not carry migration-child facts")
        return "published"

    parents = [
        _nonzero(SHA40, parent, "current GitOps main parent SHA")
        for parent in current_parent_shas
    ]
    if parents != [base_sha]:
        raise GateError(
            "current GitOps main must be the exact one-parent child of the base"
        )
    if list(changed_paths) != [MIGRATION_PATH]:
        raise GateError(
            "pre-existing migration child must change only the migration path"
        )
    expected_subject = f"deploy(devpath-migration): {release_id} sealed {release_sha}"
    if commit_subject != expected_subject:
        raise GateError("pre-existing migration child subject is not exact")
    if commit_author_name != BOT_NAME or commit_committer_name != BOT_NAME:
        raise GateError("pre-existing migration child actor names are not exact")
    return "reused"


def build_result_evidence(
    *,
    env: Mapping[str, str],
    release_id: str,
    candidate_spec_sha256: str,
    release_manifest_sha256: str,
    workflow_raw: bytes,
    environment_raw: bytes,
    approvals_raw: bytes,
    jobs_raw: bytes,
    gitops_base_sha: str,
    sealed_release_sha: str,
    pre_push_main_sha: str,
    migration_commit_sha: str,
    migration_tree_sha: str,
    publish_mode: str,
    gitops_write_app_slug: str,
    gitops_write_app_id: str,
    gitops_write_app_installation_id: str,
    sole_changed_path: str,
    rendered_job_name: str,
    commit_subject: str,
    commit_author_name: str,
    commit_committer_name: str,
    image_digest: str,
) -> bytes:
    if RELEASE_ID.fullmatch(release_id) is None:
        raise GateError("release_id has an invalid format")
    candidate_sha = _nonzero(
        SHA64, candidate_spec_sha256, "candidate_spec_sha256"
    )
    release_sha = _nonzero(
        SHA64, release_manifest_sha256, "release_manifest_sha256"
    )
    source_sha = _nonzero(SHA40, env.get("GITHUB_SHA"), "GITHUB_SHA")
    expected_context = {
        "GITHUB_REPOSITORY": REPOSITORY,
        "GITHUB_EVENT_NAME": "workflow_dispatch",
        "GITHUB_REF": GITOPS_REF,
        "GITHUB_WORKFLOW_REF": WORKFLOW_REF,
        "GITHUB_WORKFLOW_SHA": source_sha,
        "GITHUB_RUN_ATTEMPT": "1",
        "GITHUB_JOB": JOB_NAME,
    }
    for key, expected in expected_context.items():
        if env.get(key) != expected:
            raise GateError(f"{key} must equal {expected}")
    run_id = _positive_integer_string(env.get("GITHUB_RUN_ID"), "GITHUB_RUN_ID")
    workflow_text = _validate_lf_text(
        workflow_raw, "migration release workflow", MAX_WORKFLOW_BYTES
    )
    expected_workflow_name = (
        "name: Mission Spine - sealed migration GitOps release\n"
    )
    if not workflow_text.startswith(expected_workflow_name):
        raise GateError(
            "migration release workflow bytes are not the expected workflow"
        )
    workflow_sha256 = hashlib.sha256(workflow_raw).hexdigest()
    approval = validate_protected_approval(
        env=env,
        environment_raw=environment_raw,
        approvals_raw=approvals_raw,
        jobs_raw=jobs_raw,
    )
    base_sha = _nonzero(SHA40, gitops_base_sha, "gitops base SHA")
    sealed_sha = _nonzero(SHA40, sealed_release_sha, "sealed release SHA")
    pre_push_sha = _nonzero(SHA40, pre_push_main_sha, "pre-push main SHA")
    migration_sha = _nonzero(SHA40, migration_commit_sha, "migration commit SHA")
    tree_sha = _nonzero(SHA40, migration_tree_sha, "migration tree SHA")
    if not isinstance(publish_mode, str) or publish_mode not in PUBLISH_MODES:
        raise GateError("migration publish mode is invalid")
    if pre_push_sha != (base_sha if publish_mode == "published" else migration_sha):
        raise GateError("pre-push main SHA does not match migration publish mode")
    if migration_sha == base_sha:
        raise GateError("migration commit must be distinct from the GitOps base")
    if gitops_write_app_slug != GITOPS_WRITE_APP_SLUG:
        raise GateError("GitOps write App slug is not exact")
    app_id = _positive_integer_string(gitops_write_app_id, "GitOps App id")
    installation_id = _positive_integer_string(
        gitops_write_app_installation_id, "GitOps App installation id"
    )
    if sole_changed_path != MIGRATION_PATH:
        raise GateError("migration sole changed path is not exact")
    digest = _nonzero(DIGEST, image_digest, "migration image digest")
    expected_job_name = derived_migration_job_name(digest)
    if rendered_job_name != expected_job_name:
        raise GateError("rendered migration Job name is not digest-derived")
    expected_subject = f"deploy(devpath-migration): {release_id} sealed {release_sha}"
    if commit_subject != expected_subject:
        raise GateError("migration commit subject is not exact")
    if commit_author_name != BOT_NAME or commit_committer_name != BOT_NAME:
        raise GateError("migration commit actor names are not exact")
    document: dict[str, object] = {
        "schema_version": RESULT_SCHEMA_VERSION,
        "document_type": RESULT_DOCUMENT_TYPE,
        "release_id": release_id,
        "candidate_spec_sha256": candidate_sha,
        "release_manifest_sha256": release_sha,
        "shared": {
            "repository": REPOSITORY,
            "source_sha": source_sha,
            "workflow_path": WORKFLOW_PATH,
            "workflow_ref": WORKFLOW_REF,
            "workflow_sha256": workflow_sha256,
            "run_id": run_id,
            "run_attempt": 1,
            "event_name": "workflow_dispatch",
            "ref": GITOPS_REF,
            "job": JOB_NAME,
            "environment": ENVIRONMENT_NAME,
        },
        "approval": approval,
        "gitops": {
            "repository": GITOPS_REPOSITORY,
            "base_sha": base_sha,
            "sealed_release_sha": sealed_sha,
            "pre_push_main_sha": pre_push_sha,
            "migration_commit_sha": migration_sha,
            "migration_tree_sha": tree_sha,
            "publish_mode": publish_mode,
            "write_app_slug": GITOPS_WRITE_APP_SLUG,
            "write_app_id": app_id,
            "write_app_installation_id": installation_id,
            "branch": GITOPS_BRANCH,
            "sole_changed_path": MIGRATION_PATH,
            "rendered_job_name": expected_job_name,
            "commit_subject": expected_subject,
            "commit_author_name": BOT_NAME,
            "commit_committer_name": BOT_NAME,
        },
        "migration_image": {
            "repository": IMAGE_REPOSITORY,
            "digest": digest,
        },
    }
    raw = _canonical_json(document)
    validate_result_evidence(raw)
    return raw


def validate_result_evidence(raw: bytes) -> dict[str, object]:
    document = _ordered_keys(
        _json_object(raw, "migration result evidence", MAX_EVIDENCE_BYTES),
        (
            "schema_version",
            "document_type",
            "release_id",
            "candidate_spec_sha256",
            "release_manifest_sha256",
            "shared",
            "approval",
            "gitops",
            "migration_image",
        ),
        "migration result evidence",
    )
    if (
        type(document["schema_version"]) is not int
        or document["schema_version"] != RESULT_SCHEMA_VERSION
    ):
        raise GateError("migration result evidence schema_version is not exact")
    if document["document_type"] != RESULT_DOCUMENT_TYPE:
        raise GateError("migration result evidence document_type is not exact")
    release_id = document["release_id"]
    if not isinstance(release_id, str) or RELEASE_ID.fullmatch(release_id) is None:
        raise GateError("migration result evidence release_id is invalid")
    _nonzero(
        SHA64, document["candidate_spec_sha256"], "candidate_spec_sha256"
    )
    release_sha = _nonzero(
        SHA64, document["release_manifest_sha256"], "release_manifest_sha256"
    )

    shared = _ordered_keys(
        document["shared"],
        (
            "repository",
            "source_sha",
            "workflow_path",
            "workflow_ref",
            "workflow_sha256",
            "run_id",
            "run_attempt",
            "event_name",
            "ref",
            "job",
            "environment",
        ),
        "shared evidence",
    )
    expected_shared = {
        "repository": REPOSITORY,
        "workflow_path": WORKFLOW_PATH,
        "workflow_ref": WORKFLOW_REF,
        "event_name": "workflow_dispatch",
        "ref": GITOPS_REF,
        "job": JOB_NAME,
        "environment": ENVIRONMENT_NAME,
    }
    for key, expected in expected_shared.items():
        if shared[key] != expected:
            raise GateError(f"shared evidence {key} is not exact")
    if type(shared["run_attempt"]) is not int or shared["run_attempt"] != 1:
        raise GateError("shared evidence run_attempt is not exact")
    _nonzero(SHA40, shared["source_sha"], "shared.source_sha")
    _nonzero(SHA64, shared["workflow_sha256"], "shared.workflow_sha256")
    _positive_integer(shared["run_id"], "shared.run_id")

    approval = _ordered_keys(
        document["approval"],
        (
            "environment_id",
            "reviewer_login",
            "reviewer_id",
            "reviewer_type",
            "state",
            "approval_effective_at",
        ),
        "approval evidence",
    )
    _positive_integer(approval["environment_id"], "approval.environment_id")
    _login(approval["reviewer_login"], "approval.reviewer_login")
    _positive_integer(approval["reviewer_id"], "approval.reviewer_id")
    if approval["reviewer_type"] != "User" or approval["state"] != "approved":
        raise GateError("approval evidence reviewer type/state is not exact")
    _utc_z_seconds(
        approval["approval_effective_at"], "approval effective time"
    )

    gitops = _ordered_keys(
        document["gitops"],
        (
            "repository",
            "base_sha",
            "sealed_release_sha",
            "pre_push_main_sha",
            "migration_commit_sha",
            "migration_tree_sha",
            "publish_mode",
            "write_app_slug",
            "write_app_id",
            "write_app_installation_id",
            "branch",
            "sole_changed_path",
            "rendered_job_name",
            "commit_subject",
            "commit_author_name",
            "commit_committer_name",
        ),
        "gitops evidence",
    )
    expected_gitops = {
        "repository": GITOPS_REPOSITORY,
        "write_app_slug": GITOPS_WRITE_APP_SLUG,
        "branch": GITOPS_BRANCH,
        "sole_changed_path": MIGRATION_PATH,
        "commit_author_name": BOT_NAME,
        "commit_committer_name": BOT_NAME,
    }
    for key, expected in expected_gitops.items():
        if gitops[key] != expected:
            raise GateError(f"gitops evidence {key} is not exact")
    base_sha = _nonzero(SHA40, gitops["base_sha"], "gitops.base_sha")
    _nonzero(
        SHA40, gitops["sealed_release_sha"], "gitops.sealed_release_sha"
    )
    pre_push_sha = _nonzero(
        SHA40, gitops["pre_push_main_sha"], "gitops.pre_push_main_sha"
    )
    migration_sha = _nonzero(
        SHA40, gitops["migration_commit_sha"], "gitops.migration_commit_sha"
    )
    _nonzero(SHA40, gitops["migration_tree_sha"], "gitops.migration_tree_sha")
    if migration_sha == base_sha:
        raise GateError("migration evidence commit must differ from its base")
    mode = gitops["publish_mode"]
    if not isinstance(mode, str) or mode not in PUBLISH_MODES:
        raise GateError("gitops evidence publish_mode is invalid")
    if pre_push_sha != (base_sha if mode == "published" else migration_sha):
        raise GateError("gitops pre-push SHA does not match publish mode")
    _positive_integer(gitops["write_app_id"], "gitops.write_app_id")
    _positive_integer(
        gitops["write_app_installation_id"],
        "gitops.write_app_installation_id",
    )
    expected_subject = f"deploy(devpath-migration): {release_id} sealed {release_sha}"
    if gitops["commit_subject"] != expected_subject:
        raise GateError("gitops evidence commit subject is not exact")

    migration_image = _ordered_keys(
        document["migration_image"],
        ("repository", "digest"),
        "migration image evidence",
    )
    if migration_image["repository"] != IMAGE_REPOSITORY:
        raise GateError("migration image repository is not exact")
    digest = _nonzero(DIGEST, migration_image["digest"], "migration image digest")
    if gitops["rendered_job_name"] != derived_migration_job_name(digest):
        raise GateError("gitops rendered Job name is not digest-derived")

    if raw != _canonical_json(document):
        raise GateError("migration result evidence is not canonical JSON plus LF")
    return document


def write_result_evidence(directory: Path, raw: bytes) -> Path:
    validate_result_evidence(raw)
    parent = directory.parent
    if parent.is_symlink() or not parent.is_dir():
        raise GateError("evidence parent must be one existing regular directory")
    try:
        directory.mkdir(mode=0o700)
    except FileExistsError as exc:
        raise GateError("evidence directory already exists") from exc
    if directory.is_symlink() or not directory.is_dir():
        raise GateError("evidence directory is not a regular directory")
    path = directory / RESULT_FILENAME
    try:
        with path.open("xb") as output:
            output.write(raw)
            output.flush()
            os.fsync(output.fileno())
        path.chmod(0o600)
    except OSError as exc:
        raise GateError("could not create immutable result evidence") from exc
    verify_result_evidence_dir(directory)
    return path


def verify_result_evidence_dir(directory: Path) -> dict[str, object]:
    if directory.is_symlink() or not directory.is_dir():
        raise GateError("evidence path must be one regular directory")
    entries = list(directory.iterdir())
    if len(entries) != 1 or entries[0].name != RESULT_FILENAME:
        raise GateError("evidence directory must contain only evidence.json")
    raw = _read_regular_file(entries[0], RESULT_FILENAME, MAX_EVIDENCE_BYTES)
    return validate_result_evidence(raw)


def write_migration_release_patch(path: Path, image_digest: str) -> str:
    raw = _read_regular_file(
        path, "migration kustomization", MAX_KUSTOMIZATION_BYTES
    )
    result = add_migration_release_patch(raw, image_digest)
    temporary = path.with_name(f".{path.name}.mission-spine.tmp")
    if temporary.exists() or temporary.is_symlink():
        raise GateError("migration kustomization temporary path is occupied")
    try:
        with temporary.open("xb") as output:
            output.write(result)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    except OSError as exc:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            pass
        raise GateError("could not atomically add the migration release patch") from exc
    validate_migration_kustomization(
        _read_regular_file(path, "migration kustomization", MAX_KUSTOMIZATION_BYTES),
        image_digest,
    )
    return derived_migration_job_name(image_digest)


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


def inspect_pre_reconstruction_source(
    *,
    root: Path,
    release_id: str,
    release_manifest_sha256: str,
    gitops_base_sha: str,
    supplied_source_sha: str,
) -> str:
    if root.is_symlink() or not root.is_dir():
        raise GateError("GitOps root must be one regular directory")
    status = _git(root, "status", "--porcelain=v1", "--untracked-files=all")
    if status:
        raise GateError("GitOps checkout must be clean before source validation")
    head_sha = _nonzero(
        SHA40, _git(root, "rev-parse", "HEAD"), "current GitOps main SHA"
    )
    base_sha = _nonzero(SHA40, gitops_base_sha, "gitops base SHA")
    if head_sha == base_sha:
        parents: list[str] = []
        changed: list[str] = []
        subject = ""
        author_name = ""
        committer_name = ""
    else:
        revision = _git(root, "rev-list", "--parents", "-n", "1", head_sha).split()
        if not revision or revision[0] != head_sha:
            raise GateError("could not inspect the current GitOps main parents")
        parents = revision[1:]
        changed = (
            _git(
                root,
                "diff-tree",
                "--no-commit-id",
                "--name-only",
                "-r",
                head_sha,
            ).splitlines()
        )
        subject = _git(root, "show", "-s", "--format=%s", head_sha)
        author_name = _git(root, "show", "-s", "--format=%an", head_sha)
        committer_name = _git(root, "show", "-s", "--format=%cn", head_sha)
    return validate_pre_reconstruction_source_facts(
        release_id=release_id,
        release_manifest_sha256=release_manifest_sha256,
        gitops_base_sha=base_sha,
        supplied_source_sha=supplied_source_sha,
        current_head_sha=head_sha,
        current_parent_shas=parents,
        changed_paths=changed,
        commit_subject=subject,
        commit_author_name=author_name,
        commit_committer_name=committer_name,
    )


def inspect_migration_commit(
    *,
    root: Path,
    release_id: str,
    release_manifest_sha256: str,
    gitops_base_sha: str,
    pre_push_main_sha: str,
    expected_tree_sha: str,
    publish_mode: str,
) -> dict[str, object]:
    if root.is_symlink() or not root.is_dir():
        raise GateError("GitOps root must be one regular directory")
    status = _git(root, "status", "--porcelain=v1", "--untracked-files=all")
    if status:
        raise GateError("GitOps checkout must be clean before commit inspection")
    migration_sha = _nonzero(
        SHA40, _git(root, "rev-parse", "HEAD"), "migration commit SHA"
    )
    parents = _git(root, "rev-list", "--parents", "-n", "1", migration_sha).split()
    if len(parents) != 2 or parents[0] != migration_sha:
        raise GateError("migration commit must have exactly one parent")
    parent_sha = parents[1]
    tree_sha = _git(root, "rev-parse", f"{migration_sha}^{{tree}}")
    changed = _git(
        root,
        "diff-tree",
        "--no-commit-id",
        "--name-only",
        "-r",
        parent_sha,
        migration_sha,
    ).splitlines()
    values = validate_migration_facts(
        release_id=release_id,
        release_manifest_sha256=release_manifest_sha256,
        gitops_base_sha=gitops_base_sha,
        pre_push_main_sha=pre_push_main_sha,
        migration_commit_sha=migration_sha,
        migration_parent_sha=parent_sha,
        migration_tree_sha=tree_sha,
        expected_tree_sha=expected_tree_sha,
        changed_paths=changed,
        commit_subject=_git(root, "show", "-s", "--format=%s", migration_sha),
        commit_author_name=_git(root, "show", "-s", "--format=%an", migration_sha),
        commit_committer_name=_git(
            root, "show", "-s", "--format=%cn", migration_sha
        ),
        publish_mode=publish_mode,
    )
    return values


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

    authorization = subparsers.add_parser("verify-gitops-authorization")
    authorization.add_argument("--app-slug", required=True)
    authorization.add_argument("--app-id", required=True)
    authorization.add_argument("--installation-id", required=True)
    authorization.add_argument("--repositories", type=Path, required=True)
    authorization.add_argument("--classic-protection-status", required=True)
    authorization.add_argument("--rulesets", type=Path, required=True)
    authorization.add_argument(
        "--ruleset-detail", type=Path, action="append", required=True
    )
    authorization.add_argument("--github-output", type=Path, required=True)

    approval = subparsers.add_parser("verify-protected-approval")
    approval.add_argument("--environment-document", type=Path, required=True)
    approval.add_argument("--approvals-document", type=Path, required=True)
    approval.add_argument("--jobs-document", type=Path, required=True)

    add_patch = subparsers.add_parser("add-migration-release-patch")
    add_patch.add_argument("--kustomization", type=Path, required=True)
    add_patch.add_argument("--image-digest", required=True)
    add_patch.add_argument("--github-output", type=Path, required=True)

    render = subparsers.add_parser("validate-migration-render")
    render.add_argument("--render", type=Path, required=True)
    render.add_argument("--image-digest", required=True)
    render.add_argument("--github-output", type=Path, required=True)

    base_render = subparsers.add_parser("validate-base-migration-render")
    base_render.add_argument("--render", type=Path, required=True)

    source = subparsers.add_parser("verify-pre-reconstruction-source")
    source.add_argument("--root", type=Path, required=True)
    source.add_argument("--release-id", required=True)
    source.add_argument("--release-manifest-sha256", required=True)
    source.add_argument("--gitops-base-sha", required=True)
    source.add_argument("--supplied-source-sha", required=True)

    commit = subparsers.add_parser("verify-migration-commit")
    commit.add_argument("--root", type=Path, required=True)
    commit.add_argument("--release-id", required=True)
    commit.add_argument("--release-manifest-sha256", required=True)
    commit.add_argument("--gitops-base-sha", required=True)
    commit.add_argument("--pre-push-main-sha", required=True)
    commit.add_argument("--expected-tree-sha", required=True)
    commit.add_argument("--publish-mode", choices=sorted(PUBLISH_MODES), required=True)
    commit.add_argument("--github-output", type=Path, required=True)

    emit = subparsers.add_parser("emit-result-evidence")
    emit.add_argument("--root", type=Path, required=True)
    emit.add_argument("--release-id", required=True)
    emit.add_argument("--candidate-spec-sha256", required=True)
    emit.add_argument("--release-manifest-sha256", required=True)
    emit.add_argument("--workflow", type=Path, required=True)
    emit.add_argument("--environment-document", type=Path, required=True)
    emit.add_argument("--approvals-document", type=Path, required=True)
    emit.add_argument("--jobs-document", type=Path, required=True)
    emit.add_argument("--gitops-base-sha", required=True)
    emit.add_argument("--sealed-release-sha", required=True)
    emit.add_argument("--pre-push-main-sha", required=True)
    emit.add_argument("--expected-tree-sha", required=True)
    emit.add_argument("--publish-mode", choices=sorted(PUBLISH_MODES), required=True)
    emit.add_argument("--app-slug", required=True)
    emit.add_argument("--app-id", required=True)
    emit.add_argument("--installation-id", required=True)
    emit.add_argument("--image-digest", required=True)
    emit.add_argument("--render", type=Path, required=True)
    emit.add_argument("--evidence-dir", type=Path, required=True)

    verify_result = subparsers.add_parser("verify-result-evidence")
    verify_result.add_argument("--evidence-dir", type=Path, required=True)
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
                release_raw=_read_regular_file(
                    args.release, "release-manifest", MAX_API_DOCUMENT_BYTES
                ),
                candidate_raw=_read_regular_file(
                    args.candidate, "candidate-spec", MAX_API_DOCUMENT_BYTES
                ),
            )
            _write_outputs(args.github_output, values)
            print("verified sealed release and exact migration image digest")
        elif args.command == "verify-gitops-authorization":
            values = validate_gitops_authorization(
                app_slug=args.app_slug,
                app_id=args.app_id,
                installation_id=args.installation_id,
                repositories_raw=_read_regular_file(
                    args.repositories,
                    "GitOps App repositories",
                    MAX_API_DOCUMENT_BYTES,
                ),
                classic_protection_status=args.classic_protection_status,
                rulesets_raw=_read_regular_file(
                    args.rulesets, "GitOps rulesets", MAX_API_DOCUMENT_BYTES
                ),
                ruleset_details_raw=tuple(
                    _read_regular_file(
                        detail,
                        f"GitOps ruleset detail {index + 1}",
                        MAX_API_DOCUMENT_BYTES,
                    )
                    for index, detail in enumerate(args.ruleset_detail)
                ),
            )
            _write_outputs(
                args.github_output,
                {key: str(value) for key, value in values.items()},
            )
            print("verified exact GitOps App scope and effective main rulesets")
        elif args.command == "verify-protected-approval":
            validate_protected_approval(
                env=os.environ,
                environment_raw=_read_regular_file(
                    args.environment_document,
                    "protected environment",
                    MAX_API_DOCUMENT_BYTES,
                ),
                approvals_raw=_read_regular_file(
                    args.approvals_document,
                    "workflow approval history",
                    MAX_API_DOCUMENT_BYTES,
                ),
                jobs_raw=_read_regular_file(
                    args.jobs_document,
                    "attempt-one jobs",
                    MAX_API_DOCUMENT_BYTES,
                ),
            )
            print("verified protected environment approval before GitOps mutation")
        elif args.command == "add-migration-release-patch":
            job_name = write_migration_release_patch(
                args.kustomization, args.image_digest
            )
            _write_outputs(args.github_output, {"rendered_job_name": job_name})
            print("added exact digest-derived and unsuspend migration patch")
        elif args.command == "validate-migration-render":
            job_name = validate_migration_render(
                _read_regular_file(
                    args.render, "migration render", MAX_RENDER_BYTES
                ),
                args.image_digest,
            )
            _write_outputs(args.github_output, {"rendered_job_name": job_name})
            print("verified exact digest-derived migration render")
        elif args.command == "validate-base-migration-render":
            validate_base_migration_render(
                _read_regular_file(
                    args.render, "base migration render", MAX_RENDER_BYTES
                )
            )
            print("verified the sealed base migration Job is inert")
        elif args.command == "verify-pre-reconstruction-source":
            mode = inspect_pre_reconstruction_source(
                root=args.root.resolve(),
                release_id=args.release_id,
                release_manifest_sha256=args.release_manifest_sha256,
                gitops_base_sha=args.gitops_base_sha,
                supplied_source_sha=args.supplied_source_sha,
            )
            print(f"verified protected GitOps source chain for {mode} mode")
        elif args.command == "verify-migration-commit":
            values = inspect_migration_commit(
                root=args.root.resolve(),
                release_id=args.release_id,
                release_manifest_sha256=args.release_manifest_sha256,
                gitops_base_sha=args.gitops_base_sha,
                pre_push_main_sha=args.pre_push_main_sha,
                expected_tree_sha=args.expected_tree_sha,
                publish_mode=args.publish_mode,
            )
            _write_outputs(
                args.github_output,
                {key: str(value) for key, value in values.items()},
            )
            print("verified exact GitOps migration child commit")
        elif args.command == "emit-result-evidence":
            facts = inspect_migration_commit(
                root=args.root.resolve(),
                release_id=args.release_id,
                release_manifest_sha256=args.release_manifest_sha256,
                gitops_base_sha=args.gitops_base_sha,
                pre_push_main_sha=args.pre_push_main_sha,
                expected_tree_sha=args.expected_tree_sha,
                publish_mode=args.publish_mode,
            )
            rendered_job_name = validate_migration_render(
                _read_regular_file(
                    args.render, "migration render", MAX_RENDER_BYTES
                ),
                args.image_digest,
            )
            raw = build_result_evidence(
                env=os.environ,
                release_id=args.release_id,
                candidate_spec_sha256=args.candidate_spec_sha256,
                release_manifest_sha256=args.release_manifest_sha256,
                workflow_raw=_read_regular_file(
                    args.workflow,
                    "migration release workflow",
                    MAX_WORKFLOW_BYTES,
                ),
                environment_raw=_read_regular_file(
                    args.environment_document,
                    "protected environment",
                    MAX_API_DOCUMENT_BYTES,
                ),
                approvals_raw=_read_regular_file(
                    args.approvals_document,
                    "workflow approval history",
                    MAX_API_DOCUMENT_BYTES,
                ),
                jobs_raw=_read_regular_file(
                    args.jobs_document,
                    "attempt-one jobs",
                    MAX_API_DOCUMENT_BYTES,
                ),
                gitops_base_sha=args.gitops_base_sha,
                sealed_release_sha=args.sealed_release_sha,
                pre_push_main_sha=args.pre_push_main_sha,
                migration_commit_sha=str(facts["migration_commit_sha"]),
                migration_tree_sha=str(facts["migration_tree_sha"]),
                publish_mode=args.publish_mode,
                gitops_write_app_slug=args.app_slug,
                gitops_write_app_id=args.app_id,
                gitops_write_app_installation_id=args.installation_id,
                sole_changed_path=str(facts["sole_changed_path"]),
                rendered_job_name=rendered_job_name,
                commit_subject=str(facts["commit_subject"]),
                commit_author_name=str(facts["commit_author_name"]),
                commit_committer_name=str(facts["commit_committer_name"]),
                image_digest=args.image_digest,
            )
            path = write_result_evidence(args.evidence_dir, raw)
            print(f"wrote protected migration result evidence to {path}")
        elif args.command == "verify-result-evidence":
            verify_result_evidence_dir(args.evidence_dir)
            print("verified sole canonical protected migration result evidence")
        else:  # pragma: no cover
            raise GateError("unsupported migration gate command")
    except (GateError, OSError, subprocess.CalledProcessError) as exc:
        print(f"migration release verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
