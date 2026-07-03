package ai.devpath.shared.event;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class WeeklyReportGeneratedEventTest {

  @Test
  void eventTypeAndFields() {
    Instant now = Instant.now();
    LocalDate week = LocalDate.of(2026, 7, 5);
    WeeklyReportGeneratedEvent e = new WeeklyReportGeneratedEvent(
        UUID.randomUUID(), now, 42L, week, 12, 75, List.of("STUDENT", "TEACHER"), "Spring MVC 실습");

    assertEquals("progress.report.generated", e.eventType());
    assertEquals("progress.report.generated", WeeklyReportGeneratedEvent.EVENT_TYPE);
    assertEquals(42L, e.userId());
    assertEquals(week, e.weekOf());
    assertEquals(12, e.streakDays());
    assertEquals(75, e.progressPercent());
    assertEquals(List.of("STUDENT", "TEACHER"), e.badgesEarnedThisWeek());
    assertEquals("Spring MVC 실습", e.nextTaskTitle());
  }
}
