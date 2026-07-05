# 오브젝트 스토리지 인프라 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`).

**Goal:** devpath-shared에 S3 호환 오브젝트 스토리지 기반(포트+구현+검증+자동설정)과 MinIO 로컬 compose를 추가해, 각 svc가 shared 의존만으로 서버 경유 파일 업로드를 배선할 수 있게 한다.

**Architecture:** `ai.devpath.shared.storage`에 `ObjectStorage` 포트를 두고 AWS SDK v2 `S3Client` 기반 `S3ObjectStorage`로 구현한다. Spring Boot `@AutoConfiguration`이 `devpath.storage.*` 프로퍼티가 있을 때만 빈을 등록한다(미사용 svc 무영향). 파일 검증 실패는 기존 `IllegalArgumentException→400`, 스토리지 장애는 `StorageException→503`.

**Tech Stack:** Java 21 · Gradle(Kotlin DSL, `java-library`) · AWS SDK for Java v2(`software.amazon.awssdk:s3`) · Spring Boot 4.0.7 autoconfigure · MinIO · Testcontainers.

## Global Constraints

- **shared는 Spring/AWS SDK를 `compileOnly`로만 의존한다** — 기존 관례(build.gradle.kts: spring-web/security/webmvc가 compileOnly). 소비 svc가 런타임 의존을 제공한다. 스토리지 SDK도 동일: 소비 svc(마이페이지 spec)가 `software.amazon.awssdk:s3` 런타임 의존을 추가한다.
- **의존성 버전**: 착수 시 mavenCentral 최신 안정 버전을 확인해 pin한다. 이 plan의 예시 버전 — AWS SDK BOM `2.28.0`, Testcontainers BOM `1.20.4`, spring-boot `4.0.7`(기존 shared 관리버전과 일치), MinIO 이미지 `minio/minio:RELEASE.2024-10-13T13-34-11Z`.
- **에러코드 문자열 = enum name** — 프론트 dp_core `ApiErrorCode.fromWire`가 소비. `STORAGE_UNAVAILABLE`은 관례(`SANDBOX_UNAVAILABLE(503)`)에 맞춰 **503**.
- **로컬 자격증명만 커밋** — 프로덕션 값 금지(compose는 로컬 전용 `devpath`/`localdev123`).
- **TDD**: 각 Task는 실패 테스트 먼저 → 최소 구현 → `./gradlew test` 통과를 눈으로 확인 → 커밋.
- 모든 명령은 `cd /d/workspace/dpa/devpath-shared`에서 실행. 브랜치 `feat/object-storage`(이미 생성됨, base develop).

## File Structure

- `src/main/java/ai/devpath/shared/error/ErrorCode.java` (수정): `STORAGE_UNAVAILABLE(503)` 추가
- `src/main/java/ai/devpath/shared/storage/StorageException.java` (신규): `ApiException` 확장
- `src/main/java/ai/devpath/shared/storage/StoredFileValidator.java` (신규): 타입·크기 검증 + 키 생성
- `src/main/java/ai/devpath/shared/storage/ObjectStorage.java` (신규): 포트 + `StoredObject` record
- `src/main/java/ai/devpath/shared/storage/StorageProperties.java` (신규): `@ConfigurationProperties`
- `src/main/java/ai/devpath/shared/storage/S3ObjectStorage.java` (신규): 포트 구현
- `src/main/java/ai/devpath/shared/storage/StorageAutoConfiguration.java` (신규): 조건부 빈
- `src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (신규): autoconfig 등록
- `build.gradle.kts` (수정): 의존성
- `docker-compose.yml` (수정): minio 서비스
- 테스트: `src/test/java/ai/devpath/shared/storage/{StorageExceptionTest,StoredFileValidatorTest,S3ObjectStorageIT,StorageAutoConfigurationTest}.java`

---

## Task 1: STORAGE_UNAVAILABLE 에러코드 + StorageException

**Files:**
- Modify: `src/main/java/ai/devpath/shared/error/ErrorCode.java`
- Create: `src/main/java/ai/devpath/shared/storage/StorageException.java`
- Test: `src/test/java/ai/devpath/shared/storage/StorageExceptionTest.java`

**Interfaces:**
- Produces: `ErrorCode.STORAGE_UNAVAILABLE`(status 503); `StorageException extends ApiException`(생성자 `StorageException(String message)` 및 `StorageException(String message, Throwable cause)`, `code()==STORAGE_UNAVAILABLE`).

- [ ] **Step 1: 실패 테스트 작성**

`src/test/java/ai/devpath/shared/storage/StorageExceptionTest.java`:
```java
package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertEquals;

import ai.devpath.shared.error.ErrorCode;
import org.junit.jupiter.api.Test;

class StorageExceptionTest {
  @Test
  void carriesStorageUnavailableCodeAndStatus() {
    StorageException e = new StorageException("s3 down");
    assertEquals(ErrorCode.STORAGE_UNAVAILABLE, e.code());
    assertEquals(503, e.code().status());
    assertEquals("s3 down", e.getMessage());
  }

  @Test
  void preservesCause() {
    RuntimeException cause = new RuntimeException("sdk");
    StorageException e = new StorageException("wrap", cause);
    assertEquals(cause, e.getCause());
  }
}
```

- [ ] **Step 2: 실패 확인**

Run: `./gradlew test --tests '*StorageExceptionTest' --console=plain 2>&1 | tail -8`
Expected: 컴파일 실패(`ErrorCode.STORAGE_UNAVAILABLE`·`StorageException` 미존재).

- [ ] **Step 3: ErrorCode에 STORAGE_UNAVAILABLE 추가**

`ErrorCode.java`의 `SANDBOX_UNAVAILABLE(503),` 다음 줄에 추가:
```java
  SANDBOX_UNAVAILABLE(503),
  STORAGE_UNAVAILABLE(503),
  INTERNAL_ERROR(500);
```
(기존 `INTERNAL_ERROR(500);`는 유지 — 위 블록은 `SANDBOX_UNAVAILABLE`~`INTERNAL_ERROR` 구간 교체.)

- [ ] **Step 4: StorageException 작성**

`src/main/java/ai/devpath/shared/storage/StorageException.java`:
```java
package ai.devpath.shared.storage;

import ai.devpath.shared.error.ApiException;
import ai.devpath.shared.error.ErrorCode;

/** 오브젝트 스토리지 장애(S3/네트워크). {@link ApiExceptionHandler}가 503으로 렌더한다. */
public class StorageException extends ApiException {

  private static final long serialVersionUID = 1L;

  public StorageException(String message) {
    super(ErrorCode.STORAGE_UNAVAILABLE, message);
  }

  public StorageException(String message, Throwable cause) {
    super(ErrorCode.STORAGE_UNAVAILABLE, message);
    initCause(cause);
  }
}
```

- [ ] **Step 5: 통과 확인 + 커밋**

Run: `./gradlew test --tests '*StorageExceptionTest' --console=plain 2>&1 | tail -6`
Expected: PASS.
```bash
git add src/main/java/ai/devpath/shared/error/ErrorCode.java src/main/java/ai/devpath/shared/storage/StorageException.java src/test/java/ai/devpath/shared/storage/StorageExceptionTest.java
git commit -m "feat(storage): STORAGE_UNAVAILABLE(503) 에러코드 + StorageException"
```

---

## Task 2: StoredFileValidator (타입·크기 검증 + 키 생성)

**Files:**
- Create: `src/main/java/ai/devpath/shared/storage/StoredFileValidator.java`
- Test: `src/test/java/ai/devpath/shared/storage/StoredFileValidatorTest.java`

**Interfaces:**
- Produces: `StoredFileValidator(Set<String> allowedContentTypes, long maxFileSize)`; `void validate(String contentType, long size)`(위반 시 `IllegalArgumentException`); `String key(String prefix, String originalFilename)`(→ `"<prefix>/<uuid>.<ext>"`, 확장자 화이트리스트 png/jpg/jpeg/webp, 그 외 확장자 없음).

- [ ] **Step 1: 실패 테스트 작성**

`src/test/java/ai/devpath/shared/storage/StoredFileValidatorTest.java`:
```java
package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Set;
import org.junit.jupiter.api.Test;

class StoredFileValidatorTest {
  private final StoredFileValidator validator =
      new StoredFileValidator(Set.of("image/png", "image/jpeg", "image/webp"), 5 * 1024 * 1024);

  @Test
  void acceptsAllowedTypeWithinSize() {
    assertDoesNotThrow(() -> validator.validate("image/png", 1024));
  }

  @Test
  void rejectsDisallowedType() {
    assertThrows(IllegalArgumentException.class, () -> validator.validate("application/pdf", 1024));
  }

  @Test
  void rejectsOverSize() {
    assertThrows(
        IllegalArgumentException.class, () -> validator.validate("image/png", 5 * 1024 * 1024 + 1));
  }

  @Test
  void keyHasPrefixUuidAndExtension() {
    String key = validator.key("avatars", "photo.PNG");
    assertTrue(key.startsWith("avatars/"), key);
    assertTrue(key.endsWith(".png"), key);
    // avatars/<uuid>.png — uuid 36자
    assertEquals("avatars/".length() + 36 + ".png".length(), key.length());
  }

  @Test
  void keyDropsUnknownExtension() {
    String key = validator.key("avatars", "noext");
    assertTrue(key.startsWith("avatars/"), key);
    assertTrue(!key.contains("."), key);
  }
}
```

- [ ] **Step 2: 실패 확인**

Run: `./gradlew test --tests '*StoredFileValidatorTest' --console=plain 2>&1 | tail -8`
Expected: 컴파일 실패(`StoredFileValidator` 미존재).

- [ ] **Step 3: 구현**

`src/main/java/ai/devpath/shared/storage/StoredFileValidator.java`:
```java
package ai.devpath.shared.storage;

import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/** 업로드 파일 검증 + 저장 키 생성. 위반은 {@link IllegalArgumentException}(→ 400). */
public class StoredFileValidator {

  private static final Map<String, String> EXT =
      Map.of("image/png", "png", "image/jpeg", "jpg", "image/webp", "webp");

  private final Set<String> allowedContentTypes;
  private final long maxFileSize;

  public StoredFileValidator(Set<String> allowedContentTypes, long maxFileSize) {
    this.allowedContentTypes = Set.copyOf(allowedContentTypes);
    this.maxFileSize = maxFileSize;
  }

  public void validate(String contentType, long size) {
    if (contentType == null || !allowedContentTypes.contains(contentType)) {
      throw new IllegalArgumentException("허용되지 않은 파일 형식입니다: " + contentType);
    }
    if (size <= 0 || size > maxFileSize) {
      throw new IllegalArgumentException("파일 크기가 허용 범위를 벗어났습니다: " + size);
    }
  }

  /** {@code <prefix>/<uuid>[.<ext>]}. 확장자는 원본 파일명에서 화이트리스트로만 취한다. */
  public String key(String prefix, String originalFilename) {
    String ext = extensionOf(originalFilename);
    String base = prefix + "/" + UUID.randomUUID();
    return ext == null ? base : base + "." + ext;
  }

  private static String extensionOf(String filename) {
    if (filename == null) return null;
    int dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length() - 1) return null;
    String ext = filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    return switch (ext) {
      case "png", "jpg", "jpeg", "webp" -> ext.equals("jpeg") ? "jpg" : ext;
      default -> null;
    };
  }
}
```

- [ ] **Step 4: 통과 확인 + 커밋**

Run: `./gradlew test --tests '*StoredFileValidatorTest' --console=plain 2>&1 | tail -6`
Expected: PASS.
```bash
git add src/main/java/ai/devpath/shared/storage/StoredFileValidator.java src/test/java/ai/devpath/shared/storage/StoredFileValidatorTest.java
git commit -m "feat(storage): StoredFileValidator — 타입·크기 검증 + 키 생성"
```

---

## Task 3: ObjectStorage 포트 + StoredObject

**Files:**
- Create: `src/main/java/ai/devpath/shared/storage/ObjectStorage.java`

**Interfaces:**
- Produces: `interface ObjectStorage { StoredObject put(String key, byte[] content, String contentType); void delete(String key); String url(String key); }`; `record StoredObject(String key, String url)`.

- [ ] **Step 1: 포트 작성**

`src/main/java/ai/devpath/shared/storage/ObjectStorage.java`:
```java
package ai.devpath.shared.storage;

/**
 * 오브젝트 스토리지 포트. 소비 svc는 이 인터페이스에만 의존하며 S3 SDK를 직접 만지지 않는다.
 * 장애 시 {@link StorageException}(503)을 던진다.
 */
public interface ObjectStorage {

  /** 객체를 저장하고 접근 정보를 반환한다. */
  StoredObject put(String key, byte[] content, String contentType);

  /** 객체를 삭제한다(없으면 무시). */
  void delete(String key);

  /** 공개 접근 URL(publicBaseUrl 기반). */
  String url(String key);

  record StoredObject(String key, String url) {}
}
```

- [ ] **Step 2: 컴파일 확인 + 커밋**

Run: `./gradlew compileJava --console=plain 2>&1 | tail -4`
Expected: `BUILD SUCCESSFUL`.
```bash
git add src/main/java/ai/devpath/shared/storage/ObjectStorage.java
git commit -m "feat(storage): ObjectStorage 포트 + StoredObject"
```

---

## Task 4: 의존성 + StorageProperties

**Files:**
- Modify: `build.gradle.kts`
- Create: `src/main/java/ai/devpath/shared/storage/StorageProperties.java`

**Interfaces:**
- Produces: `StorageProperties`(record 또는 클래스) — `endpoint, bucket, accessKey, secretKey, publicBaseUrl, maxFileSize(기본 5MB), allowedContentTypes(기본 png/jpeg/webp)`. `@ConfigurationProperties("devpath.storage")`.

- [ ] **Step 1: build.gradle.kts 의존성 추가**

`dependencies { ... }` 블록에 추가(기존 `compileOnly` Spring 라인들 아래):
```kotlin
	// 오브젝트 스토리지(AWS SDK v2 S3 — MinIO 호환). Spring과 동일하게 compileOnly:
	// 소비 svc가 런타임 s3 의존을 제공한다.
	compileOnly(platform("software.amazon.awssdk:bom:2.28.0"))
	compileOnly("software.amazon.awssdk:s3")
	compileOnly("org.springframework.boot:spring-boot-autoconfigure:4.0.7")

	// 스토리지 테스트: 실 s3 클라이언트 + MinIO Testcontainers + 자동설정 검증.
	testImplementation(platform("software.amazon.awssdk:bom:2.28.0"))
	testImplementation("software.amazon.awssdk:s3")
	testImplementation(platform("org.testcontainers:testcontainers-bom:1.20.4"))
	testImplementation("org.testcontainers:minio")
	testImplementation("org.testcontainers:junit-jupiter")
	testImplementation("org.springframework.boot:spring-boot-autoconfigure:4.0.7")
	testImplementation("org.springframework.boot:spring-boot-test:4.0.7")
```
(착수 시 각 버전을 mavenCentral 최신 안정으로 확인해 pin.)

- [ ] **Step 2: 의존성 해석 확인**

Run: `./gradlew dependencies --configuration testRuntimeClasspath --console=plain 2>&1 | grep -iE "awssdk|testcontainers|minio" | head`
Expected: awssdk s3·testcontainers minio 해석됨.

- [ ] **Step 3: StorageProperties 작성**

`src/main/java/ai/devpath/shared/storage/StorageProperties.java`:
```java
package ai.devpath.shared.storage;

import java.util.Set;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** {@code devpath.storage.*} 설정. 소비 svc의 application.yml에서 주입한다. */
@ConfigurationProperties("devpath.storage")
public class StorageProperties {
  private String endpoint;
  private String bucket;
  private String accessKey;
  private String secretKey;
  private String publicBaseUrl;
  private long maxFileSize = 5 * 1024 * 1024;
  private Set<String> allowedContentTypes = Set.of("image/png", "image/jpeg", "image/webp");

  public String getEndpoint() { return endpoint; }
  public void setEndpoint(String v) { this.endpoint = v; }
  public String getBucket() { return bucket; }
  public void setBucket(String v) { this.bucket = v; }
  public String getAccessKey() { return accessKey; }
  public void setAccessKey(String v) { this.accessKey = v; }
  public String getSecretKey() { return secretKey; }
  public void setSecretKey(String v) { this.secretKey = v; }
  public String getPublicBaseUrl() { return publicBaseUrl; }
  public void setPublicBaseUrl(String v) { this.publicBaseUrl = v; }
  public long getMaxFileSize() { return maxFileSize; }
  public void setMaxFileSize(long v) { this.maxFileSize = v; }
  public Set<String> getAllowedContentTypes() { return allowedContentTypes; }
  public void setAllowedContentTypes(Set<String> v) { this.allowedContentTypes = v; }
}
```

- [ ] **Step 4: 컴파일 확인 + 커밋**

Run: `./gradlew compileJava --console=plain 2>&1 | tail -4`
Expected: `BUILD SUCCESSFUL`.
```bash
git add build.gradle.kts src/main/java/ai/devpath/shared/storage/StorageProperties.java
git commit -m "feat(storage): S3/Testcontainers 의존성 + StorageProperties"
```

---

## Task 5: S3ObjectStorage + MinIO Testcontainers 통합테스트

**Files:**
- Create: `src/main/java/ai/devpath/shared/storage/S3ObjectStorage.java`
- Test: `src/test/java/ai/devpath/shared/storage/S3ObjectStorageIT.java`

**Interfaces:**
- Consumes: `ObjectStorage`(Task 3), `StorageException`(Task 1), `StorageProperties`(Task 4).
- Produces: `S3ObjectStorage(S3Client s3, StorageProperties props)` implements `ObjectStorage`; 생성 시 버킷 없으면 생성 + 공개 read 정책 적용.

- [ ] **Step 1: 실패 통합테스트 작성**

`src/test/java/ai/devpath/shared/storage/S3ObjectStorageIT.java`:
```java
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

@Testcontainers
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
```

- [ ] **Step 2: 실패 확인**

Run: `./gradlew test --tests '*S3ObjectStorageIT' --console=plain 2>&1 | tail -10`
Expected: 컴파일 실패(`S3ObjectStorage` 미존재). (도커 필요 — 없으면 Step 4에서 스킵 가드 확인.)

- [ ] **Step 3: S3ObjectStorage 구현**

`src/main/java/ai/devpath/shared/storage/S3ObjectStorage.java`:
```java
package ai.devpath.shared.storage;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchBucketException;
import software.amazon.awssdk.services.s3.model.PutBucketPolicyRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

/** AWS SDK v2 S3 기반 구현(MinIO endpoint override + path-style). */
public class S3ObjectStorage implements ObjectStorage {

  private final S3Client s3;
  private final StorageProperties props;

  public S3ObjectStorage(S3Client s3, StorageProperties props) {
    this.s3 = s3;
    this.props = props;
    ensureBucket();
  }

  private void ensureBucket() {
    String bucket = props.getBucket();
    try {
      s3.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
    } catch (NoSuchBucketException e) {
      s3.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
      s3.putBucketPolicy(
          PutBucketPolicyRequest.builder().bucket(bucket).policy(publicReadPolicy(bucket)).build());
    } catch (S3Exception e) {
      throw new StorageException("버킷 초기화 실패: " + bucket, e);
    }
  }

  private static String publicReadPolicy(String bucket) {
    return "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\","
        + "\"Principal\":\"*\",\"Action\":\"s3:GetObject\","
        + "\"Resource\":\"arn:aws:s3:::" + bucket + "/*\"}]}";
  }

  @Override
  public StoredObject put(String key, byte[] content, String contentType) {
    try {
      s3.putObject(
          PutObjectRequest.builder()
              .bucket(props.getBucket())
              .key(key)
              .contentType(contentType)
              .build(),
          RequestBody.fromBytes(content));
      return new StoredObject(key, url(key));
    } catch (S3Exception e) {
      throw new StorageException("업로드 실패: " + key, e);
    }
  }

  @Override
  public void delete(String key) {
    try {
      s3.deleteObject(DeleteObjectRequest.builder().bucket(props.getBucket()).key(key).build());
    } catch (S3Exception e) {
      throw new StorageException("삭제 실패: " + key, e);
    }
  }

  @Override
  public String url(String key) {
    return props.getPublicBaseUrl() + "/" + props.getBucket() + "/" + key;
  }
}
```

- [ ] **Step 4: 통과 확인 + 커밋**

Run: `./gradlew test --tests '*S3ObjectStorageIT' --console=plain 2>&1 | tail -10`
Expected: PASS(도커 실행 필요). 도커 미가용이면 로그에 컨테이너 시작 실패 — 이 경우 로컬 `docker compose up -d minio`(Task 7 이후) 또는 도커 데몬 기동 후 재실행. CI 도커 가용성은 R-S2.
```bash
git add src/main/java/ai/devpath/shared/storage/S3ObjectStorage.java src/test/java/ai/devpath/shared/storage/S3ObjectStorageIT.java
git commit -m "feat(storage): S3ObjectStorage(MinIO) + Testcontainers 왕복 통합테스트"
```

---

## Task 6: StorageAutoConfiguration (조건부 빈)

**Files:**
- Create: `src/main/java/ai/devpath/shared/storage/StorageAutoConfiguration.java`
- Create: `src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`
- Test: `src/test/java/ai/devpath/shared/storage/StorageAutoConfigurationTest.java`

**Interfaces:**
- Consumes: `S3ObjectStorage`, `StorageProperties`, `ObjectStorage`.
- Produces: `devpath.storage.endpoint` 있을 때만 `S3Client`+`ObjectStorage` 빈. 없으면 미등록.

- [ ] **Step 1: 실패 테스트 작성**

`src/test/java/ai/devpath/shared/storage/StorageAutoConfigurationTest.java`:
```java
package ai.devpath.shared.storage;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class StorageAutoConfigurationTest {

  private final ApplicationContextRunner runner =
      new ApplicationContextRunner()
          .withConfiguration(AutoConfigurations.of(StorageAutoConfiguration.class));

  @Test
  void registersObjectStorageWhenEndpointSet() {
    runner
        .withPropertyValues(
            "devpath.storage.endpoint=http://localhost:9000",
            "devpath.storage.bucket=b",
            "devpath.storage.access-key=k",
            "devpath.storage.secret-key=s",
            "devpath.storage.public-base-url=http://localhost:9000")
        .run(ctx -> assertThat(ctx).hasSingleBean(ObjectStorage.class));
  }

  @Test
  void skipsWhenEndpointMissing() {
    runner.run(ctx -> assertThat(ctx).doesNotHaveBean(ObjectStorage.class));
  }
}
```
(`assertThat`은 spring-boot-test가 끌어오는 AssertJ. 미해석 시 `testImplementation("org.assertj:assertj-core")` 추가.)

- [ ] **Step 2: 실패 확인**

Run: `./gradlew test --tests '*StorageAutoConfigurationTest' --console=plain 2>&1 | tail -8`
Expected: 컴파일 실패(`StorageAutoConfiguration` 미존재).

- [ ] **Step 3: AutoConfiguration 작성**

`src/main/java/ai/devpath/shared/storage/StorageAutoConfiguration.java`:
```java
package ai.devpath.shared.storage;

import java.net.URI;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

/** {@code devpath.storage.endpoint}가 설정된 svc에만 스토리지 빈을 등록한다. */
@AutoConfiguration
@ConditionalOnProperty("devpath.storage.endpoint")
@EnableConfigurationProperties(StorageProperties.class)
public class StorageAutoConfiguration {

  @Bean
  @ConditionalOnMissingBean
  public S3Client storageS3Client(StorageProperties props) {
    return S3Client.builder()
        .endpointOverride(URI.create(props.getEndpoint()))
        .credentialsProvider(
            StaticCredentialsProvider.create(
                AwsBasicCredentials.create(props.getAccessKey(), props.getSecretKey())))
        .region(Region.US_EAST_1)
        .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
        .build();
  }

  @Bean
  @ConditionalOnMissingBean
  public ObjectStorage objectStorage(S3Client storageS3Client, StorageProperties props) {
    return new S3ObjectStorage(storageS3Client, props);
  }
}
```

- [ ] **Step 4: autoconfig 등록 파일 작성**

`src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`:
```
ai.devpath.shared.storage.StorageAutoConfiguration
```

- [ ] **Step 5: 통과 확인 + 커밋**

Run: `./gradlew test --tests '*StorageAutoConfigurationTest' --console=plain 2>&1 | tail -6`
Expected: PASS.
```bash
git add src/main/java/ai/devpath/shared/storage/StorageAutoConfiguration.java src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports src/test/java/ai/devpath/shared/storage/StorageAutoConfigurationTest.java
git commit -m "feat(storage): StorageAutoConfiguration — 조건부 빈 등록"
```

---

## Task 7: MinIO docker-compose

**Files:**
- Modify: `docker-compose.yml`

**Interfaces:**
- Produces: 로컬 `minio` 서비스(S3 `:9000`, 콘솔 `:9001`), `minio-data` 볼륨.

- [ ] **Step 1: minio 서비스 추가**

`docker-compose.yml`의 `services:` 블록 끝(마지막 서비스 다음)에 추가:
```yaml
  minio:
    image: minio/minio:RELEASE.2024-10-13T13-34-11Z
    command: ["server", "/data", "--console-address", ":9001"]
    environment:
      MINIO_ROOT_USER: devpath
      MINIO_ROOT_PASSWORD: localdev123
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio-data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 10s
      retries: 5
```
그리고 파일 하단 `volumes:` 블록에 `minio-data:` 추가(기존 `postgres-data:`·`pgvector-data:` 옆).

- [ ] **Step 2: compose 문법 검증**

Run: `docker compose -f docker-compose.yml config --quiet && echo OK`
Expected: `OK`(문법 오류 없음). 도커 미설치면 YAML 들여쓰기를 육안 확인.

- [ ] **Step 3: 커밋**

```bash
git add docker-compose.yml
git commit -m "feat(storage): MinIO 로컬 compose 서비스 추가"
```

---

## Task 8: 전체 빌드 + PR

- [ ] **Step 1: 전체 빌드 검증**

Run: `./gradlew build --console=plain 2>&1 | tail -6`
Expected: `BUILD SUCCESSFUL`(도커 가용 시 IT 포함, 미가용 시 IT는 실패할 수 있으므로 `./gradlew build -x test` 후 도커 환경에서 `./gradlew test` 별도 검증 — R-S2).

- [ ] **Step 2: develop PR**

```bash
git push -u origin feat/object-storage
gh pr create --base develop --head feat/object-storage \
  --title "feat: 오브젝트 스토리지 인프라(MinIO + shared/storage)" \
  --body "스펙: docs/superpowers/specs/2026-07-05-object-storage-design.md. ObjectStorage 포트+S3 구현+검증+조건부 자동설정 + MinIO compose + STORAGE_UNAVAILABLE(503). 소비(마이페이지 avatar)는 후속 spec."
```

- [ ] **Step 3: 발행 게이트 주의**

머지 후 소비 svc가 storage API를 쓰려면: `gh workflow run publish.yml --ref develop`로 수동 발행([[devpath-web-posttier2-roadmap]] C2 교훈).

---

## Self-Review 결과

- **Spec 커버리지**: ObjectStorage 포트→Task3, S3 구현→Task5, StorageProperties/AutoConfiguration→Task4·6, StoredFileValidator→Task2, MinIO compose→Task7, STORAGE_UNAVAILABLE→Task1, 통합/단위 테스트→Task5·2·6. 비목표(avatar 소비·presigned·리사이즈)는 태스크 없음(의도적). ✅
- **스펙과의 차이**: (1) 에러 status 502→**503**(코드 관례 SANDBOX_UNAVAILABLE 일관). (2) 스펙의 "핸들러에 502 매핑 추가" 대신 **StorageException(ApiException 확장)**으로 핸들러 무수정(더 깔끔). 두 변경 모두 스펙 의도(검증 400/장애 별도 코드 구분) 유지. ✅
- **플레이스홀더**: 버전은 예시+"착수 시 최신 pin" 명시(의도적). 그 외 실코드·실명령. ✅
- **타입 일관**: `ObjectStorage.StoredObject`(record) — Task3 정의, Task5 반환, IT 소비 일치. `StorageProperties` getter/setter — Task4 정의, Task5·6 소비 일치. `StorageException` — Task1 정의, Task5 사용 일치. ✅
- **주의**: 공개 read 버킷 정책(IT의 익명 HTTP GET 200 검증 근거)을 `ensureBucket`에 포함. 도커 의존 IT는 R-S2로 게이팅.
