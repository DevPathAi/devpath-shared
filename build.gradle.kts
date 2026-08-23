plugins {
	`java-library`
	`maven-publish`
	id("org.flywaydb.flyway") version "11.8.2"
}

group = "ai.devpath"
version = "0.0.1-et11.20260822"
description = "DevPath AI shared event schemas + common library"

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
}

repositories {
	mavenCentral()
}

dependencies {
	api("com.fasterxml.jackson.core:jackson-databind:2.20.1")

	// 공용 에러 envelope 핸들러(ai.devpath.shared.error.ApiExceptionHandler)용.
	// compileOnly라 shared 소비자(각 svc)에게 Spring을 강제하지 않는다 — svc는 이미 Spring Boot로 런타임 제공.
	// 버전은 Spring Boot 4.0.7 관리버전(spring-boot-dependencies-4.0.7.pom)과 일치.
	compileOnly("org.springframework:spring-web:7.0.8")
	compileOnly("org.springframework.security:spring-security-core:7.0.6")
	compileOnly("org.springframework:spring-webmvc:7.0.8")

	// Flyway 중앙 스키마 (SSOT) — 마이그레이션은 shared가 소유한다.
	implementation("org.flywaydb:flyway-core:11.8.2")
	implementation("org.flywaydb:flyway-database-postgresql:11.8.2")
	implementation("org.postgresql:postgresql:42.7.7")

	testImplementation(platform("org.junit:junit-bom:6.0.1"))
	testImplementation("org.junit.jupiter:junit-jupiter")
	testImplementation("org.springframework:spring-web:7.0.8")
	testImplementation("org.springframework.security:spring-security-core:7.0.6")
	testImplementation("org.springframework:spring-webmvc:7.0.8")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")

	// 오브젝트 스토리지(AWS SDK v2 S3 — MinIO 호환). Spring과 동일하게 compileOnly:
	// 소비 svc가 런타임 s3 의존을 제공한다.
	compileOnly(platform("software.amazon.awssdk:bom:2.28.0"))
	compileOnly("software.amazon.awssdk:s3")
	compileOnly("org.springframework.boot:spring-boot-autoconfigure:4.0.7")

	// 스토리지 테스트: 실 s3 클라이언트 + MinIO Testcontainers + 자동설정 검증.
	testImplementation(platform("software.amazon.awssdk:bom:2.28.0"))
	testImplementation("software.amazon.awssdk:s3")
	testImplementation(platform("org.testcontainers:testcontainers-bom:1.20.4"))
	testImplementation("org.testcontainers:minio")
	testImplementation("org.testcontainers:junit-jupiter")
	testImplementation("org.springframework.boot:spring-boot-autoconfigure:4.0.7")
	testImplementation("org.springframework.boot:spring-boot-test:4.0.7")
	testImplementation("org.assertj:assertj-core:3.27.3")
}

tasks.withType<Test> {
	useJUnitPlatform()
	// CI 로그만으로 실패 원인(SQL 오류 메시지 등)을 진단할 수 있게 예외 전문을 출력한다.
	testLogging {
		exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
	}
}

// Flyway CLI image needs only the Java migration classes. Keeping SQL resources out of this
// artifact prevents the filesystem SQL location from resolving every version twice.
tasks.register<Jar>("migrationRunnerJar") {
	archiveClassifier.set("migration-runner")
	isPreserveFileTimestamps = false
	isReproducibleFileOrder = true
	from(sourceSets.main.get().output.classesDirs) {
		include("db/migration/**")
	}
	dependsOn(tasks.named("compileJava"))
}

// 로컬 Flyway 실행 설정 (docker-compose의 postgres 대상). CI/배포는 별도 Job.
flyway {
	url = "jdbc:postgresql://localhost:5432/devpath"
	user = "devpath"
	password = "localdev"
	locations = arrayOf("classpath:db/migration")
	// 시드 콘텐츠의 JS·Dart 템플릿 리터럴(${...})을 placeholder 로 해석하지 않는다.
	// Dockerfile.migration·FlywayMigrationTest 와 같은 설정이다.
	placeholderReplacement = false
}

// GitHub Packages 배포. 인증은 CI의 GITHUB_TOKEN(자동) 또는 로컬 환경변수로 주입한다.
publishing {
	publications {
		create<MavenPublication>("maven") {
			from(components["java"])
			groupId = "ai.devpath"
			artifactId = "devpath-shared"
			version = project.version.toString()
		}
	}
	repositories {
		providers.gradleProperty("immutableSharedRepository").orNull?.let { repositoryPath ->
			maven {
				name = "ImmutableLocal"
				url = uri(repositoryPath)
			}
		}
		maven {
			name = "GitHubPackages"
			url = uri("https://maven.pkg.github.com/DevPathAi/devpath-shared")
			credentials {
				username = providers.gradleProperty("gpr.user").orElse(providers.environmentVariable("GITHUB_ACTOR")).orNull
				password = providers.gradleProperty("gpr.token").orElse(providers.environmentVariable("GITHUB_TOKEN")).orNull
			}
		}
	}
}
