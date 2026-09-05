package ai.devpath.shared.event;

/** 멘토 접근 v2 이벤트 이름의 단일 계약. */
public final class MentorEventTypes {
  public static final String ACCESS_WAITLISTED = "mentor.access.waitlisted";
  public static final String ACCESS_ACTIVATED = "mentor.access.activated";
  public static final String INVITE_BATCH_COMPLETED = "mentor.invite_batch.completed";
  public static final String INVITE_EMAIL_SENT = "mentor.invite_email.sent";

  private MentorEventTypes() {}
}
