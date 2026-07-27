package ai.devpath.shared.storage;

import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/** 업로드 파일 검증 + 저장 키 생성. 위반은 {@link IllegalArgumentException}(→ 400). */
public class StoredFileValidator {

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
