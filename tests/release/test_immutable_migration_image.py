import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from urllib.error import HTTPError
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/release/immutable_migration_image.py"
SPEC = importlib.util.spec_from_file_location("immutable_migration_image", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("unable to load immutable migration image verifier")
IMAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(IMAGE)


SOURCE_SHA = "a" * 40
IMAGE_DIGEST = "sha256:" + "b" * 64


def canonical(value: object) -> bytes:
    return (json.dumps(value, separators=(",", ":")) + "\n").encode("utf-8")


def exact_config(source_sha: str = SOURCE_SHA) -> bytes:
    return canonical(
        {
            "architecture": "amd64",
            "os": "linux",
            "config": {
                "Labels": {
                    "org.opencontainers.image.source": IMAGE.SOURCE_LABEL,
                    "org.opencontainers.image.revision": source_sha,
                    IMAGE.BUILDER_INDEX_LABEL: IMAGE.BUILDER_BASE_INDEX_DIGEST,
                    IMAGE.BUILDER_AMD64_LABEL: IMAGE.BUILDER_BASE_AMD64_DIGEST,
                    IMAGE.RUNTIME_INDEX_LABEL: IMAGE.RUNTIME_BASE_INDEX_DIGEST,
                    IMAGE.RUNTIME_AMD64_LABEL: IMAGE.RUNTIME_BASE_AMD64_DIGEST,
                }
            },
        }
    )


def exact_manifest(config_bytes: bytes) -> bytes:
    return canonical(
        {
            "schemaVersion": 2,
            "mediaType": "application/vnd.oci.image.manifest.v1+json",
            "config": {
                "mediaType": "application/vnd.oci.image.config.v1+json",
                "digest": "sha256:" + hashlib.sha256(config_bytes).hexdigest(),
                "size": len(config_bytes),
            },
            "layers": [],
        }
    )


def api_error(
    url: str,
    status: int,
    body: bytes,
    content_type: str = "application/json",
) -> HTTPError:
    return HTTPError(
        url,
        status,
        "API error",
        {"Content-Type": content_type, "Content-Length": str(len(body))},
        io.BytesIO(body),
    )


class DockerAndWorkflowContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.dockerfile = (ROOT / "Dockerfile.migration").read_text(encoding="utf-8")
        self.workflow = (ROOT / ".github/workflows/ci.yml").read_text(
            encoding="utf-8"
        )
        self.publish_workflow = (ROOT / ".github/workflows/publish.yml").read_text(
            encoding="utf-8"
        )
        self.gradle = (ROOT / "build.gradle.kts").read_text(encoding="utf-8")

    def test_dockerfile_pins_both_multiarch_bases_and_all_provenance_labels(self) -> None:
        self.assertIn(
            "FROM eclipse-temurin:21-jdk-alpine@"
            + IMAGE.BUILDER_BASE_INDEX_DIGEST
            + " AS build",
            self.dockerfile,
        )
        self.assertIn(
            "FROM flyway/flyway:11-alpine@" + IMAGE.RUNTIME_BASE_INDEX_DIGEST,
            self.dockerfile,
        )
        for literal in (
            "ARG SOURCE_REVISION",
            "ARG SOURCE_REPOSITORY",
            "org.opencontainers.image.revision=$SOURCE_REVISION",
            "org.opencontainers.image.source=$SOURCE_REPOSITORY",
            f"{IMAGE.BUILDER_INDEX_LABEL}={IMAGE.BUILDER_BASE_INDEX_DIGEST}",
            f"{IMAGE.BUILDER_AMD64_LABEL}={IMAGE.BUILDER_BASE_AMD64_DIGEST}",
            f"{IMAGE.RUNTIME_INDEX_LABEL}={IMAGE.RUNTIME_BASE_INDEX_DIGEST}",
            f"{IMAGE.RUNTIME_AMD64_LABEL}={IMAGE.RUNTIME_BASE_AMD64_DIGEST}",
        ):
            with self.subTest(literal=literal):
                self.assertIn(literal, self.dockerfile)
        for literal in (
            "RUN --mount=type=bind,source=src/main/resources/db/migration",
            "RUN --mount=type=bind,from=build,source=/workspace/build/libs",
            "find /flyway/sql -exec touch -h -d @0 {} +",
            "find /flyway/drivers -exec touch -h -d @0 {} +",
            "touch -h -d @0 /flyway",
        ):
            with self.subTest(literal=literal):
                self.assertIn(literal, self.dockerfile)
        self.assertIn("isPreserveFileTimestamps = false", self.gradle)
        self.assertIn("isReproducibleFileOrder = true", self.gradle)

    def test_image_job_is_attempt_one_one_shot_and_emits_one_sanitized_file(self) -> None:
        for literal in (
            "github.repository == 'DevPathAi/devpath-shared'",
            "docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f",
            "version: v0.34.1",
            "image=moby/buildkit:v0.30.0@sha256:"
            "0168606be2315b7c807a03b3d8aa79beefdb31c98740cebdffdfeebf31190c9f",
            "group: immutable-migration-image-${{ github.sha }}",
            "cancel-in-progress: false",
            "immutable_migration_image.py verify-source",
            "load: true",
            "push: false",
            "SOURCE_DATE_EPOCH=0",
            "CANDIDATE_CONFIG_DIGEST: ${{ steps.image-build.outputs.imageid }}",
            '--candidate-config-digest "$CANDIDATE_CONFIG_DIGEST"',
            "immutable_migration_image.py preflight",
            "immutable_migration_image.py recheck",
            "steps.push-state.outputs.push_needed == 'true'",
            "docker push \"ghcr.io/devpathai/devpath-migration:${GITHUB_SHA}\"",
            "no-cache: true",
            "provenance: false",
            "sbom: false",
            "immutable_migration_image.py postflight",
            "immutable_migration_image.py verify-evidence",
            "name: migration-image-evidence-${{ github.sha }}",
            "path: ${{ runner.temp }}/migration-image-evidence/evidence.json",
            "if-no-files-found: error",
            "immutable-shared-publication-${{ github.sha }}-"
            "${{ github.run_id }}-${{ github.run_attempt }}",
        ):
            with self.subTest(literal=literal):
                self.assertIn(literal, self.workflow)
        self.assertLess(
            self.workflow.index("docker/setup-buildx-action@"),
            self.workflow.index("id: image-build"),
        )
        self.assertNotIn("devpath-migration:main", self.workflow)
        uses = []
        for line in self.workflow.splitlines():
            stripped = line.strip()
            if stripped.startswith("uses:") or stripped.startswith("- uses:"):
                uses.append(stripped.split("uses:", 1)[1].split("#", 1)[0].strip())
        self.assertTrue(uses)
        for action in uses:
            with self.subTest(action=action):
                self.assertRegex(action, r"^[^@]+@[0-9a-f]{40}$")

    def test_ci_change_triggers_a_fresh_attempt_one_package_publish(self) -> None:
        self.assertIn('      - ".github/workflows/ci.yml"', self.publish_workflow)


class ImageVerifierTest(unittest.TestCase):
    def test_registry_success_response_length_and_identity_encoding_are_exact(self) -> None:
        client = IMAGE.RegistryClient("actor", "token")
        url = "https://ghcr.io/example"

        def response(body: bytes, headers: dict[str, str]):
            result = mock.MagicMock()
            result.__enter__.return_value = result
            result.status = 200
            result.geturl.return_value = url
            result.headers = headers
            result.read.return_value = body
            return result

        body = b"exact-response\n"
        exact = response(
            body,
            {"Content-Length": str(len(body)), "Content-Encoding": "identity"},
        )
        with mock.patch.object(client._opener, "open", return_value=exact) as opened:
            self.assertEqual(
                (
                    body,
                    {
                        "content-length": str(len(body)),
                        "content-encoding": "identity",
                    },
                ),
                client._request(url, {}, 1024),
            )
        request = opened.call_args.args[0]
        self.assertEqual("identity", request.get_header("Accept-encoding"))

        no_encoding = response(body, {"Content-Length": str(len(body))})
        with mock.patch.object(client._opener, "open", return_value=no_encoding):
            self.assertEqual(
                (body, {"content-length": str(len(body))}),
                client._request(url, {}, 1024),
            )

        with self.assertRaises(IMAGE.ImageError):
            client._request(url, {"Accept-Encoding": "gzip"}, 1024)

        for raw, headers in (
            (body, {"Content-Length": str(len(body) + 1)}),
            (body, {"Content-Length": str(len(body) - 1)}),
            (body, {"Content-Length": str(len(body)), "Content-Encoding": "gzip"}),
        ):
            with self.subTest(headers=headers):
                changed = response(raw, headers)
                with mock.patch.object(client._opener, "open", return_value=changed):
                    with self.assertRaises(IMAGE.ImageError):
                        client._request(url, {}, 1024)

    def test_registry_token_response_requires_json_content_type(self) -> None:
        client = IMAGE.RegistryClient("actor", "token")
        raw = canonical({"token": "bearer"})
        with mock.patch.object(
            client,
            "_request",
            return_value=(raw, {"content-type": "application/json"}),
        ):
            self.assertEqual("bearer", client._bearer_token())
        for content_type in (None, "text/plain", "application/json; charset=latin1"):
            headers = {} if content_type is None else {"content-type": content_type}
            with self.subTest(content_type=content_type):
                with mock.patch.object(client, "_request", return_value=(raw, headers)):
                    with self.assertRaises(IMAGE.ImageError):
                        client._bearer_token()

    def test_context_requires_attempt_one_current_main_and_clean_exact_sha(self) -> None:
        env = {
            "GITHUB_REPOSITORY": IMAGE.REPOSITORY,
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_RUN_ATTEMPT": "1",
            "GITHUB_RUN_ID": "123",
            "GITHUB_SHA": SOURCE_SHA,
        }
        IMAGE.validate_ci_context(env, SOURCE_SHA, SOURCE_SHA, SOURCE_SHA, "")
        mutations = {
            "GITHUB_REPOSITORY": "Other/repository",
            "GITHUB_EVENT_NAME": "workflow_dispatch",
            "GITHUB_REF": "refs/heads/develop",
            "GITHUB_RUN_ATTEMPT": "2",
            "GITHUB_RUN_ID": "0",
            "GITHUB_SHA": "c" * 40,
        }
        for key, value in mutations.items():
            with self.subTest(key=key):
                changed = dict(env)
                changed[key] = value
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.validate_ci_context(
                        changed, SOURCE_SHA, SOURCE_SHA, SOURCE_SHA, ""
                    )
        for head, remote, status in (
            ("c" * 40, SOURCE_SHA, ""),
            (SOURCE_SHA, "c" * 40, ""),
            (SOURCE_SHA, SOURCE_SHA, " M Dockerfile.migration"),
        ):
            with self.subTest(head=head, remote=remote, status=status):
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.validate_ci_context(env, SOURCE_SHA, head, remote, status)

    def test_source_verification_refetches_main_before_every_trust_decision(self) -> None:
        env = {
            "GITHUB_REPOSITORY": IMAGE.REPOSITORY,
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_REF": "refs/heads/main",
            "GITHUB_RUN_ATTEMPT": "1",
            "GITHUB_RUN_ID": "123",
            "GITHUB_SHA": SOURCE_SHA,
        }
        with mock.patch.dict(os.environ, env, clear=True):
            with mock.patch.object(
                IMAGE, "_git", side_effect=["", SOURCE_SHA, SOURCE_SHA, ""]
            ) as git:
                self.assertEqual(SOURCE_SHA, IMAGE.verify_ci_source(ROOT))
        self.assertEqual(
            mock.call(
                ROOT,
                "fetch",
                "--no-tags",
                "origin",
                "main:refs/remotes/origin/main",
            ),
            git.call_args_list[0],
        )

    def test_exact_manifest_digest_config_and_six_labels_are_required(self) -> None:
        config = exact_config()
        manifest = exact_manifest(config)
        digest = "sha256:" + hashlib.sha256(manifest).hexdigest()
        result = IMAGE.validate_remote_image(manifest, digest, config, SOURCE_SHA)
        self.assertEqual(digest, result.digest)

        with self.assertRaises(IMAGE.ImageError):
            IMAGE.validate_remote_image(manifest, IMAGE_DIGEST, config, SOURCE_SHA)

        index = json.loads(manifest)
        index["mediaType"] = "application/vnd.oci.image.index.v1+json"
        with self.assertRaises(IMAGE.ImageError):
            IMAGE.validate_remote_image(canonical(index), digest, config, SOURCE_SHA)

        mutations = {
            "org.opencontainers.image.source": "https://github.com/Other/repo",
            "org.opencontainers.image.revision": "c" * 40,
            IMAGE.BUILDER_INDEX_LABEL: "sha256:" + "c" * 64,
            IMAGE.BUILDER_AMD64_LABEL: "sha256:" + "c" * 64,
            IMAGE.RUNTIME_INDEX_LABEL: "sha256:" + "c" * 64,
            IMAGE.RUNTIME_AMD64_LABEL: "sha256:" + "c" * 64,
        }
        for label, value in mutations.items():
            with self.subTest(label=label):
                document = json.loads(config)
                document["config"]["Labels"][label] = value
                changed = canonical(document)
                changed_manifest = exact_manifest(changed)
                changed_digest = "sha256:" + hashlib.sha256(changed_manifest).hexdigest()
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.validate_remote_image(
                        changed_manifest, changed_digest, changed, SOURCE_SHA
                    )

    def test_existing_tag_must_equal_the_locally_built_candidate_config(self) -> None:
        config = exact_config()
        manifest = exact_manifest(config)
        digest = "sha256:" + hashlib.sha256(manifest).hexdigest()
        remote = IMAGE.validate_remote_image(manifest, digest, config, SOURCE_SHA)
        IMAGE.require_candidate_config(remote, remote.config_digest)
        with self.assertRaises(IMAGE.ImageError):
            IMAGE.require_candidate_config(remote, "sha256:" + "c" * 64)

        changed = json.loads(config)
        changed["rootfs"] = {"type": "layers", "diff_ids": ["sha256:" + "d" * 64]}
        changed_config = canonical(changed)
        changed_manifest = exact_manifest(changed_config)
        changed_digest = "sha256:" + hashlib.sha256(changed_manifest).hexdigest()
        drifted = IMAGE.validate_remote_image(
            changed_manifest, changed_digest, changed_config, SOURCE_SHA
        )
        with self.assertRaises(IMAGE.ImageError):
            IMAGE.require_candidate_config(drifted, remote.config_digest)

    def test_build_action_digest_must_equal_the_loaded_local_candidate(self) -> None:
        candidate = "sha256:" + "c" * 64
        IMAGE.require_local_candidate_config(candidate, candidate)
        for local, reported in (
            ("sha256:" + "d" * 64, candidate),
            (candidate, "sha256:" + "d" * 64),
            ("invalid", candidate),
            (candidate, "invalid"),
        ):
            with self.subTest(local=local, reported=reported):
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.require_local_candidate_config(local, reported)

    def test_local_candidate_is_exact_linux_amd64_with_all_six_labels(self) -> None:
        labels = json.loads(exact_config())["config"]["Labels"]
        document = {
            "Id": "sha256:" + "c" * 64,
            "Architecture": "amd64",
            "Os": "linux",
            "RepoTags": [f"{IMAGE.IMAGE_REPOSITORY}:{SOURCE_SHA}"],
            "Config": {"Labels": labels},
        }
        self.assertEqual(
            "sha256:" + "c" * 64,
            IMAGE.validate_local_image_document(document, SOURCE_SHA),
        )
        for path, value in (
            (("Architecture",), "arm64"),
            (("RepoTags",), []),
            (("Config", "Labels", IMAGE.RUNTIME_AMD64_LABEL), "sha256:" + "d" * 64),
        ):
            with self.subTest(path=path):
                changed = json.loads(json.dumps(document))
                target = changed
                for key in path[:-1]:
                    target = target[key]
                target[path[-1]] = value
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.validate_local_image_document(changed, SOURCE_SHA)

    def test_second_lookup_closes_normal_races_without_overwriting(self) -> None:
        candidate = "sha256:" + "c" * 64
        exact = IMAGE.RemoteImage(IMAGE_DIGEST, candidate)
        self.assertEqual((True, ""), IMAGE.resolve_recheck("true", "", None, candidate))
        self.assertEqual(
            (False, IMAGE_DIGEST),
            IMAGE.resolve_recheck("true", "", exact, candidate),
        )
        self.assertEqual(
            (False, IMAGE_DIGEST),
            IMAGE.resolve_recheck("false", IMAGE_DIGEST, exact, candidate),
        )
        for state in (
            ("false", IMAGE_DIGEST, None, candidate),
            ("false", "sha256:" + "d" * 64, exact, candidate),
            ("true", "sha256:" + "d" * 64, exact, candidate),
            ("true", "", IMAGE.RemoteImage(IMAGE_DIGEST, "sha256:" + "d" * 64), candidate),
        ):
            with self.subTest(state=state):
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.resolve_recheck(*state)

    def test_only_exact_manifest_endpoint_404_means_absent(self) -> None:
        client = IMAGE.RegistryClient("actor", "token")
        manifest_url = client.manifest_url(SOURCE_SHA)
        absent = b'{"errors":[{"code":"MANIFEST_UNKNOWN","message":"manifest unknown"}]}\n'
        with mock.patch.object(client, "_bearer_token", return_value="bearer"):
            with mock.patch.object(
                client, "_request", side_effect=api_error(manifest_url, 404, absent)
            ):
                self.assertIsNone(client.inspect(SOURCE_SHA, allow_absent=True))
            for url, status, body, content_type in (
                (manifest_url + "-other", 404, absent, "application/json"),
                (manifest_url, 403, absent, "application/json"),
                (manifest_url, 404, b"not-json\n", "application/json"),
                (
                    manifest_url,
                    404,
                    b'{"errors":[{"code":"DENIED","message":"manifest unknown"}]}\n',
                    "application/json",
                ),
                (
                    manifest_url,
                    404,
                    b'{"errors":[{"code":"MANIFEST_UNKNOWN",'
                    b'"message":"manifest unknown"},{"code":"MANIFEST_UNKNOWN",'
                    b'"message":"manifest unknown"}]}\n',
                    "application/json",
                ),
                (manifest_url, 404, absent, "text/plain"),
                (
                    manifest_url,
                    404,
                    absent,
                    "application/json; charset=iso-8859-1",
                ),
                (
                    manifest_url,
                    404,
                    b"x" * (IMAGE.MAX_ERROR_BYTES + 1),
                    "application/json",
                ),
            ):
                with self.subTest(url=url, status=status, body=body[:30]):
                    error = api_error(url, status, body, content_type)
                    with mock.patch.object(client, "_request", side_effect=error):
                        with self.assertRaises(IMAGE.ImageError):
                            client.inspect(SOURCE_SHA, allow_absent=True)
            length_mismatch = api_error(manifest_url, 404, absent)
            length_mismatch.headers["Content-Length"] = "1"
            with mock.patch.object(client, "_request", side_effect=length_mismatch):
                with self.assertRaises(IMAGE.ImageError):
                    client.inspect(SOURCE_SHA, allow_absent=True)
            encoded = api_error(manifest_url, 404, absent)
            encoded.headers["Content-Encoding"] = "gzip"
            with mock.patch.object(client, "_request", side_effect=encoded):
                with self.assertRaises(IMAGE.ImageError):
                    client.inspect(SOURCE_SHA, allow_absent=True)

    def test_registry_credentials_reject_both_cr_and_lf(self) -> None:
        for actor, token in (
            ("actor\nother", "token"),
            ("actor\rother", "token"),
            ("actor", "token\nother"),
            ("actor", "token\rother"),
        ):
            with self.subTest(actor=actor, token=token):
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE.RegistryClient(actor, token)

    def test_config_blob_allows_one_exact_auth_stripped_github_storage_redirect(self) -> None:
        config = exact_config()
        manifest = exact_manifest(config)
        manifest_digest = "sha256:" + hashlib.sha256(manifest).hexdigest()
        config_digest = "sha256:" + hashlib.sha256(config).hexdigest()
        client = IMAGE.RegistryClient("actor", "token")
        config_url = client.config_url(config_digest)
        storage_url = (
            "https://pkg-containers.githubusercontent.com/ghcrblobs09/blobs/"
            + config_digest
            + "?sig=opaque"
        )
        redirect = HTTPError(
            config_url,
            307,
            "Temporary Redirect",
            {"Location": storage_url, "Content-Length": "0"},
            io.BytesIO(b""),
        )
        calls = []

        def request(url, headers, max_bytes):
            calls.append((url, dict(headers), max_bytes))
            if len(calls) == 1:
                return manifest, {"docker-content-digest": manifest_digest}
            if len(calls) == 2:
                raise redirect
            if len(calls) == 3:
                return config, {}
            raise AssertionError("unexpected registry request")

        with mock.patch.object(client, "_bearer_token", return_value="bearer"):
            with mock.patch.object(client, "_request", side_effect=request):
                result = client.inspect(SOURCE_SHA, allow_absent=False)
        self.assertEqual(manifest_digest, result.digest)
        self.assertIn("Authorization", calls[1][1])
        self.assertNotIn("Authorization", calls[2][1])
        self.assertEqual(storage_url, calls[2][0])

        evil_locations = (
            "http://pkg-containers.githubusercontent.com/blob",
            "https://pkg-containers.githubusercontent.com.evil.example/blob",
            "https://user@pkg-containers.githubusercontent.com/blob",
            "https://pkg-containers.githubusercontent.com:444/blob",
            "https://pkg-containers.githubusercontent.com/wrong/path?sig=opaque",
            "https://pkg-containers.githubusercontent.com/ghcrblobs09/blobs/sha256:"
            + "d" * 64
            + "?sig=opaque",
        )
        for location in evil_locations:
            with self.subTest(location=location):
                bad_redirect = HTTPError(
                    config_url,
                    307,
                    "Temporary Redirect",
                    {"Location": location, "Content-Length": "0"},
                    io.BytesIO(b""),
                )
                with mock.patch.object(client, "_bearer_token", return_value="bearer"):
                    with mock.patch.object(
                        client,
                        "_request",
                        side_effect=[
                            (manifest, {"docker-content-digest": manifest_digest}),
                            bad_redirect,
                        ],
                    ):
                        with self.assertRaises(IMAGE.ImageError):
                            client.inspect(SOURCE_SHA, allow_absent=False)

        encoded_redirect = HTTPError(
            config_url,
            307,
            "Temporary Redirect",
            {
                "Location": storage_url,
                "Content-Length": "0",
                "Content-Encoding": "gzip",
            },
            io.BytesIO(b""),
        )
        with mock.patch.object(client, "_bearer_token", return_value="bearer"):
            with mock.patch.object(
                client,
                "_request",
                side_effect=[
                    (manifest, {"docker-content-digest": manifest_digest}),
                    encoded_redirect,
                ],
            ):
                with self.assertRaises(IMAGE.ImageError):
                    client.inspect(SOURCE_SHA, allow_absent=False)

        second_redirect = HTTPError(
            storage_url,
            307,
            "Temporary Redirect",
            {"Location": storage_url, "Content-Length": "0"},
            io.BytesIO(b""),
        )
        fresh_first_redirect = HTTPError(
            config_url,
            307,
            "Temporary Redirect",
            {"Location": storage_url, "Content-Length": "0"},
            io.BytesIO(b""),
        )
        with mock.patch.object(client, "_bearer_token", return_value="bearer"):
            with mock.patch.object(
                client,
                "_request",
                side_effect=[
                    (manifest, {"docker-content-digest": manifest_digest}),
                    fresh_first_redirect,
                    second_redirect,
                ],
            ):
                with self.assertRaises(IMAGE.ImageError):
                    client.inspect(SOURCE_SHA, allow_absent=False)


class EvidenceContractTest(unittest.TestCase):
    def test_evidence_exact_fields_and_attempt_one_semantics_reject_mutations(self) -> None:
        document = IMAGE._evidence_document(
            SOURCE_SHA, 123, 1, IMAGE_DIGEST, "published"
        )
        IMAGE._validate_evidence(document)
        mutations = {
            "schema_version": "other",
            "status": "failed",
            "repository": "Other/repository",
            "source_sha": "c" * 40,
            "producer_run_id": 0,
            "producer_run_attempt": 2,
            "image_repository": "ghcr.io/other/image",
            "image_tag": "c" * 40,
            "image_digest": "sha256:" + "0" * 64,
            "publish_mode": "overwritten",
            "source_label": "https://github.com/Other/repository",
            "revision_label": "c" * 40,
            "builder_base_index_digest": "sha256:" + "c" * 64,
            "builder_base_amd64_digest": "sha256:" + "c" * 64,
            "runtime_base_index_digest": "sha256:" + "c" * 64,
            "runtime_base_amd64_digest": "sha256:" + "c" * 64,
        }
        for key, value in mutations.items():
            with self.subTest(key=key):
                changed = dict(document)
                changed[key] = value
                with self.assertRaises(IMAGE.ImageError):
                    IMAGE._validate_evidence(changed)

        reordered = dict(document)
        schema_version = reordered.pop("schema_version")
        reordered["schema_version"] = schema_version
        with self.assertRaises(IMAGE.ImageError):
            IMAGE._validate_evidence(reordered)

    def test_evidence_is_exact_ordered_utf8_and_one_regular_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "evidence"
            evidence = IMAGE.write_evidence(
                root,
                source_sha=SOURCE_SHA,
                run_id=123,
                run_attempt=1,
                image_digest=IMAGE_DIGEST,
                publish_mode="published",
            )
            parsed = IMAGE.validate_evidence_directory(root)
            self.assertEqual(IMAGE.EVIDENCE_KEYS, tuple(parsed))
            self.assertEqual(evidence, root / "evidence.json")
            raw = evidence.read_bytes()
            self.assertFalse(raw.startswith(b"\xef\xbb\xbf"))
            self.assertTrue(raw.endswith(b"\n"))
            self.assertLessEqual(len(raw), IMAGE.MAX_EVIDENCE_BYTES)

            (root / "extra.json").write_text("{}\n", encoding="utf-8")
            with self.assertRaises(IMAGE.ImageError):
                IMAGE.validate_evidence_directory(root)

    def test_evidence_rejects_symlink_oversize_and_invalid_utf8(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "evidence"
            root.mkdir()
            evidence = root / "evidence.json"
            evidence.write_bytes(b"x" * (IMAGE.MAX_EVIDENCE_BYTES + 1))
            with self.assertRaises(IMAGE.ImageError):
                IMAGE.validate_evidence_directory(root)
            evidence.write_bytes(b"\xff\n")
            with self.assertRaises(IMAGE.ImageError):
                IMAGE.validate_evidence_directory(root)
            evidence.unlink()
            target = Path(temp) / "target.json"
            target.write_text("{}\n", encoding="utf-8")
            try:
                os.symlink(target, evidence)
            except OSError:
                self.skipTest("symlink creation is unavailable")
            with self.assertRaises(IMAGE.ImageError):
                IMAGE.validate_evidence_directory(root)


if __name__ == "__main__":
    unittest.main()
