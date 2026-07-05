package ai.devpath.shared.storage;

import java.net.URI;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

/** {@code devpath.storage.endpoint}가 설정된 svc에만 스토리지 빈을 등록한다. */
@AutoConfiguration
@ConditionalOnProperty("devpath.storage.endpoint")
@EnableConfigurationProperties(StorageProperties.class)
public class StorageAutoConfiguration {

  @Bean
  @ConditionalOnMissingBean
  public S3Client storageS3Client(StorageProperties props) {
    return S3Client.builder()
        .endpointOverride(URI.create(props.getEndpoint()))
        .credentialsProvider(
            StaticCredentialsProvider.create(
                AwsBasicCredentials.create(props.getAccessKey(), props.getSecretKey())))
        .region(Region.US_EAST_1)
        .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
        .build();
  }

  @Bean
  @ConditionalOnMissingBean
  public ObjectStorage objectStorage(S3Client storageS3Client, StorageProperties props) {
    return new S3ObjectStorage(storageS3Client, props);
  }
}
