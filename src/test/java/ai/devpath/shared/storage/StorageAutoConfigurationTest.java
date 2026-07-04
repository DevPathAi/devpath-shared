package ai.devpath.shared.storage;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class StorageAutoConfigurationTest {

  private final ApplicationContextRunner runner =
      new ApplicationContextRunner()
          .withConfiguration(AutoConfigurations.of(StorageAutoConfiguration.class));

  @Test
  void registersObjectStorageWhenEndpointSet() {
    runner
        .withPropertyValues(
            "devpath.storage.endpoint=http://localhost:9000",
            "devpath.storage.bucket=b",
            "devpath.storage.access-key=k",
            "devpath.storage.secret-key=s",
            "devpath.storage.public-base-url=http://localhost:9000")
        .run(ctx -> assertThat(ctx).hasSingleBean(ObjectStorage.class));
  }

  @Test
  void skipsWhenEndpointMissing() {
    runner.run(ctx -> assertThat(ctx).doesNotHaveBean(ObjectStorage.class));
  }
}
