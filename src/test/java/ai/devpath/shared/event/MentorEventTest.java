package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class MentorEventTest {

  private final ObjectMapper mapper = new ObjectMapper();

  @Test
  void v2EventTypesComeFromOneStableContract() {
    Instant now = Instant.parse("2026-09-05T00:00:00Z");

    assertEquals(MentorEventTypes.ACCESS_WAITLISTED,
        new MentorAccessWaitlistedEvent(UUID.randomUUID(), now, 1L, "u@example.com", now)
            .eventType());
    assertEquals(MentorEventTypes.ACCESS_ACTIVATED,
        new MentorAccessActivatedEvent(UUID.randomUUID(), now, 1L, "u@example.com",
            "BATCH", now, 7L).eventType());
    assertEquals(MentorEventTypes.INVITE_BATCH_COMPLETED,
        new MentorInviteBatchCompletedEvent(UUID.randomUUID(), now, 7L,
            LocalDate.parse("2026-09-05"), 3).eventType());
    assertEquals(MentorEventTypes.INVITE_EMAIL_SENT,
        new MentorInviteEmailSentEvent(UUID.randomUUID(), now, 1L, 7L, "delivery-1", now)
            .eventType());
  }

  @Test
  void v2EventsRemainJacksonSerializableAndDoNotCarryInviteCodes() throws Exception {
    String json = mapper.writeValueAsString(new MentorAccessActivatedEvent(
        UUID.randomUUID(), null, 1L, "u@example.com", "INVITE_CODE", null, null));

    assertTrue(json.contains("u@example.com"));
    assertTrue(json.contains("INVITE_CODE"));
    assertTrue(!json.toLowerCase().contains("invitecode"));
  }

  @Test
  void legacyBetaEventsRemainConsumableDuringMigration() throws Exception {
    var legacy = new BetaAccessApprovedEvent(UUID.randomUUID(), null, 1L, "u@example.com");

    assertEquals("user.beta.approved", legacy.eventType());
    assertTrue(mapper.writeValueAsString(legacy).contains("u@example.com"));
  }
}
