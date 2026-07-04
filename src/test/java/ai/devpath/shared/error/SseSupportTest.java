package ai.devpath.shared.error;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

class SseSupportTest {
  @Test
  void sendError_emits_error_event_with_envelope() throws Exception {
    List<Object> sent = new ArrayList<>();
    SseEmitter emitter = new SseEmitter() {
      @Override public void send(SseEventBuilder builder) {
        // 직렬화된 데이터 셋을 캡처(이름/데이터 확인은 builder.build()로).
        builder.build().forEach(d -> sent.add(d.getData()));
      }
    };
    SseSupport.sendError(emitter, ErrorCode.INTERNAL_ERROR, "boom");
    // 이벤트 데이터에 ErrorResponse(중첩 error.code)가 포함된다.
    assertTrue(sent.stream().anyMatch(o -> o instanceof ErrorResponse
        && ((ErrorResponse) o).error().code().equals("INTERNAL_ERROR")
        && ((ErrorResponse) o).error().message().equals("boom")));
  }
}
