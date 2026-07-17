package ai.devpath.shared.event;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class BetaEventSerializationTest {

    private final ObjectMapper mapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @Test
    void waitlistEvent_roundTrips() throws Exception {
        var e = new BetaWaitlistRegisteredEvent(
                UUID.randomUUID(), Instant.parse("2026-07-17T00:00:00Z"), 42L, "a@b.com");
        String json = mapper.writeValueAsString(e);
        var back = mapper.readValue(json, BetaWaitlistRegisteredEvent.class);
        assertThat(back).isEqualTo(e);
        assertThat(back.eventType()).isEqualTo("user.beta.waitlisted");
    }

    @Test
    void approvedEvent_roundTrips() throws Exception {
        var e = new BetaAccessApprovedEvent(
                UUID.randomUUID(), Instant.parse("2026-07-17T00:00:00Z"), 42L, "a@b.com");
        String json = mapper.writeValueAsString(e);
        var back = mapper.readValue(json, BetaAccessApprovedEvent.class);
        assertThat(back).isEqualTo(e);
        assertThat(back.eventType()).isEqualTo("user.beta.approved");
    }
}
