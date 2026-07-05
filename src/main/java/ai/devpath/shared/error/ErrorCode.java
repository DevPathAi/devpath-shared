package ai.devpath.shared.error;

/**
 * 스펙 §3.4 공통 에러 코드 카탈로그(documents/04_API_명세서.md).
 *
 * <p>wire의 {@code error.code} 문자열은 enum name과 동일하다. 프론트 dp_core
 * {@code ApiErrorCode.fromWire}가 이 문자열을 소비한다.
 */
public enum ErrorCode {
  UNAUTHORIZED(401),
  FORBIDDEN(403),
  ONBOARDING_INCOMPLETE(403),
  RESOURCE_NOT_FOUND(404),
  VALIDATION_FAILED(400),
  CONFLICT(409),
  QUOTA_EXCEEDED(429),
  AI_KILL_SWITCH_ACTIVE(503),
  SANDBOX_UNAVAILABLE(503),
  STORAGE_UNAVAILABLE(503),
  INTERNAL_ERROR(500);

  private final int status;

  ErrorCode(int status) {
    this.status = status;
  }

  /** 스펙 §3.4 표의 HTTP status. */
  public int status() {
    return status;
  }
}
