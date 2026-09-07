import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "mission-spine-migration-release.yml"


class Prod26R4IndependentDispatchContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        jobs = cls.workflow.split("  dispatch:\n", 1)[1]
        cls.dispatch, promotion_and_rest = jobs.split("  promote-main:\n", 1)
        cls.promotion, separator, cls.seal = promotion_and_rest.partition(
            "  seal-develop:\n"
        )
        if separator:
            cls.seal = "  seal-develop:\n" + cls.seal
        cls.seal, separator, cls.attestation = cls.seal.partition(
            "  attest-develop:\n"
        )
        if separator:
            cls.attestation = "  attest-develop:\n" + cls.attestation

    def test_workflow_preserves_main_deploy_and_isolates_branch_dispatcher(self) -> None:
        self.assertIn("name: Mission Spine - sealed migration GitOps release", self.workflow)
        self.assertEqual(self.workflow.count("workflow_dispatch:"), 1)
        self.assertIn("environment: mission-spine-migration-release", self.workflow)
        self.assertIn("actions/checkout", self.workflow)
        self.assertIn("  deploy:\n    if: github.ref == 'refs/heads/main'", self.workflow)
        self.assertIn(
            "  dispatch:\n"
            "    if: >-\n"
            "      github.ref == 'refs/heads/chore/prod26r4-independent-dispatch'",
            self.workflow,
        )
        self.assertIn(
            "  promote-main:\n"
            "    if: >-\n"
            "      github.ref == 'refs/heads/chore/shared-promotion-bot-20260907'",
            self.workflow,
        )

    def test_dispatcher_has_only_required_repository_permissions(self) -> None:
        self.assertIn("permissions:\n  actions: write\n  contents: read", self.workflow)
        for forbidden in (
            "administration: write",
            "contents: write",
            "workflows: write",
        ):
            self.assertNotRegex(self.dispatch, rf"(?m)^\s+{forbidden}\s*$")
        self.assertIn(
            "permissions:\n      actions: read\n      contents: read\n      deployments: write",
            self.workflow,
        )

    def test_dispatcher_pins_the_exact_sealed_release_coordinates(self) -> None:
        expected_values = (
            "ms-20260828-prod26r4",
            "4f245d61cc4924c9db0f3f3cbb90434ad0fe7d93",
            "e866a50f5ca535ebc1ed83343c651af064e424de",
            "eca2a73378eff8a9ce310f7ef997b51b7910984f",
            "0b012f527ad30fde9a9cfdf9280377d84ef9a38da78987962ad86b38661a0575",
        )
        for value in expected_values:
            self.assertEqual(self.dispatch.count(value), 1, value)

    def test_dispatcher_uses_the_actions_app_and_fails_closed(self) -> None:
        required_fragments = (
            'test "$GITHUB_ACTOR" = "VelkaressiaBlutkrone"',
            'test "$GITHUB_TRIGGERING_ACTOR" = "VelkaressiaBlutkrone"',
            'test "$GITHUB_RUN_ATTEMPT" = "1"',
            'test "$GITHUB_REF" = "refs/heads/chore/prod26r4-independent-dispatch"',
            'repos/$GITHUB_REPOSITORY/actions/workflows/335839429/dispatches',
            '"ref": "main"',
            'test "$inner_actor" = "github-actions[bot]"',
            'test "$inner_triggering_actor" = "github-actions[bot]"',
            'actions/runs/$inner_run_id/cancel',
        )
        for fragment in required_fragments:
            self.assertIn(fragment, self.dispatch)

    def test_main_promotion_is_bot_authored_and_cannot_mutate_protection(self) -> None:
        required_fragments = (
            "permissions:\n      contents: read\n      pull-requests: write",
            "shared-main-20260907-mentor-access",
            "b6b8c6ba79818af4d338f2875352ecd07f455068",
            "ca9aaa72d0a039d77afa7bdf64bb7221c10dd46f",
            "d25fc0f49d8d72e491805ed0308bacad9ca2c26a",
            "efb73a6b5aab7c78d7580bfe97d7f0c35abfc417",
            "4beab8926e6905dff6d5f7052f6052cd8ebbc731948db4510b87e227caff9a0e",
            'EXPECTED_NONCE_SHA256: "ff846ded5f1e98b49b09d434aadc7240337aa542f1f8242916dd93dc13dc915d"',
            'test "$GITHUB_RUN_ATTEMPT" = "1"',
            'test "$(git rev-parse HEAD^1)" = "$EXPECTED_CONTENT_SHA"',
            'test "$(git rev-parse HEAD^2)" = "$EXPECTED_MAIN_SHA"',
            'test "$(git rev-parse HEAD^{tree})" = "$EXPECTED_TREE_SHA"',
            'test "$diff_sha256" = "$EXPECTED_DIFF_SHA256"',
            'test "$(git show -s --format=%an HEAD)" = "Velkaressia"',
            'test "$(git show -s --format=%cn HEAD)" = "GitHub"',
            '--title "chore(release): promote mentor access contracts"',
            "Automation-authored Shared main promotion after validated PR #83.",
            'test "$(gh pr view "$pr_number" --json author --jq ',
            '"app/github-actions"',
        )
        for fragment in required_fragments:
            self.assertIn(fragment, self.promotion)
        for forbidden in (
            "--force",
            "administration: write",
            "/protection",
            "/rulesets",
            "git push",
            "refs/heads/main",
        ):
            self.assertNotIn(forbidden, self.promotion)

    def test_develop_seal_is_exact_bot_push_without_main_mutation(self) -> None:
        required_fragments = (
            "  seal-develop:\n",
            "github.ref == 'refs/heads/chore/shared-promotion-bot-20260907'",
            "shared-main-seal-20260907-mentor-access",
            "permissions:\n      contents: write\n      pull-requests: read",
            "b6b8c6ba79818af4d338f2875352ecd07f455068",
            "d25fc0f49d8d72e491805ed0308bacad9ca2c26a",
            "efb73a6b5aab7c78d7580bfe97d7f0c35abfc417",
            "e805e9580381c79d56497b844f428f4b5912977a",
            'EXPECTED_NONCE_SHA256: "1b8438927b4a01205434ca3b5a2272f9c8e73812bbb65d2f906492edb03edebb"',
            'test "$GITHUB_RUN_ATTEMPT" = "1"',
            'test "$(git rev-parse HEAD)" = "$EXPECTED_DEVELOP_SHA"',
            'GIT_AUTHOR_NAME="github-actions[bot]"',
            'GIT_AUTHOR_DATE="2026-09-07T10:57:00Z"',
            'git commit-tree "$EXPECTED_TREE_SHA" -p "$EXPECTED_DEVELOP_SHA"',
            'test "$sealed_sha" = "$EXPECTED_SEALED_SHA"',
            'git push origin "$sealed_sha:refs/heads/develop"',
            'test "$server_develop" = "$EXPECTED_SEALED_SHA"',
            'test "$pr_author" = "github-actions[bot]"',
        )
        for fragment in required_fragments:
            self.assertIn(fragment, self.seal)
        for forbidden in (
            "--force",
            "administration: write",
            "pull-requests: write",
            "refs/heads/main",
        ):
            self.assertNotIn(forbidden, self.seal)

    def test_release_attestation_is_one_exact_reviewable_bot_push(self) -> None:
        required_fragments = (
            "  attest-develop:\n",
            "github.ref == 'refs/heads/chore/shared-promotion-bot-20260907'",
            "shared-main-attest-20260907-mentor-access",
            "permissions:\n      contents: write\n      pull-requests: read",
            "b6b8c6ba79818af4d338f2875352ecd07f455068",
            "e805e9580381c79d56497b844f428f4b5912977a",
            "efb73a6b5aab7c78d7580bfe97d7f0c35abfc417",
            "ffc4dbdd66345ccc459df5ba11fa26ef3f61fc30",
            "3565aba4733b601285ca4fecf50bd443257797ba",
            "5b688a2274ad0de8285b0d77d3a8a6ea802b3808",
            "6e84dddd3b62aa9439ead259b8961df3ff42fd71739f10dd5cb49dc71ef66bb6",
            'EXPECTED_NONCE_SHA256: "08e322cb35f2059cdb395ad1367bc0342c665c53c06c3398fcfcda1bd90eea09"',
            "docs/releases/2026-09-07-mentor-access-promotion.md",
            'test "$(git hash-object "$ATTESTATION_PATH")" = "$EXPECTED_BLOB_SHA"',
            'test "$attested_tree" = "$EXPECTED_ATTESTED_TREE_SHA"',
            'GIT_AUTHOR_DATE="2026-09-07T11:14:00Z"',
            'git commit-tree "$EXPECTED_ATTESTED_TREE_SHA" -p "$EXPECTED_DEVELOP_SHA"',
            'test "$attested_sha" = "$EXPECTED_ATTESTED_SHA"',
            'git push origin "$attested_sha:refs/heads/develop"',
            'test "$server_develop" = "$EXPECTED_ATTESTED_SHA"',
        )
        for fragment in required_fragments:
            self.assertIn(fragment, self.attestation)
        for forbidden in (
            "--force",
            "administration: write",
            "pull-requests: write",
            "refs/heads/main",
        ):
            self.assertNotIn(forbidden, self.attestation)


if __name__ == "__main__":
    unittest.main()
