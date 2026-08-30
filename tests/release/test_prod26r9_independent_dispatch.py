import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "mission-spine-migration-release.yml"


class Prod26R9IndependentDispatchContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.dispatch = cls.workflow.split("  dispatch:\n", 1)[1]

    def test_main_deploy_and_helper_dispatch_are_ref_isolated(self) -> None:
        self.assertIn("  deploy:\n    if: github.ref == 'refs/heads/main'", self.workflow)
        self.assertIn(
            "  dispatch:\n"
            "    if: github.ref == 'refs/heads/chore/prod26r9-independent-dispatch'",
            self.workflow,
        )

    def test_dispatcher_has_only_actions_write_permission(self) -> None:
        self.assertIn("permissions:\n  actions: write\n  contents: read", self.workflow)
        for forbidden in (
            "administration: write",
            "contents: write",
            "workflows: write",
            "pull-requests: write",
        ):
            self.assertNotIn(forbidden, self.dispatch)

    def test_dispatcher_pins_exact_prod26r9_coordinates(self) -> None:
        expected_values = (
            "ms-20260830-prod26r9",
            "b6b8c6ba79818af4d338f2875352ecd07f455068",
            "9ae75a2f0dc9f22f2383775fd2f785d510f93740",
            "bda5d3d991922db18ceafe379fb54e2d3ee603fc",
            "fb563a971d59474d4fc4ce1425a76c53157535c51ade0127be54632a8f4dcea2",
        )
        for value in expected_values:
            self.assertEqual(1, self.dispatch.count(value), value)

    def test_dispatcher_uses_actions_app_and_fails_closed(self) -> None:
        required_fragments = (
            'test "$GITHUB_ACTOR" = "VelkaressiaBlutkrone"',
            'test "$GITHUB_TRIGGERING_ACTOR" = "VelkaressiaBlutkrone"',
            'test "$GITHUB_RUN_ATTEMPT" = "1"',
            'test "$GITHUB_REF" = "refs/heads/chore/prod26r9-independent-dispatch"',
            'repos/$GITHUB_REPOSITORY/actions/workflows/335839429/dispatches',
            '"ref": "main"',
            'test "$inner_actor" = "github-actions[bot]"',
            'test "$inner_triggering_actor" = "github-actions[bot]"',
            'actions/runs/$inner_run_id/cancel',
        )
        for fragment in required_fragments:
            self.assertIn(fragment, self.dispatch)


if __name__ == "__main__":
    unittest.main()
