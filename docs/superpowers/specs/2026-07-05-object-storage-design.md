# 설계: 오브젝트 스토리지 인프라 (범용 기반)

- 날짜: 2026-07-05
- 로드맵: [documents/44_MVP_잔여_로드맵](https://github.com/DevPathAi/documents/blob/develop/44_MVP_잔여_로드맵.md) **② 마이페이지의 선행 서브프로젝트**. 마이페이지 avatar 파일 업로드가 첫 소비자이나, 이 spec은 재사용 가능한 범용 스토리지 기반만 다룬다.
- 영향 레포: **devpath-shared**(스토리지 클라이언트 라이브러리 + MinIO compose). 소비 svc(platform 등)는 후속 spec.
- 브랜치: `feat/object-storage`(base develop).

## 배경 / 목표

프로젝트에 오브젝트 스토리지가 전무하다(실측 2026-07-05: MinIO/S3 의존·업로드 엔드포인트 없음, `devpath-shared/docker-compose.yml`은 postgres·postgres-vector·redis·elasticsearch·kafka만). 마이페이지 avatar 업로드를 비롯해 향후 파일 업로드(이미지·첨부)를 위한 **재사용 가능한 서버 경유 업로드 기반**을 shared에 구축한다.

**목표**: shared에 S3 호환 오브젝트 스토리지 포트+구현+검증+자동설정, MinIO 로컬 compose, 통합/단위 테스트. 각 svc가 shared 의존만으로 파일 업로드를 배선할 수 있는 기반.

**비목표**: 실제 avatar 소비(→ 마이페이지 spec), presigned URL, 이미지 리사이즈/썸네일, CDN, 프로덕션 자격증명(런북).

## 결정 사항

- **S3 클라이언트 = AWS SDK for Java v2** (`software.amazon.awssdk:s3`). MinIO는 S3 호환이므로 엔드포인트 override + path-style 접근으로 동일 코드. 로컬(MinIO)→프로덕션(실 S3/R2) 이식성 확보. (MinIO 자체 SDK 대비 이식성 우위 — 정확한 아티팩트 버전·API는 구현 plan에서 context7로 확정.)
- **업로드 = 서버 경유**: svc 컨트롤러가 `MultipartFile` 수신 → 검증 → `ObjectStorage.put` → 공개 URL 반환. presigned는 비범위.
- **소유 = shared 라이브러리**: 스토리지 접근을 `ai.devpath.shared.storage`에 캡슐화, 각 svc가 재사용(에러 envelope 패턴과 동일 구조).
- **파일 제한**: 이미지 `image/png`·`image/jpeg`·`image/webp`, 최대 5MB(프로퍼티로 조정 가능).
- **가시성**: MVP는 공개 읽기 버킷(URL 직접 접근). 비공개+서명 URL은 후속.

## 컴포넌트 (`ai.devpath.shared.storage`)

### ObjectStorage (포트 인터페이스)
```java
public interface ObjectStorage {
  StoredObject put(String key, byte[] content, String contentType);
  void delete(String key);
  String url(String key);
}
public record StoredObject(String key, String url) {}
```
소비 svc는 이 인터페이스에만 의존(S3 SDK 직접 노출 금지).

### S3ObjectStorage (구현)
- AWS SDK v2 `S3Client`: 엔드포인트 override(MinIO), path-style 접근(MinIO 요건), region은 임의값.
- `put`: `PutObjectRequest`(bucket, key, contentType) + 바이트 본문. → `StoredObject(key, url(key))`.
- `url`: `publicBaseUrl` + `/` + `bucket` + `/` + `key`(공개 버킷 다운로드 URL).
- `delete`: `DeleteObjectRequest`.

### StorageProperties (`@ConfigurationProperties("devpath.storage")`)
- `endpoint`(MinIO URL), `bucket`, `accessKey`, `secretKey`, `publicBaseUrl`.
- `maxFileSize`(기본 5MB), `allowedContentTypes`(기본 `image/png,image/jpeg,image/webp`).

### StorageAutoConfiguration
- `@ConditionalOnProperty("devpath.storage.endpoint")`: 프로퍼티 존재 시에만 `S3Client`+`ObjectStorage` 빈 등록. **스토리지 미사용 svc(대부분)는 무영향**.
- 부팅 시 버킷 없으면 생성(`createBucketIfMissing`) — 로컬 편의.

### StoredFileValidator
- `validate(contentType, size)`: `allowedContentTypes`·`maxFileSize` 검사. 위반 → `IllegalArgumentException`(→ 기존 shared `ApiExceptionHandler` 400 VALIDATION_FAILED).
- `key(prefix, originalFilename) → "<prefix>/<uuid>.<ext>"` 키 생성 헬퍼(경로 traversal 방지, 확장자 화이트리스트).

### MinIO compose (`devpath-shared/docker-compose.yml`에 서비스 추가)
```yaml
minio:
  image: minio/minio:<pinned>
  command: server /data --console-address ":9001"
  environment:
    MINIO_ROOT_USER: devpath
    MINIO_ROOT_PASSWORD: localdev123   # 로컬 전용, 프로덕션 값 커밋 금지
  ports: ["9000:9000", "9001:9001"]
  volumes: ["minio-data:/data"]
  healthcheck: [mc ready / curl health]
```

## 데이터 흐름 (소비 svc 관점 — 참고, 실제 컨트롤러는 마이페이지 spec)
```
프론트 multipart/form-data → svc 컨트롤러(@RequestParam MultipartFile)
  → StoredFileValidator.validate(contentType, size)
  → key = validator.key("avatars", originalFilename)
  → ObjectStorage.put(key, bytes, contentType) → StoredObject{key, url}
  → svc가 url을 도메인 엔티티(예: user_profiles.avatar)에 저장 → url 반환
조회: StoredObject.url(공개 버킷) 직접 접근
```

## 에러 처리
- 타입/크기 위반 → `IllegalArgumentException` → 기존 shared `ApiExceptionHandler` 400 VALIDATION_FAILED(추가 작업 없음).
- S3/네트워크 예외(`SdkException`) → shared 핸들러에 **`502 STORAGE_UNAVAILABLE`** 매핑 신규 추가(`ApiErrorCode`에 코드 추가 + 프론트 `api_error_code.dart` 매핑은 마이페이지 spec에서 소비 시 반영). 소비자가 검증 실패(400)와 스토리지 장애(502)를 구분할 수 있게 한다.

## 테스트
- **통합**(`S3ObjectStorageIT`): **MinIO Testcontainers**로 실 S3 API 왕복 — `put` → `url` HTTP GET 200 → `delete` → 재접근 404. 도커 미가용 환경은 가드로 스킵(로컬 compose로 수동 검증 병행).
- **단위**(`StoredFileValidatorTest`): 허용 타입 통과·비허용 타입 거부·경계 크기(5MB±1) 통과/거부·키 생성 형식·확장자 화이트리스트.
- shared `./gradlew build` 그린.

## 롤아웃
1. shared `feat/object-storage`: `storage` 패키지 + compose + 테스트 + `ApiErrorCode.STORAGE_UNAVAILABLE` → develop PR.
2. **발행 게이트**: shared는 main push만 자동발행 → 머지 후 `gh workflow run publish.yml --ref develop` 수동 발행(소비 svc가 storage API를 의존하려면 필요).
3. 소비(마이페이지 avatar)는 발행된 storage 기반 위에서 **별도 spec→plan**.

## 리스크
- **R-S1 자동설정 조건**: `@ConditionalOnProperty`로 스토리지 미사용 svc 무영향 보장. 소비 svc만 `devpath.storage.*` 프로퍼티 설정.
- **R-S2 Testcontainers 도커 의존**: CI/로컬에 도커 필요. 미가용 시 통합테스트 스킵 + 단위테스트로 최소 보장 — CI 도커 가용성 확인 필요.
- **R-S3 공개 버킷**: MVP는 공개 읽기(URL 직접). 비공개+서명 URL은 후속(보안 강화 시).
- **R-S4 발행 게이트**: storage API 소비 전 shared 발행 필수([[devpath-web-posttier2-roadmap]] C2 교훈).
- **R-S5 SDK 정확도**: AWS SDK v2 S3 아티팩트 버전·`S3Client` 빌더 API(엔드포인트/path-style override)는 Spring Boot 4·Java 21 호환을 구현 plan에서 context7로 확정.
