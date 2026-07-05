package ai.devpath.shared.storage;

import java.util.Set;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** {@code devpath.storage.*} 설정. 소비 svc의 application.yml에서 주입한다. */
@ConfigurationProperties("devpath.storage")
public class StorageProperties {
  private String endpoint;
  private String bucket;
  private String accessKey;
  private String secretKey;
  private String publicBaseUrl;
  private long maxFileSize = 5 * 1024 * 1024;
  private Set<String> allowedContentTypes = Set.of("image/png", "image/jpeg", "image/webp");

  public String getEndpoint() {
    return endpoint;
  }

  public void setEndpoint(String v) {
    this.endpoint = v;
  }

  public String getBucket() {
    return bucket;
  }

  public void setBucket(String v) {
    this.bucket = v;
  }

  public String getAccessKey() {
    return accessKey;
  }

  public void setAccessKey(String v) {
    this.accessKey = v;
  }

  public String getSecretKey() {
    return secretKey;
  }

  public void setSecretKey(String v) {
    this.secretKey = v;
  }

  public String getPublicBaseUrl() {
    return publicBaseUrl;
  }

  public void setPublicBaseUrl(String v) {
    this.publicBaseUrl = v;
  }

  public long getMaxFileSize() {
    return maxFileSize;
  }

  public void setMaxFileSize(long v) {
    this.maxFileSize = v;
  }

  public Set<String> getAllowedContentTypes() {
    return allowedContentTypes;
  }

  public void setAllowedContentTypes(Set<String> v) {
    this.allowedContentTypes = v;
  }
}
