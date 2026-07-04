package ai.devpath.shared.error;

import java.io.IOException;
import java.time.Instant;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * SSE 스트림 중간 에러를 스펙 §3.4 envelope로 방출하는 공용 헬퍼.
 *
 * <p>스트림 개시(HTTP 200) 후 실패 시 {@code completeWithError} 대신 이 메서드로
 * {@code event:error} + {@link ErrorResponse} 프레임을 보내고, 호출자는 이어서
 * {@link SseEmitter#complete()}를 호출한다. 프론트 dp_core SseClient가 이 프레임을
 * ApiException으로 해석한다.
 */
public final class SseSupport {
  private SseSupport() {}

  public static void sendError(SseEmitter emitter, ErrorCode code, String message) {
    ErrorResponse envelope = ErrorResponse.of(code, message, null, Instant.now().toString());
    try {
      emitter.send(SseEmitter.event().name("error").data(envelope));
    } catch (IOException e) {
      throw new IllegalStateException("SSE error frame send failed", e);
    }
  }
}
