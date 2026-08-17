from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "release" / "migration_release_gate.py"
SPEC = importlib.util.spec_from_file_location(
    "migration_release_gate_result", MODULE_PATH
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("migration release gate module is missing")
MIGRATION = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MIGRATION)


def canonical(value: object) -> bytes:
    return (json.dumps(value, separators=(",", ":")) + "\n").encode("utf-8")


class MigrationResultEvidenceTest(unittest.TestCase):
    def setUp(self) -> None:
        self.release_id = "ms-20260817-et9-shared"
        self.source_sha = "1" * 40
        self.candidate_sha = "2" * 64
        self.release_sha = "3" * 64
        self.base_sha = "4" * 40
        self.sealed_sha = "5" * 40
        self.migration_sha = "6" * 40
        self.tree_sha = "7" * 40
        self.image_digest = "sha256:" + "8" * 64
        self.started_at = "2026-08-17T03:04:05Z"
        self.workflow_raw = b"name: Mission Spine - sealed migration GitOps release\n"
        self.workflow_sha256 = hashlib.sha256(self.workflow_raw).hexdigest()
        self.env = {
            "GITHUB_REPOSITORY": "DevPathAi/devpath-shared",
            "GITHUB_EVENT_NAME": "workflow_dispatch",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_SHA": self.source_sha,
            "GITHUB_WORKFLOW_REF": (
                "DevPathAi/devpath-shared/.github/workflows/"
                "mission-spine-migration-release.yml@refs/heads/main"
            ),
            "GITHUB_WORKFLOW_SHA": self.source_sha,
            "GITHUB_RUN_ID": "987654321",
            "GITHUB_RUN_ATTEMPT": "1",
            "GITHUB_JOB": "deploy",
            "GITHUB_ACTOR": "release-initiator",
            "GITHUB_TRIGGERING_ACTOR": "release-initiator",
        }
        self.environment = {
            "id": 12345,
            "name": "mission-spine-migration-release",
            "protection_rules": [
                {
                    "id": 22,
                    "type": "required_reviewers",
                    "prevent_self_review": True,
                    "reviewers": [
                        {
                            "type": "User",
                            "reviewer": {
                                "login": "independent-reviewer",
                                "id": 42,
                                "type": "User",
                            },
                        }
                    ],
                }
            ],
        }
        self.approvals = [
            {
                "state": "approved",
                "environments": [
                    {
                        "id": 12345,
                        "name": "mission-spine-migration-release",
                    }
                ],
                "user": {
                    "login": "independent-reviewer",
                    "id": 42,
                    "type": "User",
                },
            }
        ]
        self.jobs = {
            "total_count": 1,
            "jobs": [
                {
                    "id": 777,
                    "name": "deploy",
                    "run_attempt": 1,
                    "head_sha": self.source_sha,
                    "status": "in_progress",
                    "conclusion": None,
                    "started_at": self.started_at,
                }
            ],
        }
        self.subject = (
            f"deploy(devpath-migration): {self.release_id} sealed {self.release_sha}"
        )

    def build(self, **overrides: object) -> bytes:
        arguments = {
            "env": self.env,
            "release_id": self.release_id,
            "candidate_spec_sha256": self.candidate_sha,
            "release_manifest_sha256": self.release_sha,
            "workflow_raw": self.workflow_raw,
            "environment_raw": canonical(self.environment),
            "approvals_raw": canonical(self.approvals),
            "jobs_raw": canonical(self.jobs),
            "gitops_base_sha": self.base_sha,
            "sealed_release_sha": self.sealed_sha,
            "pre_push_main_sha": self.base_sha,
            "migration_commit_sha": self.migration_sha,
            "migration_tree_sha": self.tree_sha,
            "publish_mode": "published",
            "gitops_write_app_slug": "devpath-gitops-release",
            "gitops_write_app_id": "4242",
            "gitops_write_app_installation_id": "7654321",
            "sole_changed_path": "apps/devpath-migration/base/kustomization.yaml",
            "rendered_job_name": "devpath-flyway-migrate-" + "8" * 24,
            "commit_subject": self.subject,
            "commit_author_name": "devpath-gitops-release[bot]",
            "commit_committer_name": "devpath-gitops-release[bot]",
            "image_digest": self.image_digest,
        }
        arguments.update(overrides)
        return MIGRATION.build_result_evidence(**arguments)

    def expected(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "document_type": "mission-spine-migration-result",
            "release_id": self.release_id,
            "candidate_spec_sha256": self.candidate_sha,
            "release_manifest_sha256": self.release_sha,
            "shared": {
                "repository": "DevPathAi/devpath-shared",
                "source_sha": self.source_sha,
                "workflow_path": (
                    ".github/workflows/mission-spine-migration-release.yml"
                ),
                "workflow_ref": (
                    "DevPathAi/devpath-shared/.github/workflows/"
                    "mission-spine-migration-release.yml@refs/heads/main"
                ),
                "workflow_sha256": self.workflow_sha256,
                "run_id": 987654321,
                "run_attempt": 1,
                "event_name": "workflow_dispatch",
                "ref": "refs/heads/main",
                "job": "deploy",
                "environment": "mission-spine-migration-release",
            },
            "approval": {
                "environment_id": 12345,
                "reviewer_login": "independent-reviewer",
                "reviewer_id": 42,
                "reviewer_type": "User",
                "state": "approved",
                "approval_effective_at": self.started_at,
            },
            "gitops": {
                "repository": "DevPathAi/devpath-gitops",
                "base_sha": self.base_sha,
                "sealed_release_sha": self.sealed_sha,
                "pre_push_main_sha": self.base_sha,
                "migration_commit_sha": self.migration_sha,
                "migration_tree_sha": self.tree_sha,
                "publish_mode": "published",
                "write_app_slug": "devpath-gitops-release",
                "write_app_id": 4242,
                "write_app_installation_id": 7654321,
                "branch": "main",
                "sole_changed_path": (
                    "apps/devpath-migration/base/kustomization.yaml"
                ),
                "rendered_job_name": "devpath-flyway-migrate-" + "8" * 24,
                "commit_subject": self.subject,
                "commit_author_name": "devpath-gitops-release[bot]",
                "commit_committer_name": "devpath-gitops-release[bot]",
            },
            "migration_image": {
                "repository": "ghcr.io/devpathai/devpath-migration",
                "digest": self.image_digest,
            },
        }

    def test_generator_emits_the_exact_canonical_contract(self) -> None:
        raw = self.build()
        self.assertEqual(canonical(self.expected()), raw)
        self.assertEqual(self.expected(), MIGRATION.validate_result_evidence(raw))

        reused_expected = self.expected()
        reused_expected["gitops"]["pre_push_main_sha"] = self.migration_sha
        reused_expected["gitops"]["publish_mode"] = "reused"
        reused_raw = self.build(
            pre_push_main_sha=self.migration_sha,
            publish_mode="reused",
        )
        self.assertEqual(canonical(reused_expected), reused_raw)
        self.assertEqual(
            reused_expected, MIGRATION.validate_result_evidence(reused_raw)
        )

    def test_contract_mutations_duplicates_order_and_noncanonical_bytes_reject(
        self,
    ) -> None:
        mutations: list[tuple[tuple[str, ...], object]] = [
            (("schema_version",), 2),
            (("schema_version",), True),
            (("candidate_spec_sha256",), "0" * 64),
            (("shared", "workflow_sha256"), "0" * 64),
            (("shared", "run_attempt"), 2),
            (("shared", "run_attempt"), True),
            (("shared", "ref"), "refs/heads/develop"),
            (("approval", "state"), "rejected"),
            (("approval", "approval_effective_at"), "2026-08-17T03:04:05+00:00"),
            (("gitops", "write_app_slug"), "another-app"),
            (("gitops", "write_app_id"), True),
            (("gitops", "publish_mode"), "unknown"),
            (("gitops", "pre_push_main_sha"), "9" * 40),
            (("gitops", "sole_changed_path"), "apps/other/kustomization.yaml"),
            (("gitops", "rendered_job_name"), "devpath-flyway-migrate-latest"),
            (("migration_image", "digest"), "sha256:" + "0" * 64),
        ]
        for path, value in mutations:
            document = copy.deepcopy(self.expected())
            target = document
            for key in path[:-1]:
                target = target[key]  # type: ignore[assignment,index]
            target[path[-1]] = value  # type: ignore[index]
            with self.subTest(path=path), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_result_evidence(canonical(document))

        extra = self.expected()
        extra["unexpected"] = True
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_result_evidence(canonical(extra))

        reordered = self.expected()
        reordered = {
            "document_type": reordered.pop("document_type"),
            **reordered,
        }
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_result_evidence(canonical(reordered))

        raw = self.build()
        duplicate = raw.replace(
            b'{"schema_version":1,',
            b'{"schema_version":1,"schema_version":1,',
            1,
        )
        for changed in (duplicate, raw.rstrip(b"\n"), raw + b"\n", b" " + raw):
            with self.subTest(changed=changed[:40]), self.assertRaises(
                MIGRATION.GateError
            ):
                MIGRATION.validate_result_evidence(changed)

    def test_environment_approval_and_live_job_are_exact_and_nonself(self) -> None:
        approval = MIGRATION.validate_protected_approval(
            env=self.env,
            environment_raw=canonical(self.environment),
            approvals_raw=canonical(self.approvals),
            jobs_raw=canonical(self.jobs),
        )
        self.assertEqual(
            {
                "environment_id": 12345,
                "reviewer_login": "independent-reviewer",
                "reviewer_id": 42,
                "reviewer_type": "User",
                "state": "approved",
                "approval_effective_at": self.started_at,
            },
            approval,
        )

        mutations: list[tuple[str, object]] = []
        environment = copy.deepcopy(self.environment)
        environment["protection_rules"][0]["prevent_self_review"] = False
        mutations.append(("self-review-enabled", environment))
        environment = copy.deepcopy(self.environment)
        environment["protection_rules"][0]["reviewers"][0]["type"] = "Team"
        mutations.append(("team-reviewer", environment))
        environment = copy.deepcopy(self.environment)
        environment["protection_rules"].append(
            copy.deepcopy(environment["protection_rules"][0])
        )
        mutations.append(("duplicate-review-rule", environment))
        for label, changed_environment in mutations:
            with self.subTest(label=label), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_protected_approval(
                    env=self.env,
                    environment_raw=canonical(changed_environment),
                    approvals_raw=canonical(self.approvals),
                    jobs_raw=canonical(self.jobs),
                )

        approvals = copy.deepcopy(self.approvals)
        approvals[0]["user"]["login"] = self.env["GITHUB_ACTOR"]
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=self.env,
                environment_raw=canonical(self.environment),
                approvals_raw=canonical(approvals),
                jobs_raw=canonical(self.jobs),
            )
        approvals = copy.deepcopy(self.approvals)
        approvals.append(copy.deepcopy(approvals[0]))
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=self.env,
                environment_raw=canonical(self.environment),
                approvals_raw=canonical(approvals),
                jobs_raw=canonical(self.jobs),
            )
        jobs = copy.deepcopy(self.jobs)
        jobs["jobs"][0]["run_attempt"] = 2
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=self.env,
                environment_raw=canonical(self.environment),
                approvals_raw=canonical(self.approvals),
                jobs_raw=canonical(jobs),
            )
        jobs = copy.deepcopy(self.jobs)
        jobs["total_count"] = True
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=self.env,
                environment_raw=canonical(self.environment),
                approvals_raw=canonical(self.approvals),
                jobs_raw=canonical(jobs),
            )

    def test_gitops_app_scope_and_rulesets_are_exact(self) -> None:
        repositories = {
            "total_count": 1,
            "repositories": [{"full_name": "DevPathAi/devpath-gitops"}],
        }
        integrity = {
            "id": 1001,
            "name": "mission-spine-main-integrity",
            "target": "branch",
            "source_type": "Repository",
            "source": "DevPathAi/devpath-gitops",
            "enforcement": "active",
            "bypass_actors": [],
            "conditions": {
                "ref_name": {"include": ["refs/heads/main"], "exclude": []}
            },
            "rules": [
                {"type": "deletion"},
                {"type": "non_fast_forward"},
                {"type": "required_linear_history"},
            ],
        }
        governance = {
            "id": 1002,
            "name": "mission-spine-main-governance",
            "target": "branch",
            "source_type": "Repository",
            "source": "DevPathAi/devpath-gitops",
            "enforcement": "active",
            "bypass_actors": [
                {
                    "actor_id": 4242,
                    "actor_type": "Integration",
                    "bypass_mode": "always",
                }
            ],
            "conditions": {
                "ref_name": {"include": ["refs/heads/main"], "exclude": []}
            },
            "rules": [
                {
                    "type": "pull_request",
                    "parameters": {
                        "allowed_merge_methods": ["squash"],
                        "dismiss_stale_reviews_on_push": True,
                        "dismissal_restriction": {
                            "enabled": False,
                            "allowed_actors": [],
                        },
                        "require_code_owner_review": False,
                        "require_last_push_approval": True,
                        "required_approving_review_count": 1,
                        "required_review_thread_resolution": True,
                        "required_reviewers": [],
                    },
                },
                {
                    "type": "required_status_checks",
                    "parameters": {
                        "do_not_enforce_on_create": False,
                        "required_status_checks": [
                            {
                                "context": "mission-spine-release-contract",
                                "integration_id": 15368,
                            },
                            {"context": "kustomize", "integration_id": 15368},
                        ],
                        "strict_required_status_checks_policy": True,
                    },
                },
            ],
        }
        rulesets = [
            [
                {
                    "id": 1001,
                    "name": "mission-spine-main-integrity",
                    "source_type": "Repository",
                    "source": "DevPathAi/devpath-gitops",
                    "enforcement": "active",
                },
                {
                    "id": 1002,
                    "name": "mission-spine-main-governance",
                    "source_type": "Repository",
                    "source": "DevPathAi/devpath-gitops",
                    "enforcement": "active",
                },
            ]
        ]
        self.assertEqual(
            {
                "write_app_slug": "devpath-gitops-release",
                "write_app_id": 4242,
                "write_app_installation_id": 7654321,
            },
            MIGRATION.validate_gitops_authorization(
                app_slug="devpath-gitops-release",
                app_id="4242",
                installation_id="7654321",
                repositories_raw=canonical(repositories),
                classic_protection_status="404",
                rulesets_raw=canonical(rulesets),
                ruleset_details_raw=(canonical(integrity), canonical(governance)),
            ),
        )

        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_gitops_authorization(
                app_slug="devpath-gitops-release",
                app_id="4242",
                installation_id="0",
                repositories_raw=canonical(repositories),
                classic_protection_status="404",
                rulesets_raw=canonical(rulesets),
                ruleset_details_raw=(canonical(integrity), canonical(governance)),
            )

        bad_cases: list[
            tuple[
                str,
                str,
                str,
                dict[str, object],
                str,
                list[list[dict[str, object]]],
                tuple[dict[str, object], dict[str, object]],
            ]
        ] = []
        changed_repositories = copy.deepcopy(repositories)
        changed_repositories["total_count"] = 2
        changed_repositories["repositories"].append(
            {"full_name": "DevPathAi/another-repository"}
        )
        bad_cases.append(
            (
                "repository-scope",
                "devpath-gitops-release",
                "4242",
                changed_repositories,
                "404",
                rulesets,
                (integrity, governance),
            )
        )
        bad_cases.append(
            (
                "app-id-output",
                "devpath-gitops-release",
                "0",
                repositories,
                "404",
                rulesets,
                (integrity, governance),
            )
        )
        changed_integrity = copy.deepcopy(integrity)
        changed_integrity["bypass_actors"] = [
            {"actor_id": 1, "actor_type": "User", "bypass_mode": "always"}
        ]
        bad_cases.append(
            (
                "integrity-bypass",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (changed_integrity, governance),
            )
        )
        changed_integrity = copy.deepcopy(integrity)
        del changed_integrity["target"]
        bad_cases.append(
            (
                "detail-missing-target",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (changed_integrity, governance),
            )
        )
        changed_governance = copy.deepcopy(governance)
        changed_governance["bypass_actors"] = []
        bad_cases.append(
            (
                "hidden-bypass",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (integrity, changed_governance),
            )
        )
        changed_governance = copy.deepcopy(governance)
        changed_governance["rules"][0]["parameters"][
            "require_last_push_approval"
        ] = False
        bad_cases.append(
            (
                "pr-policy",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (integrity, changed_governance),
            )
        )
        changed_governance = copy.deepcopy(governance)
        changed_governance["rules"][0]["parameters"][
            "required_approving_review_count"
        ] = True
        bad_cases.append(
            (
                "json-type-confusion",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (integrity, changed_governance),
            )
        )
        changed_governance = copy.deepcopy(governance)
        changed_governance["rules"][1]["parameters"]["required_status_checks"][
            0
        ]["integration_id"] = -1
        bad_cases.append(
            (
                "check-provider",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                rulesets,
                (integrity, changed_governance),
            )
        )
        changed_rulesets = copy.deepcopy(rulesets)
        changed_rulesets[0].append(copy.deepcopy(changed_rulesets[0][0]))
        bad_cases.append(
            (
                "extra-effective-ruleset",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                changed_rulesets,
                (integrity, governance),
            )
        )
        changed_rulesets = copy.deepcopy(rulesets)
        changed_rulesets[0][1]["id"] = changed_rulesets[0][0]["id"]
        changed_governance = copy.deepcopy(governance)
        changed_governance["id"] = changed_rulesets[0][0]["id"]
        bad_cases.append(
            (
                "duplicate-ruleset-id",
                "devpath-gitops-release",
                "4242",
                repositories,
                "404",
                changed_rulesets,
                (integrity, changed_governance),
            )
        )
        bad_cases.append(
            (
                "classic-protection",
                "devpath-gitops-release",
                "4242",
                repositories,
                "200",
                rulesets,
                (integrity, governance),
            )
        )
        bad_cases.append(
            (
                "slug",
                "other",
                "4242",
                repositories,
                "404",
                rulesets,
                (integrity, governance),
            )
        )
        for (
            label,
            slug,
            app_id,
            repository_document,
            classic_status,
            ruleset_pages,
            detail_documents,
        ) in bad_cases:
            with self.subTest(label=label), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_gitops_authorization(
                    app_slug=slug,
                    app_id=app_id,
                    installation_id="7654321",
                    repositories_raw=canonical(repository_document),
                    classic_protection_status=classic_status,
                    rulesets_raw=canonical(ruleset_pages),
                    ruleset_details_raw=tuple(
                        canonical(document) for document in detail_documents
                    ),
                )

    def test_migration_child_must_be_the_exact_single_path_commit(self) -> None:
        self.assertEqual(
            {
                "pre_push_main_sha": self.base_sha,
                "migration_commit_sha": self.migration_sha,
                "migration_tree_sha": self.tree_sha,
                "publish_mode": "published",
                "sole_changed_path": (
                    "apps/devpath-migration/base/kustomization.yaml"
                ),
                "commit_subject": self.subject,
                "commit_author_name": "devpath-gitops-release[bot]",
                "commit_committer_name": "devpath-gitops-release[bot]",
            },
            MIGRATION.validate_migration_facts(
                release_id=self.release_id,
                release_manifest_sha256=self.release_sha,
                gitops_base_sha=self.base_sha,
                pre_push_main_sha=self.base_sha,
                migration_commit_sha=self.migration_sha,
                migration_parent_sha=self.base_sha,
                migration_tree_sha=self.tree_sha,
                expected_tree_sha=self.tree_sha,
                changed_paths=["apps/devpath-migration/base/kustomization.yaml"],
                commit_subject=self.subject,
                commit_author_name="devpath-gitops-release[bot]",
                commit_committer_name="devpath-gitops-release[bot]",
                publish_mode="published",
            ),
        )
        reused = MIGRATION.validate_migration_facts(
            release_id=self.release_id,
            release_manifest_sha256=self.release_sha,
            gitops_base_sha=self.base_sha,
            pre_push_main_sha=self.migration_sha,
            migration_commit_sha=self.migration_sha,
            migration_parent_sha=self.base_sha,
            migration_tree_sha=self.tree_sha,
            expected_tree_sha=self.tree_sha,
            changed_paths=["apps/devpath-migration/base/kustomization.yaml"],
            commit_subject=self.subject,
            commit_author_name="devpath-gitops-release[bot]",
            commit_committer_name="devpath-gitops-release[bot]",
            publish_mode="reused",
        )
        self.assertEqual("reused", reused["publish_mode"])
        mutations = {
            "migration_commit_sha": self.base_sha,
            "pre_push_main_sha": "9" * 40,
            "migration_parent_sha": "9" * 40,
            "migration_tree_sha": "0" * 40,
            "expected_tree_sha": "9" * 40,
            "changed_paths": [
                "apps/devpath-migration/base/kustomization.yaml",
                "apps/other/base/kustomization.yaml",
            ],
            "commit_subject": self.subject + " drift",
            "commit_author_name": "attacker",
            "commit_committer_name": "attacker",
            "publish_mode": "reused",
        }
        for key, value in mutations.items():
            arguments = {
                "release_id": self.release_id,
                "release_manifest_sha256": self.release_sha,
                "gitops_base_sha": self.base_sha,
                "pre_push_main_sha": self.base_sha,
                "migration_commit_sha": self.migration_sha,
                "migration_parent_sha": self.base_sha,
                "migration_tree_sha": self.tree_sha,
                "expected_tree_sha": self.tree_sha,
                "changed_paths": [
                    "apps/devpath-migration/base/kustomization.yaml"
                ],
                "commit_subject": self.subject,
                "commit_author_name": "devpath-gitops-release[bot]",
                "commit_committer_name": "devpath-gitops-release[bot]",
                "publish_mode": "published",
            }
            arguments[key] = value
            with self.subTest(key=key), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_migration_facts(**arguments)

    def test_pre_reconstruction_source_chain_rejects_untrusted_gitops_code(
        self,
    ) -> None:
        base_arguments = {
            "release_id": self.release_id,
            "release_manifest_sha256": self.release_sha,
            "gitops_base_sha": self.base_sha,
            "supplied_source_sha": self.base_sha,
            "current_head_sha": self.base_sha,
            "current_parent_shas": [],
            "changed_paths": [],
            "commit_subject": "",
            "commit_author_name": "",
            "commit_committer_name": "",
        }
        self.assertEqual(
            "published",
            MIGRATION.validate_pre_reconstruction_source_facts(**base_arguments),
        )

        child_arguments = {
            **base_arguments,
            "supplied_source_sha": self.migration_sha,
            "current_head_sha": self.migration_sha,
            "current_parent_shas": [self.base_sha],
            "changed_paths": [
                "apps/devpath-migration/base/kustomization.yaml"
            ],
            "commit_subject": self.subject,
            "commit_author_name": "devpath-gitops-release[bot]",
            "commit_committer_name": "devpath-gitops-release[bot]",
        }
        self.assertEqual(
            "reused",
            MIGRATION.validate_pre_reconstruction_source_facts(**child_arguments),
        )

        mutations = {
            "gitops_base_sha": "9" * 40,
            "supplied_source_sha": "9" * 40,
            "current_head_sha": "9" * 40,
            "current_parent_shas": ["9" * 40],
            "changed_paths": ["apps/unrelated/base/kustomization.yaml"],
            "commit_subject": self.subject + " drift",
            "commit_author_name": "untrusted",
            "commit_committer_name": "untrusted",
        }
        for key, value in mutations.items():
            arguments = dict(child_arguments)
            arguments[key] = value
            with self.subTest(key=key), self.assertRaises(MIGRATION.GateError):
                MIGRATION.validate_pre_reconstruction_source_facts(**arguments)

        merge_arguments = dict(child_arguments)
        merge_arguments["current_parent_shas"] = [self.base_sha, "9" * 40]
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_pre_reconstruction_source_facts(**merge_arguments)

    def test_digest_derived_name_patch_and_render_are_exact_and_force_free(
        self,
    ) -> None:
        digest_hex = "8" * 64
        derived_name = "devpath-flyway-migrate-" + digest_hex[:24]
        base = (
            "apiVersion: kustomize.config.k8s.io/v1beta1\n"
            "kind: Kustomization\n"
            "resources:\n"
            "- job.yaml\n"
            "images:\n"
            f"- digest: sha256:{digest_hex}\n"
            "  name: ghcr.io/devpathai/devpath-migration\n"
            "  newName: ghcr.io/devpathai/devpath-migration\n"
        ).encode("utf-8")
        patch = (
            "patches:\n"
            "- target:\n"
            "    group: batch\n"
            "    version: v1\n"
            "    kind: Job\n"
            "    name: devpath-flyway-migrate\n"
            "  patch: |-\n"
            "    - op: replace\n"
            "      path: /metadata/name\n"
            f"      value: {derived_name}\n"
            "    - op: replace\n"
            "      path: /spec/suspend\n"
            "      value: false\n"
        ).encode("utf-8")
        self.assertEqual(
            derived_name, MIGRATION.derived_migration_job_name(self.image_digest)
        )
        self.assertEqual(
            base + patch,
            MIGRATION.add_migration_release_patch(base, self.image_digest),
        )
        MIGRATION.validate_migration_kustomization(base + patch, self.image_digest)

        render = (
            "apiVersion: v1\n"
            "kind: ConfigMap\n"
            "metadata:\n"
            "  name: preflight\n"
            "---\n"
            "apiVersion: batch/v1\n"
            "kind: Job\n"
            "metadata:\n"
            f"  name: {derived_name}\n"
            "spec:\n"
            "  suspend: false\n"
            "  template:\n"
            "    spec:\n"
            "      containers:\n"
            "      - name: flyway\n"
            "        image: ghcr.io/devpathai/devpath-migration@"
            f"sha256:{digest_hex}\n"
        ).encode("utf-8")
        self.assertEqual(
            derived_name,
            MIGRATION.validate_migration_render(render, self.image_digest),
        )
        base_render = render.replace(
            derived_name.encode(), b"devpath-flyway-migrate"
        ).replace(
            b"  suspend: false\n",
            b"  suspend: true\n",
        )
        MIGRATION.validate_base_migration_render(base_render)

        for changed in (
            base + b"patchesStrategicMerge:\n- legacy.yaml\n",
            base + patch.replace(b"replace", b"add"),
            base + patch.replace(b"/metadata/name", b"/metadata/annotations"),
            base + patch.split(b"    - op: replace\n      path: /spec/suspend", 1)[0],
            base + patch + b"# Force=true,Replace=true\n",
            (base + patch).replace(digest_hex[:24].encode(), b"9" * 24),
        ):
            with self.subTest(changed=changed[-100:]), self.assertRaises(
                MIGRATION.GateError
            ):
                MIGRATION.validate_migration_kustomization(changed, self.image_digest)
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render.replace(derived_name.encode(), b"devpath-flyway-migrate-latest"),
                self.image_digest,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render + render.split(b"---\n", 1)[1], self.image_digest
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render
                + (
                    "        image: ghcr.io/devpathai/"
                    "devpath-migration:mutable\n"
                ).encode(),
                self.image_digest,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render.replace(b"  suspend: false\n", b"  suspend: true\n"),
                self.image_digest,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_base_migration_render(
                base_render.replace(b"  suspend: true\n", b"  suspend: false\n")
            )

    def test_git_inspector_recomputes_parent_tree_path_subject_and_actor(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)

            def git(*arguments: str) -> str:
                return subprocess.run(
                    ["git", "-C", str(root), *arguments],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding="utf-8",
                ).stdout.strip()

            git("init", "-q")
            git("config", "user.name", "base-author")
            git("config", "user.email", "base@example.invalid")
            path = root / "apps/devpath-migration/base/kustomization.yaml"
            path.parent.mkdir(parents=True)
            path.write_text("base\n", encoding="utf-8", newline="\n")
            git("add", "--", "apps/devpath-migration/base/kustomization.yaml")
            git("commit", "-q", "-m", "base")
            base_sha = git("rev-parse", "HEAD")
            self.assertEqual(
                "published",
                MIGRATION.inspect_pre_reconstruction_source(
                    root=root,
                    release_id=self.release_id,
                    release_manifest_sha256=self.release_sha,
                    gitops_base_sha=base_sha,
                    supplied_source_sha=base_sha,
                ),
            )
            git("config", "user.name", "devpath-gitops-release[bot]")
            git(
                "config",
                "user.email",
                "devpath-gitops-release[bot]@users.noreply.github.com",
            )
            path.write_text("migration\n", encoding="utf-8", newline="\n")
            git("add", "--", "apps/devpath-migration/base/kustomization.yaml")
            git("commit", "-q", "-m", self.subject)
            migration_sha = git("rev-parse", "HEAD")
            tree_sha = git("rev-parse", "HEAD^{tree}")

            self.assertEqual(
                "reused",
                MIGRATION.inspect_pre_reconstruction_source(
                    root=root,
                    release_id=self.release_id,
                    release_manifest_sha256=self.release_sha,
                    gitops_base_sha=base_sha,
                    supplied_source_sha=migration_sha,
                ),
            )

            result = MIGRATION.inspect_migration_commit(
                root=root,
                release_id=self.release_id,
                release_manifest_sha256=self.release_sha,
                gitops_base_sha=base_sha,
                pre_push_main_sha=base_sha,
                expected_tree_sha=tree_sha,
                publish_mode="published",
            )
            self.assertEqual(migration_sha, result["migration_commit_sha"])
            self.assertEqual(tree_sha, result["migration_tree_sha"])

            (root / "untracked").write_text("drift\n", encoding="utf-8")
            with self.assertRaises(MIGRATION.GateError):
                MIGRATION.inspect_migration_commit(
                    root=root,
                    release_id=self.release_id,
                    release_manifest_sha256=self.release_sha,
                    gitops_base_sha=base_sha,
                    pre_push_main_sha=base_sha,
                    expected_tree_sha=tree_sha,
                    publish_mode="published",
                )

    def test_writer_creates_and_verifies_one_regular_file_only(self) -> None:
        raw = self.build()
        with tempfile.TemporaryDirectory() as temporary:
            evidence_dir = Path(temporary) / "result"
            evidence_file = MIGRATION.write_result_evidence(evidence_dir, raw)
            self.assertEqual(evidence_dir / "evidence.json", evidence_file)
            self.assertEqual(raw, evidence_file.read_bytes())
            self.assertEqual(
                self.expected(), MIGRATION.verify_result_evidence_dir(evidence_dir)
            )
            (evidence_dir / "extra.json").write_text("{}\n", encoding="utf-8")
            with self.assertRaises(MIGRATION.GateError):
                MIGRATION.verify_result_evidence_dir(evidence_dir)

        with tempfile.TemporaryDirectory() as temporary:
            occupied = Path(temporary) / "result"
            occupied.mkdir()
            with self.assertRaises(MIGRATION.GateError):
                MIGRATION.write_result_evidence(occupied, raw)


if __name__ == "__main__":
    unittest.main()
