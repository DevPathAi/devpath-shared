-- 학습 콘텐츠 시드 (MD2 승인 150개). @Profile("dev") 시더의 운영 미적용 갭 복구.
-- 멱등: contents가 비어있을 때만 적재. 임베딩은 제외(후속 Ollama 백필).
DO $$
BEGIN
  IF (SELECT count(*) FROM contents) = 0 THEN
    INSERT INTO contents (slug, title, track, content_md, estimated_minutes, difficulty, bloom_level, concept_tags, status) VALUES
('backend-spring-dependency-injection','Dependency Injection','BACKEND_SPRING','## Dependency Injection
This lesson helps the learner connect dependency-injection to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of dependency-injection in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "dependency-injection"; }
}
```',12,0.25,'UNDERSTAND','["backend-spring-dependency-injection","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-jpa-entity-mapping','Jpa Entity Mapping','BACKEND_SPRING','## Jpa Entity Mapping
This lesson helps the learner connect jpa-entity-mapping to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of jpa-entity-mapping in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "jpa-entity-mapping"; }
}
```',12,0.25,'UNDERSTAND','["backend-spring-jpa-entity-mapping","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-postgresql-indexes','Postgresql Indexes','BACKEND_SPRING','## Postgresql Indexes
This lesson helps the learner connect postgresql-indexes to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of postgresql-indexes in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "postgresql-indexes"; }
}
```',12,0.25,'UNDERSTAND','["backend-spring-postgresql-indexes","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-repository-query-methods','Repository Query Methods','BACKEND_SPRING','## Repository Query Methods
This lesson helps the learner connect repository-query-methods to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of repository-query-methods in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "repository-query-methods"; }
}
```',12,0.2,'UNDERSTAND','["backend-spring-repository-query-methods","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-rest-controller-contracts','Rest Controller Contracts','BACKEND_SPRING','## Rest Controller Contracts
This lesson helps the learner connect rest-controller-contracts to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of rest-controller-contracts in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "rest-controller-contracts"; }
}
```',12,0.2,'UNDERSTAND','["backend-spring-rest-controller-contracts","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-spring-bean-lifecycle','Spring Bean Lifecycle','BACKEND_SPRING','## Spring Bean Lifecycle
This lesson helps the learner connect spring-bean-lifecycle to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of spring-bean-lifecycle in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "spring-bean-lifecycle"; }
}
```',12,0.2,'UNDERSTAND','["backend-spring-spring-bean-lifecycle","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-transaction-boundaries','Transaction Boundaries','BACKEND_SPRING','## Transaction Boundaries
This lesson helps the learner connect transaction-boundaries to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of transaction-boundaries in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "transaction-boundaries"; }
}
```',12,0.2,'UNDERSTAND','["backend-spring-transaction-boundaries","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-validation-errors','Validation Errors','BACKEND_SPRING','## Validation Errors
This lesson helps the learner connect validation-errors to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of validation-errors in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "validation-errors"; }
}
```',12,0.25,'UNDERSTAND','["backend-spring-validation-errors","backend-spring-intro"]'::jsonb,'PUBLISHED'),
('backend-spring-actuator-health','Actuator Health','BACKEND_SPRING','## Actuator Health
This lesson helps the learner connect actuator-health to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of actuator-health in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["backend-spring-actuator-health","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-async-events','Async Events','BACKEND_SPRING','## Async Events
This lesson helps the learner connect async-events to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of async-events in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["backend-spring-async-events","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-exception-handling','Exception Handling','BACKEND_SPRING','## Exception Handling
This lesson helps the learner connect exception-handling to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of exception-handling in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["backend-spring-exception-handling","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-flyway-migrations','Flyway Migrations','BACKEND_SPRING','## Flyway Migrations
This lesson helps the learner connect flyway-migrations to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of flyway-migrations in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["backend-spring-flyway-migrations","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-idempotent-commands','Idempotent Commands','BACKEND_SPRING','## Idempotent Commands
This lesson helps the learner connect idempotent-commands to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of idempotent-commands in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["backend-spring-idempotent-commands","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-kafka-consumer-flow','Kafka Consumer Flow','BACKEND_SPRING','## Kafka Consumer Flow
This lesson helps the learner connect kafka-consumer-flow to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of kafka-consumer-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "kafka-consumer-flow"; }
}
```',18,0.55,'APPLY','["backend-spring-kafka-consumer-flow","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-method-security','Method Security','BACKEND_SPRING','## Method Security
This lesson helps the learner connect method-security to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of method-security in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "method-security"; }
}
```',18,0.5,'APPLY','["backend-spring-method-security","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-optimistic-locking','Optimistic Locking','BACKEND_SPRING','## Optimistic Locking
This lesson helps the learner connect optimistic-locking to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of optimistic-locking in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["backend-spring-optimistic-locking","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-outbox-pattern','Outbox Pattern','BACKEND_SPRING','## Outbox Pattern
This lesson helps the learner connect outbox-pattern to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of outbox-pattern in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "outbox-pattern"; }
}
```',18,0.6,'APPLY','["backend-spring-outbox-pattern","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-pagination-sorting','Pagination Sorting','BACKEND_SPRING','## Pagination Sorting
This lesson helps the learner connect pagination-sorting to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of pagination-sorting in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["backend-spring-pagination-sorting","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-redis-cache-aside','Redis Cache Aside','BACKEND_SPRING','## Redis Cache Aside
This lesson helps the learner connect redis-cache-aside to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of redis-cache-aside in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["backend-spring-redis-cache-aside","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-spring-security-jwt','Spring Security Jwt','BACKEND_SPRING','## Spring Security Jwt
This lesson helps the learner connect spring-security-jwt to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of spring-security-jwt in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```java
@RestController
class LessonController {
  String topic() { return "spring-security-jwt"; }
}
```',18,0.6,'APPLY','["backend-spring-spring-security-jwt","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-structured-logging','Structured Logging','BACKEND_SPRING','## Structured Logging
This lesson helps the learner connect structured-logging to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of structured-logging in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["backend-spring-structured-logging","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-test-slices','Test Slices','BACKEND_SPRING','## Test Slices
This lesson helps the learner connect test-slices to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of test-slices in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["backend-spring-test-slices","backend-spring-intermediate"]'::jsonb,'PUBLISHED'),
('backend-spring-configuration-properties','Configuration Properties','BACKEND_SPRING','## Configuration Properties
This lesson helps the learner connect configuration-properties to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of configuration-properties in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["backend-spring-configuration-properties","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-contract-testing','Contract Testing','BACKEND_SPRING','## Contract Testing
This lesson helps the learner connect contract-testing to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of contract-testing in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["backend-spring-contract-testing","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-database-pooling','Database Pooling','BACKEND_SPRING','## Database Pooling
This lesson helps the learner connect database-pooling to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of database-pooling in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["backend-spring-database-pooling","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-observability-traces','Observability Traces','BACKEND_SPRING','## Observability Traces
This lesson helps the learner connect observability-traces to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of observability-traces in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["backend-spring-observability-traces","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-profile-based-config','Profile Based Config','BACKEND_SPRING','## Profile Based Config
This lesson helps the learner connect profile-based-config to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of profile-based-config in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["backend-spring-profile-based-config","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-rate-limit-boundaries','Rate Limit Boundaries','BACKEND_SPRING','## Rate Limit Boundaries
This lesson helps the learner connect rate-limit-boundaries to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of rate-limit-boundaries in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["backend-spring-rate-limit-boundaries","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-release-readiness','Release Readiness','BACKEND_SPRING','## Release Readiness
This lesson helps the learner connect release-readiness to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of release-readiness in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["backend-spring-release-readiness","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('backend-spring-webclient-timeouts','Webclient Timeouts','BACKEND_SPRING','## Webclient Timeouts
This lesson helps the learner connect webclient-timeouts to real DevPath work in the BACKEND_SPRING track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of webclient-timeouts in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["backend-spring-webclient-timeouts","backend-spring-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-accessibility-labels','Accessibility Labels','FRONTEND_REACT','## Accessibility Labels
This lesson helps the learner connect accessibility-labels to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of accessibility-labels in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''accessibility-labels'';
  return label.toUpperCase();
}
```',12,0.2,'UNDERSTAND','["frontend-react-accessibility-labels","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-component-composition','Component Composition','FRONTEND_REACT','## Component Composition
This lesson helps the learner connect component-composition to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of component-composition in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''component-composition'';
  return label.toUpperCase();
}
```',12,0.2,'UNDERSTAND','["frontend-react-component-composition","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-error-boundaries','Error Boundaries','FRONTEND_REACT','## Error Boundaries
This lesson helps the learner connect error-boundaries to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of error-boundaries in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''error-boundaries'';
  return label.toUpperCase();
}
```',12,0.25,'UNDERSTAND','["frontend-react-error-boundaries","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-form-validation','Form Validation','FRONTEND_REACT','## Form Validation
This lesson helps the learner connect form-validation to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of form-validation in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''form-validation'';
  return label.toUpperCase();
}
```',12,0.25,'UNDERSTAND','["frontend-react-form-validation","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-react-query-cache','React Query Cache','FRONTEND_REACT','## React Query Cache
This lesson helps the learner connect react-query-cache to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of react-query-cache in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''react-query-cache'';
  return label.toUpperCase();
}
```',12,0.2,'UNDERSTAND','["frontend-react-react-query-cache","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-responsive-layouts','Responsive Layouts','FRONTEND_REACT','## Responsive Layouts
This lesson helps the learner connect responsive-layouts to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of responsive-layouts in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''responsive-layouts'';
  return label.toUpperCase();
}
```',12,0.25,'UNDERSTAND','["frontend-react-responsive-layouts","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-route-guards','Route Guards','FRONTEND_REACT','## Route Guards
This lesson helps the learner connect route-guards to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of route-guards in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''route-guards'';
  return label.toUpperCase();
}
```',12,0.2,'UNDERSTAND','["frontend-react-route-guards","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-state-lifting','State Lifting','FRONTEND_REACT','## State Lifting
This lesson helps the learner connect state-lifting to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of state-lifting in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''state-lifting'';
  return label.toUpperCase();
}
```',12,0.25,'UNDERSTAND','["frontend-react-state-lifting","frontend-react-intro"]'::jsonb,'PUBLISHED'),
('frontend-react-api-client-errors','Api Client Errors','FRONTEND_REACT','## Api Client Errors
This lesson helps the learner connect api-client-errors to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of api-client-errors in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["frontend-react-api-client-errors","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-auth-token-refresh','Auth Token Refresh','FRONTEND_REACT','## Auth Token Refresh
This lesson helps the learner connect auth-token-refresh to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of auth-token-refresh in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["frontend-react-auth-token-refresh","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-bundle-splitting','Bundle Splitting','FRONTEND_REACT','## Bundle Splitting
This lesson helps the learner connect bundle-splitting to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of bundle-splitting in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["frontend-react-bundle-splitting","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-debounced-search','Debounced Search','FRONTEND_REACT','## Debounced Search
This lesson helps the learner connect debounced-search to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of debounced-search in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''debounced-search'';
  return label.toUpperCase();
}
```',18,0.55,'APPLY','["frontend-react-debounced-search","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-design-tokens','Design Tokens','FRONTEND_REACT','## Design Tokens
This lesson helps the learner connect design-tokens to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of design-tokens in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''design-tokens'';
  return label.toUpperCase();
}
```',18,0.6,'APPLY','["frontend-react-design-tokens","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-feature-flags','Feature Flags','FRONTEND_REACT','## Feature Flags
This lesson helps the learner connect feature-flags to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of feature-flags in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["frontend-react-feature-flags","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-memoization-basics','Memoization Basics','FRONTEND_REACT','## Memoization Basics
This lesson helps the learner connect memoization-basics to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of memoization-basics in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["frontend-react-memoization-basics","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-modal-focus-trap','Modal Focus Trap','FRONTEND_REACT','## Modal Focus Trap
This lesson helps the learner connect modal-focus-trap to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of modal-focus-trap in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["frontend-react-modal-focus-trap","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-optimistic-updates','Optimistic Updates','FRONTEND_REACT','## Optimistic Updates
This lesson helps the learner connect optimistic-updates to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of optimistic-updates in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''optimistic-updates'';
  return label.toUpperCase();
}
```',18,0.5,'APPLY','["frontend-react-optimistic-updates","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-storybook-states','Storybook States','FRONTEND_REACT','## Storybook States
This lesson helps the learner connect storybook-states to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of storybook-states in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["frontend-react-storybook-states","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-suspense-loading','Suspense Loading','FRONTEND_REACT','## Suspense Loading
This lesson helps the learner connect suspense-loading to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of suspense-loading in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["frontend-react-suspense-loading","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-table-pagination','Table Pagination','FRONTEND_REACT','## Table Pagination
This lesson helps the learner connect table-pagination to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of table-pagination in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```tsx
export function lessonLabel() {
  const label = ''table-pagination'';
  return label.toUpperCase();
}
```',18,0.6,'APPLY','["frontend-react-table-pagination","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-toast-feedback','Toast Feedback','FRONTEND_REACT','## Toast Feedback
This lesson helps the learner connect toast-feedback to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of toast-feedback in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["frontend-react-toast-feedback","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-unit-testing-hooks','Unit Testing Hooks','FRONTEND_REACT','## Unit Testing Hooks
This lesson helps the learner connect unit-testing-hooks to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of unit-testing-hooks in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["frontend-react-unit-testing-hooks","frontend-react-intermediate"]'::jsonb,'PUBLISHED'),
('frontend-react-chart-rendering','Chart Rendering','FRONTEND_REACT','## Chart Rendering
This lesson helps the learner connect chart-rendering to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of chart-rendering in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["frontend-react-chart-rendering","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-e2e-user-flows','E2e User Flows','FRONTEND_REACT','## E2e User Flows
This lesson helps the learner connect e2e-user-flows to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of e2e-user-flows in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["frontend-react-e2e-user-flows","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-empty-states','Empty States','FRONTEND_REACT','## Empty States
This lesson helps the learner connect empty-states to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of empty-states in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["frontend-react-empty-states","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-i18n-copy','I18n Copy','FRONTEND_REACT','## I18n Copy
This lesson helps the learner connect i18n-copy to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of i18n-copy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["frontend-react-i18n-copy","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-keyboard-navigation','Keyboard Navigation','FRONTEND_REACT','## Keyboard Navigation
This lesson helps the learner connect keyboard-navigation to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of keyboard-navigation in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["frontend-react-keyboard-navigation","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-performance-profiling','Performance Profiling','FRONTEND_REACT','## Performance Profiling
This lesson helps the learner connect performance-profiling to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of performance-profiling in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["frontend-react-performance-profiling","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-release-checklist','Release Checklist','FRONTEND_REACT','## Release Checklist
This lesson helps the learner connect release-checklist to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of release-checklist in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["frontend-react-release-checklist","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('frontend-react-theme-switching','Theme Switching','FRONTEND_REACT','## Theme Switching
This lesson helps the learner connect theme-switching to real DevPath work in the FRONTEND_REACT track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of theme-switching in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["frontend-react-theme-switching","frontend-react-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-async-snapshot-handling','Async Snapshot Handling','MOBILE_FLUTTER','## Async Snapshot Handling
This lesson helps the learner connect async-snapshot-handling to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of async-snapshot-handling in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''async-snapshot-handling'';
String describeTopic() => lessonTopic;
```',12,0.25,'UNDERSTAND','["mobile-flutter-async-snapshot-handling","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-form-field-validation','Form Field Validation','MOBILE_FLUTTER','## Form Field Validation
This lesson helps the learner connect form-field-validation to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of form-field-validation in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''form-field-validation'';
String describeTopic() => lessonTopic;
```',12,0.2,'UNDERSTAND','["mobile-flutter-form-field-validation","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-navigation-routes','Navigation Routes','MOBILE_FLUTTER','## Navigation Routes
This lesson helps the learner connect navigation-routes to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of navigation-routes in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''navigation-routes'';
String describeTopic() => lessonTopic;
```',12,0.25,'UNDERSTAND','["mobile-flutter-navigation-routes","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-offline-cache-read','Offline Cache Read','MOBILE_FLUTTER','## Offline Cache Read
This lesson helps the learner connect offline-cache-read to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of offline-cache-read in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''offline-cache-read'';
String describeTopic() => lessonTopic;
```',12,0.2,'UNDERSTAND','["mobile-flutter-offline-cache-read","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-riverpod-providers','Riverpod Providers','MOBILE_FLUTTER','## Riverpod Providers
This lesson helps the learner connect riverpod-providers to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of riverpod-providers in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''riverpod-providers'';
String describeTopic() => lessonTopic;
```',12,0.2,'UNDERSTAND','["mobile-flutter-riverpod-providers","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-secure-token-storage','Secure Token Storage','MOBILE_FLUTTER','## Secure Token Storage
This lesson helps the learner connect secure-token-storage to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of secure-token-storage in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''secure-token-storage'';
String describeTopic() => lessonTopic;
```',12,0.25,'UNDERSTAND','["mobile-flutter-secure-token-storage","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-stateful-vs-stateless','Stateful Vs Stateless','MOBILE_FLUTTER','## Stateful Vs Stateless
This lesson helps the learner connect stateful-vs-stateless to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of stateful-vs-stateless in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''stateful-vs-stateless'';
String describeTopic() => lessonTopic;
```',12,0.25,'UNDERSTAND','["mobile-flutter-stateful-vs-stateless","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-widget-composition','Widget Composition','MOBILE_FLUTTER','## Widget Composition
This lesson helps the learner connect widget-composition to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of widget-composition in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''widget-composition'';
String describeTopic() => lessonTopic;
```',12,0.2,'UNDERSTAND','["mobile-flutter-widget-composition","mobile-flutter-intro"]'::jsonb,'PUBLISHED'),
('mobile-flutter-accessibility-semantics','Accessibility Semantics','MOBILE_FLUTTER','## Accessibility Semantics
This lesson helps the learner connect accessibility-semantics to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of accessibility-semantics in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["mobile-flutter-accessibility-semantics","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-animation-controller','Animation Controller','MOBILE_FLUTTER','## Animation Controller
This lesson helps the learner connect animation-controller to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of animation-controller in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["mobile-flutter-animation-controller","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-background-sync','Background Sync','MOBILE_FLUTTER','## Background Sync
This lesson helps the learner connect background-sync to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of background-sync in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["mobile-flutter-background-sync","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-deep-link-routing','Deep Link Routing','MOBILE_FLUTTER','## Deep Link Routing
This lesson helps the learner connect deep-link-routing to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of deep-link-routing in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["mobile-flutter-deep-link-routing","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-error-snackbars','Error Snackbars','MOBILE_FLUTTER','## Error Snackbars
This lesson helps the learner connect error-snackbars to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of error-snackbars in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["mobile-flutter-error-snackbars","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-golden-test-basics','Golden Test Basics','MOBILE_FLUTTER','## Golden Test Basics
This lesson helps the learner connect golden-test-basics to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of golden-test-basics in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["mobile-flutter-golden-test-basics","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-http-client-timeouts','Http Client Timeouts','MOBILE_FLUTTER','## Http Client Timeouts
This lesson helps the learner connect http-client-timeouts to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of http-client-timeouts in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["mobile-flutter-http-client-timeouts","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-integration-test-flow','Integration Test Flow','MOBILE_FLUTTER','## Integration Test Flow
This lesson helps the learner connect integration-test-flow to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of integration-test-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["mobile-flutter-integration-test-flow","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-json-serialization','Json Serialization','MOBILE_FLUTTER','## Json Serialization
This lesson helps the learner connect json-serialization to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of json-serialization in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["mobile-flutter-json-serialization","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-list-view-performance','List View Performance','MOBILE_FLUTTER','## List View Performance
This lesson helps the learner connect list-view-performance to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of list-view-performance in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''list-view-performance'';
String describeTopic() => lessonTopic;
```',18,0.55,'APPLY','["mobile-flutter-list-view-performance","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-platform-permissions','Platform Permissions','MOBILE_FLUTTER','## Platform Permissions
This lesson helps the learner connect platform-permissions to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of platform-permissions in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["mobile-flutter-platform-permissions","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-pull-to-refresh','Pull To Refresh','MOBILE_FLUTTER','## Pull To Refresh
This lesson helps the learner connect pull-to-refresh to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of pull-to-refresh in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''pull-to-refresh'';
String describeTopic() => lessonTopic;
```',18,0.6,'APPLY','["mobile-flutter-pull-to-refresh","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-responsive-breakpoints','Responsive Breakpoints','MOBILE_FLUTTER','## Responsive Breakpoints
This lesson helps the learner connect responsive-breakpoints to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of responsive-breakpoints in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''responsive-breakpoints'';
String describeTopic() => lessonTopic;
```',18,0.6,'APPLY','["mobile-flutter-responsive-breakpoints","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-theming-material','Theming Material','MOBILE_FLUTTER','## Theming Material
This lesson helps the learner connect theming-material to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of theming-material in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```dart
final lessonTopic = ''theming-material'';
String describeTopic() => lessonTopic;
```',18,0.5,'APPLY','["mobile-flutter-theming-material","mobile-flutter-intermediate"]'::jsonb,'PUBLISHED'),
('mobile-flutter-analytics-events','Analytics Events','MOBILE_FLUTTER','## Analytics Events
This lesson helps the learner connect analytics-events to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of analytics-events in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["mobile-flutter-analytics-events","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-app-lifecycle-events','App Lifecycle Events','MOBILE_FLUTTER','## App Lifecycle Events
This lesson helps the learner connect app-lifecycle-events to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of app-lifecycle-events in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["mobile-flutter-app-lifecycle-events","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-build-flavors','Build Flavors','MOBILE_FLUTTER','## Build Flavors
This lesson helps the learner connect build-flavors to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of build-flavors in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["mobile-flutter-build-flavors","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-crash-reporting','Crash Reporting','MOBILE_FLUTTER','## Crash Reporting
This lesson helps the learner connect crash-reporting to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of crash-reporting in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["mobile-flutter-crash-reporting","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-image-cache-sizing','Image Cache Sizing','MOBILE_FLUTTER','## Image Cache Sizing
This lesson helps the learner connect image-cache-sizing to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of image-cache-sizing in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["mobile-flutter-image-cache-sizing","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-local-notifications','Local Notifications','MOBILE_FLUTTER','## Local Notifications
This lesson helps the learner connect local-notifications to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of local-notifications in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["mobile-flutter-local-notifications","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-performance-overlay','Performance Overlay','MOBILE_FLUTTER','## Performance Overlay
This lesson helps the learner connect performance-overlay to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of performance-overlay in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["mobile-flutter-performance-overlay","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('mobile-flutter-store-release-prep','Store Release Prep','MOBILE_FLUTTER','## Store Release Prep
This lesson helps the learner connect store-release-prep to real DevPath work in the MOBILE_FLUTTER track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of store-release-prep in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["mobile-flutter-store-release-prep","mobile-flutter-advanced"]'::jsonb,'PUBLISHED'),
('devops-aws-vpc-basics','Aws Vpc Basics','DEVOPS','## Aws Vpc Basics
This lesson helps the learner connect aws-vpc-basics to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of aws-vpc-basics in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: aws-vpc-basics
  healthcheck: enabled
```',12,0.25,'UNDERSTAND','["devops-aws-vpc-basics","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-compose-service-health','Compose Service Health','DEVOPS','## Compose Service Health
This lesson helps the learner connect compose-service-health to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of compose-service-health in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: compose-service-health
  healthcheck: enabled
```',12,0.25,'UNDERSTAND','["devops-compose-service-health","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-dockerfile-layering','Dockerfile Layering','DEVOPS','## Dockerfile Layering
This lesson helps the learner connect dockerfile-layering to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of dockerfile-layering in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: dockerfile-layering
  healthcheck: enabled
```',12,0.2,'UNDERSTAND','["devops-dockerfile-layering","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-ecs-service-rollout','Ecs Service Rollout','DEVOPS','## Ecs Service Rollout
This lesson helps the learner connect ecs-service-rollout to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of ecs-service-rollout in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: ecs-service-rollout
  healthcheck: enabled
```',12,0.2,'UNDERSTAND','["devops-ecs-service-rollout","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-github-actions-cache','Github Actions Cache','DEVOPS','## Github Actions Cache
This lesson helps the learner connect github-actions-cache to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of github-actions-cache in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: github-actions-cache
  healthcheck: enabled
```',12,0.2,'UNDERSTAND','["devops-github-actions-cache","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-pipeline-secrets','Pipeline Secrets','DEVOPS','## Pipeline Secrets
This lesson helps the learner connect pipeline-secrets to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of pipeline-secrets in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: pipeline-secrets
  healthcheck: enabled
```',12,0.25,'UNDERSTAND','["devops-pipeline-secrets","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-rds-backup-policy','Rds Backup Policy','DEVOPS','## Rds Backup Policy
This lesson helps the learner connect rds-backup-policy to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of rds-backup-policy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: rds-backup-policy
  healthcheck: enabled
```',12,0.25,'UNDERSTAND','["devops-rds-backup-policy","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-terraform-state-locking','Terraform State Locking','DEVOPS','## Terraform State Locking
This lesson helps the learner connect terraform-state-locking to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of terraform-state-locking in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: terraform-state-locking
  healthcheck: enabled
```',12,0.2,'UNDERSTAND','["devops-terraform-state-locking","devops-intro"]'::jsonb,'PUBLISHED'),
('devops-blue-green-deploy','Blue Green Deploy','DEVOPS','## Blue Green Deploy
This lesson helps the learner connect blue-green-deploy to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of blue-green-deploy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["devops-blue-green-deploy","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-cdn-cache-policy','Cdn Cache Policy','DEVOPS','## Cdn Cache Policy
This lesson helps the learner connect cdn-cache-policy to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of cdn-cache-policy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["devops-cdn-cache-policy","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-container-scanning','Container Scanning','DEVOPS','## Container Scanning
This lesson helps the learner connect container-scanning to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of container-scanning in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["devops-container-scanning","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-dependency-scanning','Dependency Scanning','DEVOPS','## Dependency Scanning
This lesson helps the learner connect dependency-scanning to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of dependency-scanning in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["devops-dependency-scanning","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-dns-cutover','Dns Cutover','DEVOPS','## Dns Cutover
This lesson helps the learner connect dns-cutover to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of dns-cutover in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["devops-dns-cutover","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-grafana-dashboard','Grafana Dashboard','DEVOPS','## Grafana Dashboard
This lesson helps the learner connect grafana-dashboard to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of grafana-dashboard in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: grafana-dashboard
  healthcheck: enabled
```',18,0.6,'APPLY','["devops-grafana-dashboard","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-incident-triage','Incident Triage','DEVOPS','## Incident Triage
This lesson helps the learner connect incident-triage to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of incident-triage in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["devops-incident-triage","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-kafka-topic-config','Kafka Topic Config','DEVOPS','## Kafka Topic Config
This lesson helps the learner connect kafka-topic-config to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of kafka-topic-config in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: kafka-topic-config
  healthcheck: enabled
```',18,0.5,'APPLY','["devops-kafka-topic-config","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-least-privilege-iam','Least Privilege Iam','DEVOPS','## Least Privilege Iam
This lesson helps the learner connect least-privilege-iam to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of least-privilege-iam in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["devops-least-privilege-iam","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-log-retention','Log Retention','DEVOPS','## Log Retention
This lesson helps the learner connect log-retention to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of log-retention in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["devops-log-retention","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-prometheus-metrics','Prometheus Metrics','DEVOPS','## Prometheus Metrics
This lesson helps the learner connect prometheus-metrics to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of prometheus-metrics in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: prometheus-metrics
  healthcheck: enabled
```',18,0.55,'APPLY','["devops-prometheus-metrics","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-redis-memory-policy','Redis Memory Policy','DEVOPS','## Redis Memory Policy
This lesson helps the learner connect redis-memory-policy to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of redis-memory-policy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```yaml
service:
  name: redis-memory-policy
  healthcheck: enabled
```',18,0.6,'APPLY','["devops-redis-memory-policy","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-rollback-runbook','Rollback Runbook','DEVOPS','## Rollback Runbook
This lesson helps the learner connect rollback-runbook to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of rollback-runbook in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["devops-rollback-runbook","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-slo-error-budget','Slo Error Budget','DEVOPS','## Slo Error Budget
This lesson helps the learner connect slo-error-budget to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of slo-error-budget in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["devops-slo-error-budget","devops-intermediate"]'::jsonb,'PUBLISHED'),
('devops-autoscaling-signals','Autoscaling Signals','DEVOPS','## Autoscaling Signals
This lesson helps the learner connect autoscaling-signals to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of autoscaling-signals in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["devops-autoscaling-signals","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-backup-restore-drill','Backup Restore Drill','DEVOPS','## Backup Restore Drill
This lesson helps the learner connect backup-restore-drill to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of backup-restore-drill in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["devops-backup-restore-drill","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-cost-tagging','Cost Tagging','DEVOPS','## Cost Tagging
This lesson helps the learner connect cost-tagging to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of cost-tagging in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["devops-cost-tagging","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-database-migration-window','Database Migration Window','DEVOPS','## Database Migration Window
This lesson helps the learner connect database-migration-window to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of database-migration-window in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["devops-database-migration-window","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-environment-parity','Environment Parity','DEVOPS','## Environment Parity
This lesson helps the learner connect environment-parity to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of environment-parity in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["devops-environment-parity","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-postmortem-template','Postmortem Template','DEVOPS','## Postmortem Template
This lesson helps the learner connect postmortem-template to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of postmortem-template in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["devops-postmortem-template","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-queue-backpressure','Queue Backpressure','DEVOPS','## Queue Backpressure
This lesson helps the learner connect queue-backpressure to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of queue-backpressure in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["devops-queue-backpressure","devops-advanced"]'::jsonb,'PUBLISHED'),
('devops-release-approval','Release Approval','DEVOPS','## Release Approval
This lesson helps the learner connect release-approval to real DevPath work in the DEVOPS track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of release-approval in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["devops-release-approval","devops-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-api-contract-first','Api Contract First','FULLSTACK','## Api Contract First
This lesson helps the learner connect api-contract-first to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of api-contract-first in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''api-contract-first'';
export const ready = Boolean(lessonTopic);
```',12,0.2,'UNDERSTAND','["fullstack-api-contract-first","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-auth-session-handshake','Auth Session Handshake','FULLSTACK','## Auth Session Handshake
This lesson helps the learner connect auth-session-handshake to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of auth-session-handshake in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''auth-session-handshake'';
export const ready = Boolean(lessonTopic);
```',12,0.2,'UNDERSTAND','["fullstack-auth-session-handshake","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-dashboard-data-loading','Dashboard Data Loading','FULLSTACK','## Dashboard Data Loading
This lesson helps the learner connect dashboard-data-loading to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of dashboard-data-loading in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''dashboard-data-loading'';
export const ready = Boolean(lessonTopic);
```',12,0.2,'UNDERSTAND','["fullstack-dashboard-data-loading","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-file-upload-path','File Upload Path','FULLSTACK','## File Upload Path
This lesson helps the learner connect file-upload-path to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of file-upload-path in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''file-upload-path'';
export const ready = Boolean(lessonTopic);
```',12,0.2,'UNDERSTAND','["fullstack-file-upload-path","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-notification-preferences','Notification Preferences','FULLSTACK','## Notification Preferences
This lesson helps the learner connect notification-preferences to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of notification-preferences in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''notification-preferences'';
export const ready = Boolean(lessonTopic);
```',12,0.25,'UNDERSTAND','["fullstack-notification-preferences","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-schema-to-ui-flow','Schema To Ui Flow','FULLSTACK','## Schema To Ui Flow
This lesson helps the learner connect schema-to-ui-flow to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of schema-to-ui-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''schema-to-ui-flow'';
export const ready = Boolean(lessonTopic);
```',12,0.25,'UNDERSTAND','["fullstack-schema-to-ui-flow","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-search-filter-contract','Search Filter Contract','FULLSTACK','## Search Filter Contract
This lesson helps the learner connect search-filter-contract to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of search-filter-contract in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''search-filter-contract'';
export const ready = Boolean(lessonTopic);
```',12,0.25,'UNDERSTAND','["fullstack-search-filter-contract","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-user-onboarding-flow','User Onboarding Flow','FULLSTACK','## User Onboarding Flow
This lesson helps the learner connect user-onboarding-flow to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of user-onboarding-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''user-onboarding-flow'';
export const ready = Boolean(lessonTopic);
```',12,0.25,'UNDERSTAND','["fullstack-user-onboarding-flow","fullstack-intro"]'::jsonb,'PUBLISHED'),
('fullstack-admin-audit-log','Admin Audit Log','FULLSTACK','## Admin Audit Log
This lesson helps the learner connect admin-audit-log to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of admin-audit-log in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''admin-audit-log'';
export const ready = Boolean(lessonTopic);
```',18,0.5,'APPLY','["fullstack-admin-audit-log","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-background-job-status','Background Job Status','FULLSTACK','## Background Job Status
This lesson helps the learner connect background-job-status to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of background-job-status in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''background-job-status'';
export const ready = Boolean(lessonTopic);
```',18,0.55,'APPLY','["fullstack-background-job-status","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-billing-usage-view','Billing Usage View','FULLSTACK','## Billing Usage View
This lesson helps the learner connect billing-usage-view to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of billing-usage-view in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''billing-usage-view'';
export const ready = Boolean(lessonTopic);
```',18,0.6,'APPLY','["fullstack-billing-usage-view","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-cache-invalidation-flow','Cache Invalidation Flow','FULLSTACK','## Cache Invalidation Flow
This lesson helps the learner connect cache-invalidation-flow to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of cache-invalidation-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["fullstack-cache-invalidation-flow","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-error-taxonomy','Error Taxonomy','FULLSTACK','## Error Taxonomy
This lesson helps the learner connect error-taxonomy to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of error-taxonomy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["fullstack-error-taxonomy","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-feature-flag-rollout','Feature Flag Rollout','FULLSTACK','## Feature Flag Rollout
This lesson helps the learner connect feature-flag-rollout to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of feature-flag-rollout in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["fullstack-feature-flag-rollout","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-multi-tenant-guard','Multi Tenant Guard','FULLSTACK','## Multi Tenant Guard
This lesson helps the learner connect multi-tenant-guard to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of multi-tenant-guard in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["fullstack-multi-tenant-guard","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-observability-correlation','Observability Correlation','FULLSTACK','## Observability Correlation
This lesson helps the learner connect observability-correlation to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of observability-correlation in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["fullstack-observability-correlation","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-pagination-end-to-end','Pagination End To End','FULLSTACK','## Pagination End To End
This lesson helps the learner connect pagination-end-to-end to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of pagination-end-to-end in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.55,'APPLY','["fullstack-pagination-end-to-end","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-realtime-status-sync','Realtime Status Sync','FULLSTACK','## Realtime Status Sync
This lesson helps the learner connect realtime-status-sync to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of realtime-status-sync in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["fullstack-realtime-status-sync","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-role-based-navigation','Role Based Navigation','FULLSTACK','## Role Based Navigation
This lesson helps the learner connect role-based-navigation to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of role-based-navigation in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["fullstack-role-based-navigation","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-transactional-outbox-ui','Transactional Outbox Ui','FULLSTACK','## Transactional Outbox Ui
This lesson helps the learner connect transactional-outbox-ui to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of transactional-outbox-ui in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.6,'APPLY','["fullstack-transactional-outbox-ui","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-validation-shared-rules','Validation Shared Rules','FULLSTACK','## Validation Shared Rules
This lesson helps the learner connect validation-shared-rules to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of validation-shared-rules in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',18,0.5,'APPLY','["fullstack-validation-shared-rules","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-webhook-retry-flow','Webhook Retry Flow','FULLSTACK','## Webhook Retry Flow
This lesson helps the learner connect webhook-retry-flow to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of webhook-retry-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.

```typescript
const lessonTopic = ''webhook-retry-flow'';
export const ready = Boolean(lessonTopic);
```',18,0.6,'APPLY','["fullstack-webhook-retry-flow","fullstack-intermediate"]'::jsonb,'PUBLISHED'),
('fullstack-accessibility-pass','Accessibility Pass','FULLSTACK','## Accessibility Pass
This lesson helps the learner connect accessibility-pass to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of accessibility-pass in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["fullstack-accessibility-pass","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-export-csv-flow','Export Csv Flow','FULLSTACK','## Export Csv Flow
This lesson helps the learner connect export-csv-flow to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of export-csv-flow in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["fullstack-export-csv-flow","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-integration-test-harness','Integration Test Harness','FULLSTACK','## Integration Test Harness
This lesson helps the learner connect integration-test-harness to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of integration-test-harness in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["fullstack-integration-test-harness","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-local-dev-compose','Local Dev Compose','FULLSTACK','## Local Dev Compose
This lesson helps the learner connect local-dev-compose to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of local-dev-compose in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["fullstack-local-dev-compose","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-performance-budget','Performance Budget','FULLSTACK','## Performance Budget
This lesson helps the learner connect performance-budget to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of performance-budget in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["fullstack-performance-budget","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-product-metrics-loop','Product Metrics Loop','FULLSTACK','## Product Metrics Loop
This lesson helps the learner connect product-metrics-loop to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of product-metrics-loop in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.85,'ANALYZE','["fullstack-product-metrics-loop","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-release-smoke-test','Release Smoke Test','FULLSTACK','## Release Smoke Test
This lesson helps the learner connect release-smoke-test to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of release-smoke-test in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["fullstack-release-smoke-test","fullstack-advanced"]'::jsonb,'PUBLISHED'),
('fullstack-seed-data-strategy','Seed Data Strategy','FULLSTACK','## Seed Data Strategy
This lesson helps the learner connect seed-data-strategy to real DevPath work in the FULLSTACK track. Use it as a focused reading and implementation checkpoint before moving to the next path task.

- Define the responsibility of seed-data-strategy in one sentence.
- Identify the input, output, and failure mode that matter most.
- Apply the idea in a small project slice and record what changed.
- Check the result with a quick test, log, or review note.',24,0.8,'ANALYZE','["fullstack-seed-data-strategy","fullstack-advanced"]'::jsonb,'PUBLISHED');
  END IF;
END $$;
