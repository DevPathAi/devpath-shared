-- 진단 문항 사실 정확성 교정 (2026-08-22 전수 검수 후속).
--
-- 800문항 전수 검수(3단계: 병렬 검수 → 적대 재검증 → 컨트롤러 직접 판정)에서
-- 확정된 결함 중 이 레포의 시드(V202608131001·V202608141002)가 담당하는
-- 6트랙 분을 교정한다:
--   키 오답 31건(answer_key 만 교체) + 문항 재작성 124건(content·options·answer_key 교체).
-- NODE_TYPESCRIPT·DATA_AI 2트랙 분은 learning-svc db/seed 원본에서 교정한다.
--
-- 매칭은 id 가 아니라 md5(content) 로 한다 — 시드 INSERT 에 id 가 없어
-- 신규 환경의 id 는 비결정적이다. content 는 800건 중 중복 0 으로 유일하며,
-- 155건 전부 시드 마이그레이션 원문과 바이트 일치함을 실측했다.
--
-- 0단계로 content 의 CRLF 를 LF 로 정규화한다 — CRLF 체크아웃에서 시드된
-- DB(로컬 개발 등)는 여러 줄 content 가 CRLF 로 저장돼(61/155 실측) md5 가
-- 리포지토리 정본(LF)과 어긋난다. 정규화로 모든 환경을 운영과 같은 LF 로
-- 수렴시킨 뒤 매칭한다.
--
-- 운영 DB 는 2026-08-22 조건부 UPDATE 로 이미 교정됐다(재덤프 전수 대조 일치).
-- 이 마이그레이션은 운영에서 no-op 이고 신규·개발 환경에서만 실제로 갱신한다.
-- 근거·판정 자료: documents/docs/reports/2026-08-22-question-bank-accuracy-audit.md
--   (defects.json · key-fixes.sql · rewrites.sql)
--
-- 전체를 to_regclass 가드된 DO 블록으로 감싼다 — 스테이지드 마이그레이션
-- 테스트(AiReviewIdempotencyMigrationTest 등)는 question_bank 가 없는 부분
-- 스키마에 baseline 이후 체인을 적용하므로, 테이블이 없으면 건너뛴다
-- (V202608161006 등과 같은 관례).

DO $qb_correct_202608221001$
DECLARE
  matched INTEGER;
BEGIN
  IF to_regclass(format('%I.question_bank', current_schema())) IS NULL THEN
    RAISE NOTICE 'Skipping question_bank accuracy correction: %.question_bank is absent',
      current_schema();
    RETURN;
  END IF;

  -- 0단계: content 개행 정규화 (CRLF → LF)
  UPDATE question_bank
  SET content = replace(content, chr(13) || chr(10), chr(10))
  WHERE content LIKE '%' || chr(13) || '%';

-- id(운영) 504 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Kafka에서 컨슈머 그룹의 역할은 무엇인가?', options = '["동일한 토픽의 메시지를 다른 그룹이 받지 못하게 독점적으로 소비한다.","같은 그룹 내에서 각 컨슈머는 서로 다른 파티션을 나누어 소비한다.","같은 그룹의 모든 컨슈머가 모든 메시지를 중복으로 수신하도록 보장한다.","컨슈머 그룹은 한 번에 하나의 토픽만 구독할 수 있다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '8d8679ff684eac2be2b7cacbe03f00ec';

-- id(운영) 509 BACKEND_SPRING: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '100b969f41e77be41e4d04533ad071ff' AND answer_key = '{"correct":0}';

-- id(운영) 510 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Boot 애플리케이션에서 application.yml 파일의 역할로 옳은 것은 무엇인가?', options = '["자바 소스 코드를 컴파일하기 전에 변환 규칙을 정의하는 빌드 스크립트다.","설정 프로퍼티를 정의해 스프링 빈의 속성에 바인딩할 수 있다.","운영체제 수준의 환경 변수를 영구적으로 등록하는 파일이다.","빈 사이의 의존성 주입 순서를 강제로 지정하는 파일이다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '2ce94d792a2efda93482ecae60d50cb2';

-- id(운영) 511 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Cloud를 사용하지 않는 순수 Spring Boot 애플리케이션에서, jar 내부 classpath의 application.properties와 실행 디렉터리의 config/application.yaml에 같은 프로퍼티가 서로 다른 값으로 정의되어 있다. 기동 시 어떤 값이 적용되는가?', options = '["classpath의 application.properties 값이 적용된다.","먼저 로드된 파일의 값이 적용되고 나머지는 무시된다.","실행 디렉터리의 config/application.yaml 값이 적용된다.","동일 프로퍼티 충돌로 애플리케이션 기동이 실패한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = 'bf225b6a9c98100c2359916968acae35';

-- id(운영) 516 BACKEND_SPRING: 키 교정 2 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '5d857d2f4df0bb89e66cdaae560902d6' AND answer_key = '{"correct":2}';

-- id(운영) 517 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Boot 애플리케이션에서 프로파일을 사용하여 환경별 설정을 구분하는 방법은 무엇인가?', options = '["환경별 설정 파일을 만들어 두면 Spring Boot가 실행 호스트명을 보고 자동으로 알맞은 프로파일을 활성화한다.","spring.profiles.active 프로퍼티에 활성화할 프로파일을 명시하며, 이를 통해 해당 환경에 대한 설정이 로드된다.","application.yml 파일 내부에서 @Profile 어노테이션으로 분할된 설정을 정의하고, 필요한 프로필 이름을 지정한다.","운영 환경에서는 메인 클래스에 @ActiveProfiles 어노테이션을 붙여 프로파일을 활성화하는 것이 표준 방법이다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '20d2ca8643fbd9115de24181b337f442';

-- id(운영) 521 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Boot 애플리케이션에서 @Profile 어노테이션과 application.yml 파일을 사용하여 환경 설정을 변경할 때 주의해야 할 사항으로 옳은 것은 무엇인가요?', options = '["환경 변수를 통해 활성 프로파일을 동적으로 변경하는 것이 가능합니다.","프로파일은 애플리케이션당 한 번에 하나만 활성화할 수 있습니다.","비프로필 기본 설정이 프로필별 설정보다 항상 우선 적용됩니다.","Spring Boot는 프로필 기반 설정을 지원하지 않습니다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '11f00e3b3883ae9af91fa3a7a21b4208';

-- id(운영) 526 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Security의 폼 로그인에서 요청의 username·password 파라미터를 읽어 인증을 시도하는 필터는 무엇인가요?', options = '["AuthenticationFilter","AuthenticatingFilter","UsernamePasswordAuthenticationFilter","AuthenticationProcessingFilter"]', answer_key = '{"correct":2}'
WHERE md5(content) = '532fa2e6b74041401c3a0b68e320c9e6';

-- id(운영) 529 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Data JPA에서 엔티티(Entity) 간의 관계를 표현하기 위해 사용하는 어노테이션은 무엇인가?', options = '["@Entity","@Table","@Id","@OneToMany"]', answer_key = '{"correct":3}'
WHERE md5(content) = 'b4b89e5373537801bb855c1b1ed592a9';

-- id(운영) 535 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring AOP에서 advice의 종류에 대한 설명으로 옳은 것은 무엇인가?', options = '["Before, After, Around 세 가지이며, 예외 발생 시점에 실행되는 advice 종류는 따로 존재하지 않는다.","Before, After returning, After throwing, After (finally), Around의 다섯 가지가 있다.","advice의 종류는 Pointcut과 JoinPoint 두 가지로, 각각 advice가 적용될 위치와 실행 시점을 지정한다.","Before와 After 두 가지뿐이며, 대상 메소드 실행을 감싸는 형태의 advice는 지원되지 않는다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'a075c4156201977cd4f7f5e775adef1c';

-- id(운영) 539 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Security에서 인증(Authentication)과 인가(Authorization)의 구분으로 옳은 것은 무엇인가?', options = '["인증과 인가는 동일한 개념이며 Spring Security는 둘을 구분하지 않는다.","인증은 사용자의 권한을 확인하고 인가는 로그인 여부를 확인한다.","인증은 사용자의 신원을 확인하고 인가는 접근 허용 여부를 확인한다.","인가가 항상 인증보다 먼저 수행된 뒤에 신원 확인이 이루어진다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '505882f833218806846aae379f7fa4aa';

-- id(운영) 543 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'JPA에서 연관 엔티티 조회 시 발생하는 N+1 문제를 해결하는 방법으로 옳은 것은 무엇인가?', options = '["JPQL의 fetch join으로 연관 엔티티를 한 번의 쿼리로 함께 조회한다.","@Transactional을 메소드에 붙이면 영속성 컨텍스트가 개별 쿼리들을 자동으로 하나로 합쳐 준다.","모든 연관관계를 EAGER 로딩으로 변경한다.","엔티티의 equals와 hashCode를 오버라이드해 중복 조회를 막는다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'df90e3d4e332f6f7c43fa753c06467ba';

-- id(운영) 548 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '브라우저 세션 쿠키 기반의 Spring Security 애플리케이션에서 CSRF(Cross-Site Request Forgery) 공격에 대비하기 위한 올바른 설정은 무엇인가?', options = '["@EnableWebSecurity 설정 클래스에서 csrf().disable()을 호출한다.","기본 활성화된 CSRF 보호를 유지하고, 상태 변경 요청에 CSRF 토큰을 담아 검증받는다.","CSRF 보호는 기본 비활성 상태이므로 spring.security.csrf.enable=true 프로퍼티를 명시해야만 켜진다.","스프링 시큐리티 필터 체인에서 CsrfFilter를 제거해 토큰 충돌을 방지한다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '879c9764cb3865c1218f4ae8f7d9d361';

-- id(운영) 549 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Boot에서 Spring Data Redis를 사용할 때, opsForValue() 등의 연산으로 Redis 명령을 직접 실행하는 데 사용하는 핵심 클래스는 무엇인가?', options = '["CacheManager","RedisTemplate","JedisClient","CachingConfigurer"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'b64e9ad4aba6be94fca9da642c935131';

-- id(운영) 553 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring에서 비동기 작업을 처리할 때 `@Async` 어노테이션의 사용은 중요합니다. 다음 중 올바른 설명을 선택하세요.', options = '["비동기 메서드는 항상 새로운 쓰레드를 생성하여 실행되며, 쓰레드 풀은 사용되지 않습니다.","스프링 컨텍스트가 모든 비동기 메서드 호출에 대해 결과를 기다리는 동안 블로킹합니다.","void 반환 비동기 메서드에서 발생한 예외는 호출자 스레드로 항상 자동 전파되어 호출부의 try-catch로 잡을 수 있습니다.","비동기 메서드의 반환값을 호출자가 받아오려면 메서드가 Future 계열(예: CompletableFuture) 타입을 반환해야 합니다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '0f8bfbe66ab5ef3c75c1883e92eefc82';

-- id(운영) 556 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Kafka에서 Consumer Group의 역할과 파티션 배정은 어떻게 이루어지는지 설명해보자.', options = '["Consumer Group은 여러 컨슈머를 하나의 단위로 취급하며, 하나의 파티션을 그룹 내 여러 컨슈머가 동시에 나눠 읽도록 할당하여 처리량을 높인다.","Consumer Group은 동일한 주제에 대한 모든 메시지를 읽기 위해 독립적으로 작동하는 컨슈머들의 집합이며, 각 파티션은 배정 전략 없이 매 폴링마다 임의의 컨슈머에게 새로 할당된다.","Consumer Group은 Kafka 클러스터 내에서 중복된 메시지 처리를 방지하기 위한 식별자로서 동작하며, 모든 파티션이 단일 Consumer Group에 속한다.","각 파티션은 특정 소비그룹의 컨슈머에게 고유하게 할당되며, 리밸런싱 시점에서 자동적으로 파티션이 재할당된다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '9cecf8b55f65e40d6110c77ddc0fb425';

-- id(운영) 557 BACKEND_SPRING: 키 교정 2 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'c02fd9c056279125794c0948bbfac604' AND answer_key = '{"correct":2}';

-- id(운영) 560 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Spring Boot에서 application.yml 안에 `spring.config.activate.on-profile: prod`로 구분한 prod 전용 설정 블록을 정의했는데, 애플리케이션을 아무 옵션 없이 실행하면 이 블록이 적용되지 않는다. 가장 가능성 높은 원인은 무엇인가?', options = '["spring.profiles.active 등으로 prod 프로파일을 활성화하지 않아 해당 문서 블록이 로드 대상에서 제외되었다.","application.yml은 한 파일 안에 여러 프로파일 문서를 담을 수 없으므로 항상 application-prod.yml 같은 별도 파일로 분리해야만 한다.","YAML 형식 자체가 프로파일 조건 설정을 지원하지 않으므로 .properties 형식으로 변환해야만 프로파일이 동작한다.","on-profile 조건 블록은 클라우드 배포 환경에서만 평가되며 로컬 실행에서는 스프링이 항상 무시하도록 설계되어 있다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'b06196fe645ffc1dd5285879d5fcbcb0';

-- id(운영) 564 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'JPA에서 N+1 문제를 해결하기 위해 사용할 수 있는 방법 중 하나는 무엇인가?', options = '["fetch join 사용","연관 컬럼에 데이터베이스 인덱스 추가","Lazy Loading 사용","Eager Loading 사용"]', answer_key = '{"correct":0}'
WHERE md5(content) = 'd442918ec99e9699fbd34f88b22ee66f';

-- id(운영) 565 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = 'Kafka에서 메시지 발행을 담당하는 KafkaProducer 클래스가 속한 패키지는 무엇인가?', options = '["org.springframework.kafka.core","org.apache.kafka.clients.consumer","org.apache.kafka.clients.producer","org.apache.kafka.connect.runtime"]', answer_key = '{"correct":2}'
WHERE md5(content) = 'cbd576203454ab27efe611fa34b15237';

-- id(운영) 573 BACKEND_SPRING: 키 교정 1 -> 2
UPDATE question_bank SET answer_key = '{"correct":2}'
WHERE md5(content) = '519ca1e8c0a6136834ac141e2abb7295' AND answer_key = '{"correct":1}';

-- id(운영) 584 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '다음 코드는 @Cacheable 어노테이션을 사용하여 데이터베이스 쿼리를 캐시합니다.

@Cacheable("userCache")
public User findUserById(Integer id) {
    return userRepository.findById(id).orElse(null);
}
', options = '["데이터를 성공적으로 캐싱하고 요청 시 복잡성을 줄입니다.","데이터베이스의 값이 변경되면 캐시가 이를 자동으로 감지해 무효화되므로 항상 최신 값이 반환됩니다.","findUserById 메서드는 캐시에 저장된 데이터만 반환합니다.","이 코드는 퍼포먼스 저하를 일으킵니다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'f502888f3a21a6dc306fd46b9140e49c';

-- id(운영) 585 BACKEND_SPRING: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '8b1133987f68736ba861470dc165cdfe' AND answer_key = '{"correct":0}';

-- id(운영) 586 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '다음 코드에서 @Transactional(readOnly = true) 메서드 안에서 조회한 엔티티의 필드를 수정하면 어떤 일이 발생하는가? (JPA 구현체는 Hibernate 기본 구성)

@Transactional(readOnly = true)
public void readOnlyMethod() {
    User user = repository.findById(1L).orElseThrow();
    user.setName("changed");
}
', options = '["readOnly 트랜잭션에서는 엔티티의 setter를 호출하는 시점에 즉시 예외가 발생한다.","변경 감지(dirty checking)가 정상 동작하여 커밋 시점에 UPDATE 쿼리가 실행된다.","Hibernate가 세션 플러시 모드를 MANUAL로 설정해 자동 플러시가 생략되므로, 필드 변경이 DB에 반영되지 않는다.","readOnly 설정으로 트랜잭션 자체가 시작되지 않아 영속성 컨텍스트가 아예 만들어지지 않는다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '7271b2d39102ccce924f37e63f8c23b2';

-- id(운영) 587 BACKEND_SPRING: 키 교정 2 -> 1
UPDATE question_bank SET answer_key = '{"correct":1}'
WHERE md5(content) = '6558a7a39c36b82878754e46353ab656' AND answer_key = '{"correct":2}';

-- id(운영) 591 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '다음 코드에서 @Transactional(readOnly = true) 설정은 어떤 역할을 하는가?

@Transactional(readOnly = true)
public void readData() {
    List<User> users = userRepository.findAll();
}
', options = '["트랜잭션을 시작하지 않고 데이터를 읽는다.","findAll() 결과의 모든 행에 자동으로 비관적 읽기 잠금(SELECT ... FOR SHARE)을 걸어 다른 트랜잭션의 수정을 막는다.","트랜잭션이 읽기 전용임을 하위 계층에 힌트로 전달해 플러시 생략 같은 최적화를 유도하지만, 모든 쓰기 시도의 실패를 절대적으로 보장하지는 않는다.","JPA 2차 캐시를 강제로 활성화하여 이후 동일한 조회는 데이터베이스 대신 캐시에서만 읽어오도록 만든다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '124e4d000eeb3bf192eb67359e49978a';

-- id(운영) 592 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '다음 코드에서 @Transactional(readOnly = true) 설정이 주어진 상황에서, readOnlyMethod() 메서드의 호출은 어떻게 작동하는가? (JPA 구현체는 Hibernate 기본 구성)

@Transactional(readOnly = true)
public void readOnlyMethod() {
    repository.delete(entity);
}
', options = '["delete() 호출 시점에 DELETE 쿼리가 즉시 실행되어 엔티티가 데이터베이스에서 삭제된다.","삭제 요청은 영속성 컨텍스트에 등록되지만, 플러시 모드가 MANUAL이라 커밋 시 자동 플러시가 생략되어 DELETE가 DB에 반영되지 않는다.","readOnly 위반을 감지한 Spring이 delete() 호출 시점에 UnsupportedOperationException을 던지도록 표준으로 보장한다.","삭제는 정상적으로 수행되지만 트랜잭션이 커밋 대신 자동으로 롤백 처리된다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '4d2eecfd3f5ac32f2d080d151380694c';

-- id(운영) 596 BACKEND_SPRING: 키 교정 2 -> 1
UPDATE question_bank SET answer_key = '{"correct":1}'
WHERE md5(content) = 'dbb2e602b0c7d2b9c917500584b391ee' AND answer_key = '{"correct":2}';

-- id(운영) 600 BACKEND_SPRING: 재작성
UPDATE question_bank SET content = '@Transactional(readOnly = true) 메서드 안에서 repository.save(entity)를 호출했을 때의 동작에 대한 가장 정확한 설명은 무엇인가?

@Transactional(readOnly = true)
public void readOnlyMethod() {
    repository.save(entity);
}
', options = '["JPA 표준이 readOnly 트랜잭션에서의 save() 호출에 대해 항상 즉시 예외를 던지도록 강제한다.","save()는 readOnly 설정과 완전히 무관하게 동작하도록 규정되어 있어, 어떤 구성에서도 커밋 시점의 INSERT 실행이 예외 없이 항상 보장된다.","readOnly는 최적화 힌트일 뿐이라 결과가 구성에 따라 갈린다 — ID 생성 전략과 JPA 구현체에 따라 INSERT가 즉시 실행될 수도, 플러시 생략으로 조용히 무시될 수도 있다.","Spring이 save() 호출을 감지해 메서드 전체를 no-op으로 바꾸므로 아무 일도 일어나지 않음이 항상 보장된다."]', answer_key = '{"correct":2}'
WHERE md5(content) = 'bdd57facf82271bcdd18c8fe7b15b5d1';

-- id(운영) 603 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '리액트에서 `React.memo`로 감싼 컴포넌트가 재렌더링을 건너뛰는 조건은 무엇입니까?', options = '["컴포넌트의 key 값이 고유하게 유지될 때","props로 매 렌더링마다 새로운 객체 리터럴이나 인라인 함수를 만들어 전달할 때","컴포넌트 내부의 state가 변경되었을 때","부모가 재렌더링되어도 전달된 props가 얕은 비교(shallow compare)로 이전과 같을 때"]', answer_key = '{"correct":3}'
WHERE md5(content) = '5b8505121fcdddf3c7e4b3402ab07633';

-- id(운영) 604 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'Redux 스토어와 Context API를 비교할 때, 어떤 상황에서 Redux가 더 적합한가?', options = '["미들웨어와 개발자 도구 기반 디버깅을 활용해 복잡한 전역 상태 갱신 로직을 다뤄야 할 때","단일 컴포넌트 내부에서만 쓰이는 폼 입력 상태를 관리할 때","거의 변하지 않는 테마나 로케일 값을 하위 트리에 단순히 전달하기만 하면 될 때","외부 라이브러리 의존성을 최소화하고 싶을 때"]', answer_key = '{"correct":0}'
WHERE md5(content) = 'c37aba9c10b64bd53f3023e7dabb970f';

-- id(운영) 608 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '리액트 컴포넌트에서 `useEffect` 훅으로 API 요청을 할 때, 이전 요청의 늦은 응답이 최신 상태를 덮어쓰는 경쟁 상태(race condition)를 피하는 방법은 무엇인가요?', options = '["API 요청 전에 상태를 미리 업데이트해 두어 응답 지연을 숨긴다.","setTimeout으로 요청 사이에 일정한 간격을 강제로 두어 응답이 항상 순서대로 도착하게 만든다.","cleanup 함수에서 ignore 플래그를 설정하거나 AbortController로 이전 요청을 취소한다.","useMemo로 응답 데이터를 캐싱해 같은 요청을 반복하지 않는다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '634bd96db3ea552b159b38b79538d192';

-- id(운영) 609 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 함수형 컴포넌트에서 `useState` 훅으로 초기 상태 값을 설정하는 올바른 방법은?', options = '["const [count, setCount] = useState(0);","const [count, setCount] = setState(0);","const count = useState(0); count.value = 0;","함수 컴포넌트 본문에 this.state = { count: 0 }; 을 작성한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'dc6b29f5f33658b6c1ca4fefb28d070c';

-- id(운영) 610 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 컴포넌트의 props에 대한 설명으로 옳은 것은 무엇인가요?', options = '["props는 반드시 문자열 형태로만 전달할 수 있다.","자식 컴포넌트는 전달받은 props를 직접 수정해서 부모의 상태를 갱신하는 것이 권장된다.","props가 바뀌어도 자식 컴포넌트는 다시 렌더링되지 않는다.","props는 부모 컴포넌트에서 자식 컴포넌트로 전달되는 읽기 전용 데이터다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '72c0e99427696324dd67e00c25ee99bd';

-- id(운영) 611 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 컴포넌트에서 비제어(uncontrolled) 컴포넌트를 사용하는 장점은 무엇인가요?', options = '["입력값이 항상 React state와 자동으로 동기화된다.","React가 입력값 유효성 검사를 자동으로 수행해 준다.","키 입력마다 setState가 호출되지 않아 리렌더링이 발생하지 않는다.","value prop 값을 바꾸는 것만으로 언제든 입력값을 즉시 재설정할 수 있다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '6ff09b9aa4ba861e7ba489779c598e72';

-- id(운영) 618 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 함수형 컴포넌트에서 상태(state)를 선언하고 업데이트하기 위해 사용하는 가장 기본적인 훅은 무엇인가요?', options = '["useContext()","useState()","useCallback()","useMemo()"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'fb216352b6db0f371c7dab6ee23fe0e3';

-- id(운영) 621 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '부모 컴포넌트가 리렌더링될 때, props가 변하지 않은 자식 컴포넌트의 불필요한 재렌더링을 막으려면 어떤 방법을 사용해야 하나?', options = '["useEffect() 안에서 상태 업데이트를 모아 배치로 처리한다.","자식 컴포넌트를 React.memo()로 감싼다.","자식 컴포넌트에서 useState() 호출을 제거하고 전역 변수에 값을 보관한다.","부모의 setState() 호출을 setTimeout으로 지연시킨다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '6bf8622cebedcfdb07a22229a9610943';

-- id(운영) 623 FRONTEND_REACT: 키 교정 0 -> 2
UPDATE question_bank SET answer_key = '{"correct":2}'
WHERE md5(content) = 'e34e3d7781e318d8f8c6f903791faa43' AND answer_key = '{"correct":0}';

-- id(운영) 626 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 함수형 컴포넌트에서 useState의 setter를 호출하면, 새 상태 값은 언제 반영됩니까?', options = '["setter 호출 직후 같은 함수 안에서 즉시 새 값을 읽을 수 있다.","다음 렌더링에서 새 값으로 반영된다.","useEffect의 cleanup 함수가 실행된 뒤에만 반영된다.","브라우저 이벤트 루프가 한 바퀴 돈 뒤 렌더링 없이 조용히 반영된다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '94102fa26daf5cd48fe15f7d04cdb220';

-- id(운영) 631 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React에서 제어(controlled) 컴포넌트로 입력값 state를 관리할 때, 올바르게 작성된 코드는?', options = '["function MyComponent() { const [value, setValue] = useState(''''); return <input value={value} onChange={(e) => setValue(e.target.value)} />; }","function MyComponent() { let value = ''''; return <input value={value} onChange={(e) => value = e.target.value} />; }","function MyComponent() { const value = ''''; return <input value={value} onChange={(e) => value = e.target.value} />; }","function MyComponent() { let [value, setValue] = useState(''''); return <input value={value} onChange={(e) => value = e.target.value} />; }"]', answer_key = '{"correct":0}'
WHERE md5(content) = 'b37726feaf4053fe2e58255d791a0c14';

-- id(운영) 634 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'useEffect 내부에서 참조하는 상태 값을 의존성 배열에 포함하지 않으면 어떤 문제가 발생할 수 있습니까?', options = '["이펙트가 매 렌더링마다 무조건 다시 실행된다.","React가 컴파일 단계에서 오류를 내며 렌더링을 중단한다.","이펙트가 이전 렌더링 시점의 낡은(stale) 값을 계속 참조한다.","상태 업데이트가 동기적으로 즉시 반영되어 배치 처리가 깨진다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '8bb4402d508d09979ae13c848a591028';

-- id(운영) 635 FRONTEND_REACT: 키 교정 1 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '2430fc0b8b29307bdffa3aec408309fa' AND answer_key = '{"correct":1}';

-- id(운영) 636 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 컴포넌트에서 props를 전달받아 사용할 때, 다음 중 올바르게 작성된 코드는?', options = '["function MyComponent(name) { return <div>Hello, {name}</div>; }","function MyComponent(props) { return <div>Hello, {props.name}</div>; }","function MyComponent() { return <div>Hello, props.name</div>; }","function MyComponent({ name: ''John'' }) { return <div>Hello, {name}</div>; }"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'b0f30629ae7459545ede0ce72b910c4b';

-- id(운영) 646 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React에서 비제어(uncontrolled) 컴포넌트로 입력 폼의 값을 다룰 때 올바른 방법은 무엇인가요?', options = '["onChange 이벤트 핸들러에서 useState 훅으로 매 입력마다 value를 갱신한다.","value 속성을 props로 전달해 입력값을 강제한다.","defaultValue로 초기값을 주고 ref로 현재 값을 읽는다.","useContext 훅으로 폼 값을 구독한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '9487a4b533d3cf90137b0928f9013811';

-- id(운영) 649 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 함수형 컴포넌트에서 state 값을 업데이트하려면 어떤 방법을 사용해야 하나요?', options = '["props로 전달받은 값을 직접 수정한다.","this.setState() 메서드를 호출한다.","useState 훅이 반환한 setter 함수를 호출한다.","this.state 객체의 속성을 직접 변경한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '78ba94af7ea77a97157bdcc0afe99d96';

-- id(운영) 653 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '리액트에서 리스트로 렌더링되는 요소들에 key 속성을 부여하는 이유는 무엇인가요?', options = '["서버와 클라이언트에서 렌더링 결과가 항상 동일하게 보이도록 보장하기 위해서다.","key가 각 요소의 CSS 클래스로 자동 부여되어 스타일링에 활용되기 때문이다.","리액트가 key를 전역 상태 저장소의 식별자로 사용해 상태를 보존하기 때문이다.","각 아이템을 고유하게 식별해 재조정(reconciliation) 시 변경·추가·제거된 항목을 판별하게 한다."]', answer_key = '{"correct":3}'
WHERE md5(content) = 'e48673c86aa8ec913d7b4c29f19d893e';

-- id(운영) 657 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'react-router에서 useNavigate로 페이지를 이동하되, 브라우저 히스토리에 새 항목을 추가하지 않고 현재 항목을 대체하려면 어떻게 해야 하나요?', options = '["const navigate = useNavigate(); navigate(''/path'', { replace: true });","const navigate = useNavigate(); navigate(''/path'', { state: { data } });","const navigate = useNavigate(); navigate(''/path'', { preventDefault: true });","useNavigate({ replace: true })를 호출하면 반환 함수 없이 즉시 대체 이동이 일어난다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '3f3a43cb10cc75c613754147dbd3094e';

-- id(운영) 659 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 중 React의 훅 규칙(Rules of Hooks)을 올바르게 지킨 코드는?', options = '["function MyComponent({ show }) { if (show) { const [n, setN] = useState(0); } return <div>Content</div>; }","function MyComponent() { const [count, setCount] = useState(0); useEffect(() => {}, []); return <div>Content</div>; }","function handleClick() { const [on, setOn] = useState(false); return on; }","function MyComponent() { for (let i = 0; i < 3; i++) { useState(i); } return <div>Content</div>; }"]', answer_key = '{"correct":1}'
WHERE md5(content) = '5a402f931d6b80c373a3abd1b7041dec';

-- id(운영) 661 FRONTEND_REACT: 키 교정 1 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '7867481175fc7a837eda042f408ddbaa' AND answer_key = '{"correct":1}';

-- id(운영) 667 FRONTEND_REACT: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '77c9be5529ed9af935295b249a34fc00' AND answer_key = '{"correct":1}';

-- id(운영) 668 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = 'React 함수 컴포넌트에서 useState 훅의 상태 초기값은 어떻게 지정하는가?', options = '["첫 렌더링이 끝난 뒤 setState를 한 번 호출해서 지정한다","useEffect 안에서 setState를 호출해서 지정한다","useState를 호출할 때 인자(initialState)로 전달한다","props로 넘기기만 하면 자동으로 상태 초기값이 된다"]', answer_key = '{"correct":2}'
WHERE md5(content) = '3cb68d7f38e6dda83967b62bf603da41';

-- id(운영) 672 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 Counter 컴포넌트가 처음 마운트된 뒤 버튼을 한 번 클릭했다. 2초 후 setTimeout 콜백 안의 console.log(count)가 출력하는 값은 무엇인가?

import React, { useState } from ''react'';
function Counter() {
  const [count, setCount] = useState(0);
  function handleClick() {
    setTimeout(() => {
      setCount(count + 1);
      console.log(count);
    }, 2000);
  }
  return <button onClick={handleClick}>Increment</button>;
}', options = '["0 — 콜백은 클릭 시점 렌더의 count 값을 클로저로 캡처한다","1 — 콜백 실행 시점에는 setCount가 반영된 최신 state를 읽는다","undefined — 타이머가 실행될 때 count 변수는 이미 소멸해 있다","TypeError — 함수 컴포넌트의 state는 setTimeout 안에서 읽을 수 없다"]', answer_key = '{"correct":0}'
WHERE md5(content) = 'b41a5412e3eb813cc684ec41dd71aed4';

-- id(운영) 676 FRONTEND_REACT: 키 교정 0 -> 2
UPDATE question_bank SET answer_key = '{"correct":2}'
WHERE md5(content) = '8d608e299334ea3c8f90b6f87609264d' AND answer_key = '{"correct":0}';

-- id(운영) 677 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드는 정상 동작하지만 상태 업데이트 방식에 개선할 점이 있다. 무엇인가?

import React from ''react'';
class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
  }
  handleClick = () => {
    this.setState({ count: this.state.count + 1 });
  };
  render() {
    return (
      <div>
        <p>카운트: {this.state.count}</p>
        <button onClick={this.handleClick}>증가</button>
      </div>
    );
  }
}
export default App;', options = '["stale closure 때문에 setState에 전달한 객체가 렌더 시점의 값을 캡처해 count가 영원히 0에서 1 사이만 오간다","다음 상태를 this.state.count에서 직접 계산하므로 한 배치에서 연속 호출되면 업데이트가 유실될 수 있다 — 업데이터 함수가 안전하다","클래스 컴포넌트에서는 setState를 쓸 수 없으므로 useState 훅으로 바꿔야 한다","handleClick을 화살표 함수 클래스 필드로 정의하면 this 바인딩이 깨져 클릭 시 TypeError가 발생한다"]', answer_key = '{"correct":1}'
WHERE md5(content) = '11f089db53a0b6746f7494868b9d00c5';

-- id(운영) 678 FRONTEND_REACT: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'f4bd54a2bae2102d3117bb088b535164' AND answer_key = '{"correct":1}';

-- id(운영) 679 FRONTEND_REACT: 키 교정 0 -> 2
UPDATE question_bank SET answer_key = '{"correct":2}'
WHERE md5(content) = 'f1b49d2c1cf04b902d5f85cc277cc883' AND answer_key = '{"correct":0}';

-- id(운영) 680 FRONTEND_REACT: 키 교정 2 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '79a70e5676e2fe47451358893cc9911e' AND answer_key = '{"correct":2}';

-- id(운영) 681 FRONTEND_REACT: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '6cfe33ea40b863bd770352aea6e78f75' AND answer_key = '{"correct":1}';

-- id(운영) 684 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 컴포넌트가 리렌더링될 때, JSX가 반환하는 React 엘리먼트 객체와 실제 DOM 노드에 대한 설명으로 옳은 것은?

const [items, setItems] = useState([{id: 1, text: ''a''}]);
return (
  <div key={items[0].id}>{items[0].text}</div>
);', options = '["엘리먼트 객체는 렌더마다 새로 생성되지만, type과 key가 같으면 기존 DOM 노드는 재사용된다.","엘리먼트 객체는 최초 렌더에 한 번만 생성되고, 이후 렌더에서는 같은 객체가 캐시에서 반환되어 그대로 재사용된다.","key가 같으면 JSX 평가 자체가 생략되어 엘리먼트 객체가 생성되지 않는다.","렌더마다 DOM 노드가 새로 만들어지고 이전 노드는 항상 제거된다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '59c14f9908e4c36567a1080a7b4a271a';

-- id(운영) 685 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 `React.memo`를 사용했지만, 컴포넌트가 계속해서 렌더링되는 이유는 무엇인가요?

const MyComponent = React.memo(({ count }) => {
  console.log(''MyComponent rendered'');
  return <div>{count}</div>;
});

function App() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    setInterval(() => setCount(prev => prev + 1), 1000);
  }, []);

  return <MyComponent count={count} />;
}', options = '["React.memo는 함수형 컴포넌트에는 적용되지 않아 메모이제이션이 무시되기 때문이다.","React.memo는 이벤트 핸들러의 변경사항을 감지하지 못하기 때문이다.","React.memo로 감싼 컴포넌트는 부모가 렌더링되면 props와 무관하게 무조건 다시 렌더링되기 때문이다.","setInterval로 count prop이 매초 변경되어 memo의 얕은 비교가 매번 다르다고 판정하기 때문이다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '6b522e308f5aee3ab56b777e175cbfbb';

-- id(운영) 686 FRONTEND_REACT: 키 교정 3 -> 2
UPDATE question_bank SET answer_key = '{"correct":2}'
WHERE md5(content) = 'cc8294c863b177a3c524d627e1d75d95' AND answer_key = '{"correct":3}';

-- id(운영) 687 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 `React.memo`를 사용했지만, 컴포넌트가 계속해서 렌더링되는 이유는 무엇인가요?

const MemoComponent = React.memo(function Component({ count }) {
  console.log(''MemoComponent rendered'');
  return <div>{count}</div>;
});

function App() {
  const [count, setCount] = useState(0);
  useEffect(() => {
    setInterval(() => setCount(prev => prev + 1), 1000);
  }, []);

  return <MemoComponent count={count} />;
}', options = '["React.memo는 props를 깊은 비교하므로 숫자 타입 prop의 변경은 감지하지 못하기 때문이다.","React.memo는 이벤트 핸들러의 변경사항을 감지하지 못하기 때문이다.","React.memo로 감싼 컴포넌트는 state를 가진 부모 아래에서는 항상 리렌더링되기 때문이다.","매초 count prop이 바뀌어 memo의 props 비교에서 이전 값과 달라지므로 정상적으로 리렌더링되기 때문이다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '890d9b889569b1e332c8ac5219527464';

-- id(운영) 690 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드의 useLayoutEffect 훅은 useEffect와 비교해 언제 실행되는가?

useLayoutEffect(() => {
  console.log(''layout effect'');
}, []);

// 컴포넌트 내용', options = '["브라우저가 화면을 페인트한 후에 비동기적으로 실행되어 페인트를 막지 않는다","DOM 변경이 반영된 후, 브라우저가 화면을 페인트하기 전에 동기적으로 실행된다","컴포넌트 함수가 호출(렌더)되기 전에 먼저 실행된다","실행 시점이 보장되지 않아 페인트 전후 어느 쪽에서든 실행될 수 있다"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'e9c212dc157daa7e6d684b0569607c37';

-- id(운영) 691 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드가 실행될 때 어떤 문제가 발생할 수 있을까요?

import React, { useState } from ''react'';
function Counter() {
  const [count, setCount] = useState(0);
  const handleClick = () => {
    setTimeout(() => {
      setCount(count + 1); // 문제점이 있는 코드
    }, 500);
  };
  return (
    <div>
      <p>카운트: {count}</p>
      <button onClick={handleClick}>증가</button>
    </div>
  );
}
export default Counter;', options = '["setTimeout 내부에서 setCount를 호출하는 것 자체가 React에서 금지되어 있어 경고가 출력됩니다.","setTimeout 콜백이 클릭 시점의 count 값을 클로저로 캡처하므로, 500ms 안에 여러 번 클릭해도 stale closure 때문에 카운트가 1만 증가할 수 있습니다.","함수 컴포넌트에서는 setTimeout을 사용할 수 없습니다.","setCount가 setTimeout 안에서는 배치되지 않고 동기적으로 즉시 실행되어 카운트가 매 클릭마다 두 배씩 증가합니다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '5b041101a841b64cedbda58a4f4e29af';

-- id(운영) 694 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 useLayoutEffect 훅이 사용된 이유는 무엇인가?

import React, { useLayoutEffect } from ''react'';
const Example = () => {
  useLayoutEffect(() => {
    console.log(''useLayoutEffect called'');
    document.body.style.backgroundColor = ''#fff'';
  }, []);

  return <div>Example</div>;
};', options = '["useLayoutEffect와 useEffect는 실행 시점까지 완전히 동일하므로 어느 것을 써도 아무 차이가 없다.","DOM 변경이 반영된 뒤 브라우저가 화면을 페인트하기 전에 동기적으로 배경색을 적용해, 이전 배경이 잠깐 보이는 깜빡임을 막기 위해 사용되었다.","렌더링 도중(render phase)에 컴포넌트의 상태를 변경하기 위해 사용되었다.","서버 사이드 렌더링 환경에서만 실행되는 훅이기 때문에 사용되었다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'bffd1d3e2e0a0e72ae56fe0b94b45b29';

-- id(운영) 695 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 ''증가'' 버튼을 클릭하면 어떤 문제가 발생할까요?

import React from ''react'';
class Counter extends React.Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
  }
  handleClick() {
    setTimeout(() => {
      const latestCount = this.state.count; // 문제점이 있는 코드
      this.setState({ count: latestCount + 1 });
    }, 500); 
  }
  render() {
    return (
      <div>
        <p>카운트: {this.state.count}</p>
        <button onClick={this.handleClick}>증가</button>
      </div>
    );
  }
}
export default Counter;', options = '["setTimeout 내부에서 this.setState를 호출하는 것 자체가 React에서 금지되어 있어 개발 모드에서 경고가 출력되고 업데이트가 무시됩니다.","setState 메서드는 setTimeout 내부에서는 동작하지 않습니다.","handleClick이 this에 바인딩되지 않은 채 onClick에 전달되어 콜백 실행 시 this가 undefined가 되고, this.state.count를 읽는 순간 TypeError가 발생합니다.","클래스 컴포넌트에서는 setTimeout을 사용할 수 없습니다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '85433f23873e6df5c3ba065f50492206';

-- id(운영) 699 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 ''증가'' 버튼을 한 번 클릭했을 때 발생하는 문제점은 무엇인가?

import React from ''react'';
class Counter extends React.Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
    this.handleClick = this.handleClick.bind(this);
  }
  handleClick() {
    this.setState({ count: this.state.count + 1 });
    this.setState({ count: this.state.count + 1 });
    this.setState({ count: this.state.count + 1 }); // 3 증가를 의도한 코드
  }
  render() {
    return (
      <div>
        <p>카운트: {this.state.count}</p>
        <button onClick={this.handleClick}>증가</button>
      </div>
    );
  }
}
export default Counter;', options = '["세 번의 setState가 한 이벤트 핸들러 안에서 배치 병합되고 this.state.count는 그동안 갱신되지 않아, 카운트가 3이 아니라 1만 증가합니다.","한 핸들러에서 setState를 연속 호출하면 React가 예외를 던져 컴포넌트가 언마운트됩니다.","각 setState가 호출 즉시 재렌더링을 일으키므로 클릭당 3씩 정상적으로 증가하며 아무 문제가 없습니다.","클래스 컴포넌트에서는 객체를 인자로 넘기는 setState 호출이 허용되지 않습니다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'df25e80c300907819cb009030c284d7d';

-- id(운영) 700 FRONTEND_REACT: 재작성
UPDATE question_bank SET content = '다음 코드에서 `useContext` 훅이 어떻게 작동하는지를 설명해 주세요.

const ThemeContext = React.createContext(''light'');

function App() {
  const [theme, setTheme] = useState(''dark'');
  return (
    <ThemeContext.Provider value={theme}>
      <Child />
    </ThemeContext.Provider>
  );
}

function Child() {
  const theme = useContext(ThemeContext);
  useEffect(() => {
    console.log(`Current Theme: ${theme}`);
  }, [theme]);
  return null;
}', options = '["useContext는 컴포넌트 트리에서 가장 가까운 컨텍스트 값을 가져온다.","useContext 훅은 직접 제공된 value값을 무시하고, 최상위 Provider의 값만 사용한다.","useEffect 내부에서 useContext 훅이 호출되면, 이 컴포넌트는 렌더링되지 않는다.","ThemeContext.Provider가 없으면 useContext는 createContext에 준 기본값을 무시하고 항상 undefined를 반환한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '11ca8164598e0fdf063c51a922484ec7';

-- id(운영) 703 MOBILE_FLUTTER: 키 교정 0 -> 1
UPDATE question_bank SET answer_key = '{"correct":1}'
WHERE md5(content) = '7ff8b4154fd67436050630e7cdb3fb67' AND answer_key = '{"correct":0}';

-- id(운영) 706 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Dart에서 Future를 사용하여 비동기 작업을 처리할 때, 다음 중 올바른 사용법은?', options = '["async 로 선언하지 않은 일반 함수의 본문 안에서 await 키워드 사용하기","async 함수 안에서 await 키워드로 다른 Future 의 완료를 기다리기","완료된 Future 의 값을 await 대신 .result 속성으로 동기적으로 꺼내기","Future.delayed 의 콜백이 동기적으로 즉시 실행된다고 가정하고 반환값 바로 사용하기"]', answer_key = '{"correct":1}'
WHERE md5(content) = '82b3a1c3af14f8055ac159d87f0fa627';

-- id(운영) 707 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 Provider 로 제공된 int 값이 변경되면 위젯 트리에는 어떤 일이 일어나는가?

```
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(''Provider Example'')),
      body: Center(child: ValueCounter()),
    );
  }
}

class ValueCounter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int value = Provider.of<int>(context); // Provider 사용
    return Text(''Value: $value'');
  }
}
```', options = '["MyHomePage 를 포함한 위젯 트리 전체가 rebuild 된다.","Provider.of 는 값을 한 번만 읽으므로 값이 변경되어도 아무 위젯도 rebuild 되지 않는다.","Provider.of(context) 로 값을 구독한 ValueCounter 위젯만 rebuild 된다.","BuildContext 가 무효화되어 Scaffold 부터 새로운 트리가 생성된다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '1f3d948bd49b69275565146167e5a51c';

-- id(운영) 710 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Flutter의 비동기 처리와 관련된 다음 설명 중 올바른 것은 무엇인가요?', options = '["FutureBuilder 의 future 파라미터에는 Future 객체를 전달한다.","StreamBuilder 는 Future 객체를 구독하며 Stream 은 처리할 수 없다.","await 는 함수 전체를 블로킹해 UI 스레드를 멈추게 하는 동기 키워드다.","위젯 트리에 다시 삽입될 State 객체라도 dispose 는 build 직후마다 반드시 호출된다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'b2a130028e626b6f67ad815b5ac957da';

-- id(운영) 713 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'StatefulWidget 의 생명주기 메서드 initState 와 dispose 는 각각 언제 호출되고 어떤 역할을 하는가?', options = '["initState 는 build 가 호출될 때마다 매번 다시 실행되어 상태를 재초기화한다.","initState 는 State 가 트리에 삽입될 때 한 번 호출되어 초기화를 수행하고, dispose 는 State 가 영구 제거될 때 호출되어 리소스를 해제한다.","dispose 는 setState 가 호출될 때마다 실행되어 이전 프레임의 상태를 정리한다.","initState 와 dispose 는 모두 State 객체가 처음 생성되는 시점에 연달아 호출되어 초기 설정과 정리 콜백 등록을 동시에 수행한다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '675613c097b1b42cf2079be5a1bdd481';

-- id(운영) 717 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Flutter 에서 Row 의 자식 위젯들의 너비 합이 화면 너비를 넘어 오버플로(RenderFlex overflowed) 경고가 발생합니다. 자식들이 가용 공간에 맞춰 유연하게 줄어들도록 하려면 어떻게 해야 할까요?', options = '["mainAxisAlignment 를 MainAxisAlignment.spaceBetween 으로 설정한다.","crossAxisAlignment 를 CrossAxisAlignment.stretch 로 설정해 자식을 세로로 늘인다.","Row 의 mainAxisSize 를 MainAxisSize.min 으로 설정해 자식들의 크기를 줄인다.","각 자식 위젯을 Expanded 로 감싸 가용 공간을 나눠 갖게 한다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '80eceb0768378485b02bfd78ebeec72c';

-- id(운영) 721 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Flutter에서 StatelessWidget과 StatefulWidget을 사용할 때, 각각 어떤 상황에 적합한가?', options = '["상태 변경이 필요한 화면에는 StatelessWidget 을, 정적인 화면에는 StatefulWidget 을 사용한다.","변경 가능한 내부 상태가 있으면 StatefulWidget 을, 없으면 StatelessWidget 을 사용한다.","모든 위젯은 성능을 위해 항상 StatefulWidget 으로 작성해야 한다.","StatelessWidget 은 setState 호출로 자신의 필드 값을 갱신해 화면을 다시 그릴 수 있다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '3d98b0371f5359b70219bc700802b373';

-- id(운영) 723 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Flutter에서 Stack과 Positioned 위젯을 사용하여 화면에 아이콘을 표시하려고 한다. 아이콘이 항상 화면의 중앙에 위치하도록 설정해야 하는데, 어떻게 해야 할까?', options = '["Positioned 위젯의 top 과 left 속성을 0 으로 설정해 아이콘을 배치한다.","Positioned 위젯의 top 과 left 속성을 각각 화면 높이와 너비의 절반 값으로 설정해 아이콘을 배치한다.","Stack 의 alignment 를 Alignment.center 로 설정하고 아이콘을 Positioned 없이 자식으로 둔다.","Stack 대신 Expanded 위젯으로 아이콘을 직접 감싸 중앙에 배치한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = 'fa951e4c67df5264ccd0192174782c8c';

-- id(운영) 724 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'ListView.builder가 많은 항목을 가진 리스트에서 성능을 최적화하는 핵심 메커니즘은 무엇인가?', options = '["모든 항목 위젯을 리스트 생성 시점에 한꺼번에 만들어 메모리에 캐시해 둔다.","화면에 보일 항목만 필요한 시점에 itemBuilder로 생성한다.","각 항목 위젯을 별도 isolate에서 병렬로 빌드한다.","itemExtent를 지정하지 않으면 항목을 자동으로 압축해 메모리 사용량을 줄인다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'd7837b72b3c5e37c77982f8c25d0395b';

-- id(운영) 728 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Flutter에서 Navigator를 사용하여 페이지 이동을 구현하고 있다. 다음 중 Navigator의 동작에 대한 설명으로 옳은 것은?', options = '["Navigator의 push 메서드는 현재 스택에 있는 모든 라우트를 제거한 뒤 새 라우트를 넣는다.","Navigator의 pop 메서드는 스택의 가장 아래에 있는 첫 번째 라우트를 제거한다.","Navigator의 push 메서드는 새로운 라우트를 스택 맨 위에 추가하여 해당 화면으로 전환한다.","Navigator의 pop 메서드는 남은 스택 깊이와 무관하게 항상 첫 화면으로 즉시 이동한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '0442352ed97a524c7f12793342521767';

-- id(운영) 736 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Provider 패키지로 상태 관리를 할 때, ChangeNotifierProvider가 수행하는 역할은 무엇인가?', options = '["상태를 앱 재시작 후에도 유지되도록 SharedPreferences에 자동으로 직렬화해 저장한다.","하위 위젯의 build 메서드를 별도 isolate에서 비동기로 실행해 성능을 높인다.","ChangeNotifier 인스턴스를 하위 트리에 제공하고, notifyListeners() 호출 시 이를 구독(watch)하는 위젯을 다시 빌드하게 한다.","하위 위젯의 setState 호출을 가로채 한 프레임으로 병합한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '6041ffc4214fd27e38f32c4e58d8d0f9';

-- id(운영) 737 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 `Positioned` 위젯은 어떤 좌표계를 기준으로 위치를 지정하는가?

```
Stack(
  children: [
    Positioned(left: 50, top: 30, child: Container(color: Colors.red)),
  ],
)
```', options = '["Container 위젯의 크기","Stack 위젯의 크기","화면 전체의 크기","가장 가까운 Scaffold body의 크기"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'ceb69687398ddf8d580ae7bd408cc34f';

-- id(운영) 744 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Dart에서 비동기 코드를 작성할 때, 이벤트 루프와 isolate의 개념을 이해하고 적절히 활용하는 것이 중요하다. 다음 중 이벤트 루프와 isolate에 대한 올바른 설명은 무엇인가?', options = '["isolate는 Dart VM에서 메모리를 공유하지 않는 별도의 실행 컨텍스트이며, 메인 isolate와는 SendPort/ReceivePort로 메시지를 주고받는다.","이벤트 루프는 비동기 작업이 완료될 때마다 이벤트를 처리하며, 동기 코드가 실행되는 동안에도 큐의 이벤트를 계속 꺼내 처리한다.","isolate는 프로그램의 전체 생명주기를 관리하며, 메인 isolate에서 생성된 모든 isolate는 자동으로 종료된다.","이벤트 루프는 비동기 작업을 큐에 넣어 처리하지만, 이벤트가 발생하지 않으면 이벤트 루프 자체가 영구히 중단된다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '8d43d15277d610538bbd91dace98efa7';

-- id(운영) 754 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 중 Flutter 앱에서 플랫폼(OS) 권한 요청을 처리하는 방법이 아닌 것은?', options = '["Platform Channel로 네이티브 권한 요청 코드를 호출한다.","permission_handler 패키지의 request()를 사용한다.","firebase_messaging의 requestPermission()으로 알림 권한을 요청한다.","shared_preferences에 권한 상태 플래그를 저장한다."]', answer_key = '{"correct":3}'
WHERE md5(content) = 'f99f6ce8368535c872b0d091f651c5d8';

-- id(운영) 758 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = 'Provider 패키지와 비교했을 때 Riverpod가 제공하는 차별점으로 옳은 것은 무엇인가요?', options = '["Riverpod의 프로바이더는 위젯 트리 바깥에 선언되며, BuildContext 없이도 상태를 읽을 수 있다.","Riverpod는 상태가 하나라도 변경되면 앱의 전체 위젯 트리를 루트부터 다시 빌드해 일관성을 보장한다.","Provider는 InheritedWidget을 사용하지 않지만 Riverpod는 InheritedWidget에 의존한다.","Riverpod의 프로바이더는 StatefulWidget 내부에서만 선언하고 사용할 수 있다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '6f1be800378bae842d7aa3409230d4ff';

-- id(운영) 763 MOBILE_FLUTTER: 키 교정 2 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '5c652a2df2dab9d5759eb2d9ec6c3ef3' AND answer_key = '{"correct":2}';

-- id(운영) 774 MOBILE_FLUTTER: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '8159b7f03e3ece53dab26cb1990f5060' AND answer_key = '{"correct":0}';

-- id(운영) 787 MOBILE_FLUTTER: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = '346e484401e378c5e3e4ae5a0219878b' AND answer_key = '{"correct":1}';

-- id(운영) 790 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 MyInheritedWidget의 data가 새 값으로 바뀌어 위젯이 다시 생성되어도, 이를 참조(dependOnInheritedWidgetOfExactType)하는 하위 위젯들이 다시 빌드되지 않습니다. 원인은 무엇일까요?

class MyInheritedWidget extends InheritedWidget {
  final int data;
  const MyInheritedWidget({super.key, required this.data, required super.child});

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) => false;
}', options = '["updateShouldNotify가 항상 false를 반환해 의존 위젯에 갱신이 통지되지 않는다.","InheritedWidget의 필드는 final로 선언할 수 없으므로 data 선언 자체가 잘못되어 값 비교가 항상 실패한다.","생성자가 const로 선언되어 있어 데이터 변경이 프레임워크에 감지되지 않는다.","child를 super 생성자에 넘기면 하위 위젯이 트리에서 분리되어 갱신을 받지 못한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'c5041f52f4f1d5c37cc2e2c90a7c4ff4';

-- id(운영) 793 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 Stack의 자식인 빨간 Container를 좌측 상단 기준 (left: 50, top: 10) 좌표에 배치하려고 합니다. Container를 어떤 위젯으로 감싸야 할까요?

Stack(
  children: [
    Container(width: 20, height: 20, color: Colors.red),
  ],
)', options = '["Expanded 위젯","Flexible 위젯","Center 위젯","Positioned 위젯"]', answer_key = '{"correct":3}'
WHERE md5(content) = '3a9eaa5aba8e614aacf136d616b6b9bb';

-- id(운영) 795 MOBILE_FLUTTER: 키 교정 3 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'b2d9bfee64210736f55c94101ea4719a' AND answer_key = '{"correct":3}';

-- id(운영) 796 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드는 StatelessWidget을 사용하여 상수(const) 위젯을 정의합니다.

return const MyWidget();

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(''Hello World'');
  }
}', options = '["MyWidget은 StatefulWidget처럼 내부 상태를 setState로 변경할 수 있습니다.","const 키워드로 생성하지 않으면 MyWidget의 필드 값은 생성 이후에도 자유롭게 변경할 수 있는 가변 상태가 됩니다.","const로 생성하면 build 메서드는 최초 한 번도 호출되지 않습니다.","부모가 다시 빌드될 때 const로 생성된 동일 인스턴스는 재사용되어 불필요한 rebuild를 건너뛸 수 있습니다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '92d8157d46619a0965997680da85a60a';

-- id(운영) 797 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 ListView.builder가 정상적으로 동작하지 않도록 설계되었습니다. 이 문제를 해결하기 위해 어떤 수정이 필요할까요?

ListView.builder(
itemBuilder: (context, index) {
return Container(height: 50);
},
count: 100,
)
', options = '["Container 위젯에서 height 속성을 제거한다.","ListTile 위젯을 사용하도록 itemBuilder 메소드를 수정한다.","ListView.builder에서 count 대신 itemCount를 사용한다.","itemBuilder 메서드에서 setState 호출을 제거한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '1cd91500fa3ca86fec2f731e3b9c3e50';

-- id(운영) 799 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드에서 setState 메서드의 사용과 상태 관리에 대한 설명으로 옳은 것을 고르세요.

class Counter extends StatefulWidget {
  final int initialCount;
  const Counter({super.key, required this.initialCount});
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  late int count = widget.initialCount;
  void increment() { setState(() { count++; }); }
  @override
  Widget build(BuildContext context) {
    return Text(count.toString());
  }
}
', options = '["increment()의 setState 호출은 _CounterState의 build를 다시 실행하게 하여 변경된 count가 화면에 반영됩니다.","setState 없이 count++만 실행해도 다음 프레임에서 화면이 자동으로 갱신됩니다.","setState는 count 값을 변경하지만 build가 반환하는 Text는 이전 값을 유지합니다.","setState의 콜백은 다음 프레임이 그려진 뒤 비동기로 실행되므로 count 증가가 한 프레임 늦게 반영됩니다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '827dde99874e8dbd32def72b276598a9';

-- id(운영) 800 MOBILE_FLUTTER: 재작성
UPDATE question_bank SET content = '다음 코드는 FutureBuilder를 사용하여 비동기 작업의 결과를 화면에 표시하려고 합니다.

FutureBuilder<String>(
  future: _fetchData(), // 비동기 작업
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text(''Error: ${snapshot.error}'');
    switch (snapshot.connectionState) {
      case ConnectionState.none:
        return Text(''Awaiting connection...'');
      case ConnectionState.active:
        return Text(''Connection active'');
      case ConnectionState.waiting:
        return Text(''Loading...'');
      case ConnectionState.done:
        if (snapshot.hasData) {
          return Text(snapshot.data!);
        } else {
          return Text(''No data available'');
        }
    }
  },
)', options = '["비동기 작업이 완료되면 ''Loading...''이라는 텍스트가 계속 표시됩니다.","비동기 작업 중 오류 발생 시 에러 메시지가 화면에 표시됩니다.","비동기 작업이 성공적으로 완료되어도 화면에는 항상 ''No data available''이 표시됩니다.","비동기 작업이 완료되지 않은 동안에는 ''Awaiting connection...''이라는 텍스트만 표시됩니다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'a6c0bd2bab7043c8ff07be8b6340c6e0';

-- id(운영) 802 DEVOPS: 재작성
UPDATE question_bank SET content = '다음은 Kubernetes에서 Pod를 정의하는 YAML 파일입니다. 이 설정의 문제점은 무엇인가요?

apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
  - name: app
    image: nginx:1.27
    resources:
      requests:
        memory: "2Gi"
      limits:
        memory: "1Gi"', options = '["memory limits(1Gi)가 requests(2Gi)보다 작아 Pod 생성이 거부된다.","restartPolicy를 지정하지 않으면 컨테이너가 종료 후 다시 시작되지 않는다.","containers 항목이 하나뿐이라 Pod 스펙 검증을 통과하지 못한다.","이미지에 태그를 명시하면 Pod를 생성할 수 없다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '017070ae34102463d9bd761e769d4671';

-- id(운영) 805 DEVOPS: 재작성
UPDATE question_bank SET content = 'Docker 빌드에서 레이어 캐시를 효과적으로 활용하는 방법으로 옳은 것은?', options = '["자주 바뀌는 소스 코드의 COPY 단계를 의존성 설치 단계 뒤에 배치한다.","COPY . . 명령을 Dockerfile의 첫 단계에 두어 모든 파일을 먼저 복사해 둔다.","매 빌드마다 --no-cache 옵션을 사용해 캐시를 새로 만든다.","베이스 이미지 태그를 빌드마다 변경해 캐시 충돌을 예방한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'b4a855e1c25bfc2142a8d9df2d61df1a';

-- id(운영) 808 DEVOPS: 재작성
UPDATE question_bank SET content = 'CI/CD 파이프라인에서, 새 버전을 소수의 사용자 트래픽에만 먼저 노출해 지표를 관찰하고 문제가 없으면 점차 비율을 늘려 가는 배포 전략은?', options = '["blue-green 배포","canary 배포","rolling 배포","big-bang 배포"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'b9ca8dda37b6fbe5b2606269e15d8b31';

-- id(운영) 811 DEVOPS: 재작성
UPDATE question_bank SET content = 'Prometheus 메트릭 타입 중, 값이 증가만 하고 감소하지 않는(프로세스 재시작 시 0으로 리셋될 수는 있음) 누적 값을 표현하는 타입은?', options = '["Counter","Gauge","Histogram","Summary"]', answer_key = '{"correct":0}'
WHERE md5(content) = '2fcf749836371d7d868cf9c319e610f6';

-- id(운영) 813 DEVOPS: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '7084b2d20ebc92793e72f3d1123778e9' AND answer_key = '{"correct":0}';

-- id(운영) 815 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes에서 컨테이너가 요청을 받을 준비가 되었는지 판단하여, 준비되지 않은 동안 해당 Pod를 Service 엔드포인트에서 제외하는 프로브 유형은?', options = '["livenessProbe","readinessProbe","startupProbe","execProbe"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'f85dffe51562c83663834e00c806d064';

-- id(운영) 816 DEVOPS: 재작성
UPDATE question_bank SET content = 'Dockerfile에서 빌드 컨텍스트의 파일을 이미지로 복사할 때, 원격 URL 다운로드나 압축 자동 해제 같은 부가 동작 없이 단순 복사만 수행해 빌드의 예측 가능성 측면에서 권장되는 명령어는?', options = '["ADD","COPY","RUN","SHELL"]', answer_key = '{"correct":1}'
WHERE md5(content) = '4357b55cade2c03c1252355c39526d7b';

-- id(운영) 817 DEVOPS: 재작성
UPDATE question_bank SET content = '다음은 Kubernetes에서 Service를 정의하는 YAML 파일입니다. Deployment의 Pod 라벨은 app: web 입니다. 이 설정의 문제점은 무엇인가요?

apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: web-api
  ports:
  - port: 80
    targetPort: 8080', options = '["selector가 Pod 라벨(app: web)과 일치하지 않아 엔드포인트가 생성되지 않고 트래픽이 전달되지 않는다.","targetPort는 port와 반드시 같은 값이어야 하므로 8080을 지정하면 Service 생성이 거부된다.","type 필드를 생략하면 Service가 생성되지 않는다.","port 80은 시스템 예약 포트라 Service에서 사용할 수 없다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '5ad2eaf854ba47b1233c7f9a8132c382';

-- id(운영) 819 DEVOPS: 재작성
UPDATE question_bank SET content = 'Docker 컨테이너에서 볼륨(volume)과 바인드 마운트(bind mount)의 가장 중요한 차이는 무엇인가?', options = '["볼륨은 Docker가 관리하는 저장 영역에 데이터를 두고, 바인드 마운트는 호스트의 특정 경로를 직접 지정해 연결한다.","볼륨은 컨테이너 삭제 시 항상 함께 삭제되지만, 바인드 마운트는 컨테이너와 무관하게 데이터가 남는다.","바인드 마운트는 읽기 전용으로만 사용할 수 있고, 볼륨은 읽기와 쓰기가 모두 가능하다.","볼륨은 리눅스 호스트에서만 동작하고, 바인드 마운트는 모든 운영체제에서 동작한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'f6a8cc055716ec8b0dcb13f9762f944b';

-- id(운영) 821 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes에서 readinessProbe를 사용하기에 가장 적절한 시나리오는?', options = '["컨테이너가 응답 불능(교착) 상태에 빠지면 kubelet이 자동으로 재시작하도록 하고 싶을 때.","초기화를 마치고 준비가 끝난 Pod만 Service의 트래픽 대상에 포함시키고 싶을 때.","Pod의 CPU 사용량에 따라 복제본 수를 자동으로 조절하고 싶을 때.","컨테이너 기동이 오래 걸려 초기 기동 동안 다른 프로브 검사를 유예하고 싶을 때."]', answer_key = '{"correct":1}'
WHERE md5(content) = '7428d1e6ac5b80bf3b0da53f9bf72ac0';

-- id(운영) 825 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes에서 Pod에 설정하는 startupProbe의 목적은 무엇인가요?', options = '["실행 중인 컨테이너가 교착 상태에 빠졌는지 주기적으로 확인해 재시작을 유발한다.","서비스 준비 상태를 확인하고 요청을 받아들일 수 있는지 여부를 결정한다.","초기화가 긴 컨테이너의 기동이 끝날 때까지 liveness·readiness 검사를 유예한다.","리소스 사용량을 모니터링하여 과부하를 감지한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '3ac586e3f6e3ab3febf09bf8b81bebee';

-- id(운영) 826 DEVOPS: 재작성
UPDATE question_bank SET content = 'GitOps 방식으로 애플리케이션 배포를 관리할 때 실제로 고려해야 하는 한계(도전 과제)는 무엇인가요?', options = '["시크릿(비밀 값)을 Git에 평문으로 둘 수 없어 별도의 시크릿 관리 방안이 필요하다.","커밋 이력이 배포 상태와 무관하게 저장되므로 이전 상태로의 롤백을 전혀 지원하지 않는다.","선언형 매니페스트를 사용할 수 없어 모든 배포를 명령형 스크립트로 작성해야 한다.","Argo CD나 Flux 같은 도구와 함께 사용할 수 없다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'f86831a42b630d62ca9f24612f9c4c03';

-- id(운영) 830 DEVOPS: 재작성
UPDATE question_bank SET content = 'Docker에서 바인드 마운트가 아닌 볼륨(volume)을 사용하기에 가장 적절한 시나리오는?', options = '["컨테이너가 삭제돼도 데이터베이스 데이터를 Docker가 관리하는 저장소에 영속적으로 보존해야 할 때.","컨테이너 이미지의 크기를 줄여야 할 때.","호스트의 소스 코드 디렉터리를 경로 그대로 컨테이너에 노출해 편집 내용을 즉시 반영해야 할 때.","이미지 빌드 시 레이어 캐시를 최대한 활용해야 할 때."]', answer_key = '{"correct":0}'
WHERE md5(content) = '32925f1cc430c15064088282b8367554';

-- id(운영) 833 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes에서 Pod의 livenessProbe와 readinessProbe를 구분하는 가장 중요한 차이는 무엇인가요?', options = '["livenessProbe 실패는 컨테이너 재시작을 유발하고, readinessProbe 실패는 Service 트래픽 대상에서 제외를 유발한다.","livenessProbe는 Pod가 배치된 노드의 하드웨어 상태를 확인하고, readinessProbe는 클러스터 전체의 네트워크 상태를 확인한다.","livenessProbe는 HTTP 방식만 지원하고, readinessProbe는 TCP 방식만 지원한다.","readinessProbe가 실패하면 Pod가 즉시 삭제되고 새 Pod가 생성된다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '280f9e0e119d271eafc6a5a2d68ca050';

-- id(운영) 835 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes Deployment에서 매니페스트 파일을 수정하지 않고 명령 한 줄로 컨테이너 이미지를 교체해 롤링 업데이트를 트리거하는 명령어는?', options = '["kubectl apply -f deployment.yaml","kubectl rollout status deployment/name","kubectl set image deployment/name container=image:tag","kubectl rollout undo deployment/name"]', answer_key = '{"correct":2}'
WHERE md5(content) = 'ddbad386c9fa2f1f300a8a8be5fdd081';

-- id(운영) 836 DEVOPS: 재작성
UPDATE question_bank SET content = 'CI/CD 파이프라인에서 Blue-Green 배포 전략의 주요 특징은 무엇인가?', options = '["하나의 환경 안에서 Pod를 순차적으로 교체하며 구버전과 신버전 Pod에 트래픽이 섞여 들어가게 한다.","새로운 버전만 먼저 실행한 후 기존 버전 환경을 즉시 삭제해 롤백 경로를 없앤다.","기존 애플리케이션을 완전히 중지한 다음 새로운 버전으로 대체한다.","두 환경을 나란히 두고 새 환경 검증이 끝나면 트래픽을 한 번에 새 환경으로 전환한다."]', answer_key = '{"correct":3}'
WHERE md5(content) = 'f0ca854f6ab2e8090c288b169253e4d2';

-- id(운영) 842 DEVOPS: 재작성
UPDATE question_bank SET content = 'Docker 이미지 최적화를 위해 다음과 같은 Dockerfile을 사용합니다. 이 코드의 문제점은 무엇인가요?

FROM node:20
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]', options = '["소스 전체를 먼저 복사한 뒤 의존성을 설치해, 코드가 한 줄만 바뀌어도 npm install 레이어 캐시가 무효화된다.","WORKDIR 명령은 반드시 모든 COPY 뒤에 위치해야 하므로 이 순서로는 이미지 빌드 자체가 실패한다.","CMD는 배열(exec) 형식을 사용할 수 없어 컨테이너가 시작되지 않는다.","FROM에 태그를 지정하면 레이어 캐시를 사용할 수 없다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '9e46986a6c8b01971a7b142a5bfac5af';

-- id(운영) 846 DEVOPS: 재작성
UPDATE question_bank SET content = 'COPY . . 으로 빌드 컨텍스트 전체를 복사하는 Dockerfile에서, .git 디렉터리와 node_modules 등 불필요한 파일이 이미지에 함께 들어가고 빌드 컨텍스트 전송도 느립니다. 가장 직접적인 해결 방법은 무엇인가요?', options = '[".dockerignore 파일에 해당 경로를 추가해 빌드 컨텍스트에서 제외한다.","이미지 빌드 시마다 --no-cache 옵션으로 모든 레이어를 새로 만든다.","CMD 명령을 ENTRYPOINT로 바꿔 실행 시점에 해당 파일을 무시하게 한다.","빌드가 끝난 뒤 컨테이너 안에서 해당 파일을 삭제하는 RUN 명령을 Dockerfile 마지막에 추가한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '906687f95bf83ad5dd6d6e5118af1901';

-- id(운영) 851 DEVOPS: 재작성
UPDATE question_bank SET content = 'CI/CD 파이프라인에서 Blue-Green 배포 전략과 Canary 배포 전략은 어떻게 다른가요?', options = '["Blue-Green 배포는 새로운 버전의 서비스를 실행시키지 않고 기존 서비스만 제자리에서 업데이트한다.","Canary 배포는 전체 트래픽을 단번에 새 서비스로 이동시킨다.","Blue-Green 배포는 두 환경을 나란히 두고 검증 후 트래픽을 전환하며, Canary 배포는 일부 트래픽만 새 버전으로 보내 점진적으로 확대한다.","Canary 배포는 트래픽 비율을 조절하지 않고 항상 절반씩 고정 분배하며, Blue-Green 배포는 Pod를 하나씩 순차 교체해 두 버전이 섞이는 것을 전제로 한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '7d1b693e2b56a6a0f01219e08c5822ae';

-- id(운영) 852 DEVOPS: 재작성
UPDATE question_bank SET content = 'Dockerfile로 이미지를 빌드할 때, 다음 중 이미지 크기 최적화에 실제로 도움이 되는 방법은?', options = '["RUN 명령을 최대한 여러 개로 쪼개 레이어 수를 늘린다.","이미지 빌드 시마다 --no-cache 옵션으로 항상 새로 빌드한다.","볼륨 마운트를 사용하여 실행 시점의 변경 사항을 반영한다.",".dockerignore 파일로 빌드 컨텍스트의 불필요한 파일을 배제한다."]', answer_key = '{"correct":3}'
WHERE md5(content) = '3bb2064a819dcf59cb56dbfcda872a03';

-- id(운영) 858 DEVOPS: 재작성
UPDATE question_bank SET content = 'Docker 이미지 빌드 시 다음 명령어가 어떤 역할을 하는지 고르세요.

docker build -t myapp:1.0 .', options = '["myapp:1.0 이미지를 컨테이너로 실행한다.","현재 디렉터리를 빌드 컨텍스트로 삼아 Dockerfile로 이미지를 빌드하고 myapp:1.0 태그를 붙인다.","myapp:1.0 이미지를 원격 레지스트리에 업로드한다.","로컬의 기존 myapp 이미지와 파일을 비교해 달라진 파일만 담은 증분 이미지를 별도로 생성한다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '824423ae743913f475550e29d0e8ff52';

-- id(운영) 861 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 중 Docker 이미지 크기를 줄이는 데 효과적인 방법은 무엇인가요?', options = '["컨테이너를 루트 권한으로 실행한다","빌드 도구와 캐시 파일을 디버깅 편의를 위해 최종 이미지에 그대로 남겨 둔다","멀티 스테이지 빌드로 빌드 단계의 산출물만 최종 이미지에 복사한다","실행 중인 도커 인스턴스 수를 늘린다"]', answer_key = '{"correct":2}'
WHERE md5(content) = 'dd04f067524adcbf92f148628787a354';

-- id(운영) 863 DEVOPS: 재작성
UPDATE question_bank SET content = 'CI/CD 파이프라인에서 Blue-Green 배포 전략의 장점으로 옳은 것은 무엇인가요?', options = '["두 환경을 동시에 운영할 필요가 없어 인프라 비용이 절감된다","이전 버전 환경이 그대로 남아 있어 트래픽 전환만으로 빠르게 롤백할 수 있다","데이터베이스 스키마 동기화 문제가 자동으로 해결된다","구버전과 신버전 파드가 섞인 채 순차 교체되므로 추가 자원이 거의 들지 않는다"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'f65113ecf4e1ab26d0585961598c7a4e';

-- id(운영) 864 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes의 HPA(Horizontal Pod Autoscaler)에 대한 설명으로 옳은 것은 무엇인가요?', options = '["HPA는 metrics server 없이도 기본적으로 CPU 사용률 지표를 수집한다","HPA는 파드 수 대신 개별 파드의 CPU·메모리 요청량(requests)을 조정한다","HPA는 minReplicas 설정과 무관하게 파드를 0개까지 자동으로 축소한다","HPA는 autoscaling/v2부터 CPU 외에 메모리·커스텀 메트릭 기준으로도 스케일링할 수 있다"]', answer_key = '{"correct":3}'
WHERE md5(content) = 'ce5e961b1bcce0247607dc4cc573dcef';

-- id(운영) 865 DEVOPS: 재작성
UPDATE question_bank SET content = '동일한 운영 환경 두 벌을 준비해 두고, 새 버전 검증이 끝나면 라우터에서 트래픽을 한 번에 새 환경으로 전환하는 배포 전략은 무엇인가요?', options = '["Canary Release","Blue-Green Deployment","Rolling Update","Recreate Deployment"]', answer_key = '{"correct":1}'
WHERE md5(content) = '945f15ea351fa4a0228e21afdc0f88f1';

-- id(운영) 867 DEVOPS: 재작성
UPDATE question_bank SET content = 'Prometheus의 메트릭 타입에 대한 설명으로 옳은 것은 무엇인가?', options = '["Gauge는 한 번 기록되면 감소할 수 없는 누적 측정값이다","Histogram은 관측된 원시 값을 모두 저장해 서버가 임의의 분위수를 정확히 계산한다","Counter는 감소하지 않으며, 프로세스 재시작 시 0으로 리셋될 수 있는 누적 값이다","Summary가 클라이언트에서 계산한 분위수는 여러 인스턴스에 걸쳐 평균 내어 합산해도 유효하다"]', answer_key = '{"correct":2}'
WHERE md5(content) = '295f2eae45d00d265d254e21ab189299';

-- id(운영) 869 DEVOPS: 재작성
UPDATE question_bank SET content = 'Kubernetes의 Pod와 Deployment 간의 주요 차이점은?', options = '["Pod는 일회성 배치 작업 전용이고, 지속 서비스는 Deployment가 컨테이너를 직접 실행한다","Deployment는 ReplicaSet을 통해 Pod 집합의 선언적 배포·스케일링을 관리하고, Pod는 하나 이상의 컨테이너를 묶은 최소 배포 단위다","Pod는 복수의 컨테이너를 포함할 수 있지만, Deployment는 단일 컨테이너 Pod만 관리할 수 있다","Deployment를 삭제해도 그것이 생성한 Pod들은 기본 설정에서 계속 실행된다"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'fbc9d661a00ad9bc3eaa458babdc2b8d';

-- id(운영) 870 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 중 시계열 메트릭을 pull 방식으로 수집·저장하고 PromQL로 질의할 수 있는 관측성 도구는 무엇인가요?', options = '["Prometheus","Grafana","Kibana","Jenkins"]', answer_key = '{"correct":0}'
WHERE md5(content) = '0ab078a06a4a79e35f6527f97b7e290f';

-- id(운영) 875 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 Dockerfile에서 마지막 줄 CMD ["npm", "start"]의 역할은 무엇인가?

FROM node:14-alpine
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
CMD ["npm", "start"]', options = '["이미지 빌드 시점에 npm start를 실행해 그 결과를 이미지에 굽는다","컨테이너 시작 시 실행할 기본 명령을 지정하며, docker run에서 다른 명령을 주면 대체된다","빌드 결과 이미지에 npm 의존성 패키지를 설치한다","컨테이너가 종료될 때 실행할 정리 명령을 등록한다"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'a522525cd7f10abc392a7c20a256996d';

-- id(운영) 878 DEVOPS: 키 교정 1 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '055237abf1008503f0d80a4f5e157883' AND answer_key = '{"correct":1}';

-- id(운영) 880 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 YAML 파일은 Kubernetes HorizontalPodAutoscaler를 정의합니다. 문제가 될 부분은 무엇일까요?

apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-deployment
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 50', options = '["minReplicas(2)가 maxReplicas(6)보다 커서 스케일링 범위가 유효하지 않습니다.","targetCPUUtilizationPercentage는 autoscaling/v1 전용 필드라서, v2beta2에서는 metrics 배열로 지정해야 합니다.","spec 아래에는 scaleTargetRef를 둘 수 없으므로 제거해야 합니다.","CPU 사용률은 HPA가 지원하지 않는 메트릭 종류입니다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'd2ac780a2082e6c7226c15e593b61a8e';

-- id(운영) 881 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 Dockerfile에서 package.json만 먼저 복사해 npm install을 실행한 뒤, 그 다음에 나머지 소스 코드를 복사하는 이유는 무엇인가?

FROM node:14-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "start"]', options = '["최종 이미지 크기가 절반 이하로 줄어들기 때문","package.json을 나중에 복사하면 npm install이 아예 실행되지 않기 때문","소스 코드만 변경된 경우 npm install 레이어의 캐시를 재사용해 빌드 시간을 줄이기 위해","COPY . . 명령이 node_modules 디렉터리를 덮어쓰는 것을 방지하기 위해"]', answer_key = '{"correct":2}'
WHERE md5(content) = '020c2729c404cd49aec2401c2ef525e1';

-- id(운영) 884 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 Docker Compose 파일이 정의하는 구성으로 옳은 것은 무엇인가?

version: ''3''
services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - .:/code
    environment:
      - DATABASE_HOST=db
  db:
    image: postgres', options = '["web 하나의 서비스만 정의하며 db는 외부 클러스터에 대한 참조다","web 컨테이너와 db 컨테이너를 병합해 하나의 컨테이너에서 단일 프로세스로 실행하도록 정의한다","postgres 이미지를 베이스 이미지로 삼아 web 이미지를 다시 빌드하도록 정의한다","현재 디렉터리에서 빌드하는 web 서비스와 postgres 이미지를 사용하는 db 서비스, 두 개의 서비스를 정의한다"]', answer_key = '{"correct":3}'
WHERE md5(content) = 'ae2483a999135ffa62ae319c5b64514f';

-- id(운영) 886 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 Kubernetes YAML 파일은 ReplicaSet을 정의합니다. 이 매니페스트를 적용(kubectl apply)하면 어떻게 되나요?

apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: example-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: example-app
  template:
    metadata:
      labels:
        app: another-app
    spec:
      containers:
      - name: example-container
        image: nginx:latest', options = '["ReplicaSet이 생성되고 ''another-app'' 라벨을 가진 Pod 3개가 정상적으로 만들어집니다.","selector가 template의 라벨과 일치하지 않아 API 서버가 생성 요청 자체를 거부합니다.","ReplicaSet이 생성되고 ''example-app'' 라벨을 가진 Pod 3개가 만들어집니다.","ReplicaSet은 생성되지만 라벨은 무시하고 이름 기준으로 Pod를 관리합니다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '92250b5164d0c8856d26e5d51fa11c46';

-- id(운영) 887 DEVOPS: 재작성
UPDATE question_bank SET content = '다음 Dockerfile의 빌드 캐시 동작에 대한 설명으로 옳은 것은?

FROM node:14-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
CMD ["npm", "start"]', options = '["소스 코드가 한 줄이라도 바뀌면 npm install 레이어까지 항상 다시 실행된다","package.json이 변경되지 않는 한 npm install 레이어는 캐시에서 재사용된다","컨테이너를 시작할 때마다 모든 노드 모듈이 다시 설치된다","COPY . . 명령은 캐시를 사용할 수 없어 매 빌드마다 베이스 이미지 전체를 새로 내려받는다"]', answer_key = '{"correct":1}'
WHERE md5(content) = '04c5ef363ceb7cd1c4d259d852df6209';

-- id(운영) 890 DEVOPS: 키 교정 2 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'fdbd5ff9f94be230aa52e3d91c44e906' AND answer_key = '{"correct":2}';

-- id(운영) 893 DEVOPS: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'bec70924d0a90a0f2abedc2b4e1b955f' AND answer_key = '{"correct":1}';

-- id(운영) 899 DEVOPS: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '71144bff57968c429cbe6994beb43ad6' AND answer_key = '{"correct":0}';

-- id(운영) 904 FULLSTACK: 재작성
UPDATE question_bank SET content = '서버가 클라이언트가 제시한 JWT를 위변조되지 않았다고 신뢰할 수 있는 핵심 근거는 무엇인가요?', options = '["페이로드가 암호화되어 있어 발급자 외에는 아무도 내용을 읽을 수 없기 때문","비밀키(또는 개인키)로 생성된 서명을 검증해 토큰의 위변조 여부를 확인할 수 있기 때문","JWT는 프로토콜상 HTTPS로만 전송되도록 강제되어 있기 때문","서버가 발급한 모든 토큰을 데이터베이스에 저장해 두고 매 요청마다 원본과 대조하기 때문"]', answer_key = '{"correct":1}'
WHERE md5(content) = '204453b813a5376fd8bf634c0c03db6a';

-- id(운영) 912 FULLSTACK: 재작성
UPDATE question_bank SET content = '프론트엔드-백엔드 통신에서 XSS 공격으로 주입된 스크립트가 인증 자격 증명을 직접 읽어 탈취하지 못하도록 하는 저장 방식은 무엇인가요?', options = '["세션 식별자를 HttpOnly 속성이 설정된 쿠키에 담아 스크립트에서 읽을 수 없게 한다.","JWT를 localStorage에 저장하고 매 요청마다 자바스크립트로 읽어 헤더에 담는다.","토큰을 URL 쿼리 스트링에 붙여 페이지 간에 전달한다.","HttpOnly 없이 document.cookie로 접근 가능한 쿠키에 토큰을 저장하고 스크립트로 관리한다."]', answer_key = '{"correct":0}'
WHERE md5(content) = '0fa9fd839d28367dd36c985b00c432b3';

-- id(운영) 913 FULLSTACK: 키 교정 1 -> 0
UPDATE question_bank SET answer_key = '{"correct":0}'
WHERE md5(content) = 'e51e4d9c079a34eccb65e1bbb7b7ab9e' AND answer_key = '{"correct":1}';

-- id(운영) 917 FULLSTACK: 키 교정 2 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '17538fe8e4233834e67eae3f514b8528' AND answer_key = '{"correct":2}';

-- id(운영) 920 FULLSTACK: 재작성
UPDATE question_bank SET content = '프론트-백 연동에서 게이트웨이(프록시) 서버가 업스트림 백엔드 서버의 응답을 제한 시간 안에 받지 못했을 때, 클라이언트에 반환하는 표준 HTTP 상태 코드는 무엇인가?', options = '["408 Request Timeout","504 Gateway Timeout","502 Bad Gateway","500 Internal Server Error"]', answer_key = '{"correct":1}'
WHERE md5(content) = '7ee7cef95cca225d5bd32c874da86874';

-- id(운영) 926 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 JWT 전달 방식 중 토큰이 서버 접근 로그와 브라우저 방문 기록, Referer 헤더에 그대로 남아 유출 위험이 가장 큰 것은 무엇인가?', options = '["Authorization 헤더에 담아 전송","HttpOnly 쿠키에 담아 전송","URL 쿼리 스트링에 담아 전송","POST 요청 본문에 담아 전송"]', answer_key = '{"correct":2}'
WHERE md5(content) = '76728b6570d2b820b9a958e946ed5039';

-- id(운영) 933 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 클라이언트-서버 인증 설계 중 명백히 안전하지 않은 것은 무엇인가요?', options = '["HttpOnly 쿠키 기반의 서버측 세션을 사용한다.","만료 시간이 짧은 액세스 토큰과 리프레시 토큰을 함께 사용한다.","사용자 암호를 브라우저에 평문으로 저장해 두고 매 API 요청에 함께 전송한다.","OAuth 2.0 인가 코드 플로우로 외부 신원 제공자에 인증을 위임한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = 'b7d43fd8aa5831ae29f5b7f31cd72734';

-- id(운영) 936 FULLSTACK: 재작성
UPDATE question_bank SET content = '서로 다른 수천 명의 사용자가 몇 분간 내용이 바뀌지 않는 같은 인기 게시글 목록 API를 반복 호출하고 있다. 데이터베이스로 가는 조회 요청 수 자체를 줄이는 데 가장 직접적인 기법은 무엇인가요?', options = '["각 사용자 브라우저에 적용되는 클라이언트 측 캐싱","응답 결과를 Redis 등 서버 사이드 캐시에 저장해 두고 DB 조회 없이 반환","게시글 테이블에 데이터베이스 인덱스 추가","모든 요청에 대한 처리 로직 단순화"]', answer_key = '{"correct":1}'
WHERE md5(content) = 'e4ceeebdf04eec98b7d2af30f35a4ad0';

-- id(운영) 937 FULLSTACK: 재작성
UPDATE question_bank SET content = '전형적인 서버측 세션 방식의 웹 애플리케이션에서, 브라우저 쿠키에 담기는 것은 무엇인가?', options = '["세션 식별자(세션 ID)만 담기고, 실제 세션 데이터는 서버측 저장소(메모리·Redis·DB 등)에 보관된다.","직렬화된 세션 데이터 전체가 쿠키에 담긴다.","사용자 암호의 해시값이 담긴다.","서버가 세션 서명에 쓰는 비밀키가 함께 담긴다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'd9be803797752baf78dec7de89cfde1b';

-- id(운영) 943 FULLSTACK: 키 교정 2 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '8b770428d2ac952f1c151cccb6621742' AND answer_key = '{"correct":2}';

-- id(운영) 962 FULLSTACK: 재작성
UPDATE question_bank SET content = '리프레시 토큰을 발급받아 둔 SPA에서, 액세스 토큰이 만료되었을 때 사용자의 재로그인 없이 인증 상태를 이어 가려면 프론트엔드는 어떻게 처리해야 하는가?', options = '["무조건 로그아웃 처리하고 새로 로그인하라는 메시지를 띄운다","리프레시 토큰으로 새 액세스 토큰을 발급받은 뒤 실패했던 요청을 재시도한다","만료된 액세스 토큰을 그대로 계속 전송해 서버가 자동으로 유효기간을 연장하게 한다","액세스 토큰의 exp 클레임을 프론트엔드에서 미래 시각으로 수정해 다시 사용한다"]', answer_key = '{"correct":1}'
WHERE md5(content) = '3a204f71cb9601c0686f81e0230e4476';

-- id(운영) 963 FULLSTACK: 재작성
UPDATE question_bank SET content = '프론트엔드에서 유효한 인증 정보 없이 로그인 필수 API를 호출했을 때, 서버가 반환하는 표준 HTTP 상태 코드를 선택하세요.', options = '["200 OK","302 Found","401 Unauthorized","500 Internal Server Error"]', answer_key = '{"correct":2}'
WHERE md5(content) = '22bcc9a03c96bd65a9e63f1ba03e2140';

-- id(운영) 973 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 JavaScript 코드는 프론트엔드에서 API 호출을 수행합니다.

fetch(''/api/user'', { method: ''GET'' })
.then(response => response.json())
.catch(error => console.log(''Error:'', error));

이 코드의 문제점은 무엇인가요?', options = '["네트워크 장애가 발생해도 catch 블록이 실행되지 않아 오류가 유실된다.","response.ok 를 확인하지 않아 4xx/5xx 오류 응답도 성공 경로로 처리된다.","fetch 는 method 옵션으로 GET 을 지정할 수 없다.","response.json() 은 동기 함수라서 then 콜백 안에서 호출할 수 없다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '40783d95d05416b528702256cfa43e99';

-- id(운영) 975 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 코드 스니펫은 MySQL에서 데이터베이스 트랜잭션을 처리하는데 사용됩니다.

@Transactional
public void updateUserData(User user) {
    user.setLastLogin(new Date());
    userRepository.save(user);
}

이 코드의 동작으로 가장 정확한 설명은 무엇인가요?', options = '["트랜잭션 안에서 사용자의 마지막 로그인 시각을 갱신해 저장합니다.","사용자의 모든 데이터를 삭제합니다.","런타임 예외가 발생해도 변경 사항이 롤백되지 않고 그대로 커밋됩니다.","HTTP 요청을 직접 수신해 파싱하고 처리합니다."]', answer_key = '{"correct":0}'
WHERE md5(content) = 'aca4f176cc9899d0b7bb5d63687e4466';

-- id(운영) 976 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 SQL 은 수백만 행이 있는 PostgreSQL users 테이블에서 자주 실행되는데, 실행 계획(EXPLAIN)에 Seq Scan 이 나타나며 느립니다.

SELECT * FROM users WHERE email = ''user@example.com'' AND status = ''active'';

조회 성능을 개선하는 가장 직접적인 방법은 무엇인가요?', options = '["SELECT * 를 SELECT email 로 바꿔 반환 컬럼 수를 줄인다.","WHERE 절에서 status 조건을 제거해 비교 횟수를 줄인다.","email(과 status) 컬럼에 인덱스를 생성해 인덱스 스캔이 가능하게 한다.","테이블을 비정규화해 users 데이터를 여러 테이블에 복제한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = 'a658c72a3bc16772c5de86dee1199f03';

-- id(운영) 978 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 코드는 서버에서 클라이언트에게 데이터를 반환하는 API 핸들러입니다.

@GetMapping("/users")
public List<User> getUsers() {
    return userRepository.findAll();
}

userRepository.findAll() 메서드는 모든 사용자 정보를 가져옵니다.

이 API 의 동작으로 옳은 것은 무엇인가요?', options = '["API 는 POST 요청도 이 핸들러로 받아 동일하게 사용자 목록을 반환합니다.","GET 요청이 성공해도 응답 본문 없이 상태 코드만 반환됩니다.","GET 요청은 항상 500 Internal Server Error 를 반환합니다.","GET 요청이 성공하면 200 OK 와 함께 사용자 목록이 반환됩니다."]', answer_key = '{"correct":3}'
WHERE md5(content) = 'bdb7fe1e8545f22f386654d32446899b';

-- id(운영) 981 FULLSTACK: 키 교정 0 -> 3
UPDATE question_bank SET answer_key = '{"correct":3}'
WHERE md5(content) = '6ce3687e801d7b4bff26ef6e4ab6313e' AND answer_key = '{"correct":0}';

-- id(운영) 985 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음은 배포 환경에서 헬스 체크를 수행하는 코드 스니펫입니다.

@GetMapping("/actuator/health")
public Health health() {
    return new Health.Builder()
            .up()
            .withDetail("database", "connected")
            .build();
}

이 구현의 문제점은 무엇인가요?', options = '["이 엔드포인트는 항상 ''DOWN'' 상태를 반환한다.","실제 데이터베이스 연결을 검사하지 않고 ''connected'' 를 하드코딩해 반환한다.","Health 객체는 JSON 으로 직렬화될 수 없어 호출이 항상 실패한다.","withDetail 로 추가한 세부 정보는 응답 본문에서 항상 제외된다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '230f42fbb04af38d1c59541dce668e96';

-- id(운영) 987 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음은 사용자 로그인 정보를 데이터베이스에서 검색하는 SQL 쿼리입니다.

SELECT * FROM users WHERE username = ? AND password = PASSWORD(?)

WHERE 절의 비밀번호 필드는 해시 함수로 처리됩니다.

이 쿼리의 동작으로 가장 정확한 설명은 무엇인가요?', options = '["쿼리 자체가 인증된 사용자의 로그인 세션을 생성한다.","비밀번호가 일치하지 않아도 username 이 일치하면 해당 사용자의 행을 반환한다.","입력 비밀번호의 해시가 저장된 값과 일치하는 행만 반환해 자격 증명을 확인한다.","저장된 비밀번호 해시를 평문 암호로 복호화해 반환한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '4689c468883a72b0ddaa33f386dc61fc';

-- id(운영) 988 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음 코드는 사용자의 프로필 정보를 가져오는 API 인데, 사용자가 없으면 userRepository.findByUserId() 가 null 을 반환해 modelMapper.map() 에서 예외가 발생합니다.

@GetMapping("/profile")
public UserDTO getUserProfile(@RequestParam String userId) {
    User user = userRepository.findByUserId(userId); // 없으면 null 반환
    return modelMapper.map(user, UserDTO.class);
}

사용자가 없을 때 404 Not Found 를 반환하도록 수정하는 가장 적절한 방법은 무엇인가요?', options = '["NullPointerException 을 try-catch 로 잡은 뒤 null 을 그대로 반환한다.","메서드 시그니처에 throws NullPointerException 을 선언해 예외를 컨테이너로 전파한다.","user == null 이면 @ResponseStatus(HttpStatus.NOT_FOUND) 가 붙은 ResourceNotFoundException 을 던진다.","컨트롤러 메서드에 @ResponseStatus(HttpStatus.NOT_FOUND) 를 직접 붙여 응답 상태를 지정한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '137196cf482c273634eca047895ae5d2';

-- id(운영) 990 FULLSTACK: 재작성
UPDATE question_bank SET content = '다음은 프론트엔드에서 REST API로 데이터를 요청하는 코드입니다. 

fetch(`/api/products/${productId}`, {
  method: ''GET'',
  headers: {
    ''Authorization'': `Bearer ${token}`
  }
})
.then(response => response.json())

이 코드에 대한 설명으로 옳은 것은 무엇인가요?', options = '["네트워크 오류가 발생하면 이 코드가 오류를 잡아 사용자에게 알린다.","응답이 4xx/5xx 상태 코드이면 fetch 프라미스가 자동으로 reject 된다.","Authorization 헤더에 Bearer 토큰을 담아 요청을 전송한다.","토큰이 만료되면 fetch 가 자동으로 토큰을 갱신한 뒤 재요청한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '4f68c031496ab3694f9e068014531ecf';

-- id(운영) 1001 PYTHON_BACKEND: 재작성
UPDATE question_bank SET content = 'WSGI와 ASGI의 주요 차이점은 무엇인가?', options = '["WSGI는 동기 호출뿐 아니라 WebSocket 같은 장수명 연결도 표준 스펙 차원에서 기본 지원하므로, ASGI와 기능상 차이가 없다.","ASGI는 이름과 달리 실제로는 WSGI와 동일하게 동기 방식의 호출만 지원하고 비동기 프로토콜은 다루지 못한다.","WSGI는 HTTP 요청 응답 프로토콜을 사용하며, ASGI는 HTTP 및 WebSocket 연결을 동시에 처리할 수 있다.","ASGI는 WSGI와 마찬가지로 HTTP 요청·응답 프로토콜만 지원하며 WebSocket 같은 장수명 연결은 다루지 못한다."]', answer_key = '{"correct":2}'
WHERE md5(content) = '16be21c30acd55fd79f122b9b2647471';

-- id(운영) 1093 PYTHON_BACKEND: 재작성
UPDATE question_bank SET content = '다음 코드에서 두 번째 for 루프는 몇 번의 추가 쿼리를 실행하는가?

qs = Order.objects.prefetch_related(''items'').filter(status=''paid'')

for order in qs.iterator():
    pass

for order in qs:
    print(order.items.count())', options = '["iterator()로 이미 한 번 순회했으므로 그 결과가 내부 결과 캐시에 자동으로 남아, 두 번째 루프는 추가 쿼리 없이 캐시된 결과만 그대로 재사용한다고 오해하기 쉽다. 실제로는 iterator가 캐시를 아예 만들지 않는다.","iterator()는 내부 결과 캐시를 채우지 않으므로 두 번째 for 루프는 쿼리셋을 처음부터 다시 평가한다. 이때 주문 목록 조회 1번과 prefetch_related에 의한 items 일괄 조회 1번, 총 2번의 추가 쿼리가 실행되며, order.items.count()는 채워진 prefetch 캐시의 길이를 반환하므로 건당 추가 쿼리는 없다.","iterator()를 한 번이라도 호출한 쿼리셋은 그 뒤로 완전히 재사용이 금지되어 두 번째 순회를 시도하는 시점에 곧바로 예외가 발생한다고 잘못 알려져 있다. 실제로는 재평가가 일어날 뿐 예외는 없다.","prefetch_related는 iterator() 사용 여부와 완전히 무관하게 항상 내부적으로 결과를 캐시해두므로, 두 번째 순회에서도 캐시된 prefetch 결과가 재사용되어 추가 쿼리가 전혀 발생하지 않는다고 오해하기 쉽다."]', answer_key = '{"correct":1}'
WHERE md5(content) = 'b5b900da9496d3aaeb1e923f62ae45b9';

-- id(운영) 1098 PYTHON_BACKEND: 재작성
UPDATE question_bank SET content = 'Order 모델은 nullable ForeignKey인 coupon(Coupon, null=True)을 갖고, Coupon은 여러 Order와 연결되는 역참조 관계다. 다음 코드에서 문제가 되는 부분은?

orders = Order.objects.select_related(''coupon'', ''coupon__campaigns'')

for order in orders:
    print(order.coupon.code if order.coupon else ''no coupon'')
    for campaign in order.coupon.campaigns.all() if order.coupon else []:
        print(campaign.name)', options = '["select_related(''coupon'')는 coupon 필드가 null인 주문을 만나는 순간 예외를 던져버려서 이 쿼리 자체가 실행 도중 실패한다고 오해하기 쉽다. 실제로는 nullable FK에도 select_related가 정상적으로 동작한다.","coupon__campaigns가 역참조(reverse FK) 또는 M2M 관계라면 select_related가 따라갈 수 없는 경로이므로 쿼리셋 평가 시점에 FieldError(''Invalid field name(s) given in select_related'')가 발생한다. 이런 관계는 prefetch_related(''coupon__campaigns'')로 가져와야 한다.","coupon이 nullable FK이니 select_related가 항상 INNER JOIN을 강제해서 coupon이 없는 주문은 결과 집합에서 자동으로 완전히 제외되고 반환되지 않는다고 잘못 알려져 있다. 실제로는 LEFT OUTER JOIN을 사용한다.","select_related에 필드를 여러 개 한꺼번에 넘기면 두 번째 인자부터는 조용히 무시되어 coupon만 조인되고 campaigns는 애초에 요청조차 되지 않는다고 오해하기 쉽다. 실제로는 두 필드 모두 처리를 시도한다."]', answer_key = '{"correct":1}'
WHERE md5(content) = '2774f115d7a678ed7b963b7ca4a326dc';

  -- 검증(양성): 교정된 155건이 전부 기대 상태로 존재해야 한다.
  -- (V202608131001·V202608141002 뒤에만 실행되므로, 테이블이 있는 스키마라면
  --  시드도 반드시 존재한다.)
  SELECT count(*) INTO matched
  FROM (VALUES
    ('8d8679ff684eac2be2b7cacbe03f00ec','["동일한 토픽의 메시지를 다른 그룹이 받지 못하게 독점적으로 소비한다.","같은 그룹 내에서 각 컨슈머는 서로 다른 파티션을 나누어 소비한다.","같은 그룹의 모든 컨슈머가 모든 메시지를 중복으로 수신하도록 보장한다.","컨슈머 그룹은 한 번에 하나의 토픽만 구독할 수 있다."]'::jsonb,'{"correct":1}'::jsonb),
    ('100b969f41e77be41e4d04533ad071ff','["오류 발생한 파티션만 다시 처리한다.","전체 토픽에서 재시작한다.","해당 그룹의 모든 파티션이 다시 처리된다.","위치를 기억하고 이후에 다시 처리한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('4ed221533ead4cb974581c1e87308576','["자바 소스 코드를 컴파일하기 전에 변환 규칙을 정의하는 빌드 스크립트다.","설정 프로퍼티를 정의해 스프링 빈의 속성에 바인딩할 수 있다.","운영체제 수준의 환경 변수를 영구적으로 등록하는 파일이다.","빈 사이의 의존성 주입 순서를 강제로 지정하는 파일이다."]'::jsonb,'{"correct":1}'::jsonb),
    ('1f461fc7b032d4ae5f20b37b73e5909a','["classpath의 application.properties 값이 적용된다.","먼저 로드된 파일의 값이 적용되고 나머지는 무시된다.","실행 디렉터리의 config/application.yaml 값이 적용된다.","동일 프로퍼티 충돌로 애플리케이션 기동이 실패한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('5d857d2f4df0bb89e66cdaae560902d6','["application.yml 파일에 직접적으로 활성화할 프로필 이름을 지정한다.","@ActiveProfiles 어노테이션으로 실행 시점에 프로필을 선택한다.","@Profile 어노테이션이 적용된 설정 클래스를 사용하여 프로파일별로 구분한다.","프로젝트 빌드 시 설정 파일에서 프로필을 지정해야 한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('20d2ca8643fbd9115de24181b337f442','["환경별 설정 파일을 만들어 두면 Spring Boot가 실행 호스트명을 보고 자동으로 알맞은 프로파일을 활성화한다.","spring.profiles.active 프로퍼티에 활성화할 프로파일을 명시하며, 이를 통해 해당 환경에 대한 설정이 로드된다.","application.yml 파일 내부에서 @Profile 어노테이션으로 분할된 설정을 정의하고, 필요한 프로필 이름을 지정한다.","운영 환경에서는 메인 클래스에 @ActiveProfiles 어노테이션을 붙여 프로파일을 활성화하는 것이 표준 방법이다."]'::jsonb,'{"correct":1}'::jsonb),
    ('7b916920cdeda6980e201650a4f33747','["환경 변수를 통해 활성 프로파일을 동적으로 변경하는 것이 가능합니다.","프로파일은 애플리케이션당 한 번에 하나만 활성화할 수 있습니다.","비프로필 기본 설정이 프로필별 설정보다 항상 우선 적용됩니다.","Spring Boot는 프로필 기반 설정을 지원하지 않습니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('4e655a1fca632e65f2220bd399d7f06f','["AuthenticationFilter","AuthenticatingFilter","UsernamePasswordAuthenticationFilter","AuthenticationProcessingFilter"]'::jsonb,'{"correct":2}'::jsonb),
    ('b4b89e5373537801bb855c1b1ed592a9','["@Entity","@Table","@Id","@OneToMany"]'::jsonb,'{"correct":3}'::jsonb),
    ('9099bcf2cd8a430019e13f9712fffc4a','["Before, After, Around 세 가지이며, 예외 발생 시점에 실행되는 advice 종류는 따로 존재하지 않는다.","Before, After returning, After throwing, After (finally), Around의 다섯 가지가 있다.","advice의 종류는 Pointcut과 JoinPoint 두 가지로, 각각 advice가 적용될 위치와 실행 시점을 지정한다.","Before와 After 두 가지뿐이며, 대상 메소드 실행을 감싸는 형태의 advice는 지원되지 않는다."]'::jsonb,'{"correct":1}'::jsonb),
    ('fba08174434cd5e8a68633d6568a2403','["인증과 인가는 동일한 개념이며 Spring Security는 둘을 구분하지 않는다.","인증은 사용자의 권한을 확인하고 인가는 로그인 여부를 확인한다.","인증은 사용자의 신원을 확인하고 인가는 접근 허용 여부를 확인한다.","인가가 항상 인증보다 먼저 수행된 뒤에 신원 확인이 이루어진다."]'::jsonb,'{"correct":2}'::jsonb),
    ('6dc1901fb4b4fb7a6d01d0d4ce295b50','["JPQL의 fetch join으로 연관 엔티티를 한 번의 쿼리로 함께 조회한다.","@Transactional을 메소드에 붙이면 영속성 컨텍스트가 개별 쿼리들을 자동으로 하나로 합쳐 준다.","모든 연관관계를 EAGER 로딩으로 변경한다.","엔티티의 equals와 hashCode를 오버라이드해 중복 조회를 막는다."]'::jsonb,'{"correct":0}'::jsonb),
    ('89aa062c06d03f2a1ef53a0bec22f051','["@EnableWebSecurity 설정 클래스에서 csrf().disable()을 호출한다.","기본 활성화된 CSRF 보호를 유지하고, 상태 변경 요청에 CSRF 토큰을 담아 검증받는다.","CSRF 보호는 기본 비활성 상태이므로 spring.security.csrf.enable=true 프로퍼티를 명시해야만 켜진다.","스프링 시큐리티 필터 체인에서 CsrfFilter를 제거해 토큰 충돌을 방지한다."]'::jsonb,'{"correct":1}'::jsonb),
    ('45d6814228b4c2ab26d66fa90e249d7e','["CacheManager","RedisTemplate","JedisClient","CachingConfigurer"]'::jsonb,'{"correct":1}'::jsonb),
    ('3eb6afcdd55c0f9267f744023ba9a1a3','["비동기 메서드는 항상 새로운 쓰레드를 생성하여 실행되며, 쓰레드 풀은 사용되지 않습니다.","스프링 컨텍스트가 모든 비동기 메서드 호출에 대해 결과를 기다리는 동안 블로킹합니다.","void 반환 비동기 메서드에서 발생한 예외는 호출자 스레드로 항상 자동 전파되어 호출부의 try-catch로 잡을 수 있습니다.","비동기 메서드의 반환값을 호출자가 받아오려면 메서드가 Future 계열(예: CompletableFuture) 타입을 반환해야 합니다."]'::jsonb,'{"correct":3}'::jsonb),
    ('9cecf8b55f65e40d6110c77ddc0fb425','["Consumer Group은 여러 컨슈머를 하나의 단위로 취급하며, 하나의 파티션을 그룹 내 여러 컨슈머가 동시에 나눠 읽도록 할당하여 처리량을 높인다.","Consumer Group은 동일한 주제에 대한 모든 메시지를 읽기 위해 독립적으로 작동하는 컨슈머들의 집합이며, 각 파티션은 배정 전략 없이 매 폴링마다 임의의 컨슈머에게 새로 할당된다.","Consumer Group은 Kafka 클러스터 내에서 중복된 메시지 처리를 방지하기 위한 식별자로서 동작하며, 모든 파티션이 단일 Consumer Group에 속한다.","각 파티션은 특정 소비그룹의 컨슈머에게 고유하게 할당되며, 리밸런싱 시점에서 자동적으로 파티션이 재할당된다."]'::jsonb,'{"correct":3}'::jsonb),
    ('c02fd9c056279125794c0948bbfac604','["Producer","MessagePublisher","KafkaProducer","TopicPublisher"]'::jsonb,'{"correct":0}'::jsonb),
    ('ec70e6790b6fd1b90617123f4b28ab7f','["spring.profiles.active 등으로 prod 프로파일을 활성화하지 않아 해당 문서 블록이 로드 대상에서 제외되었다.","application.yml은 한 파일 안에 여러 프로파일 문서를 담을 수 없으므로 항상 application-prod.yml 같은 별도 파일로 분리해야만 한다.","YAML 형식 자체가 프로파일 조건 설정을 지원하지 않으므로 .properties 형식으로 변환해야만 프로파일이 동작한다.","on-profile 조건 블록은 클라우드 배포 환경에서만 평가되며 로컬 실행에서는 스프링이 항상 무시하도록 설계되어 있다."]'::jsonb,'{"correct":0}'::jsonb),
    ('d442918ec99e9699fbd34f88b22ee66f','["fetch join 사용","연관 컬럼에 데이터베이스 인덱스 추가","Lazy Loading 사용","Eager Loading 사용"]'::jsonb,'{"correct":0}'::jsonb),
    ('cbd576203454ab27efe611fa34b15237','["org.springframework.kafka.core","org.apache.kafka.clients.consumer","org.apache.kafka.clients.producer","org.apache.kafka.connect.runtime"]'::jsonb,'{"correct":2}'::jsonb),
    ('519ca1e8c0a6136834ac141e2abb7295','["주문 상태 업데이트 로직이 성공적으로 실행됩니다.","read-only 트랜잭션에서는 데이터 변경이 불가능하여 예외가 발생합니다.","트랜잭션이 읽기 전용으로 설정되어도 데이터는 변경될 수 있습니다.","DB 연결이 되지 않습니다."]'::jsonb,'{"correct":2}'::jsonb),
    ('f502888f3a21a6dc306fd46b9140e49c','["데이터를 성공적으로 캐싱하고 요청 시 복잡성을 줄입니다.","데이터베이스의 값이 변경되면 캐시가 이를 자동으로 감지해 무효화되므로 항상 최신 값이 반환됩니다.","findUserById 메서드는 캐시에 저장된 데이터만 반환합니다.","이 코드는 퍼포먼스 저하를 일으킵니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('8b1133987f68736ba861470dc165cdfe','["동작은 정상적으로 이루어지며 두 계좌의 잔액이 변경됩니다.","fromAccount에서 금액을 빼고 toAccount에 추가하려고 시도했지만 비정상적인 트랜잭션으로 실패합니다.","transferMoney 메소드가 실행될 때 발생하는 예외는 롤백하지 않습니다.","위 코드에서는 @Transactional 어노테이션이 적용되지 않았습니다."]'::jsonb,'{"correct":3}'::jsonb),
    ('bd1e344d4918edf56126b2b2b5cfebf1','["readOnly 트랜잭션에서는 엔티티의 setter를 호출하는 시점에 즉시 예외가 발생한다.","변경 감지(dirty checking)가 정상 동작하여 커밋 시점에 UPDATE 쿼리가 실행된다.","Hibernate가 세션 플러시 모드를 MANUAL로 설정해 자동 플러시가 생략되므로, 필드 변경이 DB에 반영되지 않는다.","readOnly 설정으로 트랜잭션 자체가 시작되지 않아 영속성 컨텍스트가 아예 만들어지지 않는다."]'::jsonb,'{"correct":2}'::jsonb),
    ('6558a7a39c36b82878754e46353ab656','["메서드를 동기화 처리한다.","스프링 빈 프록시를 직접 호출하여 트랜잭션을 생성한다.","인터페이스 메서드를 통해 메서드를 호출한다.","@Transactional 어노테이션을 사용하지 않고 별도로 트랜잭션을 시작한다."]'::jsonb,'{"correct":1}'::jsonb),
    ('124e4d000eeb3bf192eb67359e49978a','["트랜잭션을 시작하지 않고 데이터를 읽는다.","findAll() 결과의 모든 행에 자동으로 비관적 읽기 잠금(SELECT ... FOR SHARE)을 걸어 다른 트랜잭션의 수정을 막는다.","트랜잭션이 읽기 전용임을 하위 계층에 힌트로 전달해 플러시 생략 같은 최적화를 유도하지만, 모든 쓰기 시도의 실패를 절대적으로 보장하지는 않는다.","JPA 2차 캐시를 강제로 활성화하여 이후 동일한 조회는 데이터베이스 대신 캐시에서만 읽어오도록 만든다."]'::jsonb,'{"correct":2}'::jsonb),
    ('094c6c6233b4e6bf0ab8325616b4269e','["delete() 호출 시점에 DELETE 쿼리가 즉시 실행되어 엔티티가 데이터베이스에서 삭제된다.","삭제 요청은 영속성 컨텍스트에 등록되지만, 플러시 모드가 MANUAL이라 커밋 시 자동 플러시가 생략되어 DELETE가 DB에 반영되지 않는다.","readOnly 위반을 감지한 Spring이 delete() 호출 시점에 UnsupportedOperationException을 던지도록 표준으로 보장한다.","삭제는 정상적으로 수행되지만 트랜잭션이 커밋 대신 자동으로 롤백 처리된다."]'::jsonb,'{"correct":1}'::jsonb),
    ('dbb2e602b0c7d2b9c917500584b391ee','["트랜잭션이 유지되고 엔티티가 저장된다.","트랜잭션은 롤백되지만 엔티티는 저장되지 않는다.","엔티티는 저장되지만 트랜잭션이 예외로 인해 롤백된다.","예외 처리 없이 프로그램이 종료된다."]'::jsonb,'{"correct":1}'::jsonb),
    ('64d767979a244a82938241d233d41bf6','["JPA 표준이 readOnly 트랜잭션에서의 save() 호출에 대해 항상 즉시 예외를 던지도록 강제한다.","save()는 readOnly 설정과 완전히 무관하게 동작하도록 규정되어 있어, 어떤 구성에서도 커밋 시점의 INSERT 실행이 예외 없이 항상 보장된다.","readOnly는 최적화 힌트일 뿐이라 결과가 구성에 따라 갈린다 — ID 생성 전략과 JPA 구현체에 따라 INSERT가 즉시 실행될 수도, 플러시 생략으로 조용히 무시될 수도 있다.","Spring이 save() 호출을 감지해 메서드 전체를 no-op으로 바꾸므로 아무 일도 일어나지 않음이 항상 보장된다."]'::jsonb,'{"correct":2}'::jsonb),
    ('ccc716bcbc52697d4cdb720d363a5dd5','["컴포넌트의 key 값이 고유하게 유지될 때","props로 매 렌더링마다 새로운 객체 리터럴이나 인라인 함수를 만들어 전달할 때","컴포넌트 내부의 state가 변경되었을 때","부모가 재렌더링되어도 전달된 props가 얕은 비교(shallow compare)로 이전과 같을 때"]'::jsonb,'{"correct":3}'::jsonb),
    ('c37aba9c10b64bd53f3023e7dabb970f','["미들웨어와 개발자 도구 기반 디버깅을 활용해 복잡한 전역 상태 갱신 로직을 다뤄야 할 때","단일 컴포넌트 내부에서만 쓰이는 폼 입력 상태를 관리할 때","거의 변하지 않는 테마나 로케일 값을 하위 트리에 단순히 전달하기만 하면 될 때","외부 라이브러리 의존성을 최소화하고 싶을 때"]'::jsonb,'{"correct":0}'::jsonb),
    ('56178d10d86d711bf14c540e24846739','["API 요청 전에 상태를 미리 업데이트해 두어 응답 지연을 숨긴다.","setTimeout으로 요청 사이에 일정한 간격을 강제로 두어 응답이 항상 순서대로 도착하게 만든다.","cleanup 함수에서 ignore 플래그를 설정하거나 AbortController로 이전 요청을 취소한다.","useMemo로 응답 데이터를 캐싱해 같은 요청을 반복하지 않는다."]'::jsonb,'{"correct":2}'::jsonb),
    ('2e589dfcbf9e02498da4d39b65d576fd','["const [count, setCount] = useState(0);","const [count, setCount] = setState(0);","const count = useState(0); count.value = 0;","함수 컴포넌트 본문에 this.state = { count: 0 }; 을 작성한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('35822e08d37156431225e5dd040d173f','["props는 반드시 문자열 형태로만 전달할 수 있다.","자식 컴포넌트는 전달받은 props를 직접 수정해서 부모의 상태를 갱신하는 것이 권장된다.","props가 바뀌어도 자식 컴포넌트는 다시 렌더링되지 않는다.","props는 부모 컴포넌트에서 자식 컴포넌트로 전달되는 읽기 전용 데이터다."]'::jsonb,'{"correct":3}'::jsonb),
    ('1a1342fe9c9bacfc19e86b061197c2bd','["입력값이 항상 React state와 자동으로 동기화된다.","React가 입력값 유효성 검사를 자동으로 수행해 준다.","키 입력마다 setState가 호출되지 않아 리렌더링이 발생하지 않는다.","value prop 값을 바꾸는 것만으로 언제든 입력값을 즉시 재설정할 수 있다."]'::jsonb,'{"correct":2}'::jsonb),
    ('0e43b4a23fac4cad84cf547211d8d87a','["useContext()","useState()","useCallback()","useMemo()"]'::jsonb,'{"correct":1}'::jsonb),
    ('5d115b08ff63f1f9af898e0005e7366b','["useEffect() 안에서 상태 업데이트를 모아 배치로 처리한다.","자식 컴포넌트를 React.memo()로 감싼다.","자식 컴포넌트에서 useState() 호출을 제거하고 전역 변수에 값을 보관한다.","부모의 setState() 호출을 setTimeout으로 지연시킨다."]'::jsonb,'{"correct":1}'::jsonb),
    ('e34e3d7781e318d8f8c6f903791faa43','["무한 루프 생성","배치 업데이트 발생","상태 누락","렌더링 성능 저하"]'::jsonb,'{"correct":2}'::jsonb),
    ('a1a238d0b78a9d2b6347a1d8fb28a929','["setter 호출 직후 같은 함수 안에서 즉시 새 값을 읽을 수 있다.","다음 렌더링에서 새 값으로 반영된다.","useEffect의 cleanup 함수가 실행된 뒤에만 반영된다.","브라우저 이벤트 루프가 한 바퀴 돈 뒤 렌더링 없이 조용히 반영된다."]'::jsonb,'{"correct":1}'::jsonb),
    ('f7a03eb22864008529c70f60b19c2153','["function MyComponent() { const [value, setValue] = useState(''''); return <input value={value} onChange={(e) => setValue(e.target.value)} />; }","function MyComponent() { let value = ''''; return <input value={value} onChange={(e) => value = e.target.value} />; }","function MyComponent() { const value = ''''; return <input value={value} onChange={(e) => value = e.target.value} />; }","function MyComponent() { let [value, setValue] = useState(''''); return <input value={value} onChange={(e) => value = e.target.value} />; }"]'::jsonb,'{"correct":0}'::jsonb),
    ('302035ecc5f568149d87513c0e755e59','["이펙트가 매 렌더링마다 무조건 다시 실행된다.","React가 컴파일 단계에서 오류를 내며 렌더링을 중단한다.","이펙트가 이전 렌더링 시점의 낡은(stale) 값을 계속 참조한다.","상태 업데이트가 동기적으로 즉시 반영되어 배치 처리가 깨진다."]'::jsonb,'{"correct":2}'::jsonb),
    ('2430fc0b8b29307bdffa3aec408309fa','["비동기 콜백을 사용하지 않음","렌더링 후 즉시 업데이트 상태","이벤트 핸들러를 직접 호출","비동기 동작을 처리하는 방법 변경"]'::jsonb,'{"correct":3}'::jsonb),
    ('b0f30629ae7459545ede0ce72b910c4b','["function MyComponent(name) { return <div>Hello, {name}</div>; }","function MyComponent(props) { return <div>Hello, {props.name}</div>; }","function MyComponent() { return <div>Hello, props.name</div>; }","function MyComponent({ name: ''John'' }) { return <div>Hello, {name}</div>; }"]'::jsonb,'{"correct":1}'::jsonb),
    ('046839e5bcc730b95469acc400a62c6e','["onChange 이벤트 핸들러에서 useState 훅으로 매 입력마다 value를 갱신한다.","value 속성을 props로 전달해 입력값을 강제한다.","defaultValue로 초기값을 주고 ref로 현재 값을 읽는다.","useContext 훅으로 폼 값을 구독한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('15ab3a6f3668db295e3d939f775ca9c8','["props로 전달받은 값을 직접 수정한다.","this.setState() 메서드를 호출한다.","useState 훅이 반환한 setter 함수를 호출한다.","this.state 객체의 속성을 직접 변경한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('f676cea64d10e81183da9c18d35f8c74','["서버와 클라이언트에서 렌더링 결과가 항상 동일하게 보이도록 보장하기 위해서다.","key가 각 요소의 CSS 클래스로 자동 부여되어 스타일링에 활용되기 때문이다.","리액트가 key를 전역 상태 저장소의 식별자로 사용해 상태를 보존하기 때문이다.","각 아이템을 고유하게 식별해 재조정(reconciliation) 시 변경·추가·제거된 항목을 판별하게 한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('f365c9a8ff866c22a260be6351819fe7','["const navigate = useNavigate(); navigate(''/path'', { replace: true });","const navigate = useNavigate(); navigate(''/path'', { state: { data } });","const navigate = useNavigate(); navigate(''/path'', { preventDefault: true });","useNavigate({ replace: true })를 호출하면 반환 함수 없이 즉시 대체 이동이 일어난다."]'::jsonb,'{"correct":0}'::jsonb),
    ('eafddca0e103bc47d2eb46bf42b634c6','["function MyComponent({ show }) { if (show) { const [n, setN] = useState(0); } return <div>Content</div>; }","function MyComponent() { const [count, setCount] = useState(0); useEffect(() => {}, []); return <div>Content</div>; }","function handleClick() { const [on, setOn] = useState(false); return on; }","function MyComponent() { for (let i = 0; i < 3; i++) { useState(i); } return <div>Content</div>; }"]'::jsonb,'{"correct":1}'::jsonb),
    ('7867481175fc7a837eda042f408ddbaa','["렌더링 성능이 저하되는 모든 컴포넌트에 적용해야 함","props 변경 시 컴포넌트를 재렌더링하지 않도록 하기 위해 사용","컴포넌트의 상태 관리에 필요한 최소한의 정보만 보존하도록 사용","상태 변화 없이도 컴포넌트가 렌더링되는 경우에만 사용"]'::jsonb,'{"correct":3}'::jsonb),
    ('77c9be5529ed9af935295b249a34fc00','["상태 변화에도 불구하고 컴포넌트는 무한 재렌더링을 수행하지 않음","컴포넌트는 상태 변경 이벤트를 감지하지 못하고 업데이트되지 않음","의존성 배열에 상태가 포함되어야 하므로 컴포넌트가 오류 발생","상태 변화에도 불구하고 useEffect 내부에서만 상태 업데이트가 적용됩니다"]'::jsonb,'{"correct":0}'::jsonb),
    ('93258bdebdb1a8f989b1f5632383ad38','["첫 렌더링이 끝난 뒤 setState를 한 번 호출해서 지정한다","useEffect 안에서 setState를 호출해서 지정한다","useState를 호출할 때 인자(initialState)로 전달한다","props로 넘기기만 하면 자동으로 상태 초기값이 된다"]'::jsonb,'{"correct":2}'::jsonb),
    ('43ae5410a86558ad0404741856dede3e','["0 — 콜백은 클릭 시점 렌더의 count 값을 클로저로 캡처한다","1 — 콜백 실행 시점에는 setCount가 반영된 최신 state를 읽는다","undefined — 타이머가 실행될 때 count 변수는 이미 소멸해 있다","TypeError — 함수 컴포넌트의 state는 setTimeout 안에서 읽을 수 없다"]'::jsonb,'{"correct":0}'::jsonb),
    ('8d608e299334ea3c8f90b6f87609264d','["useEffect 의 의존성 배열에 count를 추가해야 한다.","setInterval 대신 setTimeout을 사용하면 무한 루프가 해결된다.","무한 루프는 생성되지 않는다. setCount의 호출은 즉시 리렌더를 일으키지 않기 때문에 useEffect가 무한 재호출되는 문제가 없다.","useEffect 의 의존성 배열에서 window 객체를 추가해야 한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('2b7970e35dc879e700347eaf4f137ea5','["stale closure 때문에 setState에 전달한 객체가 렌더 시점의 값을 캡처해 count가 영원히 0에서 1 사이만 오간다","다음 상태를 this.state.count에서 직접 계산하므로 한 배치에서 연속 호출되면 업데이트가 유실될 수 있다 — 업데이터 함수가 안전하다","클래스 컴포넌트에서는 setState를 쓸 수 없으므로 useState 훅으로 바꿔야 한다","handleClick을 화살표 함수 클래스 필드로 정의하면 this 바인딩이 깨져 클릭 시 TypeError가 발생한다"]'::jsonb,'{"correct":1}'::jsonb),
    ('f4bd54a2bae2102d3117bb088b535164','["count가 무한히 증가하지만, 컴포넌트 언마운트 시 정상적으로 인터벌을 제거합니다.","count가 1씩 증가하지만, 의존성 배열에 count가 없기 때문에 stale closure 문제를 일으킵니다.","count가 정확하게 1씩 증가하며 의존성 배열은 정상적으로 작동합니다.","count가 초기화되지 않고 무한히 증가하는 버그가 발생합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('f1b49d2c1cf04b902d5f85cc277cc883','["클래스 컴포넌트에서 상태 업데이트 메서드를 직접 사용할 수 없다.","this.setState를 호출하면 클래스 내부의 다른 함수에서도 이 상태값을 참조해야 한다.","이 코드는 정상적으로 동작한다.","클릭 시 클래스 인스턴스가 새롭게 생성된다."]'::jsonb,'{"correct":2}'::jsonb),
    ('79a70e5676e2fe47451358893cc9911e','["버튼 클릭 시 count 상태가 1씩 증가합니다.","버튼 클릭 시 count 상태가 계속해서 무한히 증가합니다.","버튼 클릭 시 아무런 동작이 일어나지 않습니다.","버튼 클릭 시 컴포넌트가 언마운트됩니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('6cfe33ea40b863bd770352aea6e78f75','["이 코드는 정상적으로 동작한다.","handleChange 메서드에서 this.setState를 호출하면 무한 루프가 발생할 수 있다.","클래스 컴포넌트에서는 value 속성을 사용하지 않고, onChange 이벤트 핸들러만 사용해야 한다.","인풋 필드의 값이 변경될 때마다 컴포넌트가 재렌더링되지 않는다."]'::jsonb,'{"correct":0}'::jsonb),
    ('4999393c562e4de1a1cb16c28182844f','["엘리먼트 객체는 렌더마다 새로 생성되지만, type과 key가 같으면 기존 DOM 노드는 재사용된다.","엘리먼트 객체는 최초 렌더에 한 번만 생성되고, 이후 렌더에서는 같은 객체가 캐시에서 반환되어 그대로 재사용된다.","key가 같으면 JSX 평가 자체가 생략되어 엘리먼트 객체가 생성되지 않는다.","렌더마다 DOM 노드가 새로 만들어지고 이전 노드는 항상 제거된다."]'::jsonb,'{"correct":0}'::jsonb),
    ('6b522e308f5aee3ab56b777e175cbfbb','["React.memo는 함수형 컴포넌트에는 적용되지 않아 메모이제이션이 무시되기 때문이다.","React.memo는 이벤트 핸들러의 변경사항을 감지하지 못하기 때문이다.","React.memo로 감싼 컴포넌트는 부모가 렌더링되면 props와 무관하게 무조건 다시 렌더링되기 때문이다.","setInterval로 count prop이 매초 변경되어 memo의 얕은 비교가 매번 다르다고 판정하기 때문이다."]'::jsonb,'{"correct":3}'::jsonb),
    ('cc8294c863b177a3c524d627e1d75d95','["배열에 ''item1''이 정상적으로 추가됩니다.","배열은 변하지 않고 아무 일도 발생하지 않습니다.","배열은 변하지만 컴포넌트는 리렌더되지 않습니다.","컴포넌트가 무한 루프로 리렌더됩니다."]'::jsonb,'{"correct":2}'::jsonb),
    ('890d9b889569b1e332c8ac5219527464','["React.memo는 props를 깊은 비교하므로 숫자 타입 prop의 변경은 감지하지 못하기 때문이다.","React.memo는 이벤트 핸들러의 변경사항을 감지하지 못하기 때문이다.","React.memo로 감싼 컴포넌트는 state를 가진 부모 아래에서는 항상 리렌더링되기 때문이다.","매초 count prop이 바뀌어 memo의 props 비교에서 이전 값과 달라지므로 정상적으로 리렌더링되기 때문이다."]'::jsonb,'{"correct":3}'::jsonb),
    ('f3ee809f40d3d643c6b0e3f55a04e815','["브라우저가 화면을 페인트한 후에 비동기적으로 실행되어 페인트를 막지 않는다","DOM 변경이 반영된 후, 브라우저가 화면을 페인트하기 전에 동기적으로 실행된다","컴포넌트 함수가 호출(렌더)되기 전에 먼저 실행된다","실행 시점이 보장되지 않아 페인트 전후 어느 쪽에서든 실행될 수 있다"]'::jsonb,'{"correct":1}'::jsonb),
    ('c211dcdbf6521a245a1fe1c32418f7bc','["setTimeout 내부에서 setCount를 호출하는 것 자체가 React에서 금지되어 있어 경고가 출력됩니다.","setTimeout 콜백이 클릭 시점의 count 값을 클로저로 캡처하므로, 500ms 안에 여러 번 클릭해도 stale closure 때문에 카운트가 1만 증가할 수 있습니다.","함수 컴포넌트에서는 setTimeout을 사용할 수 없습니다.","setCount가 setTimeout 안에서는 배치되지 않고 동기적으로 즉시 실행되어 카운트가 매 클릭마다 두 배씩 증가합니다."]'::jsonb,'{"correct":1}'::jsonb),
    ('bffd1d3e2e0a0e72ae56fe0b94b45b29','["useLayoutEffect와 useEffect는 실행 시점까지 완전히 동일하므로 어느 것을 써도 아무 차이가 없다.","DOM 변경이 반영된 뒤 브라우저가 화면을 페인트하기 전에 동기적으로 배경색을 적용해, 이전 배경이 잠깐 보이는 깜빡임을 막기 위해 사용되었다.","렌더링 도중(render phase)에 컴포넌트의 상태를 변경하기 위해 사용되었다.","서버 사이드 렌더링 환경에서만 실행되는 훅이기 때문에 사용되었다."]'::jsonb,'{"correct":1}'::jsonb),
    ('dfba8e3f02134efc532132efedf78989','["setTimeout 내부에서 this.setState를 호출하는 것 자체가 React에서 금지되어 있어 개발 모드에서 경고가 출력되고 업데이트가 무시됩니다.","setState 메서드는 setTimeout 내부에서는 동작하지 않습니다.","handleClick이 this에 바인딩되지 않은 채 onClick에 전달되어 콜백 실행 시 this가 undefined가 되고, this.state.count를 읽는 순간 TypeError가 발생합니다.","클래스 컴포넌트에서는 setTimeout을 사용할 수 없습니다."]'::jsonb,'{"correct":2}'::jsonb),
    ('6c04d382db4fbcce1449efa41c4b9105','["세 번의 setState가 한 이벤트 핸들러 안에서 배치 병합되고 this.state.count는 그동안 갱신되지 않아, 카운트가 3이 아니라 1만 증가합니다.","한 핸들러에서 setState를 연속 호출하면 React가 예외를 던져 컴포넌트가 언마운트됩니다.","각 setState가 호출 즉시 재렌더링을 일으키므로 클릭당 3씩 정상적으로 증가하며 아무 문제가 없습니다.","클래스 컴포넌트에서는 객체를 인자로 넘기는 setState 호출이 허용되지 않습니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('11ca8164598e0fdf063c51a922484ec7','["useContext는 컴포넌트 트리에서 가장 가까운 컨텍스트 값을 가져온다.","useContext 훅은 직접 제공된 value값을 무시하고, 최상위 Provider의 값만 사용한다.","useEffect 내부에서 useContext 훅이 호출되면, 이 컴포넌트는 렌더링되지 않는다.","ThemeContext.Provider가 없으면 useContext는 createContext에 준 기본값을 무시하고 항상 undefined를 반환한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('7ff8b4154fd67436050630e7cdb3fb67','["제약은 위로, 크기는 아래로 전파된다.","크기는 위로, 제약은 아래로 전파된다.","제약과 크기 모두 위로 전파된다.","제약과 크기 모두 아래로 전파된다."]'::jsonb,'{"correct":1}'::jsonb),
    ('82b3a1c3af14f8055ac159d87f0fa627','["async 로 선언하지 않은 일반 함수의 본문 안에서 await 키워드 사용하기","async 함수 안에서 await 키워드로 다른 Future 의 완료를 기다리기","완료된 Future 의 값을 await 대신 .result 속성으로 동기적으로 꺼내기","Future.delayed 의 콜백이 동기적으로 즉시 실행된다고 가정하고 반환값 바로 사용하기"]'::jsonb,'{"correct":1}'::jsonb),
    ('8ecdd81d1588a88118423d0feb5fe53c','["MyHomePage 를 포함한 위젯 트리 전체가 rebuild 된다.","Provider.of 는 값을 한 번만 읽으므로 값이 변경되어도 아무 위젯도 rebuild 되지 않는다.","Provider.of(context) 로 값을 구독한 ValueCounter 위젯만 rebuild 된다.","BuildContext 가 무효화되어 Scaffold 부터 새로운 트리가 생성된다."]'::jsonb,'{"correct":2}'::jsonb),
    ('8ce15a4d4cbe52b65252b13dc19b5aba','["FutureBuilder 의 future 파라미터에는 Future 객체를 전달한다.","StreamBuilder 는 Future 객체를 구독하며 Stream 은 처리할 수 없다.","await 는 함수 전체를 블로킹해 UI 스레드를 멈추게 하는 동기 키워드다.","위젯 트리에 다시 삽입될 State 객체라도 dispose 는 build 직후마다 반드시 호출된다."]'::jsonb,'{"correct":0}'::jsonb),
    ('cddedd1c29a8e45692cb9c31fef45704','["initState 는 build 가 호출될 때마다 매번 다시 실행되어 상태를 재초기화한다.","initState 는 State 가 트리에 삽입될 때 한 번 호출되어 초기화를 수행하고, dispose 는 State 가 영구 제거될 때 호출되어 리소스를 해제한다.","dispose 는 setState 가 호출될 때마다 실행되어 이전 프레임의 상태를 정리한다.","initState 와 dispose 는 모두 State 객체가 처음 생성되는 시점에 연달아 호출되어 초기 설정과 정리 콜백 등록을 동시에 수행한다."]'::jsonb,'{"correct":1}'::jsonb),
    ('eba9c1e377f389d4b91d665077c6b0ac','["mainAxisAlignment 를 MainAxisAlignment.spaceBetween 으로 설정한다.","crossAxisAlignment 를 CrossAxisAlignment.stretch 로 설정해 자식을 세로로 늘인다.","Row 의 mainAxisSize 를 MainAxisSize.min 으로 설정해 자식들의 크기를 줄인다.","각 자식 위젯을 Expanded 로 감싸 가용 공간을 나눠 갖게 한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('3d98b0371f5359b70219bc700802b373','["상태 변경이 필요한 화면에는 StatelessWidget 을, 정적인 화면에는 StatefulWidget 을 사용한다.","변경 가능한 내부 상태가 있으면 StatefulWidget 을, 없으면 StatelessWidget 을 사용한다.","모든 위젯은 성능을 위해 항상 StatefulWidget 으로 작성해야 한다.","StatelessWidget 은 setState 호출로 자신의 필드 값을 갱신해 화면을 다시 그릴 수 있다."]'::jsonb,'{"correct":1}'::jsonb),
    ('fa951e4c67df5264ccd0192174782c8c','["Positioned 위젯의 top 과 left 속성을 0 으로 설정해 아이콘을 배치한다.","Positioned 위젯의 top 과 left 속성을 각각 화면 높이와 너비의 절반 값으로 설정해 아이콘을 배치한다.","Stack 의 alignment 를 Alignment.center 로 설정하고 아이콘을 Positioned 없이 자식으로 둔다.","Stack 대신 Expanded 위젯으로 아이콘을 직접 감싸 중앙에 배치한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('6c0c12f6b83fc12e8301d2d172f710e2','["모든 항목 위젯을 리스트 생성 시점에 한꺼번에 만들어 메모리에 캐시해 둔다.","화면에 보일 항목만 필요한 시점에 itemBuilder로 생성한다.","각 항목 위젯을 별도 isolate에서 병렬로 빌드한다.","itemExtent를 지정하지 않으면 항목을 자동으로 압축해 메모리 사용량을 줄인다."]'::jsonb,'{"correct":1}'::jsonb),
    ('0c106db59a556a13da7f4424094b219f','["Navigator의 push 메서드는 현재 스택에 있는 모든 라우트를 제거한 뒤 새 라우트를 넣는다.","Navigator의 pop 메서드는 스택의 가장 아래에 있는 첫 번째 라우트를 제거한다.","Navigator의 push 메서드는 새로운 라우트를 스택 맨 위에 추가하여 해당 화면으로 전환한다.","Navigator의 pop 메서드는 남은 스택 깊이와 무관하게 항상 첫 화면으로 즉시 이동한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('e95222b943139e744f248384d5b0e7bb','["상태를 앱 재시작 후에도 유지되도록 SharedPreferences에 자동으로 직렬화해 저장한다.","하위 위젯의 build 메서드를 별도 isolate에서 비동기로 실행해 성능을 높인다.","ChangeNotifier 인스턴스를 하위 트리에 제공하고, notifyListeners() 호출 시 이를 구독(watch)하는 위젯을 다시 빌드하게 한다.","하위 위젯의 setState 호출을 가로채 한 프레임으로 병합한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('ceb69687398ddf8d580ae7bd408cc34f','["Container 위젯의 크기","Stack 위젯의 크기","화면 전체의 크기","가장 가까운 Scaffold body의 크기"]'::jsonb,'{"correct":1}'::jsonb),
    ('8d43d15277d610538bbd91dace98efa7','["isolate는 Dart VM에서 메모리를 공유하지 않는 별도의 실행 컨텍스트이며, 메인 isolate와는 SendPort/ReceivePort로 메시지를 주고받는다.","이벤트 루프는 비동기 작업이 완료될 때마다 이벤트를 처리하며, 동기 코드가 실행되는 동안에도 큐의 이벤트를 계속 꺼내 처리한다.","isolate는 프로그램의 전체 생명주기를 관리하며, 메인 isolate에서 생성된 모든 isolate는 자동으로 종료된다.","이벤트 루프는 비동기 작업을 큐에 넣어 처리하지만, 이벤트가 발생하지 않으면 이벤트 루프 자체가 영구히 중단된다."]'::jsonb,'{"correct":0}'::jsonb),
    ('41f1424fac32bb07c1de545cb4750ea1','["Platform Channel로 네이티브 권한 요청 코드를 호출한다.","permission_handler 패키지의 request()를 사용한다.","firebase_messaging의 requestPermission()으로 알림 권한을 요청한다.","shared_preferences에 권한 상태 플래그를 저장한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('7d660c2470733049ebf66670219e2c5f','["Riverpod의 프로바이더는 위젯 트리 바깥에 선언되며, BuildContext 없이도 상태를 읽을 수 있다.","Riverpod는 상태가 하나라도 변경되면 앱의 전체 위젯 트리를 루트부터 다시 빌드해 일관성을 보장한다.","Provider는 InheritedWidget을 사용하지 않지만 Riverpod는 InheritedWidget에 의존한다.","Riverpod의 프로바이더는 StatefulWidget 내부에서만 선언하고 사용할 수 있다."]'::jsonb,'{"correct":0}'::jsonb),
    ('5c652a2df2dab9d5759eb2d9ec6c3ef3','["하나의 경로(String)만 필요합니다.","이전 화면으로 돌아가는 방법과 함께 두 개 이상의 경로가 필요합니다.","이동할 페이지에서 전달할 인자와 함께 하나의 경로가 필요합니다.","새로운 라우트를 생성하기 위한 클래스 정의가 필요합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('8159b7f03e3ece53dab26cb1990f5060','["하위 자식들의 요구(constraints)를 기반으로 결정","상위 부모의 크기를 그대로 상속받음","하위 자식의 크기와 무관하게 고정된 값","상위 부모의 크기에 비례하여 확장"]'::jsonb,'{"correct":3}'::jsonb),
    ('346e484401e378c5e3e4ae5a0219878b','["closeSocketConnection(); 뒤에 super.dispose();를 추가한다.","super.dispose(); 뒤에 closeSocketConnection();를 추가한다.","코드에서 fetchUserData()를 제거한다.","코드를 수정하지 않고도 누수가 발생하지 않는다."]'::jsonb,'{"correct":0}'::jsonb),
    ('f10776799b67a05209c0c52e446ee3b4','["updateShouldNotify가 항상 false를 반환해 의존 위젯에 갱신이 통지되지 않는다.","InheritedWidget의 필드는 final로 선언할 수 없으므로 data 선언 자체가 잘못되어 값 비교가 항상 실패한다.","생성자가 const로 선언되어 있어 데이터 변경이 프레임워크에 감지되지 않는다.","child를 super 생성자에 넘기면 하위 위젯이 트리에서 분리되어 갱신을 받지 못한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('b53c76df63466b0c521c0176e7150fb2','["Expanded 위젯","Flexible 위젯","Center 위젯","Positioned 위젯"]'::jsonb,'{"correct":3}'::jsonb),
    ('b2d9bfee64210736f55c94101ea4719a','["위젯 트리는 Stack 위젯의 자식으로 정확히 위치 지정된 이미지와 빨간색 컨테이너가 포함됩니다.","위젯 트리에서 이미지는 항상 화면 중앙에 위치하며, 컨테이너는 왼쪽 상단 50px, 100px에 위치합니다.","위젯 트리는 정확히 지정된 위치에 빨간색 컨테이너만을 포함합니다.","위젯 트리에서 이미지는 화면 전체를 차지하고 컨테이너는 왼쪽 상단 50px, 100px에 위치합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('92d8157d46619a0965997680da85a60a','["MyWidget은 StatefulWidget처럼 내부 상태를 setState로 변경할 수 있습니다.","const 키워드로 생성하지 않으면 MyWidget의 필드 값은 생성 이후에도 자유롭게 변경할 수 있는 가변 상태가 됩니다.","const로 생성하면 build 메서드는 최초 한 번도 호출되지 않습니다.","부모가 다시 빌드될 때 const로 생성된 동일 인스턴스는 재사용되어 불필요한 rebuild를 건너뛸 수 있습니다."]'::jsonb,'{"correct":3}'::jsonb),
    ('1cd91500fa3ca86fec2f731e3b9c3e50','["Container 위젯에서 height 속성을 제거한다.","ListTile 위젯을 사용하도록 itemBuilder 메소드를 수정한다.","ListView.builder에서 count 대신 itemCount를 사용한다.","itemBuilder 메서드에서 setState 호출을 제거한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('e3f9ff9e79f8b1e9d1f4c6f336986027','["increment()의 setState 호출은 _CounterState의 build를 다시 실행하게 하여 변경된 count가 화면에 반영됩니다.","setState 없이 count++만 실행해도 다음 프레임에서 화면이 자동으로 갱신됩니다.","setState는 count 값을 변경하지만 build가 반환하는 Text는 이전 값을 유지합니다.","setState의 콜백은 다음 프레임이 그려진 뒤 비동기로 실행되므로 count 증가가 한 프레임 늦게 반영됩니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('a6c0bd2bab7043c8ff07be8b6340c6e0','["비동기 작업이 완료되면 ''Loading...''이라는 텍스트가 계속 표시됩니다.","비동기 작업 중 오류 발생 시 에러 메시지가 화면에 표시됩니다.","비동기 작업이 성공적으로 완료되어도 화면에는 항상 ''No data available''이 표시됩니다.","비동기 작업이 완료되지 않은 동안에는 ''Awaiting connection...''이라는 텍스트만 표시됩니다."]'::jsonb,'{"correct":1}'::jsonb),
    ('85f1d84ec7e84b67705916466b47e789','["memory limits(1Gi)가 requests(2Gi)보다 작아 Pod 생성이 거부된다.","restartPolicy를 지정하지 않으면 컨테이너가 종료 후 다시 시작되지 않는다.","containers 항목이 하나뿐이라 Pod 스펙 검증을 통과하지 못한다.","이미지에 태그를 명시하면 Pod를 생성할 수 없다."]'::jsonb,'{"correct":0}'::jsonb),
    ('278c3c7089573720a8f8ed87baa7630b','["자주 바뀌는 소스 코드의 COPY 단계를 의존성 설치 단계 뒤에 배치한다.","COPY . . 명령을 Dockerfile의 첫 단계에 두어 모든 파일을 먼저 복사해 둔다.","매 빌드마다 --no-cache 옵션을 사용해 캐시를 새로 만든다.","베이스 이미지 태그를 빌드마다 변경해 캐시 충돌을 예방한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('0cc6d00ddb6dc177f2e522b21588eaca','["blue-green 배포","canary 배포","rolling 배포","big-bang 배포"]'::jsonb,'{"correct":1}'::jsonb),
    ('faccd9ed45fc72344ee9f1f61268e33d','["Counter","Gauge","Histogram","Summary"]'::jsonb,'{"correct":0}'::jsonb),
    ('7084b2d20ebc92793e72f3d1123778e9','["서비스 중단 시간 발생","데이터 손실 위험","스케일링 이슈","노드 리소스 오버헤드"]'::jsonb,'{"correct":3}'::jsonb),
    ('08f34f674c63d6988a28559a557188fc','["livenessProbe","readinessProbe","startupProbe","execProbe"]'::jsonb,'{"correct":1}'::jsonb),
    ('e40ea65fa40e9e844ef04f9cfe6c6fca','["ADD","COPY","RUN","SHELL"]'::jsonb,'{"correct":1}'::jsonb),
    ('d6303b0f21611338089118ecd0ee0747','["selector가 Pod 라벨(app: web)과 일치하지 않아 엔드포인트가 생성되지 않고 트래픽이 전달되지 않는다.","targetPort는 port와 반드시 같은 값이어야 하므로 8080을 지정하면 Service 생성이 거부된다.","type 필드를 생략하면 Service가 생성되지 않는다.","port 80은 시스템 예약 포트라 Service에서 사용할 수 없다."]'::jsonb,'{"correct":0}'::jsonb),
    ('90d43e64016dda2b14e8a32c1842356e','["볼륨은 Docker가 관리하는 저장 영역에 데이터를 두고, 바인드 마운트는 호스트의 특정 경로를 직접 지정해 연결한다.","볼륨은 컨테이너 삭제 시 항상 함께 삭제되지만, 바인드 마운트는 컨테이너와 무관하게 데이터가 남는다.","바인드 마운트는 읽기 전용으로만 사용할 수 있고, 볼륨은 읽기와 쓰기가 모두 가능하다.","볼륨은 리눅스 호스트에서만 동작하고, 바인드 마운트는 모든 운영체제에서 동작한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('dba9c2ebca827a5745c9d8d6bc119461','["컨테이너가 응답 불능(교착) 상태에 빠지면 kubelet이 자동으로 재시작하도록 하고 싶을 때.","초기화를 마치고 준비가 끝난 Pod만 Service의 트래픽 대상에 포함시키고 싶을 때.","Pod의 CPU 사용량에 따라 복제본 수를 자동으로 조절하고 싶을 때.","컨테이너 기동이 오래 걸려 초기 기동 동안 다른 프로브 검사를 유예하고 싶을 때."]'::jsonb,'{"correct":1}'::jsonb),
    ('140c5c981027f9aace424474289d7ad3','["실행 중인 컨테이너가 교착 상태에 빠졌는지 주기적으로 확인해 재시작을 유발한다.","서비스 준비 상태를 확인하고 요청을 받아들일 수 있는지 여부를 결정한다.","초기화가 긴 컨테이너의 기동이 끝날 때까지 liveness·readiness 검사를 유예한다.","리소스 사용량을 모니터링하여 과부하를 감지한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('dc6d886e0c7822eb8da126636c1da256','["시크릿(비밀 값)을 Git에 평문으로 둘 수 없어 별도의 시크릿 관리 방안이 필요하다.","커밋 이력이 배포 상태와 무관하게 저장되므로 이전 상태로의 롤백을 전혀 지원하지 않는다.","선언형 매니페스트를 사용할 수 없어 모든 배포를 명령형 스크립트로 작성해야 한다.","Argo CD나 Flux 같은 도구와 함께 사용할 수 없다."]'::jsonb,'{"correct":0}'::jsonb),
    ('8c7b822c4729ee2937bc6b0b91432aa4','["컨테이너가 삭제돼도 데이터베이스 데이터를 Docker가 관리하는 저장소에 영속적으로 보존해야 할 때.","컨테이너 이미지의 크기를 줄여야 할 때.","호스트의 소스 코드 디렉터리를 경로 그대로 컨테이너에 노출해 편집 내용을 즉시 반영해야 할 때.","이미지 빌드 시 레이어 캐시를 최대한 활용해야 할 때."]'::jsonb,'{"correct":0}'::jsonb),
    ('280f9e0e119d271eafc6a5a2d68ca050','["livenessProbe 실패는 컨테이너 재시작을 유발하고, readinessProbe 실패는 Service 트래픽 대상에서 제외를 유발한다.","livenessProbe는 Pod가 배치된 노드의 하드웨어 상태를 확인하고, readinessProbe는 클러스터 전체의 네트워크 상태를 확인한다.","livenessProbe는 HTTP 방식만 지원하고, readinessProbe는 TCP 방식만 지원한다.","readinessProbe가 실패하면 Pod가 즉시 삭제되고 새 Pod가 생성된다."]'::jsonb,'{"correct":0}'::jsonb),
    ('ead3645c35280131d4b24c7f5da6191b','["kubectl apply -f deployment.yaml","kubectl rollout status deployment/name","kubectl set image deployment/name container=image:tag","kubectl rollout undo deployment/name"]'::jsonb,'{"correct":2}'::jsonb),
    ('f0ca854f6ab2e8090c288b169253e4d2','["하나의 환경 안에서 Pod를 순차적으로 교체하며 구버전과 신버전 Pod에 트래픽이 섞여 들어가게 한다.","새로운 버전만 먼저 실행한 후 기존 버전 환경을 즉시 삭제해 롤백 경로를 없앤다.","기존 애플리케이션을 완전히 중지한 다음 새로운 버전으로 대체한다.","두 환경을 나란히 두고 새 환경 검증이 끝나면 트래픽을 한 번에 새 환경으로 전환한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('ea32e8a412a239f4fb1975195fff115d','["소스 전체를 먼저 복사한 뒤 의존성을 설치해, 코드가 한 줄만 바뀌어도 npm install 레이어 캐시가 무효화된다.","WORKDIR 명령은 반드시 모든 COPY 뒤에 위치해야 하므로 이 순서로는 이미지 빌드 자체가 실패한다.","CMD는 배열(exec) 형식을 사용할 수 없어 컨테이너가 시작되지 않는다.","FROM에 태그를 지정하면 레이어 캐시를 사용할 수 없다."]'::jsonb,'{"correct":0}'::jsonb),
    ('f3a86752d891cdfe5598d0f34841b619','[".dockerignore 파일에 해당 경로를 추가해 빌드 컨텍스트에서 제외한다.","이미지 빌드 시마다 --no-cache 옵션으로 모든 레이어를 새로 만든다.","CMD 명령을 ENTRYPOINT로 바꿔 실행 시점에 해당 파일을 무시하게 한다.","빌드가 끝난 뒤 컨테이너 안에서 해당 파일을 삭제하는 RUN 명령을 Dockerfile 마지막에 추가한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('4726413700989656e0da38ac842a3034','["Blue-Green 배포는 새로운 버전의 서비스를 실행시키지 않고 기존 서비스만 제자리에서 업데이트한다.","Canary 배포는 전체 트래픽을 단번에 새 서비스로 이동시킨다.","Blue-Green 배포는 두 환경을 나란히 두고 검증 후 트래픽을 전환하며, Canary 배포는 일부 트래픽만 새 버전으로 보내 점진적으로 확대한다.","Canary 배포는 트래픽 비율을 조절하지 않고 항상 절반씩 고정 분배하며, Blue-Green 배포는 Pod를 하나씩 순차 교체해 두 버전이 섞이는 것을 전제로 한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('4260b4fc0372f3d428358b1f65aa8bc0','["RUN 명령을 최대한 여러 개로 쪼개 레이어 수를 늘린다.","이미지 빌드 시마다 --no-cache 옵션으로 항상 새로 빌드한다.","볼륨 마운트를 사용하여 실행 시점의 변경 사항을 반영한다.",".dockerignore 파일로 빌드 컨텍스트의 불필요한 파일을 배제한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('cac78c3b81ae53ba257d583d055463b5','["myapp:1.0 이미지를 컨테이너로 실행한다.","현재 디렉터리를 빌드 컨텍스트로 삼아 Dockerfile로 이미지를 빌드하고 myapp:1.0 태그를 붙인다.","myapp:1.0 이미지를 원격 레지스트리에 업로드한다.","로컬의 기존 myapp 이미지와 파일을 비교해 달라진 파일만 담은 증분 이미지를 별도로 생성한다."]'::jsonb,'{"correct":1}'::jsonb),
    ('10ce777f9b3a88adcd1331d54c3118d7','["컨테이너를 루트 권한으로 실행한다","빌드 도구와 캐시 파일을 디버깅 편의를 위해 최종 이미지에 그대로 남겨 둔다","멀티 스테이지 빌드로 빌드 단계의 산출물만 최종 이미지에 복사한다","실행 중인 도커 인스턴스 수를 늘린다"]'::jsonb,'{"correct":2}'::jsonb),
    ('e45db7d8526b88d41154a397d101e687','["두 환경을 동시에 운영할 필요가 없어 인프라 비용이 절감된다","이전 버전 환경이 그대로 남아 있어 트래픽 전환만으로 빠르게 롤백할 수 있다","데이터베이스 스키마 동기화 문제가 자동으로 해결된다","구버전과 신버전 파드가 섞인 채 순차 교체되므로 추가 자원이 거의 들지 않는다"]'::jsonb,'{"correct":1}'::jsonb),
    ('fc0abb8ed87653fe9f0eaea9fb00ac34','["HPA는 metrics server 없이도 기본적으로 CPU 사용률 지표를 수집한다","HPA는 파드 수 대신 개별 파드의 CPU·메모리 요청량(requests)을 조정한다","HPA는 minReplicas 설정과 무관하게 파드를 0개까지 자동으로 축소한다","HPA는 autoscaling/v2부터 CPU 외에 메모리·커스텀 메트릭 기준으로도 스케일링할 수 있다"]'::jsonb,'{"correct":3}'::jsonb),
    ('0e1e76b3b31fa03d16d68b0026a2065b','["Canary Release","Blue-Green Deployment","Rolling Update","Recreate Deployment"]'::jsonb,'{"correct":1}'::jsonb),
    ('10ea8a277b54755b34a45a62b12326ae','["Gauge는 한 번 기록되면 감소할 수 없는 누적 측정값이다","Histogram은 관측된 원시 값을 모두 저장해 서버가 임의의 분위수를 정확히 계산한다","Counter는 감소하지 않으며, 프로세스 재시작 시 0으로 리셋될 수 있는 누적 값이다","Summary가 클라이언트에서 계산한 분위수는 여러 인스턴스에 걸쳐 평균 내어 합산해도 유효하다"]'::jsonb,'{"correct":2}'::jsonb),
    ('fbc9d661a00ad9bc3eaa458babdc2b8d','["Pod는 일회성 배치 작업 전용이고, 지속 서비스는 Deployment가 컨테이너를 직접 실행한다","Deployment는 ReplicaSet을 통해 Pod 집합의 선언적 배포·스케일링을 관리하고, Pod는 하나 이상의 컨테이너를 묶은 최소 배포 단위다","Pod는 복수의 컨테이너를 포함할 수 있지만, Deployment는 단일 컨테이너 Pod만 관리할 수 있다","Deployment를 삭제해도 그것이 생성한 Pod들은 기본 설정에서 계속 실행된다"]'::jsonb,'{"correct":1}'::jsonb),
    ('9442ff711f5b640caec61d7cfade28b4','["Prometheus","Grafana","Kibana","Jenkins"]'::jsonb,'{"correct":0}'::jsonb),
    ('d4e2594c0d8537cb25f53ee7100466ae','["이미지 빌드 시점에 npm start를 실행해 그 결과를 이미지에 굽는다","컨테이너 시작 시 실행할 기본 명령을 지정하며, docker run에서 다른 명령을 주면 대체된다","빌드 결과 이미지에 npm 의존성 패키지를 설치한다","컨테이너가 종료될 때 실행할 정리 명령을 등록한다"]'::jsonb,'{"correct":1}'::jsonb),
    ('055237abf1008503f0d80a4f5e157883','["replica 개수 설정이 잘못되었습니다.","selector와 template의 라벨이 일치하지 않습니다.","containerPort가 정확하게 지정되지 않았습니다.","deployment에 대한 resource limit이 누락되었습니다."]'::jsonb,'{"correct":3}'::jsonb),
    ('d2ac780a2082e6c7226c15e593b61a8e','["minReplicas(2)가 maxReplicas(6)보다 커서 스케일링 범위가 유효하지 않습니다.","targetCPUUtilizationPercentage는 autoscaling/v1 전용 필드라서, v2beta2에서는 metrics 배열로 지정해야 합니다.","spec 아래에는 scaleTargetRef를 둘 수 없으므로 제거해야 합니다.","CPU 사용률은 HPA가 지원하지 않는 메트릭 종류입니다."]'::jsonb,'{"correct":1}'::jsonb),
    ('56019a3f6933d9e0ee57560721c6c145','["최종 이미지 크기가 절반 이하로 줄어들기 때문","package.json을 나중에 복사하면 npm install이 아예 실행되지 않기 때문","소스 코드만 변경된 경우 npm install 레이어의 캐시를 재사용해 빌드 시간을 줄이기 위해","COPY . . 명령이 node_modules 디렉터리를 덮어쓰는 것을 방지하기 위해"]'::jsonb,'{"correct":2}'::jsonb),
    ('3d2d3934947ef3358c7a987260f27dec','["web 하나의 서비스만 정의하며 db는 외부 클러스터에 대한 참조다","web 컨테이너와 db 컨테이너를 병합해 하나의 컨테이너에서 단일 프로세스로 실행하도록 정의한다","postgres 이미지를 베이스 이미지로 삼아 web 이미지를 다시 빌드하도록 정의한다","현재 디렉터리에서 빌드하는 web 서비스와 postgres 이미지를 사용하는 db 서비스, 두 개의 서비스를 정의한다"]'::jsonb,'{"correct":3}'::jsonb),
    ('37251c2ba9a05d281b2f8dca2177123a','["ReplicaSet이 생성되고 ''another-app'' 라벨을 가진 Pod 3개가 정상적으로 만들어집니다.","selector가 template의 라벨과 일치하지 않아 API 서버가 생성 요청 자체를 거부합니다.","ReplicaSet이 생성되고 ''example-app'' 라벨을 가진 Pod 3개가 만들어집니다.","ReplicaSet은 생성되지만 라벨은 무시하고 이름 기준으로 Pod를 관리합니다."]'::jsonb,'{"correct":1}'::jsonb),
    ('1b006fbf1c87f2610532f211a142d738','["소스 코드가 한 줄이라도 바뀌면 npm install 레이어까지 항상 다시 실행된다","package.json이 변경되지 않는 한 npm install 레이어는 캐시에서 재사용된다","컨테이너를 시작할 때마다 모든 노드 모듈이 다시 설치된다","COPY . . 명령은 캐시를 사용할 수 없어 매 빌드마다 베이스 이미지 전체를 새로 내려받는다"]'::jsonb,'{"correct":1}'::jsonb),
    ('fdbd5ff9f94be230aa52e3d91c44e906','["Pod가 생성되면 즉시 시작됩니다.","readinessProbe가 성공하면 시작됩니다.","initialDelaySeconds 이후에 시작됩니다.","periodSeconds마다 시작합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('bec70924d0a90a0f2abedc2b4e1b955f','["Dockerfile는 ''npm start'' 명령으로 애플리케이션을 시작합니다.","Dockerfile는 ''node server.js'' 명령으로 애플리케이션을 시작합니다.","Dockerfile는 ''npm run build'' 명령으로 애플리케이션을 빌드한 후 실행하지 않습니다.","Dockerfile는 이미지를 생성할 때 ''npm install''과 ''npm run build''를 모두 수행합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('71144bff57968c429cbe6994beb43ad6','["Secret은 암호화되어 저장되므로 안전하다.","Secret이 정상적으로 생성되지만, type 설정이 잘못되어 암호화되지 않는다.","Secret 데이터는 base64로 인코딩되어 있어 애플리케이션에서 직접 사용할 수 없다.","Secret은 정상적으로 생성되며, 애플리케이션이 이를 참조하여 환경 변수로 설정한다."]'::jsonb,'{"correct":3}'::jsonb),
    ('193ecf16025ef31ce1f784d3fd751a08','["페이로드가 암호화되어 있어 발급자 외에는 아무도 내용을 읽을 수 없기 때문","비밀키(또는 개인키)로 생성된 서명을 검증해 토큰의 위변조 여부를 확인할 수 있기 때문","JWT는 프로토콜상 HTTPS로만 전송되도록 강제되어 있기 때문","서버가 발급한 모든 토큰을 데이터베이스에 저장해 두고 매 요청마다 원본과 대조하기 때문"]'::jsonb,'{"correct":1}'::jsonb),
    ('530c21aee1cd808cb94b55c74c23825d','["세션 식별자를 HttpOnly 속성이 설정된 쿠키에 담아 스크립트에서 읽을 수 없게 한다.","JWT를 localStorage에 저장하고 매 요청마다 자바스크립트로 읽어 헤더에 담는다.","토큰을 URL 쿼리 스트링에 붙여 페이지 간에 전달한다.","HttpOnly 없이 document.cookie로 접근 가능한 쿠키에 토큰을 저장하고 스크립트로 관리한다."]'::jsonb,'{"correct":0}'::jsonb),
    ('e51e4d9c079a34eccb65e1bbb7b7ab9e','["데이터의 일관성이 중요한 경우","속도와 가용성 요구사항이 높은 경우","복잡한 계층 구조가 필요한 경우","다중 연결 관계가 있는 데이터 모델링 시"]'::jsonb,'{"correct":0}'::jsonb),
    ('17538fe8e4233834e67eae3f514b8528','["UNIQUE 인덱스","CLUSTERED 인덱스","NONCLUSTERED 인덱스","FULLTEXT 인덱스"]'::jsonb,'{"correct":3}'::jsonb),
    ('2f4cc6a775d4c9e8382639e2bb4dba73','["408 Request Timeout","504 Gateway Timeout","502 Bad Gateway","500 Internal Server Error"]'::jsonb,'{"correct":1}'::jsonb),
    ('726357db3732f1e4753af9862ebc56b0','["Authorization 헤더에 담아 전송","HttpOnly 쿠키에 담아 전송","URL 쿼리 스트링에 담아 전송","POST 요청 본문에 담아 전송"]'::jsonb,'{"correct":2}'::jsonb),
    ('facbd0ce51bdcfd5cf663a71f47b4538','["HttpOnly 쿠키 기반의 서버측 세션을 사용한다.","만료 시간이 짧은 액세스 토큰과 리프레시 토큰을 함께 사용한다.","사용자 암호를 브라우저에 평문으로 저장해 두고 매 API 요청에 함께 전송한다.","OAuth 2.0 인가 코드 플로우로 외부 신원 제공자에 인증을 위임한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('736a905b128c64a603c72576e771e57a','["각 사용자 브라우저에 적용되는 클라이언트 측 캐싱","응답 결과를 Redis 등 서버 사이드 캐시에 저장해 두고 DB 조회 없이 반환","게시글 테이블에 데이터베이스 인덱스 추가","모든 요청에 대한 처리 로직 단순화"]'::jsonb,'{"correct":1}'::jsonb),
    ('84fd8002f099db505f2a9f318a678813','["세션 식별자(세션 ID)만 담기고, 실제 세션 데이터는 서버측 저장소(메모리·Redis·DB 등)에 보관된다.","직렬화된 세션 데이터 전체가 쿠키에 담긴다.","사용자 암호의 해시값이 담긴다.","서버가 세션 서명에 쓰는 비밀키가 함께 담긴다."]'::jsonb,'{"correct":0}'::jsonb),
    ('8b770428d2ac952f1c151cccb6621742','["서브도메인 기반 (v1.example.com)","쿼리 파라미터 기반 (/api/v1/resource)","헤더 기반 (X-API-Version)","path 인자 기반 (/v1/api/resource)"]'::jsonb,'{"correct":3}'::jsonb),
    ('8cbabb48e5db2d2e279bf1655ed8b9b6','["무조건 로그아웃 처리하고 새로 로그인하라는 메시지를 띄운다","리프레시 토큰으로 새 액세스 토큰을 발급받은 뒤 실패했던 요청을 재시도한다","만료된 액세스 토큰을 그대로 계속 전송해 서버가 자동으로 유효기간을 연장하게 한다","액세스 토큰의 exp 클레임을 프론트엔드에서 미래 시각으로 수정해 다시 사용한다"]'::jsonb,'{"correct":1}'::jsonb),
    ('3238143fd2ce84c4eae500ea824a2b08','["200 OK","302 Found","401 Unauthorized","500 Internal Server Error"]'::jsonb,'{"correct":2}'::jsonb),
    ('59ff6a635069bc55520b9b9950d1fecc','["네트워크 장애가 발생해도 catch 블록이 실행되지 않아 오류가 유실된다.","response.ok 를 확인하지 않아 4xx/5xx 오류 응답도 성공 경로로 처리된다.","fetch 는 method 옵션으로 GET 을 지정할 수 없다.","response.json() 은 동기 함수라서 then 콜백 안에서 호출할 수 없다."]'::jsonb,'{"correct":1}'::jsonb),
    ('ccf77e263003b2f98ae40b8f25bfe2c7','["트랜잭션 안에서 사용자의 마지막 로그인 시각을 갱신해 저장합니다.","사용자의 모든 데이터를 삭제합니다.","런타임 예외가 발생해도 변경 사항이 롤백되지 않고 그대로 커밋됩니다.","HTTP 요청을 직접 수신해 파싱하고 처리합니다."]'::jsonb,'{"correct":0}'::jsonb),
    ('5bf200d5243c39200c39e992a96f7251','["SELECT * 를 SELECT email 로 바꿔 반환 컬럼 수를 줄인다.","WHERE 절에서 status 조건을 제거해 비교 횟수를 줄인다.","email(과 status) 컬럼에 인덱스를 생성해 인덱스 스캔이 가능하게 한다.","테이블을 비정규화해 users 데이터를 여러 테이블에 복제한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('0e15e85c7faff384caac8e65ff5dca57','["API 는 POST 요청도 이 핸들러로 받아 동일하게 사용자 목록을 반환합니다.","GET 요청이 성공해도 응답 본문 없이 상태 코드만 반환됩니다.","GET 요청은 항상 500 Internal Server Error 를 반환합니다.","GET 요청이 성공하면 200 OK 와 함께 사용자 목록이 반환됩니다."]'::jsonb,'{"correct":3}'::jsonb),
    ('6ce3687e801d7b4bff26ef6e4ab6313e','["트랜잭션이 예외 발생 시 롤백되지 않는다.","메서드명에서 saveUser 대신 save를 사용해야 한다.","userRepository에 대한 의존성 주입이 누락되었다.","@Transactional 어노테이션을 사용했지만, 예외가 발생해도 항상 롤백된다."]'::jsonb,'{"correct":3}'::jsonb),
    ('48582d6fec2b21641797eca9348c88cf','["이 엔드포인트는 항상 ''DOWN'' 상태를 반환한다.","실제 데이터베이스 연결을 검사하지 않고 ''connected'' 를 하드코딩해 반환한다.","Health 객체는 JSON 으로 직렬화될 수 없어 호출이 항상 실패한다.","withDetail 로 추가한 세부 정보는 응답 본문에서 항상 제외된다."]'::jsonb,'{"correct":1}'::jsonb),
    ('a47b560a52f123ff026c87c07f0f608c','["쿼리 자체가 인증된 사용자의 로그인 세션을 생성한다.","비밀번호가 일치하지 않아도 username 이 일치하면 해당 사용자의 행을 반환한다.","입력 비밀번호의 해시가 저장된 값과 일치하는 행만 반환해 자격 증명을 확인한다.","저장된 비밀번호 해시를 평문 암호로 복호화해 반환한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('16001bdc91e5a1f27359cc49811feb8c','["NullPointerException 을 try-catch 로 잡은 뒤 null 을 그대로 반환한다.","메서드 시그니처에 throws NullPointerException 을 선언해 예외를 컨테이너로 전파한다.","user == null 이면 @ResponseStatus(HttpStatus.NOT_FOUND) 가 붙은 ResourceNotFoundException 을 던진다.","컨트롤러 메서드에 @ResponseStatus(HttpStatus.NOT_FOUND) 를 직접 붙여 응답 상태를 지정한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('92e9c5cc28e84dcfce9b8085a1b136f8','["네트워크 오류가 발생하면 이 코드가 오류를 잡아 사용자에게 알린다.","응답이 4xx/5xx 상태 코드이면 fetch 프라미스가 자동으로 reject 된다.","Authorization 헤더에 Bearer 토큰을 담아 요청을 전송한다.","토큰이 만료되면 fetch 가 자동으로 토큰을 갱신한 뒤 재요청한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('16be21c30acd55fd79f122b9b2647471','["WSGI는 동기 호출뿐 아니라 WebSocket 같은 장수명 연결도 표준 스펙 차원에서 기본 지원하므로, ASGI와 기능상 차이가 없다.","ASGI는 이름과 달리 실제로는 WSGI와 동일하게 동기 방식의 호출만 지원하고 비동기 프로토콜은 다루지 못한다.","WSGI는 HTTP 요청 응답 프로토콜을 사용하며, ASGI는 HTTP 및 WebSocket 연결을 동시에 처리할 수 있다.","ASGI는 WSGI와 마찬가지로 HTTP 요청·응답 프로토콜만 지원하며 WebSocket 같은 장수명 연결은 다루지 못한다."]'::jsonb,'{"correct":2}'::jsonb),
    ('b5b900da9496d3aaeb1e923f62ae45b9','["iterator()로 이미 한 번 순회했으므로 그 결과가 내부 결과 캐시에 자동으로 남아, 두 번째 루프는 추가 쿼리 없이 캐시된 결과만 그대로 재사용한다고 오해하기 쉽다. 실제로는 iterator가 캐시를 아예 만들지 않는다.","iterator()는 내부 결과 캐시를 채우지 않으므로 두 번째 for 루프는 쿼리셋을 처음부터 다시 평가한다. 이때 주문 목록 조회 1번과 prefetch_related에 의한 items 일괄 조회 1번, 총 2번의 추가 쿼리가 실행되며, order.items.count()는 채워진 prefetch 캐시의 길이를 반환하므로 건당 추가 쿼리는 없다.","iterator()를 한 번이라도 호출한 쿼리셋은 그 뒤로 완전히 재사용이 금지되어 두 번째 순회를 시도하는 시점에 곧바로 예외가 발생한다고 잘못 알려져 있다. 실제로는 재평가가 일어날 뿐 예외는 없다.","prefetch_related는 iterator() 사용 여부와 완전히 무관하게 항상 내부적으로 결과를 캐시해두므로, 두 번째 순회에서도 캐시된 prefetch 결과가 재사용되어 추가 쿼리가 전혀 발생하지 않는다고 오해하기 쉽다."]'::jsonb,'{"correct":1}'::jsonb),
    ('2774f115d7a678ed7b963b7ca4a326dc','["select_related(''coupon'')는 coupon 필드가 null인 주문을 만나는 순간 예외를 던져버려서 이 쿼리 자체가 실행 도중 실패한다고 오해하기 쉽다. 실제로는 nullable FK에도 select_related가 정상적으로 동작한다.","coupon__campaigns가 역참조(reverse FK) 또는 M2M 관계라면 select_related가 따라갈 수 없는 경로이므로 쿼리셋 평가 시점에 FieldError(''Invalid field name(s) given in select_related'')가 발생한다. 이런 관계는 prefetch_related(''coupon__campaigns'')로 가져와야 한다.","coupon이 nullable FK이니 select_related가 항상 INNER JOIN을 강제해서 coupon이 없는 주문은 결과 집합에서 자동으로 완전히 제외되고 반환되지 않는다고 잘못 알려져 있다. 실제로는 LEFT OUTER JOIN을 사용한다.","select_related에 필드를 여러 개 한꺼번에 넘기면 두 번째 인자부터는 조용히 무시되어 coupon만 조인되고 campaigns는 애초에 요청조차 되지 않는다고 오해하기 쉽다. 실제로는 두 필드 모두 처리를 시도한다."]'::jsonb,'{"correct":1}'::jsonb)
  ) AS v(content_md5, expected_options, expected_answer_key)
  JOIN question_bank q
    ON md5(q.content) = v.content_md5
   AND q.options = v.expected_options
   AND q.answer_key = v.expected_answer_key;
  IF matched <> 155 THEN
    DECLARE
      crlf INTEGER; cr_only INTEGER; sample TEXT;
    BEGIN
      SELECT count(*) INTO crlf FROM question_bank
      WHERE content LIKE '%' || chr(13) || chr(10) || '%';
      SELECT count(*) INTO cr_only FROM question_bank
      WHERE content LIKE '%' || chr(13) || '%';
      -- id 694(useLayoutEffect 재작성)의 실제 저장 content 를 개행 마커로 노출
      SELECT replace(replace(substring(q.content, 1, 260), chr(13), '<CR>'), chr(10), '<LF>')
        INTO sample
      FROM question_bank q
      WHERE q.content LIKE '%useLayoutEffect%' LIMIT 1;
      RAISE EXCEPTION 'incomplete %/155 crlf_rows=% cr_rows=% sample=%',
        matched, crlf, cr_only, sample;
    END;
  END IF;
END
$qb_correct_202608221001$;
