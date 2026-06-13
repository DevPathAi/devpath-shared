plugins {
	`java-library`
	`maven-publish`
	id("org.flywaydb.flyway") version "11.8.2"
}

group = "ai.devpath"
version = "0.0.1-SNAPSHOT"
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

	// Flyway 중앙 스키마 (SSOT) — 마이그레이션은 shared가 소유한다.
	implementation("org.flywaydb:flyway-core:11.8.2")
	implementation("org.flywaydb:flyway-database-postgresql:11.8.2")
	implementation("org.postgresql:postgresql:42.7.7")

	testImplementation(platform("org.junit:junit-bom:6.0.1"))
	testImplementation("org.junit.jupiter:junit-jupiter")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
	useJUnitPlatform()
}

// 로컬 Flyway 실행 설정 (docker-compose의 postgres 대상). CI/배포는 별도 Job.
flyway {
	url = "jdbc:postgresql://localhost:5432/devpath"
	user = "devpath"
	password = "localdev"
	locations = arrayOf("classpath:db/migration")
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
		maven {
			name = "GitHubPackages"
			url = uri("https://maven.pkg.github.com/DevPathAi/devpath-shared")
			credentials {
				username = System.getenv("GITHUB_ACTOR")
				password = System.getenv("GITHUB_TOKEN")
			}
		}
	}
}
