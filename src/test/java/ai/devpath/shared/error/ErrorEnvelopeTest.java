package ai.devpath.shared.error;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

/**
 * 스펙 §3.4(04_API_명세서.md) 공통 에러 envelope 계약 검증.
 * 프론트 dp_core {@code ApiException.fromDio}는 {@code body['error']['code']}(중첩)와
 * {@code trace_id}(snake_case)를 파싱한다 — 이 형태를 백엔드가 내야 한다.
 */
class ErrorEnvelopeTest {

  private final ObjectMapper mapper = new ObjectMapper();
  private final ApiExceptionHandler handler = new ApiExceptionHandler();

  @Test
  void errorResponse_serializes_to_nested_envelope_matching_frontend_contract() throws Exception {
    ErrorResponse res =
        ErrorResponse.of(ErrorCode.RESOURCE_NOT_FOUND, "not found", "trace-1", "2026-07-03T00:00:00Z");
    JsonNode json = mapper.readTree(mapper.writeValueAsString(res));

    assertTrue(json.has("error"), "최상위 error 래퍼가 있어야 한다");
    JsonNode err = json.get("error");
    assertEquals("RESOURCE_NOT_FOUND", err.get("code").asText());
    assertEquals("not found", err.get("message").asText());
    assertEquals("trace-1", err.get("trace_id").asText(), "trace_id는 snake_case 계약");
    assertEquals("2026-07-03T00:00:00Z", err.get("timestamp").asText());
  }

  @Test
  void apiException_maps_to_its_code_status_and_envelope() {
    var r = handler.handle(new ApiException(ErrorCode.QUOTA_EXCEEDED, "quota"));
    assertEquals(429, r.getStatusCode().value());
    assertEquals("QUOTA_EXCEEDED", r.getBody().error().code());
    assertEquals("quota", r.getBody().error().message());
    assertNotNull(r.getBody().error().timestamp());
  }

  @Test
  void sandboxBusy_maps_to_typed_429_envelope() {
    var r = handler.handle(new ApiException(ErrorCode.SANDBOX_BUSY, "sandbox capacity full"));

    assertEquals(429, r.getStatusCode().value());
    assertEquals("SANDBOX_BUSY", r.getBody().error().code());
    assertEquals("sandbox capacity full", r.getBody().error().message());
  }

  @Test
  void accessDenied_maps_to_forbidden() {
    var r = handler.handleAccessDenied(new AccessDeniedException("nope"));
    assertEquals(403, r.getStatusCode().value());
    assertEquals("FORBIDDEN", r.getBody().error().code());
  }

  @Test
  void unhandled_exception_maps_to_internal_error_500() {
    var r = handler.handleGeneric(new RuntimeException("boom"));
    assertEquals(500, r.getStatusCode().value());
    assertEquals("INTERNAL_ERROR", r.getBody().error().code());
  }

  @Test
  void illegalArgument_maps_to_validation_failed_400() {
    // 다수 svc가 잘못된 입력에 IllegalArgumentException(400)을 던진다 — 공용 매핑.
    var r = handler.handleIllegalArgument(new IllegalArgumentException("bad input"));
    assertEquals(400, r.getStatusCode().value());
    assertEquals("VALIDATION_FAILED", r.getBody().error().code());
    assertEquals("bad input", r.getBody().error().message());
  }

  @Test
  void error_codes_match_spec_http_status_table() {
    assertEquals(401, ErrorCode.UNAUTHORIZED.status());
    assertEquals(403, ErrorCode.FORBIDDEN.status());
    assertEquals(403, ErrorCode.ONBOARDING_INCOMPLETE.status());
    assertEquals(404, ErrorCode.RESOURCE_NOT_FOUND.status());
    assertEquals(400, ErrorCode.VALIDATION_FAILED.status());
    assertEquals(409, ErrorCode.CONFLICT.status());
    assertEquals(429, ErrorCode.QUOTA_EXCEEDED.status());
    assertEquals(429, ErrorCode.SANDBOX_BUSY.status());
    assertEquals(503, ErrorCode.AI_KILL_SWITCH_ACTIVE.status());
    assertEquals(503, ErrorCode.SANDBOX_UNAVAILABLE.status());
    assertEquals(500, ErrorCode.INTERNAL_ERROR.status());
  }
}
