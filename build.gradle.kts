plugins {
	`java-library`
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
	testImplementation(platform("org.junit:junit-bom:6.0.1"))
	testImplementation("org.junit.jupiter:junit-jupiter")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.withType<Test> {
	useJUnitPlatform()
}
