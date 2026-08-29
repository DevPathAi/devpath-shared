import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "mission-spine-migration-release.yml"


class Prod26R4IndependentDispatchContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_workflow_preserves_main_deploy_and_isolates_branch_dispatcher(self) -> None:
        self.assertIn("name: Mission Spine - sealed migration GitOps release", self.workflow)
        self.assertEqual(self.workflow.count("workflow_dispatch:"), 1)
        self.assertIn("environment: mission-spine-migration-release", self.workflow)
        self.assertIn("actions/checkout", self.workflow)
        self.assertIn("  deploy:\n    if: github.ref == 'refs/heads/main'", self.workflow)
        self.assertIn(
            "  dispatch:\n"
            "    if: github.ref == "
            "'refs/heads/chore/prod26r4-independent-dispatch'",
            self.workflow,
        )

    def test_dispatcher_has_only_required_repository_permissions(self) -> None:
        self.assertIn("permissions:\n  actions: write\n  contents: read", self.workflow)
        for forbidden in (
            "administration: write",
            "contents: write",
            "workflows: write",
        ):
            self.assertNotRegex(self.workflow, rf"(?m)^\s+{forbidden}\s*$")
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
            self.assertEqual(self.workflow.count(value), 1, value)

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
            self.assertIn(fragment, self.workflow)


if __name__ == "__main__":
    unittest.main()
