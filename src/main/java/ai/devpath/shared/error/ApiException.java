package ai.devpath.shared.error;

/**
 * 스펙 §3.4 에러 코드를 실은 도메인 예외 베이스.
 *
 * <p>각 svc의 도메인 예외(예: {@code ReviewNotFoundException},
 * {@code SandboxUnavailableException})가 이를 확장해 적절한 {@link ErrorCode}를 부여하면,
 * {@link ApiExceptionHandler}가 자동으로 스펙 envelope로 직렬화한다.
 */
public class ApiException extends RuntimeException {

  private static final long serialVersionUID = 1L;

  private final ErrorCode code;

  public ApiException(ErrorCode code, String message) {
    super(message);
    this.code = code;
  }

  public ErrorCode code() {
    return code;
  }
}
