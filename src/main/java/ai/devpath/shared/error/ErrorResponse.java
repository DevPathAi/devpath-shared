package ai.devpath.shared.error;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * 스펙 §3.4 공통 에러 응답 envelope: {@code {"error":{"code","message","trace_id","timestamp"}}}.
 *
 * <p>프론트 dp_core {@code ApiException.fromDio}가 {@code body['error']['code']}(중첩)와
 * {@code trace_id}(snake_case)를 파싱하므로 이 형태를 반드시 유지한다.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(Body error) {

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record Body(
      String code, String message, @JsonProperty("trace_id") String traceId, String timestamp) {}

  public static ErrorResponse of(ErrorCode code, String message, String traceId, String timestamp) {
    return new ErrorResponse(new Body(code.name(), message, traceId, timestamp));
  }
}
