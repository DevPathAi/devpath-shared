package ai.devpath.shared.error;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponseException;

/**
 * 공용 예외 핸들러가 Spring MVC framework 예외의 실제 HTTP 상태코드를 보존하는지 검증한다.
 *
 * <p>회귀 방지: 이전에는 {@code @ExceptionHandler(Exception.class)}가 405/415/406 등
 * {@code org.springframework.web.ErrorResponse} 계열을 500 INTERNAL_ERROR로 뭉갰다(상태코드 마스킹).
 */
class ApiExceptionHandlerTest {

  private final ApiExceptionHandler handler = new ApiExceptionHandler();

  @Test
  void frameworkErrorResponsePreservesStatus() {
    // ErrorResponseException은 org.springframework.web.ErrorResponse 구현체(servlet 비의존).
    ResponseEntity<ErrorResponse> resp =
        handler.handleGeneric(new ErrorResponseException(HttpStatus.METHOD_NOT_ALLOWED));

    assertEquals(405, resp.getStatusCode().value());
    assertEquals("METHOD_NOT_ALLOWED", resp.getBody().error().code());
  }

  @Test
  void genericUnexpectedStaysInternalError500() {
    ResponseEntity<ErrorResponse> resp = handler.handleGeneric(new RuntimeException("boom"));

    assertEquals(500, resp.getStatusCode().value());
    assertEquals("INTERNAL_ERROR", resp.getBody().error().code());
  }
}
