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
            "rendered_job_name": (
                "devpath-flyway-migrate-" + "8" * 12 + "-" + "3" * 24
            ),
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
                "rendered_job_name": (
                    "devpath-flyway-migrate-" + "8" * 12 + "-" + "3" * 24
                ),
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

    def test_exact_github_actions_bot_is_allowed_only_as_initiator(self) -> None:
        automation_env = copy.deepcopy(self.env)
        automation_env["GITHUB_ACTOR"] = "github-actions[bot]"
        automation_env["GITHUB_TRIGGERING_ACTOR"] = "github-actions[bot]"

        approval = MIGRATION.validate_protected_approval(
            env=automation_env,
            environment_raw=canonical(self.environment),
            approvals_raw=canonical(self.approvals),
            jobs_raw=canonical(self.jobs),
        )
        self.assertEqual("independent-reviewer", approval["reviewer_login"])

        for invalid_actor in (
            "evil[bot]",
            "github-actions[bot]suffix",
            "[bot]",
        ):
            changed_env = copy.deepcopy(self.env)
            changed_env["GITHUB_ACTOR"] = invalid_actor
            changed_env["GITHUB_TRIGGERING_ACTOR"] = invalid_actor
            with self.subTest(invalid_actor=invalid_actor), self.assertRaises(
                MIGRATION.GateError
            ):
                MIGRATION.validate_protected_approval(
                    env=changed_env,
                    environment_raw=canonical(self.environment),
                    approvals_raw=canonical(self.approvals),
                    jobs_raw=canonical(self.jobs),
                )

        environment = copy.deepcopy(self.environment)
        environment["protection_rules"][0]["reviewers"][0]["reviewer"][
            "login"
        ] = "github-actions[bot]"
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=automation_env,
                environment_raw=canonical(environment),
                approvals_raw=canonical(self.approvals),
                jobs_raw=canonical(self.jobs),
            )

        approvals = copy.deepcopy(self.approvals)
        approvals[0]["user"]["login"] = "github-actions[bot]"
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_protected_approval(
                env=automation_env,
                environment_raw=canonical(self.environment),
                approvals_raw=canonical(approvals),
                jobs_raw=canonical(self.jobs),
            )

    def test_gitops_app_scope_and_rulesets_are_exact(self) -> None:
        app = {"id": 4242, "slug": "devpath-gitops-release"}
        repositories = {
            "total_count": 1,
            "repositories": [
                {
                    "id": 42,
                    "full_name": "DevPathAi/devpath-gitops",
                    "archived": False,
                }
            ],
        }
        classic = {
            "required_status_checks": None,
            "restrictions": {"users": [], "teams": [], "apps": [app]},
            "required_pull_request_reviews": {
                "dismiss_stale_reviews": True,
                "require_code_owner_reviews": False,
                "required_approving_review_count": 1,
                "require_last_push_approval": True,
                "bypass_pull_request_allowances": {
                    "users": [],
                    "teams": [],
                    "apps": [app],
                },
            },
            "enforce_admins": {"enabled": True},
            "required_linear_history": {"enabled": True},
            "required_conversation_resolution": {"enabled": True},
            "allow_force_pushes": {"enabled": False},
            "allow_deletions": {"enabled": False},
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
                    "type": "update",
                    "parameters": {"update_allows_fetch_and_merge": False},
                }
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

        def validate(**overrides):
            details = overrides.get("details", (integrity, governance))
            return MIGRATION.validate_gitops_authorization(
                app_slug=overrides.get("app_slug", "devpath-gitops-release"),
                app_id=overrides.get("app_id", "4242"),
                installation_id=overrides.get("installation_id", "7654321"),
                repositories_raw=canonical(
                    overrides.get("repositories", repositories)
                ),
                classic_protection_status=overrides.get("classic_status", "200"),
                classic_protection_raw=canonical(
                    overrides.get("classic_protection", classic)
                ),
                rulesets_raw=canonical(overrides.get("rulesets", rulesets)),
                ruleset_details_raw=tuple(canonical(document) for document in details),
            )

        self.assertEqual(
            {
                "write_app_slug": "devpath-gitops-release",
                "write_app_id": 4242,
                "write_app_installation_id": 7654321,
            },
            validate(),
        )

        hidden_integrity = copy.deepcopy(integrity)
        hidden_governance = copy.deepcopy(governance)
        del hidden_integrity["bypass_actors"]
        del hidden_governance["bypass_actors"]
        hidden_integrity["current_user_can_bypass"] = "never"
        hidden_governance["current_user_can_bypass"] = "always"
        validate(details=(hidden_integrity, hidden_governance))

        omitted_update_parameters = copy.deepcopy(governance)
        omitted_update_parameters["rules"] = [{"type": "update"}]
        validate(details=(integrity, omitted_update_parameters))

        omitted_classic_checks = copy.deepcopy(classic)
        del omitted_classic_checks["required_status_checks"]
        validate(classic_protection=omitted_classic_checks)

        disabled_dismissal = copy.deepcopy(classic)
        disabled_dismissal["required_pull_request_reviews"][
            "dismissal_restrictions"
        ] = {"users": [], "teams": [], "apps": []}
        validate(classic_protection=disabled_dismissal)

        bad_cases = []
        changed = copy.deepcopy(hidden_governance)
        del changed["current_user_can_bypass"]
        bad_cases.append(
            (
                "hidden-governance-without-proof",
                {"details": (integrity, changed)},
            )
        )
        changed = copy.deepcopy(hidden_integrity)
        changed["current_user_can_bypass"] = "always"
        bad_cases.append(("integrity-bypass", {"details": (changed, governance)}))
        changed = copy.deepcopy(governance)
        changed["bypass_actors"].append(
            {"actor_id": 1, "actor_type": "User", "bypass_mode": "always"}
        )
        bad_cases.append(("extra-bypass-actor", {"details": (integrity, changed)}))
        changed = copy.deepcopy(governance)
        changed["rules"][0]["parameters"]["update_allows_fetch_and_merge"] = True
        bad_cases.append(("fetch-and-merge", {"details": (integrity, changed)}))
        changed = copy.deepcopy(governance)
        changed["rules"] = [{"type": "pull_request"}]
        bad_cases.append(("human-pr-governance", {"details": (integrity, changed)}))
        changed = copy.deepcopy(classic)
        changed["required_status_checks"] = {}
        bad_cases.append(("classic-status-checks", {"classic_protection": changed}))
        changed = copy.deepcopy(classic)
        changed["restrictions"]["apps"] = []
        bad_cases.append(("classic-app-only-push", {"classic_protection": changed}))
        changed = copy.deepcopy(classic)
        changed["required_pull_request_reviews"][
            "require_last_push_approval"
        ] = False
        bad_cases.append(("classic-reviews", {"classic_protection": changed}))
        changed = copy.deepcopy(classic)
        changed["required_pull_request_reviews"][
            "required_approving_review_count"
        ] = True
        bad_cases.append(("classic-json-type", {"classic_protection": changed}))
        changed = copy.deepcopy(classic)
        changed["required_pull_request_reviews"]["dismissal_restrictions"] = {
            "users": [],
            "teams": [],
            "apps": [app],
        }
        bad_cases.append(("classic-dismissal", {"classic_protection": changed}))
        changed = copy.deepcopy(repositories)
        changed["total_count"] = 2
        bad_cases.append(("repository-scope", {"repositories": changed}))
        changed = copy.deepcopy(repositories)
        changed["repositories"][0]["archived"] = True
        bad_cases.append(("repository-archived", {"repositories": changed}))
        changed = copy.deepcopy(rulesets)
        changed[0].append(copy.deepcopy(changed[0][0]))
        bad_cases.append(("extra-ruleset", {"rulesets": changed}))
        changed = copy.deepcopy(integrity)
        del changed["target"]
        bad_cases.append(("detail-target", {"details": (changed, governance)}))
        changed_rulesets = copy.deepcopy(rulesets)
        changed_rulesets[0][1]["id"] = changed_rulesets[0][0]["id"]
        changed_governance = copy.deepcopy(governance)
        changed_governance["id"] = changed_rulesets[0][0]["id"]
        bad_cases.append(
            (
                "duplicate-ruleset-id",
                {
                    "rulesets": changed_rulesets,
                    "details": (integrity, changed_governance),
                },
            )
        )
        bad_cases.extend(
            (
                ("classic-absent", {"classic_status": "404"}),
                ("app-id", {"app_id": "0"}),
                ("installation-id", {"installation_id": "0"}),
                ("slug", {"app_slug": "other"}),
            )
        )
        for label, overrides in bad_cases:
            with self.subTest(label=label), self.assertRaises(MIGRATION.GateError):
                validate(**overrides)

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
        prior_hex = "7" * 64
        digest_hex = "8" * 64
        prior_digest = "sha256:" + prior_hex
        next_digest = "sha256:" + digest_hex
        prior_release_sha = "6" * 64
        next_release_sha = "9" * 64
        prior_name = (
            "devpath-flyway-migrate-" + prior_hex[:12] + "-" + prior_release_sha[:24]
        )
        derived_name = (
            "devpath-flyway-migrate-" + digest_hex[:12] + "-" + next_release_sha[:24]
        )
        legacy = (
            "apiVersion: kustomize.config.k8s.io/v1beta1\n"
            "kind: Kustomization\n"
            "resources:\n"
            "- job.yaml\n"
            "images:\n"
            "- name: ghcr.io/devpathai/devpath-migration\n"
            "  newName: ghcr.io/devpathai/devpath-migration\n"
            "  newTag: release-1\n"
        ).encode("utf-8")

        def patch(job_name: str) -> bytes:
            return (
                "patches:\n"
                "- target:\n"
                "    group: batch\n"
                "    version: v1\n"
                "    kind: Job\n"
                "    name: devpath-flyway-migrate\n"
                "  patch: |-\n"
                "    - op: replace\n"
                "      path: /metadata/name\n"
                f"      value: {job_name}\n"
                "    - op: replace\n"
                "      path: /spec/suspend\n"
                "      value: false\n"
            ).encode("utf-8")

        prior_body = legacy.replace(
            b"  newTag: release-1\n", f"  digest: {prior_digest}\n".encode()
        )
        next_body = legacy.replace(
            b"  newTag: release-1\n", f"  digest: {next_digest}\n".encode()
        )
        release_one = prior_body + patch(prior_name)
        release_two = next_body + patch(derived_name)
        self.assertEqual(
            derived_name,
            MIGRATION.derived_migration_job_name(next_digest, next_release_sha),
        )
        self.assertEqual(
            release_one,
            MIGRATION.render_migration_kustomization(
                legacy, prior_digest, prior_release_sha
            ),
        )
        self.assertEqual(
            release_two,
            MIGRATION.render_migration_kustomization(
                release_one, next_digest, next_release_sha
            ),
        )
        MIGRATION.validate_migration_kustomization(
            release_two, next_digest, next_release_sha
        )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.render_migration_kustomization(
                release_one, prior_digest, prior_release_sha
            )

        same_digest_next_name = (
            "devpath-flyway-migrate-" + prior_hex[:12] + "-" + next_release_sha[:24]
        )
        same_digest_next = prior_body + patch(same_digest_next_name)
        self.assertEqual(
            same_digest_next,
            MIGRATION.render_migration_kustomization(
                release_one, prior_digest, next_release_sha
            ),
        )

        canonical_job = (
            "apiVersion: batch/v1\n"
            "kind: Job\n"
            "metadata:\n"
            "  name: devpath-flyway-migrate\n"
            "spec:\n"
            "  # Base/main is inert. Only the protected sealed M commit may\n"
            "  # unsuspend a digest-derived Job after selecting its digest.\n"
            "  suspend: true\n"
            "  backoffLimit: 3\n"
            "  template: {}\n"
        ).encode()
        MIGRATION.validate_base_migration_job(canonical_job)

        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "kustomization.yaml"
            path.write_bytes(release_one)
            self.assertEqual(
                derived_name,
                MIGRATION.write_migration_kustomization(
                    path, next_digest, next_release_sha
                ),
            )
            self.assertEqual(release_two, path.read_bytes())

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
            MIGRATION.validate_migration_render(
                render, next_digest, next_release_sha
            ),
        )
        base_render = render.replace(
            derived_name.encode(), b"devpath-flyway-migrate"
        ).replace(
            b"  suspend: false\n",
            b"  suspend: true\n",
        )
        MIGRATION.validate_base_migration_render(base_render)

        for changed in (
            prior_body,
            legacy + patch(prior_name),
            legacy + b"patches: []\n",
            legacy + b" patches:\n",
            legacy + b"patchesJson6902:\n- legacy.yaml\n",
            legacy + b"patchesStrategicMerge:\n- legacy.yaml\n",
            release_one + patch(prior_name),
            release_one.replace(b"replace", b"add", 1),
            release_one.replace(b"/metadata/name", b"/metadata/annotations"),
            release_one.split(
                b"    - op: replace\n      path: /spec/suspend", 1
            )[0],
            release_one + b"# Force=true,Replace=true\n",
            release_one + b"# Replace=true\n",
            release_one.replace(
                prior_name.encode(),
                (
                    "devpath-flyway-migrate-"
                    + "9" * 12
                    + "-"
                    + prior_release_sha[:24]
                ).encode(),
            ),
            legacy.replace(b"  newTag: release-1\n", b"  newTag: bad tag\n"),
            legacy.replace(
                b"  newTag: release-1\n",
                b"  newTag: release-1\n  digest: sha256:" + b"9" * 64 + b"\n",
            ),
        ):
            with self.subTest(changed=changed[-100:]), self.assertRaises(
                MIGRATION.GateError
            ):
                MIGRATION.render_migration_kustomization(
                    changed, next_digest, next_release_sha
                )
        for changed_job in (
            canonical_job.replace(b"suspend: true", b"suspend: false"),
            canonical_job.replace(
                b"  suspend: true\n", b"  suspend: true\n  suspend: true\n"
            ),
            canonical_job.replace(b"  backoffLimit: 3\n", b""),
            canonical_job + b"# Force=true,Replace=true\n",
        ):
            with self.subTest(changed_job=changed_job[-80:]), self.assertRaises(
                MIGRATION.GateError
            ):
                MIGRATION.validate_base_migration_job(changed_job)
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render.replace(derived_name.encode(), b"devpath-flyway-migrate-latest"),
                next_digest,
                next_release_sha,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render + render.split(b"---\n", 1)[1],
                next_digest,
                next_release_sha,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render
                + (
                    "        image: ghcr.io/devpathai/"
                    "devpath-migration:mutable\n"
                ).encode(),
                next_digest,
                next_release_sha,
            )
        with self.assertRaises(MIGRATION.GateError):
            MIGRATION.validate_migration_render(
                render.replace(b"  suspend: false\n", b"  suspend: true\n"),
                next_digest,
                next_release_sha,
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
