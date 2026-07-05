package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Set;
import org.junit.jupiter.api.Test;

class StoredFileValidatorTest {
  private final StoredFileValidator validator =
      new StoredFileValidator(Set.of("image/png", "image/jpeg", "image/webp"), 5 * 1024 * 1024);

  @Test
  void acceptsAllowedTypeWithinSize() {
    assertDoesNotThrow(() -> validator.validate("image/png", 1024));
  }

  @Test
  void rejectsDisallowedType() {
    assertThrows(IllegalArgumentException.class, () -> validator.validate("application/pdf", 1024));
  }

  @Test
  void rejectsOverSize() {
    assertThrows(
        IllegalArgumentException.class, () -> validator.validate("image/png", 5 * 1024 * 1024 + 1));
  }

  @Test
  void keyHasPrefixUuidAndExtension() {
    String key = validator.key("avatars", "photo.PNG");
    assertTrue(key.startsWith("avatars/"), key);
    assertTrue(key.endsWith(".png"), key);
    assertEquals("avatars/".length() + 36 + ".png".length(), key.length());
  }

  @Test
  void keyDropsUnknownExtension() {
    String key = validator.key("avatars", "noext");
    assertTrue(key.startsWith("avatars/"), key);
    assertTrue(!key.contains("."), key);
  }
}
