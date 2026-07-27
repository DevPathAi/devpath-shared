package ai.devpath.shared.storage;

import ai.devpath.shared.error.ApiException;
import ai.devpath.shared.error.ErrorCode;

/** 오브젝트 스토리지 장애(S3/네트워크). {@code ApiExceptionHandler}가 503으로 렌더한다. */
public class StorageException extends ApiException {

  private static final long serialVersionUID = 1L;

  public StorageException(String message) {
    super(ErrorCode.STORAGE_UNAVAILABLE, message);
  }

  public StorageException(String message, Throwable cause) {
    super(ErrorCode.STORAGE_UNAVAILABLE, message);
    initCause(cause);
  }
}
