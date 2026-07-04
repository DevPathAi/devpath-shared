package ai.devpath.shared.storage;

import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchBucketException;
import software.amazon.awssdk.services.s3.model.PutBucketPolicyRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

/** AWS SDK v2 S3 기반 구현(MinIO endpoint override + path-style). */
public class S3ObjectStorage implements ObjectStorage {

  private final S3Client s3;
  private final StorageProperties props;

  public S3ObjectStorage(S3Client s3, StorageProperties props) {
    this.s3 = s3;
    this.props = props;
    ensureBucket();
  }

  private void ensureBucket() {
    String bucket = props.getBucket();
    try {
      s3.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
    } catch (NoSuchBucketException e) {
      s3.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
      s3.putBucketPolicy(
          PutBucketPolicyRequest.builder().bucket(bucket).policy(publicReadPolicy(bucket)).build());
    } catch (S3Exception e) {
      throw new StorageException("버킷 초기화 실패: " + bucket, e);
    }
  }

  private static String publicReadPolicy(String bucket) {
    return "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\","
        + "\"Principal\":\"*\",\"Action\":\"s3:GetObject\","
        + "\"Resource\":\"arn:aws:s3:::" + bucket + "/*\"}]}";
  }

  @Override
  public StoredObject put(String key, byte[] content, String contentType) {
    try {
      s3.putObject(
          PutObjectRequest.builder()
              .bucket(props.getBucket())
              .key(key)
              .contentType(contentType)
              .build(),
          RequestBody.fromBytes(content));
      return new StoredObject(key, url(key));
    } catch (S3Exception e) {
      throw new StorageException("업로드 실패: " + key, e);
    }
  }

  @Override
  public void delete(String key) {
    try {
      s3.deleteObject(DeleteObjectRequest.builder().bucket(props.getBucket()).key(key).build());
    } catch (S3Exception e) {
      throw new StorageException("삭제 실패: " + key, e);
    }
  }

  @Override
  public String url(String key) {
    return props.getPublicBaseUrl() + "/" + props.getBucket() + "/" + key;
  }
}
