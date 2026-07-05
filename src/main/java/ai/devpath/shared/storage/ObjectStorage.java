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
