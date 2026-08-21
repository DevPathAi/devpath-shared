from __future__ import annotations

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import tempfile
import unittest
import urllib.error
import urllib.request
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "release" / "immutable_shared_package.py"
SPEC = importlib.util.spec_from_file_location("immutable_shared_package", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("immutable publication verifier module is missing")
PACKAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE)

MIGRATION_MODULE_PATH = ROOT / "scripts" / "release" / "migration_release_gate.py"
MIGRATION_SPEC = importlib.util.spec_from_file_location(
    "migration_release_gate", MIGRATION_MODULE_PATH
)
if MIGRATION_SPEC is None or MIGRATION_SPEC.loader is None:
    raise RuntimeError("migration release gate module is missing")
MIGRATION = importlib.util.module_from_spec(MIGRATION_SPEC)
MIGRATION_SPEC.loader.exec_module(MIGRATION)


class ImmutablePublicationUnitTest(unittest.TestCase):
    def test_frozen_coordinate_and_linux_publication_bytes(self) -> None:
        self.assertEqual("ai.devpath", PACKAGE.GROUP_ID)
        self.assertEqual("devpath-shared", PACKAGE.ARTIFACT_ID)
        self.assertEqual("0.0.1-et9.20260816", PACKAGE.VERSION)
        self.assertEqual(
            {
                "devpath-shared-0.0.1-et9.20260816.jar": (
                    1_177_131,
                    "94e2adb769790d813a872163347ede20ad4c75ae88e5811df2ec6625a340f21f",
                ),
                "devpath-shared-0.0.1-et9.20260816.pom": (
                    1_546,
                    "10daef2cdf7d436f952fa6dab10a27253a933af013093bb6967dd220010dbdd7",
                ),
                "devpath-shared-0.0.1-et9.20260816.module": (
                    2_888,
                    "8c6445b67a674f8f65087728c5e602d9d3e06dd3c1a5bdbbe6d8f2d55779531c",
                ),
            },
            {name: (spec.size, spec.sha256) for name, spec in PACKAGE.ARTIFACTS.items()},
        )

    def test_exact_artifact_bytes_accept_and_mutations_reject(self) -> None:
        raw = b"immutable-artifact\n"
        spec = PACKAGE.ArtifactSpec(
            "sample.bin", len(raw), hashlib.sha256(raw).hexdigest()
        )
        PACKAGE.validate_artifact_bytes(spec, raw)
        with self.assertRaisesRegex(PACKAGE.VerificationError, "size"):
            PACKAGE.validate_artifact_bytes(spec, raw + b"x")
        with self.assertRaisesRegex(PACKAGE.VerificationError, "SHA-256"):
            PACKAGE.validate_artifact_bytes(spec, b"X" + raw[1:])

    def test_pom_and_module_coordinates_are_exact(self) -> None:
        pom = (
            b"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            b"<project xmlns=\"http://maven.apache.org/POM/4.0.0\">"
            b"<modelVersion>4.0.0</modelVersion>"
            b"<groupId>ai.devpath</groupId>"
            b"<artifactId>devpath-shared</artifactId>"
            b"<version>0.0.1-et9.20260816</version></project>\n"
        )
        module = (
            b'{"component":{"group":"ai.devpath","module":"devpath-shared",'
            b'"version":"0.0.1-et9.20260816"},"variants":[]}\n'
        )
        PACKAGE.validate_pom_semantics(pom)
        PACKAGE.validate_module_semantics(module)
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.validate_pom_semantics(pom.replace(b"et9", b"et8"))
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.validate_module_semantics(module.replace(b"devpath-shared", b"other"))

    def test_remote_preflight_is_absent_or_exact_never_partial(self) -> None:
        raw = b"artifact"
        spec = PACKAGE.ArtifactSpec("artifact", len(raw), hashlib.sha256(raw).hexdigest())
        specs = {spec.name: spec}

        self.assertTrue(
            PACKAGE.classify_remote_artifacts(lambda _name: (404, b""), specs)
        )
        self.assertFalse(
            PACKAGE.classify_remote_artifacts(lambda _name: (200, raw), specs)
        )
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.classify_remote_artifacts(lambda _name: (403, b""), specs)

        two_specs = {
            "one": PACKAGE.ArtifactSpec("one", 3, hashlib.sha256(b"one").hexdigest()),
            "two": PACKAGE.ArtifactSpec("two", 3, hashlib.sha256(b"two").hexdigest()),
        }
        with self.assertRaisesRegex(PACKAGE.VerificationError, "partial"):
            PACKAGE.classify_remote_artifacts(
                lambda name: (200, name.encode()) if name == "one" else (404, b""),
                two_specs,
            )

    def test_remote_existing_drift_and_postflight_absence_reject(self) -> None:
        raw = b"artifact"
        spec = PACKAGE.ArtifactSpec("artifact", len(raw), hashlib.sha256(raw).hexdigest())
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.classify_remote_artifacts(
                lambda _name: (200, b"drifted"), {spec.name: spec}
            )
        with self.assertRaisesRegex(PACKAGE.VerificationError, "missing"):
            PACKAGE.classify_remote_artifacts(
                lambda _name: (404, b""), {spec.name: spec}, require_present=True
            )

    def test_package_redirect_is_https_allowlisted_and_strips_credentials(self) -> None:
        handler = PACKAGE.SafePackageRedirect()
        original = urllib.request.Request(
            "https://maven.pkg.github.com/DevPathAi/devpath-shared/file.jar",
            headers={"Authorization": "Basic secret", "User-Agent": "test"},
        )
        redirected = handler.redirect_request(
            original,
            None,
            302,
            "Found",
            {},
            "https://github-registry-files.githubusercontent.com/object?signature=x",
        )
        self.assertIsNotNone(redirected)
        self.assertNotIn("Authorization", redirected.headers)
        self.assertEqual("test", redirected.headers["User-agent"])
        for target in (
            "http://github-registry-files.githubusercontent.com/object",
            "https://evil.example/object",
        ):
            with self.subTest(target=target), self.assertRaises(
                PACKAGE.VerificationError
            ):
                handler.redirect_request(original, None, 302, "Found", {}, target)
        redirected_source = urllib.request.Request(
            "https://github-registry-files.githubusercontent.com/object"
        )
        with self.assertRaises(PACKAGE.VerificationError):
            handler.redirect_request(
                redirected_source,
                None,
                302,
                "Found",
                {},
                "https://github-registry-files.githubusercontent.com/second",
            )

    def test_only_initial_maven_endpoint_404_means_coordinate_absent(self) -> None:
        self.assertTrue(
            PACKAGE.is_absent_package_response(
                "https://maven.pkg.github.com/DevPathAi/devpath-shared/file.jar", 404
            )
        )
        for url, status in (
            ("https://github-registry-files.githubusercontent.com/object", 404),
            ("https://maven.pkg.github.com/DevPathAi/devpath-shared/file.jar", 401),
            ("https://evil.example/file.jar", 404),
        ):
            with self.subTest(url=url, status=status):
                self.assertFalse(PACKAGE.is_absent_package_response(url, status))

    def test_source_identity_is_current_clean_main_attempt_one(self) -> None:
        sha = "1" * 40
        env = {
            "GITHUB_REPOSITORY": "DevPathAi/devpath-shared",
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_RUN_ATTEMPT": "1",
            "GITHUB_SHA": sha,
            "GITHUB_WORKFLOW_REF": (
                "DevPathAi/devpath-shared/.github/workflows/"
                "mission-spine-migration-release.yml@refs/heads/main"
            ),
            "GITHUB_WORKFLOW_SHA": sha,
            "GITHUB_RUN_ID": "123456",
            "GITHUB_JOB": "deploy",
        }
        PACKAGE.validate_source_identity(env, sha, sha, "")
        for key, value in {
            "GITHUB_REPOSITORY": "fork/devpath-shared",
            "GITHUB_EVENT_NAME": "workflow_dispatch",
            "GITHUB_REF": "refs/heads/develop",
            "GITHUB_RUN_ATTEMPT": "2",
            "GITHUB_SHA": "2" * 40,
        }.items():
            mutated = dict(env)
            mutated[key] = value
            with self.subTest(key=key), self.assertRaises(PACKAGE.VerificationError):
                PACKAGE.validate_source_identity(mutated, sha, sha, "")
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.validate_source_identity(env, sha, sha, "?? dirty\n")
        with self.assertRaises(PACKAGE.VerificationError):
            PACKAGE.validate_source_identity(env, sha, "2" * 40, "")


class WorkflowContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.publish = (ROOT / ".github/workflows/publish.yml").read_text(
            encoding="utf-8"
        )
        self.ci = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.migration = (
            ROOT / ".github/workflows/mission-spine-migration-release.yml"
        ).read_text(encoding="utf-8")

    def assert_actions_are_sha_pinned(self, workflow: str) -> None:
        uses = re.findall(r"^\s*-?\s*uses:\s*([^\s#]+)", workflow, re.MULTILINE)
        self.assertTrue(uses)
        for action in uses:
            with self.subTest(action=action):
                self.assertRegex(action, r"^[^@]+@[0-9a-f]{40}$")

    def test_gradle_distribution_is_sha256_pinned(self) -> None:
        wrapper = (ROOT / "gradle/wrapper/gradle-wrapper.properties").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "distributionSha256Sum="
            "bafc141b619ad6350fd975fc903156dd5c151998cc8b058e8c1044ab5f7b031f",
            wrapper,
        )
        wrapper_jar = (ROOT / "gradle/wrapper/gradle-wrapper.jar").read_bytes()
        self.assertEqual(
            "497c8c2a7e5031f6aa847f88104aa80a93532ec32ee17bdb8d1d2f67a194a9c7",
            hashlib.sha256(wrapper_jar).hexdigest(),
        )

    def test_publication_resource_line_endings_reproduce_frozen_jar(self) -> None:
        attributes = (ROOT / ".gitattributes").read_text(encoding="utf-8")
        self.assertIn("/src/main/resources/** text eol=crlf", attributes)
        for filename in (
            "V202608161009__lcs_mentor_snapshot_contract.sql",
            "V202608161011__validate_lcs_mentor_snapshot_contract.sql",
        ):
            self.assertIn(
                f"/src/main/resources/db/migration/{filename} text eol=lf",
                attributes,
            )

    def test_publish_is_main_push_only_and_one_shot_fail_closed(self) -> None:
        self.assertNotIn("workflow_dispatch:", self.publish)
        self.assertRegex(self.publish, r"(?m)^\s{4}branches: \[main\]$")
        self.assertIn("packages: write", self.publish)
        self.assertIn("GITHUB_RUN_ATTEMPT", self.publish)
        self.assertIn("refs/heads/main", self.publish)
        self.assertIn("verify-local", self.publish)
        self.assertIn("preflight-remote", self.publish)
        self.assertIn("steps.package-state.outputs.publish_needed == 'true'", self.publish)
        self.assertIn("postflight-remote", self.publish)
        self.assertIn("environment: mission-spine-shared-package-publish", self.publish)
        self.assertIn("prevent_self_review", self.publish)
        self.assertIn("21.0.12+8", self.publish)
        self.assertIn(
            "image: pgvector/pgvector:pg17@sha256:"
            "cf134a767f474095eeba57e0117be8e568e011a63f33fbf252f14c9b760f8e6f",
            self.publish,
        )
        self.assertIn("POSTGRES_DB: devpath", self.publish)
        self.assertIn("POSTGRES_USER: devpath", self.publish)
        self.assertIn("POSTGRES_PASSWORD: localdev", self.publish)
        self.assertIn("DB_URL: jdbc:postgresql://localhost:5432/devpath", self.publish)
        self.assertIn("DB_USER: devpath", self.publish)
        self.assertIn("DB_PASSWORD: localdev", self.publish)
        self.assert_actions_are_sha_pinned(self.publish)

    def test_pr_ci_verifies_exact_clean_publication_bytes(self) -> None:
        self.assertIn("generatePomFileForMavenPublication", self.ci)
        self.assertIn("generateMetadataFileForMavenPublication", self.ci)
        self.assertIn("verify-local", self.ci)
        self.assertIn("21.0.12+8", self.ci)
        self.assertIn(
            "image: pgvector/pgvector:pg17@sha256:"
            "cf134a767f474095eeba57e0117be8e568e011a63f33fbf252f14c9b760f8e6f",
            self.ci,
        )
        self.assertNotRegex(self.ci, r"(?m)^\s{2}deploy:\s*$")
        self.assertIn("ghcr.io/devpathai/devpath-migration:${{ github.sha }}", self.ci)
        self.assertNotIn("devpath-migration:main", self.ci)
        self.assert_actions_are_sha_pinned(self.ci)

    def test_migration_release_is_dispatch_and_protected_environment_only(self) -> None:
        self.assertNotRegex(self.migration, r"(?m)^\s{2}(push|pull_request):")
        self.assertIn("workflow_dispatch:", self.migration)
        self.assertIn("source_sha:", self.migration)
        self.assertIn("release_id:", self.migration)
        self.assertIn("release_manifest_sha256:", self.migration)
        self.assertIn("sealed_release_sha:", self.migration)
        self.assertIn("gitops_source_sha:", self.migration)
        self.assertIn("environment: mission-spine-migration-release", self.migration)
        self.assertIn("name: deploy", self.migration)
        self.assertIn("actions: read", self.migration)
        self.assertIn("actions/runs/$GITHUB_RUN_ID/approvals", self.migration)
        self.assertIn("attempts/1/jobs?filter=latest", self.migration)
        self.assertIn("validate-sealed-release", self.migration)
        self.assertIn('--image-digest "$IMAGE_DIGEST"', self.migration)
        self.assertIn(
            '--release-manifest-sha256 "$RELEASE_MANIFEST_SHA256"',
            self.migration,
        )
        self.assertNotIn("--force-with-lease", self.migration)
        self.assertNotIn("--force", self.migration)
        self.assertNotIn("exit 0", self.migration)
        self.assertIn("git -C gitops push origin HEAD:refs/heads/main", self.migration)
        self.assertEqual(
            2,
            self.migration.count('"repos/$GITHUB_REPOSITORY/branches/main"'),
        )
        self.assertLess(
            self.migration.index(
                "Verify protected approval before GitOps mutation"
            ),
            self.migration.index("git -C gitops push origin HEAD:refs/heads/main"),
        )
        self.assertIn(
            'test "$(git -C gitops rev-parse refs/remotes/origin/main)" = "$migration_commit_sha"',
            self.migration,
        )
        self.assertIn("GITOPS_RELEASE_APP_ID", self.migration)
        self.assertIn("GITOPS_RELEASE_APP_PRIVATE_KEY", self.migration)
        self.assertNotIn("secrets.GITOPS_APP_ID", self.migration)
        self.assertNotIn("secrets.GITOPS_APP_PRIVATE_KEY", self.migration)
        self.assertIn("permission-administration: read", self.migration)
        self.assertIn("permission-contents: write", self.migration)
        self.assertIn("owner: DevPathAi", self.migration)
        self.assertIn("repositories: devpath-gitops", self.migration)
        self.assertIn("steps.app-token.outputs.app-slug", self.migration)
        self.assertIn("steps.app-token.outputs.installation-id", self.migration)
        self.assertIn("'/installation/repositories?per_page=100'", self.migration)
        self.assertEqual(1, self.migration.count("/installation"))
        self.assertNotIn(
            '/installation >"$auth_dir/installation.json"', self.migration
        )
        self.assertIn(
            "repos/DevPathAi/devpath-gitops/branches/main/protection",
            self.migration,
        )
        self.assertIn('GITHUB_API_VERSION: "2026-03-10"', self.migration)
        self.assertIn("validate-base-migration-job", self.migration)
        self.assertIn("set-migration-release", self.migration)
        self.assertNotIn('"$KUSTOMIZE_BIN" edit set image', self.migration)
        self.assertNotIn("! grep -F 'patches:'", self.migration)
        self.assertIn("verify-pre-reconstruction-source", self.migration)
        self.assertIn("verify-protected-approval", self.migration)
        self.assertIn("verify-gitops-authorization", self.migration)
        self.assertIn("emit-result-evidence", self.migration)
        self.assertIn("verify-result-evidence", self.migration)
        self.assertIn(
            "name: mission-spine-migration-result-${{ inputs.release_id }}-"
            "${{ github.run_id }}-attempt-1",
            self.migration,
        )
        self.assertIn(
            "path: ${{ runner.temp }}/mission-spine-migration-result/"
            "evidence.json",
            self.migration,
        )
        self.assertIn("overwrite: false", self.migration)
        self.assertIn("include-hidden-files: false", self.migration)
        self.assertNotIn("overwrite: true", self.migration)
        self.assertIn(
            "actions/upload-artifact@"
            "b7c566a772e6b6bfb58ed0dc250532a479d7789f",
            self.migration,
        )
        self.assertNotIn("x-access-token:${GITOPS_TOKEN}", self.migration)
        self.assertIn("GITHUB_RUN_ATTEMPT", self.migration)
        self.assertIn("refs/heads/main", self.migration)
        self.assertIn("refs/remotes/origin/main", self.migration)
        self.assertLess(
            self.migration.index(
                'test "$(git -C gitops rev-parse refs/remotes/origin/main)" = '
                '"$GITOPS_SOURCE_SHA"'
            ),
            self.migration.index(
                "python3 expected-gitops/scripts/release/"
                "validate_release_manifest.py"
            ),
        )
        self.assertLess(
            self.migration.index("verify-pre-reconstruction-source"),
            self.migration.index(
                "python3 expected-gitops/scripts/release/"
                "validate_release_manifest.py"
            ),
        )
        self.assertLess(
            self.migration.index("verify-protected-approval"),
            self.migration.index("git -C gitops push origin HEAD:refs/heads/main"),
        )
        self.assertLess(
            self.migration.index(
                "python3 expected-gitops/scripts/release/"
                "validate_release_manifest.py"
            ),
            self.migration.index("git -C gitops push origin HEAD:refs/heads/main"),
        )
        self.assert_actions_are_sha_pinned(self.migration)


class MigrationReleaseGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.release_id = "ms-20260817-et9-shared"
        self.source_sha = "1" * 40
        self.candidate = {
            "document_type": "candidate-spec",
            "release_id": self.release_id,
            "gitops": {"base_sha": "2" * 40},
            "shared_migration": {
                "repository": "DevPathAi/devpath-shared",
                "source_sha": self.source_sha,
                "shared_version": "0.0.1-et9.20260816",
                "shared_jar_sha256": (
                    "94e2adb769790d813a872163347ede20ad4c75ae88e5811df2ec6625a340f21f"
                ),
                "image_repository": "ghcr.io/devpathai/devpath-migration",
                "image_digest": "sha256:" + "a" * 64,
                "flyway_target": "202608161011",
                "required_migration": (
                    "V202608161011__validate_lcs_mentor_snapshot_contract.sql"
                ),
                "rollback_policy": "additive-retained",
            },
        }
        self.candidate_raw = (
            json.dumps(self.candidate, separators=(",", ":"), sort_keys=True) + "\n"
        ).encode()
        self.candidate_sha = hashlib.sha256(self.candidate_raw).hexdigest()
        self.release = {
            "document_type": "release-manifest",
            "release_id": self.release_id,
            "candidate_spec": {
                "path": (
                    "release-manifests/candidates/"
                    f"{self.release_id}.candidate-spec.json"
                ),
                "sha256": self.candidate_sha,
            },
            "validation_attestation": {"validator_head_sha": "3" * 40},
        }
        self.release_raw = (
            json.dumps(self.release, separators=(",", ":"), sort_keys=True) + "\n"
        ).encode()
        self.release_sha = hashlib.sha256(self.release_raw).hexdigest()

    def validate(self, **overrides: object) -> dict[str, str]:
        arguments = {
            "release_id": self.release_id,
            "source_sha": self.source_sha,
            "release_sha256": self.release_sha,
            "release_raw": self.release_raw,
            "candidate_raw": self.candidate_raw,
        }
        arguments.update(overrides)
        return MIGRATION.validate_sealed_release(**arguments)

    def test_sealed_release_binds_exact_shared_source_and_image_digest(self) -> None:
        self.assertEqual(
            {
                "candidate_spec_sha256": self.candidate_sha,
                "gitops_base_sha": "2" * 40,
                "image_digest": "sha256:" + "a" * 64,
                "validator_head_sha": "3" * 40,
            },
            self.validate(),
        )

    def test_release_hash_linkage_and_identity_mutations_reject(self) -> None:
        mutations = {
            "release_id": "not-a-release",
            "source_sha": "0" * 40,
            "release_sha256": "f" * 64,
            "release_raw": self.release_raw + b" ",
            "candidate_raw": self.candidate_raw + b" ",
        }
        for key, value in mutations.items():
            with self.subTest(key=key), self.assertRaises(MIGRATION.GateError):
                self.validate(**{key: value})
        release = json.loads(self.release_raw)
        release["validation_attestation"]["validator_head_sha"] = "0" * 40
        release_raw = (
            json.dumps(release, separators=(",", ":"), sort_keys=True) + "\n"
        ).encode()
        with self.assertRaises(MIGRATION.GateError):
            self.validate(
                release_raw=release_raw,
                release_sha256=hashlib.sha256(release_raw).hexdigest(),
            )

    def test_candidate_shared_contract_mutations_reject(self) -> None:
        for path, value in {
            "repository": "fork/devpath-shared",
            "source_sha": "3" * 40,
            "shared_version": "0.0.1-SNAPSHOT",
            "shared_jar_sha256": "b" * 64,
            "image_repository": "ghcr.io/other/image",
            "image_digest": "sha256:" + "0" * 64,
            "flyway_target": "0",
            "required_migration": "other.sql",
            "rollback_policy": "destructive",
        }.items():
            candidate = json.loads(self.candidate_raw)
            candidate["shared_migration"][path] = value
            raw = (json.dumps(candidate, separators=(",", ":"), sort_keys=True) + "\n").encode()
            release = json.loads(self.release_raw)
            release["candidate_spec"]["sha256"] = hashlib.sha256(raw).hexdigest()
            release_raw = (
                json.dumps(release, separators=(",", ":"), sort_keys=True) + "\n"
            ).encode()
            with self.subTest(path=path), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_sealed_release(
                    release_id=self.release_id,
                    source_sha=self.source_sha,
                    release_sha256=hashlib.sha256(release_raw).hexdigest(),
                    release_raw=release_raw,
                    candidate_raw=raw,
                )

    def test_dispatch_context_is_current_clean_main_attempt_one(self) -> None:
        sha = "4" * 40
        env = {
            "GITHUB_REPOSITORY": "DevPathAi/devpath-shared",
            "GITHUB_EVENT_NAME": "workflow_dispatch",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_RUN_ATTEMPT": "1",
            "GITHUB_SHA": sha,
            "GITHUB_WORKFLOW_REF": (
                "DevPathAi/devpath-shared/.github/workflows/"
                "mission-spine-migration-release.yml@refs/heads/main"
            ),
            "GITHUB_WORKFLOW_SHA": sha,
            "GITHUB_RUN_ID": "123456",
            "GITHUB_JOB": "deploy",
        }
        MIGRATION.validate_dispatch_context(env, sha, sha, "", sha)
        for key, value in {
            "GITHUB_REPOSITORY": "fork/devpath-shared",
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_REF": "refs/heads/develop",
            "GITHUB_RUN_ATTEMPT": "2",
            "GITHUB_SHA": "5" * 40,
            "GITHUB_WORKFLOW_REF": "fork/workflow@refs/heads/main",
            "GITHUB_WORKFLOW_SHA": "5" * 40,
            "GITHUB_RUN_ID": "0",
            "GITHUB_JOB": "other",
        }.items():
            mutated = dict(env)
            mutated[key] = value
            with self.subTest(key=key), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_dispatch_context(mutated, sha, sha, "", sha)
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_dispatch_context(env, sha, "5" * 40, "", sha)
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_dispatch_context(env, sha, sha, "?? dirty\n", sha)


if __name__ == "__main__":
    unittest.main()

# 2026-08-21: et9 게시 재트리거용 무해 주석 — publish.yml 의 one-shot(attempt=1) 규칙 때문에
# 승인 게이트에서 소진된 run 은 재실행할 수 없어, 트리거 경로의 이 파일로 새 push 이벤트를 만든다.
