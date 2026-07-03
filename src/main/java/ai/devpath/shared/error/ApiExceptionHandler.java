package ai.devpath.shared.error;

import java.time.Instant;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 스펙 §3.4 공통 에러 envelope를 렌더하는 공용 예외 핸들러.
 *
 * <p>각 svc가 컴포넌트 스캔 또는 {@code @Import}로 채택한다. svc 고유 도메인 예외는
 * {@link ApiException}을 확장해 코드를 부여하면 자동으로 envelope로 직렬화된다.
 * {@link Ordered#LOWEST_PRECEDENCE}이므로 svc-local advice가 있으면 그쪽이 우선한다.
 */
@Order(Ordered.LOWEST_PRECEDENCE)
@RestControllerAdvice
public class ApiExceptionHandler {

  @ExceptionHandler(ApiException.class)
  public ResponseEntity<ErrorResponse> handle(ApiException e) {
    return build(e.code(), e.getMessage());
  }

  @ExceptionHandler(AccessDeniedException.class)
  public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException e) {
    return build(ErrorCode.FORBIDDEN, e.getMessage());
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException e) {
    return build(ErrorCode.VALIDATION_FAILED, "validation failed");
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleGeneric(Exception e) {
    return build(ErrorCode.INTERNAL_ERROR, "internal error");
  }

  private ResponseEntity<ErrorResponse> build(ErrorCode code, String message) {
    return ResponseEntity.status(code.status())
        .body(ErrorResponse.of(code, message, currentTraceId(), Instant.now().toString()));
  }

  /** 분산 트레이싱 미도입 — trace_id는 후속(MDC 연동)에서 채운다. 현재는 null(직렬화에서 생략). */
  private String currentTraceId() {
    return null;
  }
}
