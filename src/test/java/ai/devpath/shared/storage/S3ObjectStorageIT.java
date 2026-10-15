package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.containers.MinIOContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

/**
 * 도커 미가용 로컬에서는 스킵한다. CI(환경변수 CI 존재)에서는 스킵하지 않는다 — 도커를 못 쓰면
 * 컨테이너 기동이 실패해 빌드가 빨갛게 된다. Testcontainers 1.20.4 가 Docker 29 를 「도커 없음」으로
 * 판정해 IT 가 조용히 빠졌던 구멍(2026-10)을 CI 에서 다시 놓치지 않기 위해서다.
 */
@Testcontainers
@EnabledIf("dockerAvailableOrCi")
class S3ObjectStorageIT {

  static boolean dockerAvailableOrCi() {
    return System.getenv("CI") != null || DockerClientFactory.instance().isDockerAvailable();
  }

  // Docker Hub 의 minio/minio 저장소가 사라졌다(2026-10 확인, pull 404). 같은 계열 커뮤니티 포크
  // pgsty/minio:RELEASE.2026-08-04T00-00-00Z 를 digest 로 고정한다.
  @Container
  static final MinIOContainer MINIO =
      new MinIOContainer(
          DockerImageName.parse(
                  "pgsty/minio@sha256:b6bfe7239bfc83fb90d31612d9704d86039dd714f7904b3f1ad68f211e602372")
              .asCompatibleSubstituteFor("minio/minio"));

  private S3ObjectStorage storage() {
    StorageProperties props = new StorageProperties();
    props.setEndpoint(MINIO.getS3URL());
    props.setBucket("test-bucket");
    props.setAccessKey(MINIO.getUserName());
    props.setSecretKey(MINIO.getPassword());
    props.setPublicBaseUrl(MINIO.getS3URL());
    props.setAllowedContentTypes(Set.of("image/png"));
    S3Client s3 =
        S3Client.builder()
            .endpointOverride(URI.create(MINIO.getS3URL()))
            .credentialsProvider(
                StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(MINIO.getUserName(), MINIO.getPassword())))
            .region(Region.US_EAST_1)
            .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
            .build();
    return new S3ObjectStorage(s3, props);
  }

  @Test
  void putGetDeleteRoundTrip() throws Exception {
    S3ObjectStorage storage = storage();
    byte[] content = "hello".getBytes();

    ObjectStorage.StoredObject stored = storage.put("avatars/a.png", content, "image/png");
    assertTrue(stored.url().endsWith("test-bucket/avatars/a.png"), stored.url());

    HttpClient http = HttpClient.newHttpClient();
    HttpResponse<byte[]> get =
        http.send(
            HttpRequest.newBuilder(URI.create(stored.url())).GET().build(),
            HttpResponse.BodyHandlers.ofByteArray());
    assertEquals(200, get.statusCode());
    assertEquals("hello", new String(get.body()));

    storage.delete("avatars/a.png");
    HttpResponse<byte[]> afterDelete =
        http.send(
            HttpRequest.newBuilder(URI.create(stored.url())).GET().build(),
            HttpResponse.BodyHandlers.ofByteArray());
    assertEquals(404, afterDelete.statusCode());
  }
}
