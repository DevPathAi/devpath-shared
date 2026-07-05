package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.MinIOContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

/** 도커 미가용 환경(로컬)에서는 자동 스킵(disabledWithoutDocker). 도커/CI에서 왕복 검증. */
@Testcontainers(disabledWithoutDocker = true)
class S3ObjectStorageIT {

  @Container
  static final MinIOContainer MINIO =
      new MinIOContainer("minio/minio:RELEASE.2024-10-13T13-34-11Z");

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
