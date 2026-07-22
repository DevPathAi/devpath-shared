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

  /** 다수 svc가 잘못된 입력에 던지는 IllegalArgumentException → VALIDATION_FAILED(400). */
  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorResponse> handleIllegalArgument(IllegalArgumentException e) {
    return build(ErrorCode.VALIDATION_FAILED, e.getMessage());
  }

  /**
   * 최종 폴백. Spring MVC framework 예외(405/415/406/404-no-resource/400 역직렬화 등)는 실제 HTTP
   * 상태코드를 보존하고, 그 외 예상 못한 예외만 500 INTERNAL_ERROR로 처리한다.
   *
   * <p>이전에는 여기서 무조건 500으로 뭉개(상태코드 마스킹) 클라이언트·프록시·모니터링이 잘못된
   * 405/400을 500으로 인지했다. Spring의 framework 예외는 대부분 {@code org.springframework.web.ErrorResponse}
   * 를 구현하므로(servlet 의존 없는 인터페이스) {@code instanceof}로 실제 상태코드를 되살린다.
   * (구체 예외 타입은 {@code jakarta.servlet.ServletException} 상속이라 컴파일 의존이 늘어 FQN·instanceof로 회피.)
   */
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleGeneric(Exception e) {
    if (e instanceof org.springframework.web.ErrorResponse er) {
      int status = er.getStatusCode().value();
      return buildStatus(status, wireCode(status), e.getMessage());
    }
    return build(ErrorCode.INTERNAL_ERROR, "internal error");
  }

  private ResponseEntity<ErrorResponse> build(ErrorCode code, String message) {
    return ResponseEntity.status(code.status())
        .body(ErrorResponse.of(code, message, currentTraceId(), Instant.now().toString()));
  }

  private ResponseEntity<ErrorResponse> buildStatus(int status, String code, String message) {
    return ResponseEntity.status(status)
        .body(new ErrorResponse(new ErrorResponse.Body(code, message, currentTraceId(), Instant.now().toString())));
  }

  /** framework 예외의 상태코드를 wire error.code 문자열로 매핑(스펙 §3.4 카탈로그 우선, 나머지는 상태 명명). */
  private static String wireCode(int status) {
    return switch (status) {
      case 400 -> ErrorCode.VALIDATION_FAILED.name();
      case 404 -> ErrorCode.RESOURCE_NOT_FOUND.name();
      case 405 -> "METHOD_NOT_ALLOWED";
      case 406 -> "NOT_ACCEPTABLE";
      case 415 -> "UNSUPPORTED_MEDIA_TYPE";
      default -> ErrorCode.INTERNAL_ERROR.name();
    };
  }

  /** 분산 트레이싱 미도입 — trace_id는 후속(MDC 연동)에서 채운다. 현재는 null(직렬화에서 생략). */
  private String currentTraceId() {
    return null;
  }
}
