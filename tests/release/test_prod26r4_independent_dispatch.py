import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "mission-spine-migration-release.yml"


class Prod26R4IndependentDispatchContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        jobs = cls.workflow.split("  dispatch:\n", 1)[1]
        cls.dispatch, cls.promotion = jobs.split("  promote-main:\n", 1)

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


if __name__ == "__main__":
    unittest.main()
