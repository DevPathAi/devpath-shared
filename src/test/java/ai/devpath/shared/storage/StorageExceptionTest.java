package ai.devpath.shared.storage;

import static org.junit.jupiter.api.Assertions.assertEquals;

import ai.devpath.shared.error.ErrorCode;
import org.junit.jupiter.api.Test;

class StorageExceptionTest {
  @Test
  void carriesStorageUnavailableCodeAndStatus() {
    StorageException e = new StorageException("s3 down");
    assertEquals(ErrorCode.STORAGE_UNAVAILABLE, e.code());
    assertEquals(503, e.code().status());
    assertEquals("s3 down", e.getMessage());
  }

  @Test
  void preservesCause() {
    RuntimeException cause = new RuntimeException("sdk");
    StorageException e = new StorageException("wrap", cause);
    assertEquals(cause, e.getCause());
  }
}
