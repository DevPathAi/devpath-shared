-- PYTHON_BACKEND 트랙 문항·콘텐츠·임베딩을 운영에 증분 적재한다.
--
-- 이것은 재시드(V202608131001)와 다르다 -- 그 마이그레이션은 기존 500행을
-- DELETE 하고 5트랙 전량을 재삽입했다. 이번은 기존 5트랙 행을 전혀 건드리지
-- 않고 PYTHON_BACKEND 신규 행만 INSERT 한다(증분).
--
-- 발췌 방법: learning-svc 의 makeQuestionSeedSql·makeContentSeedSql 이 승인
-- JSONL 전량(6트랙)을 sha256(normalize(content)) 정렬로 재생성한 시드 SQL에서
-- track='PYTHON_BACKEND' 인 튜플만 뽑았다. 전량을 넣으면 기존 5트랙이 중복
-- 삽입된다. question_bank·contents 튜플은 여러 줄(마크다운·코드 본문 포함)일
-- 수 있어 줄 단위가 아니라 "('...로 시작해 다음 '(' 로 시작하는 줄 직전까지"를
-- 튜플 경계로 파싱해 발췌했다(1행=1튜플 가정이 CODE_READING 문항·마크다운
-- 콘텐츠에서 깨지기 때문).
--
-- content_embeddings 도 시드 SQL에 포함돼 있었다(사전에는 "포함 안 될 수
-- 있다"고 봤으나 실제로는 contents INSERT 뒤에 슬러그별 별도 INSERT ... SELECT
-- 문으로 붙어 있음). PYTHON_BACKEND 30개 콘텐츠에 대응하는 임베딩 30건도
-- 함께 발췌했다(슬러그로 매칭, contents INSERT 이후에 실행되어야 함).
--
-- 원본: devpath-learning-svc/src/main/resources/db/seed/
--       question_bank_md2_seed.sql · content_md2_seed.sql
--       (승인 JSONL tools/content-gen/generated/approved/*.jsonl 에서 결정적으로 생성, HEAD 837bfc4)
--
-- 이 파일 옆의 .sql.conf(placeholderReplacement=false)가 없으면 콘텐츠 안의
-- ${...} 형태 텍스트를 Flyway 가 치환하려다 깨진다(2026-08-13 실측).

INSERT INTO question_bank (track, question_type, content, options, answer_key, bloom_level, difficulty, concept_tags) VALUES
('PYTHON_BACKEND','MCQ','WSGI와 ASGI의 주요 차이점은 무엇인가?','["WSGI는 요청마다 워커 스레드를 블로킹하는 동기 방식의 호출만 지원하며, 비동기·WebSocket 같은 프로토콜은 애초에 처리할 수 없는 구조다.","ASGI는 이름과 달리 실제로는 WSGI와 동일하게 동기 방식의 호출만 지원하고 비동기 프로토콜은 다루지 못한다.","WSGI는 HTTP 요청 응답 프로토콜을 사용하며, ASGI는 HTTP 및 WebSocket 연결을 동시에 처리할 수 있다.","ASGI는 WSGI와 마찬가지로 HTTP 요청·응답 프로토콜만 지원하며 WebSocket 같은 장수명 연결은 다루지 못한다."]','{"correct":2}','REMEMBER',0.1,'["wsgi-asgi"]'),
('PYTHON_BACKEND','MCQ','pytest 픽스처(fixture)의 정의와 목적은 무엇인가?','["픽스처는 테스트가 모두 끝난 뒤 실행 결과를 파일로 저장해 리포트를 생성하는 도구다.","픽스처는 pytest가 내부적으로 사용하는 변수·객체를 관리하는 별도의 설정 파일이다.","픽스처는 테스트 코드에서 공통적으로 사용되는 변수나 객체를 미리 준비해두는 함수이다.","픽스처는 프로젝트 설정 파일에 나열된 모든 단위 테스트를 실행하는 스크립트다."]','{"correct":2}','REMEMBER',0.1,'["pytest-fixtures"]'),
('PYTHON_BACKEND','MCQ','GIL(Global Interpreter Lock)의 주요 기능은 무엇인가?','["파이썬 인터프리터가 한 번에 하나의 스레드만 실행하게 만든다.","파이썬 코드에서 동기 호출을 비동기로 변환한다.","파이썬 코드를 컴파일하여 빠른 실행을 가능하게 한다.","파이썬 프로그램에서 동시에 여러 스레드를 실행할 수 있게 한다."]','{"correct":0}','REMEMBER',0.1,'["gil"]'),
('PYTHON_BACKEND','MCQ','Celery 워커(worker)와 브로커(broker, 예: Redis/RabbitMQ)의 역할은 무엇인가?','["워커는 작업을 실행하고 결과를 반환하며, 브로커는 작업 요청(메시지)을 전달하는 큐 역할을 한다.","브로커가 작업을 직접 실행해 결과를 반환하고, 워커는 그 작업 요청을 큐에 밀어 넣는 역할만 한다.","워커와 브로커는 역할 구분 없이 둘 다 똑같이 작업을 큐에 넣고 실행하는 동일한 컴포넌트다.","워커가 작업 요청을 처리하면서 동시에 브로커의 큐 역할까지 스스로 겸해서 수행한다."]','{"correct":0}','REMEMBER',0.1,'["celery-worker-broker"]'),
('PYTHON_BACKEND','MCQ','캐시 무효화(cache invalidation) 전략 중 TTL(Time To Live)의 의미는?','["TTL은 캐시가 담을 수 있는 최대 메모리 용량 한도를 의미하는 값이다.","TTL은 캐시 키가 만료될 시점만 미리 표시해둘 뿐, 실제로 그 시점에 캐시에서 제거하는 동작까지 보장하지는 않는다고 잘못 알려져 있다.","TTL은 캐시 키의 유효기간을 관리하며, 시간 제한이 경과되면 자동으로 캐시를 무효화한다.","TTL은 캐시가 만료되기 전까지 조회될 수 있는 최대 횟수를 세는 값이다."]','{"correct":2}','REMEMBER',0.1,'["cache-ttl"]'),
('PYTHON_BACKEND','MCQ','파이썬 제너레이터(`yield`)의 주요 특징은 무엇인가?','["함수 내부의 로컬 변수 상태를 유지하지 않는다.","함수 호출 시 함수 본체 코드가 즉시 실행된다.","제너레이터는 모든 값을 한 번에 계산해 반환하는 함수다.","함수가 여러 값을 순차적으로 반환할 수 있도록 한다."]','{"correct":3}','REMEMBER',0.2,'["generator"]'),
('PYTHON_BACKEND','MCQ','HTTP 상태 코드 401과 403의 의미 차이는 무엇인가요?','["401은 권한 없음(Forbidden)을, 403은 무효한 요청 메서드(Method Not Allowed)를 나타낸다.","401은 서버 내부에서 발생한 오류를, 403은 요청이 그냥 거절된 경우를 나타낸다.","401은 무효한 요청 메서드 사용을, 403은 서버가 무시해버린 권한 문제를 나타낸다.","401은 인증되지 않은 상태에서 접근 시도를 나타내며, 403은 사용자에게 권한이 없는 리소스에 대한 요청을 나타낸다."]','{"correct":3}','REMEMBER',0.2,'["http-status-codes"]'),
('PYTHON_BACKEND','MCQ','파이썬 컨텍스트 매니저(`with` 문)는 어떤 기능을 제공하는가?','["파일을 읽고 쓰는 동안 발생하는 모든 오류를 자동으로 무시해버린다.","특정 스코프에서 리소스를 안전하게 정리하거나 초기화할 수 있게 한다.","동기적으로 작성된 코드를 파이썬이 알아서 비동기 호출로 바꿔 실행해준다.","with 문을 쓰면 함수 실행 결과가 자동 캐싱되어 재사용된다."]','{"correct":1}','REMEMBER',0.2,'["context-manager"]'),
('PYTHON_BACKEND','MCQ','FastAPI에서 경로 매개변수(path parameter)를 선언하는 방법은 무엇인가요?','["경로 매개변수는 반드시 Query 클래스로 감싸서 지정해야만 인식된다고 잘못 알려져 있다.","path parameter는 @path_parameter 전용 데코레이터를 붙여야만 지정된다고 오해하기 쉽다.","경로 템플릿의 {변수명}과 이름이 같은 함수 매개변수를 선언하고 타입 힌트를 붙이면 FastAPI가 자동으로 경로 매개변수로 인식한다.","경로 매개변수는 path parameter라는 키워드를 함수 앞에 붙여야 설정된다고 오해하기 쉽다."]','{"correct":2}','REMEMBER',0.2,'["fastapi-path-parameters"]'),
('PYTHON_BACKEND','MCQ','파이썬 가상환경(venv)을 만드는 표준 명령어는 무엇인가요?','["pipenv shell","conda create --name myenv","python -m venv myenv","virtualenv myenv"]','{"correct":2}','REMEMBER',0.2,'["python-virtual-environment"]'),
('PYTHON_BACKEND','MCQ','파이썬 예외 계층에서 커스텀 예외를 정의할 때 어떤 규칙을 따라야 하는가?','["커스텀 예외는 적절한 부모 클래스를 상속 받아야 한다.","이름이 `Exception`으로 시작해야 인식된다.","반드시 object만 상속해야 한다고 잘못 알려져 있다.","`BaseException`만 직접 상속해야 한다고 오해한다."]','{"correct":0}','UNDERSTAND',0.3,'["custom-exception"]'),
('PYTHON_BACKEND','MCQ','Celery 태스크가 실패했을 때 자동으로 재시도되도록 설정하는 방법은?','["Celery는 재시도 기능을 아예 지원하지 않아 실패한 태스크는 수동으로 다시 호출해야 한다고 오해하기 쉽다.","@app.task(autoretry_for=(Exception,), max_retries=3)와 같이 데코레이터에 재시도 대상 예외와 최대 횟수를 지정한다.","태스크 함수 안에서 try/except로 감싸고 아무 것도 하지 않으면 Celery가 알아서 재시도해준다고 잘못 알려져 있다.","브로커(Redis) 설정에서 retry=true라는 전역 옵션을 켜면 모든 태스크가 자동 재시도된다고 오해하기 쉽다."]','{"correct":1}','UNDERSTAND',0.3,'["celery-retry-task"]'),
('PYTHON_BACKEND','MCQ','파이썬 데코레이터가 함수를 감싸는 방식은 어떻게 작동하는가?','["데코레이터는 단순히 함수의 결과를 반환한다.","데코레이터는 함수 호출 전후로 코드를 추가할 수 있다.","데코레이터는 함수 내부에서 동작을 변경하지 않는다.","데코레이터는 클래스에는 적용할 수 없고 함수에만 사용할 수 있다."]','{"correct":1}','UNDERSTAND',0.3,'["decorator"]'),
('PYTHON_BACKEND','MCQ','pip과 poetry의 의존성 관리 방식의 근본적인 차이는?','["poetry는 poetry.lock으로 전체 의존성 트리를 고정해 재현 가능한 설치를 보장하지만, pip은 기본적으로 lock 파일 없이 requirements.txt만으로 설치한다.","pip은 가상환경을 자동으로 만들어주는 반면 poetry는 가상환경 기능 자체를 전혀 지원하지 않는다고 잘못 알려져 있다.","poetry는 내부가 C 언어로 작성되어 있어서 pip보다 설치 속도가 항상 더 빠르다고 오해하기 쉽다.","pip과 poetry는 pyproject.toml이라는 같은 파일 형식을 쓰기 때문에 실질적 차이가 전혀 없다고 오해하기 쉽다."]','{"correct":0}','UNDERSTAND',0.3,'["poetry-vs-pip-dependency-management"]'),
('PYTHON_BACKEND','MCQ','Django 시그널(signal)이 이벤트 발생 시 리시버를 호출하는 방식은?','["특정 이벤트에 대해 시그널 등록 후, 해당 이벤트 발생 시 자동 호출","시그널 없이 리시버 함수를 개발자가 매번 직접 호출해야 동작한다.","모든 이벤트에 대한 시그널 등록 후, 단일 리시버로 모든 이벤트 처리","뷰(View)에서 수동으로 시그널 객체를 생성해 매번 전송해야 한다."]','{"correct":0}','UNDERSTAND',0.3,'["django-signal-function-calling"]'),
('PYTHON_BACKEND','MCQ','CPU 바운드 작업과 I/O 바운드 작업 중 각각 멀티프로세싱과 asyncio 중 어느 것이 더 적합한가?','["I/O 바운드 작업은 asyncio, CPU 바운드 작업은 멀티프로세싱이 더 적합합니다.","멀티프로세싱과 asyncio는 모든 유형의 작업에 동일하게 적용할 수 있습니다.","CPU 바운드와 I/O 바운드 모두 스레딩만으로 충분히 처리할 수 있습니다.","CPU 바운드 작업은 asyncio, I/O 바운드 작업은 멀티프로세싱이 더 적합합니다."]','{"correct":0}','EVALUATE',0.3,'["python-cpu-iobound-processing"]'),
('PYTHON_BACKEND','MCQ','Django REST Framework Serializer의 주요 역할은 무엇인가?','["뷰(View) 로직 처리","쿼리셋 필터링","데이터 직렬화와 검증","데이터베이스 쿼리 생성"]','{"correct":2}','UNDERSTAND',0.3,'["drf-serializer-role"]'),
('PYTHON_BACKEND','MCQ','중첩된 리스트를 포함한 객체를 얕은 복사(shallow copy)했을 때 나타나는 현상으로 옳은 것은?','["최상위 객체는 새로 생성되지만 내부의 중첩 객체는 원본과 참조를 공유한다.","얕은 복사는 모든 계층을 새로 생성해 원본과 완전히 무관해진다.","얕은 복사는 실제로 아무 것도 복사하지 않고 원본의 참조만 그대로 반환한다.","얕은 복사가 깊은 복사보다 항상 느리게 동작하는 것이 파이썬의 기본 동작이다."]','{"correct":0}','UNDERSTAND',0.3,'["shallow-deep-copy"]'),
('PYTHON_BACKEND','MCQ','JWT(JSON Web Token) 기반 인증에서 서버가 토큰의 유효성을 검증하는 방식으로 옳은 것은?','["서버가 발급한 모든 토큰을 DB에 저장해두고 매 요청마다 세션 테이블과 대조한다고 잘못 알려져 있다.","클라이언트가 자신의 개인키로 서명을 검증한 뒤 결과만 서버에 통보하면 신뢰한다고 오해하기 쉽다.","대칭키(HMAC)라면 발급 때와 같은 비밀키로, 비대칭키(RS256 등)라면 그에 대응하는 공개키로 토큰의 서명을 검증해 위조 여부를 확인한다.","토큰의 만료 시간(exp) 클레임만 확인하고 서명 검증은 생략한다고 잘못 알려져 있다."]','{"correct":2}','UNDERSTAND',0.3,'["jwt-authentication"]'),
('PYTHON_BACKEND','MCQ','FastAPI Pydantic 모델이 요청 바디를 자동으로 검증하는 방식은 무엇인가요?','["Pydantic 모델은 미들웨어에 전역 등록해야만 검증에 사용할 수 있다고 잘못 알려져 있다.","Pydantic 모델 인스턴스를 직접 생성해 매 요청마다 수동으로 유효성 검사를 호출해야 한다고 오해하기 쉽다.","request_body 데코레이터로 타입 힌트를 지정하면 Pydantic 모델을 자동 생성·검증한다고 잘못 알려져 있다.","함수 매개변수에 Pydantic 모델 타입 힌트를 사용하여 지정하면, FastAPI는 자동으로 요청 바디를 검증한다."]','{"correct":3}','UNDERSTAND',0.3,'["fastapi-pydantic-models"]'),
('PYTHON_BACKEND','MCQ','Django에서 트랜잭션을 시작하고 특정 로직이 완료되면 자동으로 커밋되도록 설정하려면 어떻게 해야 하나?','["session.commit() 메서드를 직접 호출하기","db.session.commit() 메서드를 그대로 호출하기","@transaction.atomic() 데코레이터 사용","@atomic이라는 축약 데코레이터를 바로 사용하기"]','{"correct":2}','APPLY',0.3,'["django-transactions"]'),
('PYTHON_BACKEND','MCQ','Django ORM 쿼리셋을 즉시 평가하도록 강제하는 방법은 무엇인가?','["list() 호출하기","filter() 사용하기","values_list() 메서드만 사용하기","all() 메서드 사용하기"]','{"correct":0}','APPLY',0.3,'["django-orm-querysets"]'),
('PYTHON_BACKEND','MCQ','파이썬 패키지 구조에서 ''__init__.py'' 파일의 역할은 무엇인가요?','["패키지 경로를 sys.path에 추가한다.","모듈 import 시 실행되도록 한다.","패키지 내부 모든 모듈을 자동 import한다. 실제로는 명시적 import가 필요하다.","파이썬 인터프리터에게 이 디렉토리를 패키지로 처리하도록 알려준다."]','{"correct":3}','UNDERSTAND',0.4,'["python-package-structure"]'),
('PYTHON_BACKEND','MCQ','Django 미들웨어가 요청/응답 처리 흐름에서 어떤 순서로 실행되는지?','["모든 미들웨어가 스레드로 동시에 병렬 실행되어 순서가 전혀 보장되지 않는다.","미들웨어는 등록된 순서대로 요청 처리 시에도 응답 처리 시에도 항상 동일한 방향으로 순차 실행된다.","등록 순서와 관계없이 매 요청마다 미들웨어 실행 순서가 무작위로 바뀐다.","요청은 등록 순서대로 위에서 아래로 통과하고, 응답은 그 역순으로 되돌아간다."]','{"correct":3}','UNDERSTAND',0.4,'["django-middleware-execution-order"]'),
('PYTHON_BACKEND','MCQ','비동기 함수에서 `await asyncio.sleep(1)` 호출이 실행될 때 이벤트 루프는 어떻게 동작하는가?','["루프가 즉시 KeyboardInterrupt에 준하는 예외를 던지며 코루틴 실행을 강제로 중단시켜버린다.","코루틴이 일시 중단(suspend)되고, 이벤트 루프는 그동안 다른 태스크를 실행한다.","루프 자체가 완전히 멈추어 다른 모든 비동기 작업까지 함께 중단된 채로 계속 대기하게 된다.","루프는 계속 돌지만 asyncio.sleep 호출은 아무 효과 없이 무시되고 다음 줄로 바로 넘어간다."]','{"correct":1}','UNDERSTAND',0.4,'["python-async-await"]'),
('PYTHON_BACKEND','MCQ','Django ORM 쿼리셋은 언제 데이터베이스에 실제 쿼리를 실행하나?','["쿼리셋을 순회하거나 리스트로 변환할 때","쿼리셋을 정의(할당)하는 시점","조회 메서드를 호출하는 시점","필터링(filter)을 적용하는 순간 곧바로 실행된다고 오해하기 쉽다."]','{"correct":0}','UNDERSTAND',0.4,'["django-orm-lazy-evaluation"]'),
('PYTHON_BACKEND','MCQ','Celery 결과 백엔드(result backend)의 역할은 무엇인가?','["결과 백엔드는 큐에 쌓인 워커 프로세스들을 직접 관리하고 감독한다.","결과 백엔드는 브로커를 대체해 작업 자체를 워커들에게 직접 배포하고 스케줄링하는 역할까지 담당한다.","결과 백엔드는 새로운 작업 요청을 받아 큐에 추가하는 입구 역할을 한다.","결과 백엔드는 태스크 실행 상태와 반환값을 저장하고 조회 가능하게 한다."]','{"correct":3}','UNDERSTAND',0.4,'["celery-result-backend"]'),
('PYTHON_BACKEND','MCQ','DRF ViewSet과 라우터(Router)가 URL을 자동 생성하는 방식은?','["라우터에 등록된 모든 ViewSet에 대해 라우트 자동 생성","라우터를 등록할 때 개발자가 URL 패턴을 하나하나 직접 지정해야 한다.","ViewSet 클래스 안에 urls.py 등록 코드를 직접 작성해 넣어야만 라우트가 생성된다.","별도 설정 없이도 라우터 없이 URL이 완전히 자동으로 생성된다."]','{"correct":0}','UNDERSTAND',0.4,'["drf-viewset-router-url-generation"]'),
('PYTHON_BACKEND','MCQ','스레드(thread)와 코루틴(coroutine)의 동시성 처리 차이점은 무엇인가?','["스레드는 결코 비동기 작업을 지원할 수 없으며, 언제나 동기적인 순차 처리 방식으로만 동작한다.","코루틴은 스레드와 달리 이벤트 루프 없이는 여러 작업을 동시에 실행할 수 없다.","스레드는 CPU 스케줄링에 의존하여 실행되지만, 코루틴은 프로그래머가 직접 제어를 넘겨받는다.","코루틴은 스레드보다 항상 메모리 사용량이 훨씬 적어 무조건 더 효율적으로 동작한다."]','{"correct":2}','UNDERSTAND',0.4,'["thread-coroutine"]'),
('PYTHON_BACKEND','MCQ','FastAPI에서 백그라운드 태스크를 실행하려면 어떻게 해야 하는가?','["@background 데코레이터를 함수 위에 적용하기","threading.Thread로 별도 스레드를 직접 생성하기","multiprocessing.Process로 별도 프로세스 생성하기","background_tasks.add_task() 호출하기"]','{"correct":3}','APPLY',0.4,'["fastapi-background-tasks"]'),
('PYTHON_BACKEND','MCQ','`asyncio.gather` 함수의 주요 기능은 무엇인가?','["작업들을 순서대로 호출해 실행한다. 실제로는 동시 실행이 핵심이다.","작업들의 결과를 무시한다.","단일 작업만 동기 실행한다.","여러 비동기 작업 결과를 동시에 처리하고 반환한다."]','{"correct":3}','UNDERSTAND',0.4,'["asyncio-gather"]'),
('PYTHON_BACKEND','MCQ','프로세스 기반(gunicorn worker) 병렬 처리와 스레드 기반 병렬 처리 중 GIL의 영향을 받는 것은 무엇인가요?','["GIL은 멀티프로세스 환경에서도 각 프로세스 사이에 공유되어 동일하게 적용됩니다.","GIL은 스레드·프로세스·비동기 코루틴 구분 없이 파이썬이 실행되는 모든 환경에 항상 예외 없이 동일하게 적용됩니다.","gunicorn worker가 여러 개여도 하나의 프로세스 안에서만 GIL 없이 동작하도록 자동으로 통합됩니다.","스레드 기반 병렬 처리는 GIL의 영향으로 인해 CPU 바운드 작업에서 성능 저하가 발생합니다."]','{"correct":3}','ANALYZE',0.4,'["python-gil-threading"]'),
('PYTHON_BACKEND','MCQ','정적 파일(static files)을 Gunicorn/Uvicorn 같은 애플리케이션 서버가 아니라 Nginx나 CDN으로 서빙해야 하는 주된 이유는?','["애플리케이션 서버는 동적 요청 처리에 최적화되어 있어, 정적 파일을 대량으로 서빙하면 요청 처리 성능이 저하되기 때문이다.","정적 파일을 애플리케이션 서버에서 서빙하면 파일 경로 노출 같은 보안 취약점이 항상 자동으로 생겨난다. 실제로는 위치와 취약점이 자동 연결되지 않는다.","정적 파일은 반드시 데이터베이스에 저장해야만 하므로 별도의 서버가 필요해지기 때문이다.","정적 파일은 오직 파이썬 코드로만 처리할 수 있어 다른 서버로는 처리할 수 없기 때문이다."]','{"correct":0}','UNDERSTAND',0.4,'["static-files-serving"]'),
('PYTHON_BACKEND','MCQ','FastAPI가 Pydantic 모델로부터 OpenAPI 스키마를 자동 생성하는 원리는 무엇인가요?','["FastAPI는 Pydantic 모델의 메서드를 직접 호출해 연결된 데이터베이스 테이블 정의에서 스키마 정보를 가져와 자동으로 생성한다.","Pydantic 모델과 전혀 무관하게 각 엔드포인트의 함수 이름과 docstring만 파싱해 스키마를 자동으로 만든다.","함수 매개변수와 반환값(response_model)에 사용된 Pydantic 모델의 필드·타입을 분석해 OpenAPI 스키마를 생성한다.","OpenAPI 스키마는 Pydantic 모델과는 무관하게 매 요청이 들어올 때마다 그때그때 새로 추론된다."]','{"correct":2}','UNDERSTAND',0.4,'["fastapi-pydantic-openapi"]'),
('PYTHON_BACKEND','MCQ','다음 HTTP 메서드 중 멱등성(idempotency)이 보장되지 않는 것은?','["PUT","DELETE","POST","GET"]','{"correct":2}','APPLY',0.5,'["rest-api-idempotency"]'),
('PYTHON_BACKEND','MCQ','Django에서 OneToOneField 또는 ForeignKey 관계의 N+1 문제를 해결하기 위해 select_related를 사용하는 방법은?','["queryset.filter(field_name__in=values)","queryset.select_related(''field_name'')","queryset.prefetch_related(''related_field'')","model.objects.annotate(field_name=''value'')"]','{"correct":1}','APPLY',0.5,'["django-select-related-n-plus-one"]'),
('PYTHON_BACKEND','MCQ','DRF 권한 클래스(permission class)로 접근을 제어하는 방법은?','["view 함수에서 직접 체크","permission_classes 속성을 통해 적용","urls.py 라우팅에서 설정","settings.py에 전역으로만 정의해두면 충분하며, 실제로는 View·ViewSet 단위의 세밀한 제어가 불가능해진다."]','{"correct":1}','APPLY',0.5,'["drf-permission-classes"]'),
('PYTHON_BACKEND','MCQ','uvicorn이 ASGI 애플리케이션을 실행하는 방식과, gunicorn과 함께 사용할 때의 설정은 무엇인가요?','["ASGI는 WSGI와 완전히 같은 프레임워크 규격이라서 uvicorn을 그냥 직접 실행하면 충분하다고 오해하기 쉽다.","uvicorn은 자체 이벤트 루프를 사용하여 ASGI 애플리케이션을 구동합니다. gunicorn에서는 -k 옵션으로 ''uvicorn.workers.UvicornWorker''를 지정해야 합니다.","ASGI는 uvicorn과 애초에 호환되지 않아서 gunicorn이 별도의 브릿지 기능으로 억지로 연결해준다고 잘못 알려져 있다.","gunicorn에서 uvicorn을 쓸 때는 ASGI를 직접 실행할 수 없어 반드시 WSGI로 먼저 변환해야만 구동된다고 오해하기 쉽다."]','{"correct":1}','UNDERSTAND',0.5,'["python-uvicorn-gunicorn"]'),
('PYTHON_BACKEND','MCQ','FastAPI `Depends()`로 의존성 주입을 구성하는 방법은 무엇인가요?','["매개변수의 기본값으로 Depends(function)을 지정하면 FastAPI가 이를 해석해 자동으로 의존성을 주입한다.","depends()라는 전역 함수를 먼저 호출해 반환값을 매개변수에 수동으로 대입해야 한다고 오해하기 쉽다. 실제로는 그런 전역 함수가 없다.","함수 내부에서 의존성 객체를 생성한 뒤 다른 메서드에 전달해야 한다고 잘못 알려져 있다.","@depends() 데코레이터를 함수 위에 붙여 의존성을 선언해야 주입된다고 오해하기 쉽다."]','{"correct":0}','APPLY',0.5,'["fastapi-dependency-injection"]'),
('PYTHON_BACKEND','MCQ','pytest에서 외부 API 호출을 목(mock)으로 대체하는 방법은?','["pytest가 자체적으로 제공하는 @patch라는 전용 메서드를 이용하면 된다.","mock 모듈을 import하고, 함수 내에서 직접 API 호출 부분을 대체하도록 설정한다.","외부 API 호출 부분을 mock 객체로 직접 교체하기만 하면 충분하다.","@mock.patch 데코레이터를 사용하여 필요한 위치에 테스트용 객체를 삽입한다."]','{"correct":3}','APPLY',0.5,'["pytest-mock-external-api"]'),
('PYTHON_BACKEND','MCQ','pytest-cov 플러그인이 설치된 상태에서, 테스트 실행과 동시에 커버리지를 측정하려면 어떤 명령을 쓰는가?','["pytest --cov","coverage report","pytest --coverage","coverage html"]','{"correct":0}','APPLY',0.5,'["python-coverage-reporting"]'),
('PYTHON_BACKEND','MCQ','DRF ModelSerializer로 모델 필드를 자동 매핑하는 방법은?','["모든 필드를 수동으로 다시 선언해야 매핑된다.","ListSerializer로 목록 형식을 정의한다.","ModelViewSet에 필드를 나열해야 매핑된다. 실제로는 Meta.model 지정만으로 충분하다.","serializers.ModelSerializer에서 모델 클래스 정의"]','{"correct":3}','APPLY',0.5,'["drf-modelserializer-mapping"]'),
('PYTHON_BACKEND','MCQ','Celery beat로 주기적 작업(periodic task)을 예약하는 표준적인 방법은?','["beat_schedule 설정 또는 on_after_configure 시그널에서 sender.add_periodic_task()로 스케줄을 등록한다.","@periodic_task 데코레이터(레거시 API)만 붙이면 beat_schedule 등록 없이도 자동으로 스케줄링된다고 잘못 알려져 있다. 실제로는 별도 등록 절차가 여전히 필요하다.","워커 프로세스를 여러 개 띄우기만 하면 그 자체로 주기적 실행이 자동 활성화된다고 오해하기 쉽다.","태스크 함수 본문 안에 while True와 sleep()을 직접 넣어 무한 반복시켜야 한다고 잘못 알려져 있다."]','{"correct":0}','APPLY',0.5,'["celery-beat-periodic-task"]'),
('PYTHON_BACKEND','MCQ','파이썬 로깅에서 print() 대신 logging 모듈을 사용해야 하는 이유는 무엇인가요?','["print()를 사용하면 그 자체만으로 프로그램 실행 성능이 눈에 띄게 저하될 수 있다.","파이썬 로깅 시스템은 print()를 아예 인식하지 못하도록 막아두어 logging 모듈만 지원한다.","logging 모듈은 오직 파일에만 메시지를 기록할 수 있고 콘솔 출력은 지원하지 않는다.","print() 함수보다 logging 모듈은 더 다양한 출력 포맷과 필터링 옵션을 제공합니다."]','{"correct":3}','APPLY',0.5,'["python-logging-module"]'),
('PYTHON_BACKEND','MCQ','대용량 파일 업로드를 처리할 때 서버 메모리 사용을 줄이는 방법은 무엇인가요?','["파일 전송이 끝난 뒤 전체를 메모리에 통째로 올려 처리해야 스트리밍보다 안전하다고 오해하기 쉽다.","대용량 업로드는 서버 네트워크 대역폭만 고려하면 되고 메모리와는 무관하다고 잘못 알려져 있다.","파일을 파트로 나눠 전송해도 서버가 즉시 하나의 버퍼로 재조합해 절감 효과가 없다고 오해하기 쉽다.","스트림(Stream) 방식으로 파일을 읽어올 경우, 전체 데이터를 메모리에 올리지 않고 부분적으로 처리할 수 있어 메모리를 절약할 수 있다."]','{"correct":3}','APPLY',0.5,'["file-upload-streaming"]'),
('PYTHON_BACKEND','MCQ','CORS 오류를 해결하기 위해 서버에서 설정해야 하는 것은 무엇인가요?','["서버는 모든 출처에 대해 무조건 접근 권한을 열어두면 CORS 문제가 저절로 해결된다.","서버 측에 CORS 미들웨어를 설치하고, 원하는 출처에 대한 허용 목록을 설정한다.","클라이언트 측에서 요청 시 Access-Control-Allow-Origin 헤더를 직접 붙여 서버 응답을 대체한다.","서버가 자동으로 CORS 문제를 알아서 해결해주므로 개발자가 따로 설정할 필요가 없다."]','{"correct":1}','APPLY',0.5,'["cors-configuration"]'),
('PYTHON_BACKEND','MCQ','함수가 정수 id를 받아 User 객체 또는 None을 반환할 수 있을 때, 이를 타입 힌트로 정확히 표현한 것은?','["def get_user(id: int) -> User: ...  # None 가능성은 반환 타입에 반영하지 않아도 된다","def get_user(id: int) -> Optional[User]: ...","def get_user(id) -> int: ...  # id 타입과 반환 타입 모두 실제와 다르게 적어도 된다","def get_user(id: int) -> None: ...  # 반환값이 있어도 항상 None으로 명시해야 한다"]','{"correct":1}','APPLY',0.5,'["type-hinting"]'),
('PYTHON_BACKEND','MCQ','웹 애플리케이션에서 SQLAlchemy 세션(Session)을 요청 단위로 관리하는 일반적인 패턴은?','["요청이 시작될 때 세션을 새로 생성하고, 요청이 끝나면 커밋 또는 롤백한 뒤 세션을 닫는다.","세션은 스레드와 무관하게 항상 전역 공유되며 종료할 필요가 없다고 잘못 알려져 있다.","세션은 첫 쿼리 실행 시점에만 생성되고 이후 재사용하지 않는다고 오해하기 쉽다.","애플리케이션 시작 시 세션 하나만 만들어 전체 요청에서 재사용한다고 잘못 알려져 있다. 실제로는 세션 공유가 데이터 오염을 부른다."]','{"correct":0}','UNDERSTAND',0.5,'["sqlalchemy-session-lifecycle"]'),
('PYTHON_BACKEND','MCQ','FastAPI `response_model`로 응답 스키마를 제한하는 방법은 무엇인가요?','["함수 매개변수에 Pydantic 모델 타입 힌트를 사용하여 지정하면, FastAPI는 그것만으로 자동으로 응답 스키마를 제한한다고 잘못 알려져 있다.","경로 데코레이터(`@app.get(..., response_model=Model)`)에 Pydantic 모델을 지정하면 FastAPI가 응답을 그 스키마에 맞춰 직렬화·검증한다.","Pydantic 모델 클래스 변수에 직접 타입을 정의한 뒤 함수 매개변수로 써야 하며, response_model 인자는 이 경우 완전히 무시된다고 오해하기 쉽다. 실제로는 response_model이 그대로 적용된다.","함수 내부에서 Pydantic 모델을 직접 반환하기만 하면 되고, response_model이라는 인자 자체는 실제로 아무 효과가 없다고 잘못 알려져 있다."]','{"correct":1}','APPLY',0.5,'["fastapi-response-model"]'),
('PYTHON_BACKEND','MCQ','가변 기본 인자(mutable default argument) 문제를 피하는 방법은 무엇인가?','["모든 가변 객체는 무조건 불변 객체로 바꿔야 하며 다른 방법은 없다.","가변 객체는 절대 기본값으로 쓸 수 없으므로 항상 함수 외부에서 미리 생성한 뒤 인자로만 전달해야 한다.","매개변수의 기본 값으로 `None`을 사용하고, 함수 내에서 필요할 때 값을 초기화한다.","함수 매개변수에 무결성 검사 로직을 추가하면 가변 기본 인자 문제가 자동으로 해결된다."]','{"correct":2}','APPLY',0.5,'["mutable-default-argument"]'),
('PYTHON_BACKEND','MCQ','Django 프로젝트에서 개발(dev)과 운영(prod) 환경의 설정값을 분리해 관리하는 가장 흔한 방법은?','["settings/base.py에 공통 설정을 두고, settings/dev.py·settings/prod.py가 이를 상속한 뒤 DJANGO_SETTINGS_MODULE 환경변수로 선택한다.","환경에 관계없이 settings.py 파일 하나만 두고 조건 분기 없이 쓰는 것이 Django가 유일하게 공식 권장하는 방식이라고 잘못 알려져 있다.","운영 서버에 배포할 때마다 개발자가 settings.py 내용을 직접 손으로 하나하나 덮어써야 한다고 오해하기 쉽다.","settings.py 내용을 데이터베이스 테이블에 저장해두고 서버 시작 시점마다 런타임으로 조회해 읽어와야 한다고 오해하기 쉽다."]','{"correct":0}','APPLY',0.5,'["django-settings-environment-separation"]'),
('PYTHON_BACKEND','MCQ','Redis를 이용한 cache-aside(캐시 조회 후 없으면 DB 조회 후 캐시 저장) 패턴 구현 순서는?','["1. DB에서 데이터를 먼저 가져온 뒤, 2. Redis에서 해당 데이터의 캐시 키를 조회, 3. 없으면 Redis에 저장.","1. Redis에서 캐시 키 조회, 5초 동안 대기 후 다시 Redis 조회, 2. 없다면 DB에서 데이터 가져오기, 3. Redis에 저장.","1. 캐시부터 무효화한 뒤 DB에서 데이터 가져오기, 2. Redis에 키가 있는지 재확인, 3. 없으면 캐시 저장.","1. Redis에서 캐시 키 조회, 2. 없다면 DB에서 데이터 가져오기, 3. 가져온 데이터를 Redis에 저장."]','{"correct":3}','APPLY',0.5,'["redis-cache-aside"]'),
('PYTHON_BACKEND','MCQ','Kubernetes 스타일의 readiness 체크(다른 서비스로 요청을 받을 준비가 됐는지 판단하는 프로브)가 확인해야 할 항목은 무엇인가요?','["readiness 체크는 애플리케이션 서버의 CPU 사용량 하나만 확인하면 충분하다.","데이터베이스 연결, 캐시 연결 등 핵심 의존 서비스의 가용성을 체크합니다.","readiness 체크는 오직 네트워크 트래픽량만 모니터링하면 되는 지표다.","프로세스가 살아있는지만 확인하며 DB·캐시 같은 의존 서비스 상태는 절대 보지 않습니다."]','{"correct":1}','APPLY',0.5,'["python-health-check"]'),
('PYTHON_BACKEND','MCQ','환경변수로 민감한 설정값(DB 비밀번호 등)을 관리해야 하는 이유는 무엇인가요?','["환경변수는 여러 개발자가 함께 작업할 때 서로 다른 설정 값을 관리하기 쉽습니다.","환경변수를 사용하면 설정 값이 런타임에 동적으로 변경될 수 있습니다.","환경 변수를 사용하면 설정 값이 소스 코드에 노출되지 않아 보안 위험이 줄어듭니다.","환경 변수는 테스트 환경에서만 작동하므로 개발과 프로덕션 사이의 차이를 방지합니다."]','{"correct":2}','APPLY',0.6,'["python-environment-variables"]'),
('PYTHON_BACKEND','MCQ','웹 요청 핸들러 안에서 처리하면 안 되고 Celery 태스크로 분리해야 하는 작업의 특징은 무엇인가?','["작업이 데이터베이스 트랜잭션 커밋 이전 시점에 반드시 동기적으로 끝나야 하는 경우","작업이 오래 걸리거나 외부 서비스 호출처럼 응답 시간을 예측하기 어려운 경우","작업이 매우 단순한 계산이라 밀리초 단위로 곧바로 끝나버리는 경우","작업 결과를 응답 본문에 그대로 담아 즉시 반환해야만 하는 경우"]','{"correct":1}','EVALUATE',0.6,'["celery-web-requests"]'),
('PYTHON_BACKEND','MCQ','커넥션 풀(connection pool) 크기를 실제 동시 요청 수보다 너무 작게 설정했을 때 발생하는 문제는?','["커넥션 풀이 작으면 오히려 쿼리 실행 속도가 항상 더 빨라진다.","동시 요청이 몰릴 때 커넥션을 얻지 못한 요청이 대기하거나 타임아웃 오류가 발생한다.","커넥션 풀이 작을수록 서버 메모리 사용량이 오히려 더 늘어나는 부작용이 생긴다.","데이터베이스가 부하를 감지하면 커넥션 풀 크기를 자동으로 늘려 요청을 모두 받아준다."]','{"correct":1}','APPLY',0.6,'["connection-pool-sizing"]'),
('PYTHON_BACKEND','MCQ','migrations 작업을 수행하기 위해 Alembic의 주요 명령어들은 무엇인가요?','["migrations 작업에는 alembic upgrade 명령 하나만 있으면 그것만으로 스키마가 최신이 된다고 오해하기 쉽다.","Alembic에서는 Flask-Migrate처럼 python manage.py db init·migrate·upgrade 명령으로 진행해야 한다고 잘못 알려져 있다.","Alembic에는 migrations 전용 명령어가 없어서 개발자가 SQL 스크립트를 직접 작성해야 한다고 오해하기 쉽다.","Alembic에서 migrations 작업은 alembic init 명령으로 시작하고, 이후 alembic revision 및 upgrade 명령으로 업데이트한다."]','{"correct":3}','APPLY',0.6,'["alembic-migrations"]'),
('PYTHON_BACKEND','MCQ','gunicorn 워커 프로세스 수를 `(2 × CPU 코어 수) + 1` 같은 공식으로 설정하는 이유는?','["워커 수는 CPU 코어 수와 무관하게 하드웨어 한계까지 많이 띄울수록 처리량이 계속 증가하기 때문이다. 실제로는 스위칭 비용이 늘어난다.","I/O로 블로킹되는 동안에도 CPU를 놀리지 않으면서, 과도한 워커로 인한 컨텍스트 스위칭 비용은 억제하려는 경험칙이다.","gunicorn은 워커 수가 CPU 코어 수를 초과하면 프로세스 생성을 거부하고 에러를 낸다.","워커 수는 초당 요청 수와 정확히 1:1 비율로 맞춰야만 정상 동작하기 때문이다."]','{"correct":1}','APPLY',0.6,'["gunicorn-workers-cpu-cores"]'),
('PYTHON_BACKEND','MCQ','DRF에서 커서 기반 페이지네이션(cursor-based pagination)과 오프셋 기반 페이지네이션(offset-based pagination)의 주요 차이는?','["커서는 무작위 접근 가능, 오프셋은 순차적 접근만 가능","커서는 총 페이지 수를 항상 정확히 계산해 알려준다","커서는 특정 객체 ID를 사용, 오프셋은 객체 수를 사용","오프셋은 특정 객체 ID를 사용, 커서는 객체 수를 사용"]','{"correct":2}','APPLY',0.6,'["drf-pagination-strategy"]'),
('PYTHON_BACKEND','MCQ','블로킹 호출(예: 동기 I/O)이 이벤트 루프를 멈추는 문제를 피하는 방법은 무엇인가?','["블로킹 호출을 그냥 무시하고 계속 실행시키기만 해도 시간이 지나면 파이썬이 알아서 문제를 자동으로 해결해준다고 오해하기 쉽다.","동기 함수 정의 앞에 async 키워드만 붙이면, 함수 내부의 모든 블로킹 호출까지 파이썬이 자동으로 논블로킹 코드로 바꿔준다고 잘못 알려져 있다. 실제로는 그렇게 자동 변환되지 않는다.","비동기 함수를 도로 동기 함수로 되돌려 놓기만 하면 이벤트 루프가 막히는 문제 자체가 저절로 사라진다고 오해하기 쉽다.","블로킹 함수 호출을 asyncio.to_thread() 또는 loop.run_in_executor()로 별도 스레드에 위임해 이벤트 루프를 막지 않는다."]','{"correct":3}','APPLY',0.6,'["blocking-call"]'),
('PYTHON_BACKEND','MCQ','캐시 키(cache key)를 설계할 때 반드시 고려해야 할 사항은?','["캐시 키에는 콜론(:)이나 구분자 문자를 절대로 사용해서는 안 된다고 잘못 알려져 있다.","결과값에 영향을 주는 모든 파라미터(예: 사용자 ID, 필터 조건)를 키에 포함해 서로 다른 요청이 같은 키를 공유하지 않도록 한다.","키는 짧을수록 무조건 좋으므로 파라미터 없이 고정된 짧은 문자열 하나만 계속 재사용해야 한다고 오해하기 쉽다. 실제로는 요청 결과가 뒤섞여버린다.","캐시 키는 대소문자를 전혀 구분하지 않으니 설계할 때 신경 쓸 필요가 없다고 잘못 알려져 있다."]','{"correct":1}','APPLY',0.6,'["cache-key-design"]'),
('PYTHON_BACKEND','MCQ','Django 마이그레이션을 생성하고 적용하기 위한 순서는?','["makemigrations -> runserver","syncdb -> migrate","makemigrations -> migrate","migrate -> makemigrations"]','{"correct":2}','APPLY',0.6,'["django-migration-management"]'),
('PYTHON_BACKEND','MCQ','Django에서 시그널 대신 명시적 함수 호출을 선택해야 하는 상황은?','["특정 상황을 가리지 않고 모든 시나리오에서 항상 시그널을 사용해야 한다.","특정 이벤트에 대한 복잡한 처리나 실행 순서 보장이 필요할 때","뷰(View)에서 단순 데이터 조회만 수행하고 별도의 부수 효과가 전혀 없을 때","API 엔드포인트로 단순 데이터를 요청받아 그대로 반환할 때"]','{"correct":1}','EVALUATE',0.7,'["django-signal-usage-scenarios"]'),
('PYTHON_BACKEND','MCQ','인덱스가 없는 컬럼으로 WHERE 조건을 거는 쿼리에서 발생할 수 있는 성능 문제는?','["인덱스가 없으면 쿼리 자체가 실행되지 않고 곧바로 오류를 반환한다.","쿼리 옵티마이저가 실행 시점에 필요한 인덱스를 자동으로 만들어주므로 성능 문제가 발생하지 않는다.","전체 테이블을 순차 스캔(full scan)하여 응답 시간이 늘어난다.","인덱스가 없어도 데이터베이스가 항상 캐시된 결과를 반환해 오히려 더 빨라진다."]','{"correct":2}','UNDERSTAND',0.7,'["sql-indexing"]'),
('PYTHON_BACKEND','MCQ','Celery 태스크가 재시도될 때 멱등성(idempotency)이 없으면 발생하는 문제는 무엇인가?','["재시도된 태스크가 다른 태스크와 충돌해 전체 작업이 실패할 위험이 생긴다.","태스크가 재시도될 때마다 이전 실행의 메모리가 해제되지 않고 계속 쌓여 결국 워커 프로세스가 다운된다.","태스크가 중복 실행되어 결제·적립 등의 부작용이 두 번 이상 반영될 수 있다.","재시도 결과가 예측 불가능해져서 시스템 전체의 안정성이 저하된다."]','{"correct":2}','APPLY',0.7,'["celery-idempotency-retry"]'),
('PYTHON_BACKEND','MCQ','DRF 중첩 Serializer(nested serializer)가 N+1 쿼리를 유발하는 상황은?','["모든 모델 필드를 관계 없이 그대로 단순 직렬화만 하는 경우","직렬화 대상 모델 사이에 아무런 연관 관계가 없는 경우","하나의 모델에서 단일 필드 하나만 골라 직렬화하는 경우","하나의 모델이 다른 여러 모델과 연관되어 있고, 목록을 직렬화할 때마다 각 항목의 연관 객체를 별도로 조회할 때"]','{"correct":3}','ANALYZE',0.7,'["drf-nested-serializer-n-plus-one"]'),
('PYTHON_BACKEND','MCQ','@transaction.atomic() 블록 안에서 예외가 발생했을 때의 동작은?','["변경 사항 유지 또는 롤백은 설정에 따라 달라짐","예외 발생 시 모든 변경사항 롤백","예외 발생 시 변경 사항 유지","예외 발생 여부와 관계없이 항상 변경 사항 저장"]','{"correct":1}','APPLY',0.7,'["django-transaction-management"]'),
('PYTHON_BACKEND','MCQ','캐시 스탬피드(cache stampede)가 발생하는 조건과 이를 완화하는 방법으로 옳은 것은?','["인기 키가 만료된 순간 다수의 요청이 동시에 캐시 미스를 겪어 DB로 몰리는 현상이며, 락(뮤텍스)이나 조기 재계산으로 완화한다.","캐시 서버 자체가 완전히 다운되었을 때만 발생하며, 복제본을 추가하기만 하면 항상 확실히 방지된다.","캐시 키의 TTL이 아직 충분히 남아있을 때 발생하며, 단순히 캐시 크기를 키우면 항상 해결된다.","여러 요청이 서로 다른 캐시 키를 동시에 조회할 때 발생하며, 모든 키를 하나로 통합해버리면 완전히 사라진다. 실제로는 적중률이 떨어지는 부작용이 남는다."]','{"correct":0}','ANALYZE',0.8,'["cache-stampede"]'),
('PYTHON_BACKEND','MCQ','여러 개발자가 각자 브랜치에서 동시에 Alembic 마이그레이션을 작성해 리비전 히스토리에 여러 head가 생겼을 때 해결 방법은?','["가장 최근에 병합된 마이그레이션 파일 하나만 남기고 나머지 파일은 전부 지워버리면 된다.","`alembic merge heads` 명령으로 여러 head를 하나의 병합 리비전으로 합친다.","각 개발자가 서로 다른 데이터베이스를 쓰기만 하면 head 충돌이 자동으로 해소된다.","down_revision 값은 그냥 참고용이므로 무시하고 최신 파일부터 순서대로 실행하면 된다."]','{"correct":1}','ANALYZE',0.8,'["alembic-migration-conflicts"]'),
('PYTHON_BACKEND','MCQ','세션 기반 인증과 JWT 기반 인증 중 수평 확장(scale-out) 환경에 더 적합한 방식은 무엇이며 그 이유는 무엇인가요?','["세션이나 JWT나 수평 확장 환경에서 차이 없이 완전히 동일하게 쓸 수 있다고 오해하기 쉽다.","세션 인증이 애초에 수평 확장을 염두에 두고 설계됐으므로 선호해야 한다고 잘못 알려져 있다.","JWT 인증은 토큰의 무상태성(statelessness)으로 인해 여러 서버 간에 별도 세션 저장소 없이 검증될 수 있으므로 JWT를 사용하는 것이 적합합니다.","세션이나 JWT나 단일 서버에서만 유용해서 서버가 늘어나면 둘 다 곧바로 멈춘다고 오해하기 쉽다."]','{"correct":2}','EVALUATE',0.8,'["python-session-jwt-authentication"]'),
('PYTHON_BACKEND','CODE_READING','다음 Django settings.py를 운영 서버에 그대로 배포했을 때 발생할 수 있는 보안 문제는?

from django.shortcuts import render

DEBUG = True
ALLOWED_HOSTS = []

def custom_404(request, exception):
    return render(request, ''404.html'', status=404)','["DEBUG는 로컬 개발 편의를 위한 옵션일 뿐 운영 환경 보안과는 아무 관련이 없다고 오해하기 쉽다.","ALLOWED_HOSTS가 비어 있으면 DEBUG 설정과 무관하게 모든 요청이 자동 차단되어 안전하다고 잘못 알려져 있다.","custom_404 핸들러가 정의돼 있으면 DEBUG 값과 무관하게 항상 그 핸들러만 노출된다고 오해하기 쉽다.","DEBUG=True 상태에서 처리되지 않은 예외가 발생하면, 소스 코드 경로·설정값·스택트레이스 등 민감한 정보가 담긴 디버그 페이지가 그대로 클라이언트에 노출된다."]','{"correct":3}','UNDERSTAND',0.4,'["django-debug-settings"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드를 실행하면 nested_list는 어떻게 되는가?

import copy
nested_list = [[1, 2], [3, 4]]
copied_list = copy.copy(nested_list)
copied_list[0].append(5)
print(nested_list)','["append(5) 호출은 항상 새 리스트를 반환할 뿐 기존 객체는 절대 변경하지 않는다고 오해하기 쉽다.","copied_list와 nested_list는 완전히 독립된 메모리를 쓰기 때문에 서로 영향이 전혀 없다고 잘못 알려져 있다.","copy.copy()는 항상 깊은 복사를 수행하는 함수라서 nested_list는 전혀 변경되지 않는다고 오해하기 쉽다.","copy.copy()는 최상위 리스트만 새로 만들고 내부의 중첩 리스트는 원본과 참조를 공유하므로, copied_list[0]을 변경하면 nested_list에도 반영된다."]','{"correct":3}','ANALYZE',0.5,'["shallow-copy"]'),
('PYTHON_BACKEND','CODE_READING','다음 SQLAlchemy 세션 관리 코드에서는 어떤 문제가 발생할까요?

from sqlalchemy.orm import sessionmaker

Session = sessionmaker(bind=engine)

def get_session():
    db_session = Session()
    return db_session','["요청마다 커넥션 수가 자동으로 5개로 제한되어 예외 없이 안전하게 동작합니다.","get_session 호출 시점에 SQLAlchemy가 자동으로 예외를 발생시켜 세션 누수를 막아줍니다.","세션과 커넥션이 close되지 않고 계속 누적되어 결국 커넥션 풀이 고갈됩니다.","매 호출마다 이전 세션이 자동으로 재사용되어 조회 결과가 정상적으로 반환됩니다."]','{"correct":2}','ANALYZE',0.6,'["sqlalchemy-session-management"]'),
('PYTHON_BACKEND','CODE_READING','두 마이그레이션 파일이 각각 아래와 같이 작성되었다. 이 상태에서 `alembic upgrade head`를 실행하면 어떤 문제가 발생하는가?

# migration_a.py
revision = ''a1b2''
down_revision = ''base_rev''

# migration_b.py
revision = ''c3d4''
down_revision = ''base_rev''','["두 마이그레이션이 같은 down_revision(''base_rev'')을 가리켜 리비전 히스토리에 head가 두 개 생기고, Alembic이 어느 것을 최신으로 적용해야 할지 알 수 없다는 오류를 낸다.","Alembic이 두 마이그레이션 파일의 생성 시간을 자동으로 비교해 시간순으로 정렬한 뒤 아무 충돌 없이 순차 적용한다고 잘못 알려져 있다.","down_revision 값이 서로 같더라도 revision 식별자(a1b2, c3d4) 자체는 다르니 아무 충돌 없이 순서대로 적용된다고 오해하기 쉽다.","먼저 작성된 마이그레이션 파일은 자동으로 무시되고 더 나중에 작성된 파일만 골라서 적용된다고 잘못 알려져 있다."]','{"correct":0}','EVALUATE',0.7,'["alembic-multiple-heads"]'),
('PYTHON_BACKEND','CODE_READING','다음 SQLAlchemy 엔진 설정에서 동시 요청이 10개 몰릴 때 어떤 문제가 발생할 수 있는가?

from sqlalchemy import create_engine, text

engine = create_engine(''postgresql://user:pass@localhost/dbname'', pool_size=5, max_overflow=0)

def fetch_data():
    conn = engine.connect()
    try:
        result = conn.execute(text(''SELECT * FROM users''))
        return result.fetchall()
    finally:
        conn.close()','["max_overflow=0은 오버플로우를 무제한으로 허용한다는 뜻이라 문제가 없다고 오해하기 쉽다.","pool_size는 요청 수와 무관하게 데이터베이스가 자동으로 늘려준다고 잘못 알려져 있다.","conn.close()가 finally에 있으니 커넥션이 항상 즉시 반환돼 풀 부족은 절대 없다고 오해하기 쉽다.","pool_size=5, max_overflow=0으로 최대 5개 커넥션만 허용되어, 6번째 이상 요청은 커넥션을 기다리다 타임아웃될 수 있다."]','{"correct":3}','ANALYZE',0.7,'["sqlalchemy-connection-pooling"]'),
('PYTHON_BACKEND','CODE_READING','다음 Redis 캐시 코드에서는 어떤 문제가 발생할까요?

import redis

cache = redis.Redis()
db = get_database_handle()  # 외부에서 주입되는 DB 핸들

def get_value(key):
    value = cache.get(key)
    if not value:
        result = db.query(key)
        cache.set(key, result, ex=60)
        return result
    return value','["락을 쓰지 않아도 Redis가 내부적으로 요청을 자동 직렬화해줘서 문제가 없다고 잘못 알려져 있다.","캐시 키가 만료된 순간 동시에 몰린 다수의 요청이 전부 캐시 미스를 겪어 db.query가 동시에 여러 번 호출되는 캐시 스탬피드가 발생할 수 있다.","ex=60 옵션이 없으면 캐시가 영구히 만료되지 않아 오히려 안전하다고 오해하기 쉽다.","cache.get()이 항상 예외를 던지도록 구현돼 db.query가 절대 호출 못 된다고 잘못 알려져 있다."]','{"correct":1}','EVALUATE',0.7,'["redis-cache-stampede"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드를 실행하면 어떤 일이 벌어지는가?

def get_user_age(age: int) -> int:
    return age * 2

result = get_user_age(''25'')','["타입 힌트가 문자열을 파이썬 내부적으로 자동 변환해줘서 result가 정수 50이 된다고 오해하기 쉽다.","mypy 같은 별도의 정적 검사기 없이도 인터프리터가 실행 시점에 타입을 검증해 오류를 낸다고 오해하기 쉽다.","타입 힌트가 int로 지정되어 있으니, 인터프리터가 호출 시점에 인자 타입을 검사해 문자열을 넘기면 TypeError를 던진다고 잘못 알려져 있다.","타입 힌트는 런타임에 강제되지 않으므로 문자열 ''25''가 그대로 전달되고, age * 2는 문자열을 반복해 ''2525''를 반환한다."]','{"correct":3}','EVALUATE',0.7,'["type-hint-not-enforced-runtime"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드의 동작으로 옳은 것은?

def generate_data():
    for i in range(10):
        yield i

gen = generate_data()
first_three = [next(gen) for _ in range(3)]
rest = list(gen)','["제너레이터는 멈춘 지점(yield 위치)의 상태를 유지하므로, next()로 3개를 먼저 소비한 뒤 남은 값을 순회하면 rest는 [3, 4, ..., 9]가 된다.","제너레이터는 next()를 한 번이라도 호출하면 상태가 완전히 소진되어, 이후 list(gen)은 항상 빈 리스트만 반환한다고 잘못 알려져 있다. 실제로는 멈춘 지점에서 이어진다.","first_three와 rest 둘 다 range(10) 전체를 담고 있어 두 리스트에 겹치는 값이 있다고 오해하기 쉽다.","제너레이터는 순회할 때마다 매번 처음부터 다시 시작해서 rest에도 [0, ..., 9]가 담긴다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.7,'["generator-behavior"]'),
('PYTHON_BACKEND','CODE_READING','다음 데코레이터를 적용한 뒤 example.__name__을 출력하면 어떻게 되는가?

def simple_decorator(func):
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper

@simple_decorator
def example():
    """This is an example function."""
    pass

print(example.__name__)','["데코레이터가 example을 두 번 호출하도록 만들어서 부작용이 두 번 중복 발생한다고 오해하기 쉽다.","functools.wraps를 쓰지 않아도 파이썬이 원본 함수의 메타데이터를 자동으로 보존해 __name__이 여전히 ''example''로 남는다고 잘못 알려져 있다.","functools.wraps로 감싸지 않아 wrapper가 example을 대체하면서 __name__이 ''wrapper''가 되고 __doc__도 사라진다.","wrapper 함수가 example의 실제 로직을 실행하지 않아 항상 None만 반환하게 된다고 오해하기 쉽다."]','{"correct":2}','ANALYZE',0.7,'["decorator-no-wraps"]'),
('PYTHON_BACKEND','CODE_READING','다음 pytest 픽스처 코드에서는 어떤 문제가 발생할까요?

import pytest

class TestOrders:
    @pytest.fixture(scope=''session'')
    def cart(self):
        items = []
        yield items

    def test_add_item(self, cart):
        cart.append(''apple'')
        assert cart == [''apple'']

    def test_cart_starts_empty(self, cart):
        assert cart == []','["픽스처가 session 스코프이므로 테스트 간에 cart 리스트 상태가 공유되어, 실행 순서에 따라 test_cart_starts_empty가 실패할 수 있다.","pytest가 클래스 안 픽스처는 자동으로 새 cart를 만들어줘서 두 테스트 모두 통과한다고 오해하기 쉽다.","session 스코프도 클래스 컨텍스트에서는 자동으로 function 스코프로 낮춰진다고 잘못 알려져 있다.","픽스처가 제너레이터(yield)면 스코프와 무관하게 매 테스트마다 새로 생성된다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.7,'["pytest-fixtures-scope"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드를 실행하면 어떤 일이 벌어지는가?

class CustomError(object):
    pass

try:
    raise CustomError(''Custom error'')
except Exception as e:
    print(e)','["CustomError가 Exception을 상속하지 않았으니 except Exception 절을 그대로 통과해버려서 예외가 잡히지 않은 채 프로그램이 그대로 종료된다고 오해하기 쉽다.","raise CustomError(...) 시점에 파이썬이 ''exceptions must derive from BaseException'' TypeError를 발생시키고, 이 TypeError가 except Exception에 잡혀 출력된다.","CustomError가 아무 문제 없이 정상적으로 발생하고 except Exception이 이를 그대로 잡아 ''Custom error''라는 문자열을 화면에 곧바로 출력해버린다고 잘못 알려져 있다.","object를 상속한 클래스도 인터프리터가 자동으로 BaseException 서브클래스처럼 취급해줘서 아무 문제 없이 동작한다고 오해하기 쉽다."]','{"correct":1}','UNDERSTAND',0.7,'["custom-exception-must-inherit-baseexception"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드에서 might_fail() 태스크가 예외를 던지면 results 변수에는 무엇이 담기는가?

import asyncio

async def might_fail():
    raise ValueError(''boom'')

async def succeed():
    return ''ok''

async def main():
    results = await asyncio.gather(might_fail(), succeed(), return_exceptions=True)
    print(results)','["return_exceptions=True는 예외를 통째로 삭제해버려 results에는 정상 결과 ''ok'' 하나만 담긴다고 오해하기 쉽다.","return_exceptions=True이므로 gather()는 예외를 던지지 않고, results에 [ValueError(''boom''), ''ok'']처럼 예외 객체와 정상 결과가 함께 담긴다.","return_exceptions 값과 무관하게 첫 예외가 나면 gather()가 즉시 던져 results에는 아무 값도 안 담긴다고 잘못 알려져 있다.","예외가 발생한 태스크는 자동 재시도되어 results에는 정상 결과 두 개만 담긴다고 오해하기 쉽다."]','{"correct":1}','ANALYZE',0.7,'["asyncio-gather-exceptions"]'),
('PYTHON_BACKEND','CODE_READING','다음 Django 시그널 리시버에서는 어떤 문제가 발생할까요?

from django.db.models import signals
from .models import Product

def product_saved(sender, instance, created, **kwargs):
    if not created:
        instance.last_synced = True
        instance.save()

signals.post_save.connect(product_saved, sender=Product)','["instance.save()가 post_save 시그널을 다시 트리거해 무한 재귀 호출되고 결국 RecursionError로 이어질 수 있다.","업데이트된 제품에 한해서만 시그널 리시버가 정확히 한 번 호출되고, Django가 재귀 호출을 자동으로 감지해 두 번째 호출부터 조용히 무시해준다고 오해하기 쉽다.","제품 저장은 시그널 등록 여부와 무관하게 언제나 정확히 딱 한 번만 수행된다고 잘못 알려져 있다.","뷰 함수 쪽에서 처리되지 않은 예외가 나서 요청 전체가 실패로 끝난다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.7,'["django-signal-recursion"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드에서 lambdas[0](1)의 결과는 무엇인가?

numbers = [1, 2, 3]
lambdas = []
for number in numbers:
    lambdas.append(lambda x: x + number)
print(lambdas[0](1))','["for문이 끝나는 순간 number 변수 자체가 사라져서 lambdas[0](1) 호출 시 NameError가 난다고 오해하기 쉽다.","람다는 number를 지연 바인딩(late binding)하므로 모든 람다가 반복문 종료 시점의 마지막 number 값(3)을 참조해, lambdas[0](1)은 4를 반환한다.","리스트에 저장된 람다들은 언제나 numbers의 첫 번째 값(1)만 사용해 2를 반환한다고 잘못 알려져 있다.","각 람다가 생성 시점의 number 값을 즉시 복사해 저장하므로 서로 다른 값으로 2를 반환한다고 오해하기 쉽다."]','{"correct":1}','ANALYZE',0.7,'["lambda-late-binding"]'),
('PYTHON_BACKEND','CODE_READING','다음 함수를 여러 번 호출할 때 어떤 문제가 발생하는가?

def add(item, items=[]):
    items.append(item)
    return items

add(''a'')
add(''b'')','["함수를 호출할 때마다 items 매개변수가 매번 새로운 빈 리스트로 초기화된다고 알려져 있다.","add 함수는 호출될 때마다 완전히 독립적인 items 리스트를 만들어 반환하므로 문제가 없다고 오해하기 쉽다.","items 매개변수의 기본값(list)은 함수 정의 시점에 단 한 번만 생성되어 호출 간에 공유·누적된다.","append() 호출 직후 items가 자동으로 새 빈 리스트로 교체되어 이전 값이 사라진다고 잘못 알려져 있다."]','{"correct":2}','ANALYZE',0.7,'["mutable-default-argument"]'),
('PYTHON_BACKEND','CODE_READING','다음 FastAPI 엔드포인트에서는 어떤 문제가 발생할까요?

from fastapi import APIRouter
import time

router = APIRouter()

@router.get(''/slow'')
async def read_slow():
    time.sleep(5)
    return {''message'': ''done''}','["time.sleep(5)는 5초가 지나면 파이썬이 자동으로 이를 취소해 응답이 즉시 반환된다고 오해하기 쉽다.","time.sleep()이 코루틴이 아니어서 서버가 곧바로 TypeError를 던지며 요청 자체가 실패한다고 잘못 알려져 있다.","time.sleep()은 동기(블로킹) 호출이라 5초 동안 이벤트 루프 전체가 멈춰, 같은 워커가 처리 중인 다른 요청들도 함께 지연된다.","async def로만 선언하면 FastAPI가 함수 안의 모든 동기 호출을 알아서 별도 스레드로 옮겨 실행해준다고 오해하기 쉽다. 실제로는 그런 자동 감지 기능이 없다."]','{"correct":2}','ANALYZE',0.7,'["fastapi-blocking-calls"]'),
('PYTHON_BACKEND','CODE_READING','다음 엔드포인트를 호출했을 때, some_background_task 내부에서 예외가 발생하면 클라이언트는 어떤 응답을 받는가?

from fastapi import APIRouter, BackgroundTasks

def some_background_task():
    raise ValueError(''background failure'')

router = APIRouter()

@router.post(''/endpoint'')
def endpoint(background_tasks: BackgroundTasks):
    background_tasks.add_task(some_background_task)
    return {''status'': ''Task started''}','["add_task 함수는 응답을 만들기 전에 즉시 동기적으로 먼저 실행돼, 예외가 나면 엔드포인트가 실패한다고 오해하기 쉽다.","예외가 발생하면 FastAPI가 자동으로 재시도해 성공할 때까지 응답을 지연시킨다고 잘못 알려져 있다.","백그라운드 작업은 응답이 클라이언트로 전송된 이후에 실행되므로, 예외가 발생해도 클라이언트는 이미 200과 {''status'': ''Task started''}를 받은 뒤다.","백그라운드 작업의 예외는 응답 전송 전에 처리돼 클라이언트가 500 오류를 받는다고 오해하기 쉽다."]','{"correct":2}','ANALYZE',0.8,'["fastapi-background-tasks"]'),
('PYTHON_BACKEND','CODE_READING','다음 인증 함수를 실행하면 만료된 토큰에 대해 어떤 결과가 나오는가?

import jwt

SECRET = ''my-secret''

def authenticate(token):
    try:
        payload = jwt.decode(token, SECRET, algorithms=[''HS256''], options={''verify_exp'': False})
        return True
    except jwt.InvalidSignatureError:
        return False','["서명이 유효하지 않으면 만료 여부와 무관하게 언제나 인증에 실패한다고만 알려져 있어 다른 함정은 놓치기 쉽다.","options 파라미터는 서명 알고리즘 이름만 지정하는 용도이며 만료 검증과는 전혀 무관하다고 오해하기 쉽다.","options={''verify_exp'': False}로 인해 만료 시간 검증이 꺼져 있어, 서명만 유효하면 만료된 토큰도 인증에 통과한다.","PyJWT는 언제나 만료 시간을 강제로 검증하므로 이 옵션은 실질적으로 아무 효과가 없다고 잘못 알려져 있다."]','{"correct":2}','ANALYZE',0.8,'["jwt-expiration-not-verified"]'),
('PYTHON_BACKEND','CODE_READING','다음 FastAPI 의존성 주입에서는 어떤 동작이 일어날까요?

from fastapi import APIRouter, Depends

call_count = 0

async def get_user_data():
    global call_count
    call_count += 1
    return {''count'': call_count}

router = APIRouter()

@router.get(''/users'')
async def read_users(a=Depends(get_user_data), b=Depends(get_user_data)):
    return {''a'': a, ''b'': b}','["call_count 값이 요청이 들어올 때마다 자동으로 0으로 초기화된다고 오해하기 쉽다.","두 개의 Depends를 한 엔드포인트에서 동시에 쓰면 FastAPI가 예외를 던진다고 잘못 알려져 있다.","get_user_data가 매 요청마다는 물론 같은 요청 안 a와 b 계산 때도 매번 새로 호출된다고 오해하기 쉽다.","같은 요청 안에서 get_user_data가 두 번 쓰였지만 FastAPI가 결과를 캐시해 실제로는 한 번만 호출되므로 a와 b는 같은 값을 갖는다."]','{"correct":3}','UNDERSTAND',0.8,'["fastapi-dependency-injection-caching"]'),
('PYTHON_BACKEND','CODE_READING','이 태스크가 네트워크 오류로 실패해 Celery가 자동으로 재시도하면 어떤 문제가 발생할 수 있는가?

from celery import shared_task
from .models import User

@shared_task(bind=True, max_retries=3)
def add_credit(self, user_id, amount):
    user = User.objects.get(id=user_id)
    user.balance += amount
    user.save()','["balance 필드는 재시도 시점마다 자동으로 초기화되어 금액이 누적되지 않는다고 오해하기 쉽다.","user.balance += amount 연산은 실행할 때마다 잔액을 더하므로, 재시도로 같은 태스크가 두 번 실행되면 금액이 중복 반영된다.","Celery는 같은 태스크 ID의 재시도를 자동 감지해 중복 실행을 스스로 막아준다고 잘못 알려져 있다.","재시도가 일어나면 user_id 자체가 자동으로 바뀌어 다른 사용자에게 적립된다고 오해하기 쉽다."]','{"correct":1}','EVALUATE',0.8,'["celery-idempotency"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드를 프로덕션에서 실행하면 종종(항상은 아니게) notify_later가 실행되지 않고 조용히 사라진다. 원인은 무엇인가?

import asyncio

async def notify_later(user_id):
    await asyncio.sleep(5)
    await send_notification(user_id)

async def handle_event(user_id):
    asyncio.create_task(notify_later(user_id))
    return {''status'': ''accepted''}','["asyncio.create_task()로 만든 태스크의 참조를 어디에도 보관하지 않아, 이벤트 루프의 가비지 컬렉션이 태스크를 실행 도중 수거해버려 콜백이 예고 없이 취소될 수 있다.","await asyncio.sleep(5)는 5초가 지나기 전에 런타임이 강제로 타임아웃시켜 send_notification 호출이 아예 이뤄지지 못한다고 오해하기 쉽다. 실제로는 타임아웃이 아니라 참조 소실이 원인이다.","asyncio.create_task()는 handle_event가 반환된 뒤에는 코루틴을 예약할 수 없어 태스크가 애초에 생성되지 않는다고 잘못 알려져 있다.","send_notification 안 예외가 이미 완료된 handle_event의 응답까지 역전파되어 응답을 소급 취소시킨다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.9,'["asyncio-task-lost-reference"]'),
('PYTHON_BACKEND','CODE_READING','다음 설정에서 send_report 태스크가 정상 처리되고 있음에도(예외 없이) 같은 작업이 다른 워커에 또 배달되어 두 번 실행되는 일이 반복된다. 왜 그런가?

# celeryconfig.py
broker_transport_options = {''visibility_timeout'': 30}  # 초

@app.task(acks_late=True)
def send_report(report_id):
    generate_and_send(report_id)  # 평균 90초 소요','["acks_late=True는 태스크가 실제로 실패했을 때만 재전달을 트리거하는 옵션이라서, 정상적으로 처리되고 있는 태스크가 중복 배달될 리는 전혀 없으며 visibility_timeout 값 자체가 무의미해진다고 오해하기 쉽다.","acks_late=True에서는 워커가 태스크를 ''완료한 뒤''에 ack을 보낸다. visibility_timeout(30초)이 이 태스크의 평균 처리 시간(90초)보다 훨씬 짧아, 브로커가 30초 안에 ack을 못 받으면 다른 워커가 아직 죽지 않은 태스크를 재실행 대상으로 간주해 다시 배달한다.","visibility_timeout이라는 설정은 결과 백엔드 쪽에만 영향을 줄 뿐 태스크가 실제로 배달되는 방식과는 아무 관련이 없으며 브로커는 이 값을 참조조차 하지 않는다고 잘못 알려져 있다.","코드 안에 명시적인 재시도 로직이 없으니 Celery가 이를 스스로 감지해 안전을 위해 알아서 태스크를 복제한 뒤 여러 워커에서 동시에 병렬로 실행하도록 판단해서 처리한다고 오해하기 쉽다."]','{"correct":1}','EVALUATE',0.9,'["celery-acks-late-visibility-timeout"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드에서 두 번째 for 루프는 몇 번의 추가 쿼리를 실행하는가?

qs = Order.objects.prefetch_related(''items'').filter(status=''paid'')

for order in qs.iterator():
    pass

for order in qs:
    print(order.items.count())','["iterator()로 이미 한 번 순회했으므로 그 결과가 내부 결과 캐시에 자동으로 남아, 두 번째 루프는 추가 쿼리 없이 캐시된 결과만 그대로 재사용한다고 오해하기 쉽다. 실제로는 iterator가 캐시를 아예 만들지 않는다.","iterator()는 쿼리셋의 내부 결과 캐시를 채우지 않고 매번 새로 스트리밍하므로, 두 번째 for 루프는 order 목록을 다시 조회하는 쿼리 1번과, prefetch가 다시 적용되지 않아 order.items.count() 호출마다 별도 쿼리가 추가로 발생한다.","iterator()를 한 번이라도 호출한 쿼리셋은 그 뒤로 완전히 재사용이 금지되어 두 번째 순회를 시도하는 시점에 곧바로 예외가 발생한다고 잘못 알려져 있다.","prefetch_related는 iterator() 사용 여부와 완전히 무관하게 항상 내부적으로 결과를 캐시해두므로, 두 번째 순회에서도 캐시된 prefetch 결과가 재사용되어 추가 쿼리가 전혀 발생하지 않는다고 오해하기 쉽다."]','{"correct":1}','ANALYZE',0.9,'["django-queryset-iterator-prefetch"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드에서 마지막 Item.objects.create(sku=''B1'') 줄에서 어떤 일이 벌어지는가?

from django.db import transaction, IntegrityError
from .models import Item

def create_items():
    with transaction.atomic():
        Item.objects.create(sku=''A1'')
        try:
            Item.objects.create(sku=''A1'')  # sku는 unique 제약
        except IntegrityError:
            pass
        Item.objects.create(sku=''B1'')
    return ''done''','["atomic 블록 안에서 IntegrityError를 그 자리에서 잡았으니 트랜잭션 상태가 완전히 정상으로 복구되어 B1 생성도 아무 문제 없이 수행된다고 오해하기 쉽다.","atomic 블록 내부에서 DB 수준 예외가 발생하면 해당 트랜잭션이 rollback 대상으로 표시되어, 이후 같은 블록 안의 쿼리 실행 시 TransactionManagementError가 발생한다.","A1이라는 sku가 중복 생성되어 unique 제약을 어긴 채로 데이터베이스에 두 레코드가 그대로 남는다고 잘못 알려져 있다.","IntegrityError는 Django의 트랜잭션 매니저가 알아서 조용히 무시해버려서 이후 코드는 영향받지 않는다고 오해하기 쉽다."]','{"correct":1}','ANALYZE',0.9,'["django-atomic-exception-inside-block"]'),
('PYTHON_BACKEND','CODE_READING','다음 엔드포인트를 호출하면 응답 JSON에 is_admin 필드가 포함되는가?

class UserOut(BaseModel):
    id: int
    email: str

class AdminUser(BaseModel):
    id: int
    email: str
    is_admin: bool

@app.get(''/users/{user_id}'', response_model=UserOut)
def get_user(user_id: int):
    return AdminUser(id=user_id, email=''a@b.com'', is_admin=True)','["함수가 실제로 반환한 값이 is_admin 필드까지 포함한 AdminUser 인스턴스이므로 그 필드도 그대로 응답에 실린다고 오해하기 쉽다.","response_model=UserOut이 실제로 반환된 값의 타입(AdminUser)과 정확히 일치하지 않으므로, FastAPI가 이를 스키마 위반으로 간주해 응답 직렬화 단계에서 즉시 500 오류를 던진다고 잘못 알려져 있다.","response_model은 문서화용 스키마 생성에만 관여할 뿐 실제 직렬화 결과는 반환값 그대로 나간다고 오해하기 쉽다.","FastAPI는 response_model에 선언된 필드(id, email)만 직렬화해 응답에 담고, is_admin은 조용히 걸러져 응답에 포함되지 않는다."]','{"correct":3}','EVALUATE',0.9,'["fastapi-response-model-field-truncation"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드에서 태스크가 외부에서 task.cancel()로 취소되면 finally 블록은 실행되는가, 그리고 except Exception은 취소를 잡아 삼키는가?

async def worker():
    conn = await acquire_connection()
    try:
        while True:
            await process_next(conn)
    except Exception:
        logger.exception(''worker failed'')
    finally:
        await conn.close()','["asyncio.CancelledError는 파이썬 3.8부터 Exception이 아닌 BaseException을 직접 상속하므로 except Exception에 잡히지 않고 그대로 전파되며, finally의 conn.close()는 정상적으로 실행된다.","취소 시 CancelledError는 여전히 Exception의 서브클래스로 취급되어서 except Exception이 이를 그대로 잡아 로깅한 뒤 루프를 조용히 종료한다고 오해하기 쉽다.","task.cancel()이 호출되는 순간 런타임이 finally 블록 실행을 건너뛰고 즉시 태스크를 종료해버려서 conn.close()는 절대 호출되지 않는다고 잘못 알려져 있다.","CancelledError는 async 함수 문맥 안에서는 애초에 발생할 수 없는 개념이며 task.cancel() 호출은 사실상 아무 효과가 없다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.9,'["asyncio-cancelled-error-baseexception"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드는 주문 저장 후 이메일을 보낸다. 이 코드를 TestCase 기반 테스트에서 실행하면 이메일 발송 함수가 호출되는가?

from django.db import transaction

def place_order(order):
    order.save()
    transaction.on_commit(lambda: send_order_email(order.id))

class OrderTest(django.test.TestCase):
    def test_place_order_sends_email(self):
        place_order(make_order())
        assert email_was_sent()','["on_commit에 등록한 콜백은 save() 함수 호출 직후 예외 없이 즉시 동기적으로 실행되므로, 이 테스트는 어떤 상황에서도 항상 통과한다고 오해하기 쉽다.","django.test.TestCase는 각 테스트를 트랜잭션으로 감싸고 테스트가 끝나면 항상 롤백하므로, 실제 커밋이 일어나지 않아 on_commit 콜백이 전혀 실행되지 않는다. 운영에서는 되는데 테스트에서만 실패하는 전형적인 원인이다.","on_commit은 Django 시그널 시스템의 일종이라서 signals.py 파일에 별도로 등록하지 않으면 어떤 경우에도 무시된다고 잘못 알려져 있다.","TestCase는 각 테스트 메서드가 시작·종료될 때마다 실제 데이터베이스에 진짜 커밋을 수행하도록 설계되어 있어, 콜백도 매 테스트마다 정상 호출된다고 오해하기 쉽다."]','{"correct":1}','ANALYZE',0.9,'["django-on-commit-hook"]'),
('PYTHON_BACKEND','CODE_READING','Order 모델은 nullable ForeignKey인 coupon(Coupon, null=True)을 갖고, Coupon은 여러 Order와 연결되는 역참조 관계다. 다음 코드에서 문제가 되는 부분은?

orders = Order.objects.select_related(''coupon'', ''coupon__campaigns'')

for order in orders:
    print(order.coupon.code if order.coupon else ''no coupon'')
    for campaign in order.coupon.campaigns.all() if order.coupon else []:
        print(campaign.name)','["select_related(''coupon'')는 coupon 필드가 null인 주문을 만나는 순간 예외를 던져버려서 이 쿼리 자체가 실행 도중 실패한다고 오해하기 쉽다. 실제로는 nullable FK에도 select_related가 정상적으로 동작한다.","coupon__campaigns가 역참조(reverse FK) 또는 M2M 관계라면 select_related로는 가져올 수 없어 무시되고, campaigns.all() 순회 시 각 쿠폰마다 별도 쿼리가 실행되는 N+1이 그대로 발생한다. 그 경우 prefetch_related로 바꿔야 한다.","coupon이 nullable FK이니 select_related가 항상 INNER JOIN을 강제해서 coupon이 없는 주문은 결과 집합에서 자동으로 완전히 제외되고 반환되지 않는다고 잘못 알려져 있다. 실제로는 LEFT OUTER JOIN을 사용한다.","select_related에 필드를 여러 개 한꺼번에 넘기면 두 번째 인자부터는 조용히 무시되어 coupon만 조인되고 campaigns는 애초에 요청조차 되지 않는다고 오해하기 쉽다. 실제로는 두 필드 모두 처리를 시도한다."]','{"correct":1}','ANALYZE',0.9,'["django-select-related-limits"]'),
('PYTHON_BACKEND','CODE_READING','다음 코드를 실행하면 마지막 print(user.name)에서 어떤 일이 벌어지는가?

from sqlalchemy.orm import sessionmaker

Session = sessionmaker(bind=engine)  # expire_on_commit 기본값(True) 그대로

def get_username(user_id):
    with Session() as session:
        user = session.query(User).get(user_id)
        session.commit()
    return user

user = get_username(1)
print(user.name)','["expire_on_commit 기본값(True) 때문에 commit() 시점에 user 인스턴스의 속성이 만료(expire)되고, with 블록을 벗어나 세션이 닫힌 뒤 user.name에 접근하면 새로 SELECT를 시도하다가 DetachedInstanceError가 발생한다.","session.commit()은 인스턴스 속성에 어떤 영향도 주지 않으므로 print(user.name)은 세션이 닫힌 뒤에도 항상 처음에 캐시된 값을 그대로 출력한다고 오해하기 쉽다. 실제로는 expire_on_commit 기본값이 속성을 만료시킨다.","with 블록을 벗어나 세션이 닫히는 순간 user 객체 자체가 자동으로 None으로 바뀌어버려서, print(user.name)이 AttributeError를 낸다고 잘못 알려져 있다. 실제로는 객체 자체는 살아있고 속성 접근만 실패한다.","get_username이 값을 반환하기 전에 SQLAlchemy가 세션이 추적하던 모든 속성 값을 미리 순수 파이썬 타입으로 자동 복사해두어서, 세션이 닫힌 뒤에도 print(user.name)이 언제나 안전하게 출력된다고 오해하기 쉽다."]','{"correct":0}','ANALYZE',0.9,'["sqlalchemy-expire-on-commit"]'),
('PYTHON_BACKEND','CODE_READING','다음 gunicorn 설정으로 서비스를 띄운 뒤 얼마 지나지 않아 워커들이 무작위로 ''connection already closed'' 또는 ''server closed the connection unexpectedly'' 오류를 던진다. 가장 유력한 원인은?

# gunicorn.conf.py
preload_app = True
workers = 4

# app.py (모듈 최상단, import 시점에 실행됨)
engine = create_engine(DATABASE_URL)
db_connection = engine.connect()','["preload_app=True는 오히려 각 워커가 자기 몫의 커넥션을 새로 여는 것 자체를 원천적으로 차단해버려서 워커가 뜰 때마다 언제나 즉시 오류가 발생한다고 오해하기 쉽다. 실제로는 커넥션을 여는 것을 막지 않는다.","workers=4로 설정하기만 하면 gunicorn이 데이터베이스 커넥션 풀 크기를 자동으로 4등분해 각 워커에게 정확히 나눠 배분해주므로 별도 설정이 전혀 필요 없다고 잘못 알려져 있다.","preload_app=True는 마스터 프로세스가 앱을 한 번만 로드한 뒤 fork로 워커를 만든다. 이때 import 시점에 이미 연 DB 커넥션(db_connection)까지 그대로 fork되어, 여러 워커가 같은 소켓을 공유하다가 한쪽이 사용하거나 닫으면 다른 워커의 연결이 깨진다.","gunicorn은 preload_app 설정과 무관하게 fork() 시점에 항상 부모의 모든 전역 변수(열린 커넥션 포함)를 완전히 새로 초기화해 자식에게 넘기도록 설계되어 있어, 이 코드에서는 충돌이 절대 일어날 수 없다고 잘못 알려져 있다."]','{"correct":2}','ANALYZE',0.9,'["gunicorn-preload-app-fork"]');

INSERT INTO contents (slug, title, track, content_md, estimated_minutes, difficulty, bloom_level, concept_tags, status) VALUES
('python-backend-asyncio-gather-basics','Python asyncio.gather 이해하기','PYTHON_BACKEND','`asyncio.gather()`는 여러 코루틴을 동시에 실행하고, 모두 끝날 때까지 기다렸다가 결과를 리스트로 모아줍니다. 코루틴을 하나씩 `await`하면 순서대로 실행되지만, `gather`로 묶으면 I/O 대기 시간이 겹쳐서 전체 소요 시간이 줄어듭니다.

```python
import asyncio

class DataFetcher:
    async def fetch_data_1(self):
        await asyncio.sleep(1)
        return ''Data 1''

    async def fetch_data_2(self):
        await asyncio.sleep(1)
        return ''Data 2''

async def main():
    fetcher = DataFetcher()
    results = await asyncio.gather(
        fetcher.fetch_data_1(),
        fetcher.fetch_data_2(),
    )
    print(results)  # [''Data 1'', ''Data 2'']

asyncio.run(main())
```
`fetch_data_1`과 `fetch_data_2`를 각각 `await`로 따로 호출했다면 총 2초가 걸렸겠지만, `gather`로 묶으면 두 `sleep(1)`이 동시에 진행되어 약 1초 만에 끝납니다. 외부 API 여러 개를 순서와 상관없이 동시에 호출해야 할 때 자주 쓰는 패턴입니다.',10,0.35,'REMEMBER','["python-asyncio"]'::jsonb,'PUBLISHED'),
('python-backend-class-vs-instance-methods','클래스 메서드와 인스턴스 메서드의 차이점','PYTHON_BACKEND','Python에서 클래스 메서드는 `@classmethod` 데코레이터를 사용하여 정의되며, 첫 번째 파라미터로 클래스 자체(`cls`)를 받습니다. 인스턴스 메서드는 첫 번째 파라미터로 인스턴스(`self`)를 받아 그 객체의 상태를 읽거나 바꿉니다.

```python
class MyClass:
    class_var = 0

    @classmethod
    def increment_class_var(cls):
        cls.class_var += 1
        return cls.class_var

    def increment_instance_attr(self, value):
        self.instance_var = value

a = MyClass()
b = MyClass()
MyClass.increment_class_var()
print(a.class_var, b.class_var)  # 1 1 — class_var는 모든 인스턴스가 공유한다

a.increment_instance_attr(10)
print(a.instance_var)            # 10
print(hasattr(b, ''instance_var''))  # False — instance_var는 a에만 있다
```
`class_var`는 클래스 자체에 속한 상태라 어떤 인스턴스로 바꾸든 모든 인스턴스에서 같은 값이 보입니다. 반면 `increment_instance_attr`로 설정한 `instance_var`는 그 인스턴스에만 존재합니다. 여러 요청이 같은 클래스를 공유하는 웹 백엔드에서 클래스 변수에 요청별 상태를 실수로 저장하면 요청 간에 상태가 새는 버그가 생깁니다.',10,0.35,'REMEMBER','["python-classmethod"]'::jsonb,'PUBLISHED'),
('python-backend-context-managers','컨텍스트 매니저 이해하기','PYTHON_BACKEND','Python에서 컨텍스트 매니저는 `with` 문을 통해 사용됩니다. 이 구조를 이용하면 리소스를 열고 닫는 코드를 명시적으로 반복하지 않아도, 블록을 빠져나갈 때(예외가 나더라도) 자동으로 정리 작업이 실행됩니다.

다음은 파일을 열고, 프로그램이 블록을 빠져나갈 때 자동으로 파일을 닫아주는 간단한 컨텍스트 매니저입니다.

```python
class SafeFile:
    def __init__(self, filename):
        self.filename = filename
        self.filehandle = None

    def __enter__(self):
        self.filehandle = open(self.filename, ''r'')
        return self.filehandle

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.filehandle:
            self.filehandle.close()
        return False
```

```python
with SafeFile(''example.txt'') as f:
    for line in f.readlines():
        print(line)
```
`self.filehandle = None`을 `__init__`에서 먼저 초기화해두는 이유는, `open()`이 실패해도 `__exit__`이 존재하지 않는 속성을 참조하다 새로운 예외를 던지지 않게 하기 위해서입니다. `__exit__`이 `False`를 반환하면 블록 안에서 발생한 예외는 그대로 바깥으로 전파됩니다.',15,0.4,'ANALYZE','["python-context-managers"]'::jsonb,'PUBLISHED'),
('python-backend-decorators-use','데코레이터의 사용법 및 이해','PYTHON_BACKEND','Python에서 데코레이터는 함수에 행동을 추가하기 위해 사용됩니다. 예를 들어, 로깅 기능을 적용하거나 성능 측정 등을 수행할 수 있습니다.

데코레이터는 `@decorator_name` 형태로 함수 위에 정의합니다. 아래 예제에서 `my_decorator` 데코레이터는 `say_hello` 함수를 감싸서 실행 시 추가 기능을 제공합니다.

```python
import functools

def my_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        print(''Something is happening before the function is called.'')
        result = func(*args, **kwargs)
        print(f''Something is happening after the function is called. Result: {result}'')
        return result
    return wrapper

@my_decorator
def say_hello(name):
    return f''Hello, {name}''

say_hello(''World'')
```
`say_hello(''World'')`를 호출하면 실제로는 `wrapper`가 실행되면서 원래 함수 호출 앞뒤로 로그가 찍힙니다. `functools.wraps`를 빼먹으면 `say_hello.__name__`이 `''wrapper''`로 바뀌어버리는 부작용도 있으니 데코레이터를 작성할 때는 항상 함께 사용하는 습관을 들이는 것이 좋습니다.',12,0.35,'UNDERSTAND','["python-decorators"]'::jsonb,'PUBLISHED'),
('python-backend-django-transaction-atomic-basics','Django에서 트랜잭션 관리하기','PYTHON_BACKEND','트랜잭션은 여러 데이터베이스 작업을 하나의 원자적 단위로 묶어, 중간에 실패하면 전부 취소(롤백)되도록 보장합니다. Django는 `transaction.atomic()`으로 이 범위를 지정합니다.

아래 `create_user` 함수는 유저 생성과 프로필 생성, 두 가지 작업을 수행합니다. 둘 중 하나라도 실패하면 다른 하나도 저장되지 않아야 합니다.

```python
from django.db import transaction

def create_user(username, email):
    with transaction.atomic():
        user = User.objects.create_user(username=username, email=email)
        Profile.objects.create(user=user)  # 여기서 실패하면 user 생성도 롤백된다
```
`with transaction.atomic():` 블록 안에서 예외가 발생하면 Django는 블록 시작 시점의 상태로 데이터베이스를 되돌립니다. 즉 `Profile.objects.create`가 실패해도 이미 실행된 `User.objects.create_user`가 커밋된 채로 남지 않습니다. 이 보장이 없다면 유저는 있는데 프로필은 없는 반쪽짜리 데이터가 생길 수 있습니다.',10,0.35,'REMEMBER','["django-transactions"]'::jsonb,'PUBLISHED'),
('python-backend-fastapi-depends-basics','FastAPI에서 의존성 주입 이해하기','PYTHON_BACKEND','FastAPI에서 `Depends`는 경로 함수(라우트 핸들러)가 필요로 하는 자원을 함수 시그니처만으로 선언적으로 받아오게 해주는 의존성 주입 도구입니다.

```python
from fastapi import Depends, FastAPI
from sqlalchemy.orm import Session

app = FastAPI()

def get_db_session():
    session = Session()
    try:
        yield session       # 요청이 처리되는 동안 이 세션을 사용한다
    finally:
        session.close()     # 응답이 끝나면 자동으로 세션을 닫는다

@app.get(''/users/{user_id}'')
def read_user(user_id: int, db: Session = Depends(get_db_session)):
    return db.get(User, user_id)
```
`Depends(get_db_session)`을 파라미터 기본값으로 쓰면, FastAPI가 요청마다 `get_db_session`을 호출해 세션을 만들고 `read_user`에 전달합니다. `get_db_session`이 제너레이터인 이유는 `yield` 이후의 `finally` 블록이 응답을 클라이언트에게 보낸 뒤 실행되어, 요청마다 세션이 확실히 닫히도록 보장하기 때문입니다. 이렇게 하면 각 라우트 함수가 세션 생성·종료 로직을 직접 반복하지 않아도 됩니다.',14,0.5,'UNDERSTAND','["fastapi-dependency-injection"]'::jsonb,'PUBLISHED'),
('python-backend-shallow-vs-deep-copy','Python에서 얕은 복사와 깊은 복사의 차이점','PYTHON_BACKEND','Python에서는 객체를 복제할 때 얕은 복사와 깊은 복사를 구분합니다. 차이는 중첩된(nested) 객체까지 새로 복사하는지에 있습니다.

얕은 복사는 바깥쪽 컨테이너만 새로 만들고, 그 안의 요소는 원본과 같은 객체를 참조합니다. 깊은 복사는 중첩된 요소까지 재귀적으로 복사해 원본과 완전히 독립된 객체를 만듭니다.

```python
import copy

class Box:
    def __init__(self, value):
        self.value = value

original_list = [Box(1), Box(2)]

shallow_copied = original_list[:]        # 얕은 복사
deep_copied = copy.deepcopy(original_list)  # 깊은 복사

shallow_copied[0].value = ''changed by shallow''
deep_copied[1].value = ''changed by deep''

print(original_list[0].value)  # ''changed by shallow'' — 같은 Box 객체를 참조하므로 원본도 바뀐다
print(original_list[1].value)  # 2 — deep_copied는 완전히 별개의 Box 객체라 원본은 그대로다
```
`shallow_copied[0]`을 바꾸면 원본의 `Box(1)`도 함께 바뀌지만, `deep_copied[1]`을 바꿔도 원본의 `Box(2)`는 영향을 받지 않습니다. 가변 객체를 담은 리스트를 함수 인자로 넘기거나 캐시에 저장할 때 이 차이를 모르면 의도치 않게 원본 데이터를 오염시키는 버그로 이어집니다.',12,0.5,'REMEMBER','["python-copying"]'::jsonb,'PUBLISHED'),
('python-backend-threading-vs-asyncio','스레드와 asyncio에 대한 이해','PYTHON_BACKEND','Python에서 스레드를 사용하면 여러 작업을 운영체제가 스케줄링하는 별도의 실행 흐름으로 동시에 진행할 수 있고, `asyncio`를 사용하면 하나의 스레드 안에서 협력적으로(cooperatively) 여러 작업을 번갈아 실행할 수 있습니다.

```python
import threading
import asyncio
import time

def blocking_io_bound_task():  # 스레드로 실행
    print(f''Starting blocking task in thread {threading.current_thread().name}'')
    time.sleep(2)
    print(''Completed blocking task'')

async def non_blocking_io_bound_task():  # 코루틴으로 실행
    print(''Starting async task'')
    await asyncio.sleep(2)
    print(''Completed async task'')

thread = threading.Thread(target=blocking_io_bound_task)
thread.start()

asyncio.run(non_blocking_io_bound_task())
thread.join()
```
`time.sleep(2)`는 스레드를 점유한 채로 대기하므로, 그 스레드 안에서는 다른 작업을 끼워 넣을 수 없습니다. 반면 `await asyncio.sleep(2)`는 대기하는 동안 이벤트 루프의 제어권을 다른 코루틴에 넘겨줍니다. 그래서 I/O 대기가 많은 웹 백엔드에서는 스레드를 늘리는 것보다 `asyncio`로 협력적 동시성을 쓰는 편이 자원을 더 적게 쓰면서도 많은 요청을 처리할 수 있습니다.',14,0.55,'UNDERSTAND','["python-threading","python-asyncio"]'::jsonb,'PUBLISHED'),
('python-backend-async-blocking-http-clients','비동기 코드에서 동기 HTTP 클라이언트가 이벤트 루프를 막는 문제','PYTHON_BACKEND','`async def` 안에서 `requests` 같은 동기(블로킹) 라이브러리를 그대로 호출하면, 그 요청이 끝날 때까지 이벤트 루프 전체가 멈춥니다. 같은 이벤트 루프에서 동시에 처리되던 다른 요청들도 함께 대기하게 됩니다.

```python
import asyncio
import aiohttp
import requests

async def fetch_async(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.text()

async def fetch_blocking(url):
    # requests.get은 동기 함수라, 이 호출이 끝날 때까지
    # 이벤트 루프에 등록된 다른 코루틴은 전혀 진행되지 못한다.
    return requests.get(url).text
```
FastAPI 같은 ASGI 애플리케이션에서 `fetch_blocking`처럼 동기 라이브러리를 `async def` 핸들러 안에 그대로 쓰면, 한 요청이 느려질 때 서버 전체의 다른 요청까지 함께 지연됩니다. 해결책은 두 가지입니다. `aiohttp`나 `httpx.AsyncClient`처럼 진짜 비동기 라이브러리로 바꾸거나, 부득이하게 동기 라이브러리를 써야 한다면 `await asyncio.to_thread(requests.get, url)`로 별도 스레드에 위임해 이벤트 루프를 막지 않게 해야 합니다.',16,0.7,'ANALYZE','["python-asyncio","asyncio-blocking-calls"]'::jsonb,'PUBLISHED'),
('python-backend-asyncio-gather-vs-threadpool','asyncio.gather와 ThreadPoolExecutor의 차이점','PYTHON_BACKEND','`asyncio.gather()`는 여러 코루틴을 동시에 실행하지만, 이것이 실제 CPU 병렬 처리를 의미하지는 않습니다. `asyncio`는 단일 스레드에서 협력적으로 작업을 번갈아 실행할 뿐이라, CPU를 많이 쓰는 연산에는 도움이 되지 않습니다.

```python
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor

def compute_heavy_task(n):
    time.sleep(1)  # CPU 바운드 작업을 흉내낸다
    return n * n

async def main_gather(num_tasks):
    # compute_heavy_task는 async 함수가 아니므로 이렇게 그냥 호출하면
    # gather는 ''코루틴이 아닌 값''을 넘겨받아 TypeError를 던진다.
    # asyncio로 CPU 바운드 작업을 병렬화하려면 to_thread로 감싸야 한다.
    tasks = [asyncio.to_thread(compute_heavy_task, i) for i in range(num_tasks)]
    return await asyncio.gather(*tasks)

def synchronous_main(num_tasks):
    with ThreadPoolExecutor(max_workers=num_tasks) as executor:
        futures = [executor.submit(compute_heavy_task, i) for i in range(num_tasks)]
        return [future.result() for future in futures]
```
`asyncio.gather()`만으로는 동기 함수를 병렬로 돌릴 수 없습니다. `compute_heavy_task`처럼 블로킹되는 일반 함수를 넘기려면 `asyncio.to_thread`로 감싸 별도 스레드에서 실행해야 하며, 이는 결국 `ThreadPoolExecutor`를 내부적으로 쓰는 것과 원리가 같습니다. asyncio 자체의 이점은 I/O 대기가 많은 작업(네트워크 호출 등)을 적은 스레드로 많이 동시에 처리하는 데 있지, CPU 연산을 빠르게 만들어주는 것이 아닙니다.',16,0.7,'ANALYZE','["python-asyncio","python-concurrency"]'::jsonb,'PUBLISHED'),
('python-backend-celery-task-retry-idempotency','Celery 작업을 재시도해도 안전하게 만들기(멱등성)','PYTHON_BACKEND','Celery 워커는 네트워크 오류나 일시적 장애로 작업이 실패하면 자동으로 재시도할 수 있습니다. 문제는 재시도 도중 작업이 ''부분적으로는 이미 성공''했을 수 있다는 점입니다 — 예를 들어 결제 승인 요청은 실제로 처리됐는데, 그 직후 응답을 받기 전에 네트워크가 끊겨 태스크가 실패로 처리되고 재시도되는 경우입니다. 같은 작업을 몇 번 실행해도 결과가 달라지지 않는 성질을 멱등성(idempotency)이라 하며, 재시도 가능한 태스크라면 반드시 이를 보장해야 합니다.

```python
from celery import shared_task

@shared_task(bind=True, max_retries=3, default_retry_delay=10)
def charge_order(self, order_id, idempotency_key):
    order = Order.objects.get(id=order_id)

    # 이미 이 idempotency_key로 처리된 결제가 있는지 먼저 확인한다
    if Payment.objects.filter(idempotency_key=idempotency_key).exists():
        return  # 이미 처리됐으므로 다시 결제하지 않는다

    try:
        result = payment_gateway.charge(order.total, idempotency_key=idempotency_key)
        Payment.objects.create(order=order, idempotency_key=idempotency_key, status=result.status)
    except PaymentGatewayTimeout as exc:
        raise self.retry(exc=exc)
```
`idempotency_key`를 결제 게이트웨이와 우리 쪽 `Payment` 레코드 양쪽에서 같이 사용하는 것이 핵심입니다. 태스크가 재시도되어 `charge_order`가 다시 실행돼도, 이미 같은 키로 결제가 기록돼 있으면 함수 맨 앞의 조회에서 걸려 중복 결제를 막습니다. `self.retry(exc=exc)`는 태스크를 즉시 실패시키는 대신 `default_retry_delay` 뒤에 다시 큐에 넣습니다.',18,0.75,'APPLY','["celery","idempotency"]'::jsonb,'PUBLISHED'),
('python-backend-django-middleware-auth-check','Django 미들웨어로 요청 전처리하기','PYTHON_BACKEND','미들웨어는 모든 요청이 뷰에 도달하기 전, 그리고 모든 응답이 클라이언트로 나가기 전에 공통으로 거치는 지점입니다. 인증 확인, 로깅, 요청 헤더 검사처럼 여러 뷰에 반복되는 로직을 한 곳에 모을 때 씁니다.

```python
from django.shortcuts import redirect
from django.utils.deprecation import MiddlewareMixin

class RequireLoginMiddleware(MiddlewareMixin):
    EXEMPT_PATHS = {''/login/'', ''/signup/''}

    def process_request(self, request):
        if request.path in self.EXEMPT_PATHS:
            return None
        if not request.user.is_authenticated:  # 메서드가 아니라 프로퍼티다
            return redirect(''/login/'')
        return None
```
`request.user.is_authenticated`는 함수가 아니라 불리언 값을 담은 프로퍼티라서, `is_authenticated()`처럼 괄호를 붙여 호출하면 `TypeError: ''bool'' object is not callable`이 납니다. `process_request`가 `None`을 반환하면 Django는 요청 처리를 계속 다음 미들웨어와 뷰로 넘기고, `HttpResponse`(여기서는 `redirect`)를 반환하면 그 지점에서 요청 처리를 멈추고 바로 응답합니다. `EXEMPT_PATHS`처럼 로그인 페이지 자체는 검사에서 빼지 않으면 로그인 화면으로도 못 들어가는 무한 리다이렉트에 빠지기 쉽습니다.',16,0.6,'ANALYZE','["django-middleware"]'::jsonb,'PUBLISHED'),
('python-backend-django-select-related-vs-prefetch-related','Django ORM에서 select_related와 prefetch_related의 차이점','PYTHON_BACKEND','두 메서드 모두 N+1 쿼리 문제를 줄이기 위한 것이지만, 적용 대상이 다릅니다. `select_related()`는 `ForeignKey`·`OneToOneField`처럼 ''하나''를 참조하는 관계에 `JOIN`을 걸어 한 번의 쿼리로 가져옵니다. `prefetch_related()`는 `ManyToManyField`나 역방향 `ForeignKey`처럼 ''여러 개''를 참조하는 관계에 쓰며, 관련 객체를 별도 쿼리로 가져온 뒤 파이썬에서 묶어줍니다.

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)

class Book(models.Model):
    title = models.CharField(max_length=100)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    tags = models.ManyToManyField(''Tag'')

# author는 ForeignKey이므로 select_related로 JOIN 한 번에 가져온다
books = Book.objects.select_related(''author'').all()
for book in books:
    print(book.author.name)  # 추가 쿼리 없음

# tags는 ManyToManyField이므로 prefetch_related로 별도 쿼리 한 번에 가져온다
books = Book.objects.prefetch_related(''tags'').all()
for book in books:
    print([tag.name for tag in book.tags.all()])  # 추가 쿼리 없음
```
`select_related(''author'')`를 빼먹으면 `book.author.name`을 호출할 때마다 쿼리가 하나씩 나가는 전형적인 N+1이 됩니다. 반대로 `ForeignKey`에 `prefetch_related`를 쓰는 것도 동작은 하지만, `JOIN` 한 번으로 끝날 일을 굳이 별도 쿼리로 나눠 처리하는 셈이라 `select_related`보다 비효율적입니다.',18,0.8,'ANALYZE','["django-orm","django-n-plus-one"]'::jsonb,'PUBLISHED'),
('python-backend-django-settings-separation','Django 설정을 환경별로 분리하기','PYTHON_BACKEND','개발·테스트·운영 환경마다 데이터베이스 주소나 `DEBUG` 값이 달라야 하는데, 이를 하나의 `settings.py`에 조건문으로 다 넣으면 파일이 금방 지저분해지고 실수로 운영 설정이 개발 환경에 섞이기 쉽습니다. 공통 설정을 `base.py`로 뽑고 환경별로 상속하는 구조가 일반적입니다.

```python
# settings/base.py
INSTALLED_APPS = [''django.contrib.admin'', ''django.contrib.auth'']
DEBUG = False

# settings/local.py
from .base import *
DEBUG = True
DATABASES = {''default'': {''ENGINE'': ''django.db.backends.sqlite3'', ''NAME'': ''db.sqlite3''}}

# settings/production.py
import os
from .base import *
DATABASES = {''default'': {
    ''ENGINE'': ''django.db.backends.postgresql'',
    ''HOST'': os.environ[''DB_HOST''],
    ''PASSWORD'': os.environ[''DB_PASSWORD''],
}}
```
실행 시점에는 환경 변수 `DJANGO_SETTINGS_MODULE`을 어떤 파일로 가리키느냐로 환경을 전환합니다. 예를 들어 `DJANGO_SETTINGS_MODULE=myproject.settings.production python manage.py runserver`처럼 실행하면 `production.py`가 로드됩니다. `production.py`가 비밀번호 같은 값을 코드에 직접 적지 않고 `os.environ[''DB_PASSWORD'']`로 읽어오는 것도 중요한 습관인데, 이렇게 하면 운영 자격 증명이 저장소에 커밋되는 사고를 막을 수 있습니다.',16,0.6,'APPLY','["django-settings"]'::jsonb,'PUBLISHED'),
('python-backend-django-transaction-atomic-decorator','Django에서 atomic 데코레이터를 이용한 트랜잭션 관리','PYTHON_BACKEND','`@transaction.atomic`을 함수에 데코레이터로 붙이면, 함수 전체가 하나의 데이터베이스 트랜잭션으로 실행됩니다. 함수 안에서 예외가 발생하면 그 함수 안에서 이미 실행된 변경 사항까지 전부 롤백됩니다.

```python
from django.db import transaction

@transaction.atomic
def create_order(user, products):
    order = Order.objects.create(customer=user)
    for product in products:
        if product.stock <= 0:
            raise ValueError(f''{product.name} 재고가 없습니다'')
        product.stock -= 1
        product.save()
        OrderItem.objects.create(order=order, product=product)
    return order
```
상품 목록 중간에 재고가 없는 상품이 있어 `ValueError`가 발생하면, 그 이전에 이미 실행된 `Order.objects.create`와 재고 차감, `OrderItem` 생성까지 전부 롤백됩니다. `@transaction.atomic`이 없었다면 주문은 생성됐는데 일부 상품의 재고만 차감된 반쪽짜리 상태가 데이터베이스에 남았을 것입니다. 여러 테이블에 걸친 쓰기 작업을 하나의 비즈니스 로직으로 묶을 때는 항상 이 경계를 명확히 그어야 합니다.',16,0.7,'APPLY','["django-transactions"]'::jsonb,'PUBLISHED'),
('python-backend-drf-nested-serializer-n-plus-one','DRF 중첩 Serializer가 부르는 N+1 문제','PYTHON_BACKEND','Django REST Framework의 `ModelSerializer`는 관계 필드를 중첩해서 표현할 수 있어 편리하지만, 뷰셋의 쿼리셋을 최적화하지 않으면 Django ORM의 N+1 문제가 API 응답 하나마다 그대로 드러납니다.

```python
from rest_framework import serializers, viewsets

class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = [''id'', ''name'']

class BookSerializer(serializers.ModelSerializer):
    author = AuthorSerializer()  # 중첩 serializer

    class Meta:
        model = Book
        fields = [''id'', ''title'', ''author'']

class BookViewSet(viewsets.ModelViewSet):
    serializer_class = BookSerializer
    queryset = Book.objects.select_related(''author'')  # 이게 없으면 책 N권마다 author 쿼리가 하나씩 나간다
```
`BookSerializer`가 책 목록을 직렬화할 때마다 `book.author`에 접근하는데, `BookViewSet.queryset`에 `select_related(''author'')`가 없다면 책이 100권이면 저자를 가져오는 쿼리도 100번 추가로 나갑니다. 목록 API처럼 여러 행을 한 번에 직렬화하는 엔드포인트에서는 `ModelSerializer`에 중첩 필드를 추가할 때마다 그 관계가 `select_related`(FK) 또는 `prefetch_related`(M2M·역참조)로 이미 로드돼 있는지 반드시 확인해야 합니다.',18,0.75,'ANALYZE','["django-rest-framework","django-n-plus-one"]'::jsonb,'PUBLISHED'),
('python-backend-fastapi-background-tasks','FastAPI 백그라운드 태스크로 응답 지연 없이 후속 작업 처리하기','PYTHON_BACKEND','`BackgroundTasks`를 쓰면 클라이언트에게 응답을 먼저 보낸 뒤, 응답과 무관한 후속 작업(이메일 발송, 로그 적재 등)을 이어서 실행할 수 있습니다. 사용자가 이메일이 실제로 전송될 때까지 기다릴 필요가 없어집니다.

```python
from fastapi import BackgroundTasks, Depends, FastAPI
from sqlalchemy.orm import Session

app = FastAPI()

def send_email(to: str, subject: str):
    # 실제로는 SMTP 클라이언트나 이메일 API를 호출한다
    print(f''sending email to {to}: {subject}'')

@app.post(''/orders/'')
async def create_order(user_id: int, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    order = Order(customer_id=user_id)
    db.add(order)
    db.commit()
    db.refresh(order)

    background_tasks.add_task(send_email, ''user@example.com'', ''주문이 접수되었습니다'')
    return {''order_id'': order.id}
```
`background_tasks.add_task(...)`는 작업을 큐에 등록만 할 뿐 즉시 실행하지 않습니다. FastAPI는 `return` 문으로 응답을 클라이언트에게 보낸 ''이후''에 등록된 태스크를 실행합니다. 다만 이 태스크는 API 서버와 같은 프로세스 안에서 동기적으로 실행되므로, 시간이 오래 걸리는 무거운 작업이라면 Celery 같은 별도의 작업 큐로 옮기는 것이 낫습니다. `BackgroundTasks`는 어디까지나 응답 직후에 끝나는 가벼운 후속 작업에 적합합니다.',15,0.6,'APPLY','["fastapi-background-tasks"]'::jsonb,'PUBLISHED'),
('python-backend-fastapi-dependency-injection-depends','FastAPI 의존성 주입(Depends) 이해 및 적용','PYTHON_BACKEND','의존성 주입은 라우트 핸들러가 필요로 하는 자원(DB 세션, 인증된 사용자 등)을 함수 시그니처 선언만으로 받아오게 하는 패턴입니다. FastAPI는 `Depends`로 이를 지원하며, 의존성 함수를 조합해서 재사용할 수 있다는 점이 핵심입니다.

```python
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(db: Session = Depends(get_db), token: str = ''''):
    user = db.query(User).filter(User.token == token).first()
    if user is None:
        raise HTTPException(status_code=401, detail=''Unauthorized'')
    return user

@app.get(''/items/'')
def read_items(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(Item).filter(Item.owner_id == user.id).all()
```
`get_current_user`가 다시 `get_db`에 의존하는 것처럼, `Depends`는 서로 중첩될 수 있습니다. FastAPI는 요청 하나를 처리하는 동안 같은 의존성을 여러 곳에서 요구해도 기본적으로 한 번만 평가한 뒤 결과를 캐시해서 재사용하므로, `get_db`가 여러 핸들러에서 동시에 요구돼도 세션이 중복 생성되지 않습니다.',16,0.6,'APPLY','["fastapi-dependency-injection"]'::jsonb,'PUBLISHED'),
('python-backend-fastapi-pydantic-validation','FastAPI에서 Pydantic 모델 검증 적용하기','PYTHON_BACKEND','Pydantic 모델을 요청 바디 타입으로 선언하면, FastAPI가 요청이 들어올 때마다 자동으로 JSON을 파싱하고 필드 타입·필수 여부를 검증합니다. 검증에 실패하면 핸들러 코드가 실행되기도 전에 422 응답이 반환됩니다.

```python
from typing import Optional
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float = Field(gt=0)
    description: Optional[str] = None

@app.post(''/items/'')
def create_item(item: Item):
    return {''name'': item.name, ''price'': item.price}
```
`price`에 음수나 0을 보내면 `Field(gt=0)` 조건에 걸려 FastAPI가 자동으로 422 응답과 함께 어떤 필드가 왜 실패했는지 알려주는 에러 메시지를 돌려줍니다. `create_item` 함수 안에는 이 검증 로직을 위한 `if` 문이 전혀 없다는 점이 핵심입니다 — 핸들러가 호출된 시점에는 이미 `item`이 유효하다는 것이 보장되므로, 비즈니스 로직과 입력 검증을 분리해서 작성할 수 있습니다.',15,0.6,'APPLY','["fastapi-pydantic-validation"]'::jsonb,'PUBLISHED'),
('python-backend-generators-yield-memory','파이썬 제너레이터로 메모리를 아끼는 방법','PYTHON_BACKEND','제너레이터는 `yield`를 사용해, 전체 결과를 한 번에 리스트로 만들지 않고 값을 필요할 때마다 하나씩 계산해서 내보내는 함수입니다. 큰 데이터를 다룰 때 메모리 사용량을 크게 줄일 수 있습니다.

```python
def load_rows_list(path):
    rows = []
    with open(path) as f:
        for line in f:
            rows.append(line.strip())
    return rows  # 파일 전체를 메모리에 다 올려야 반환할 수 있다

def load_rows_generator(path):
    with open(path) as f:
        for line in f:
            yield line.strip()  # 호출 시점이 아니라 for 루프가 값을 요청할 때 실행된다

# 100만 줄짜리 파일이라도 한 줄씩만 메모리에 올라간다
for row in load_rows_generator(''big_file.csv''):
    process(row)
```
`load_rows_list`는 함수를 호출하는 순간 파일 전체를 읽어 리스트에 담으므로, 파일이 크면 그만큼 메모리를 차지합니다. `load_rows_generator`는 `yield`를 만나는 순간 실행을 멈추고 값을 하나 돌려준 뒤, 다음 값이 요청될 때까지 그 지점에서 대기합니다. 그래서 `for` 루프가 몇 번째 줄까지 갔든 메모리에는 항상 한 줄 분량만 있으면 됩니다. 대용량 로그나 CSV를 처리하는 배치 작업에서 특히 유용한 패턴입니다.',14,0.5,'UNDERSTAND','["python-generators"]'::jsonb,'PUBLISHED'),
('python-backend-redis-cache-aside-invalidation','Redis 캐시-어사이드 패턴과 캐시 무효화','PYTHON_BACKEND','캐시-어사이드(cache-aside)는 가장 흔히 쓰는 캐싱 패턴입니다. 읽을 때는 캐시를 먼저 확인하고 없으면(cache miss) DB를 조회해 캐시에 채워 넣고, 쓸 때는 DB를 갱신한 뒤 해당 캐시를 지워 다음 읽기에서 새로 채워지게 합니다.

```python
import json
import redis

cache = redis.Redis()
CACHE_TTL_SECONDS = 300

def get_product(product_id: int) -> dict:
    key = f''product:{product_id}''
    cached = cache.get(key)
    if cached is not None:
        return json.loads(cached)

    product = db.query(Product).get(product_id)
    data = {''id'': product.id, ''name'': product.name, ''price'': product.price}
    cache.set(key, json.dumps(data), ex=CACHE_TTL_SECONDS)
    return data

def update_product_price(product_id: int, new_price: float) -> None:
    product = db.query(Product).get(product_id)
    product.price = new_price
    db.commit()
    cache.delete(f''product:{product_id}'')  # 캐시를 갱신하지 않고 지운다
```
`update_product_price`가 캐시 값을 새 값으로 덮어쓰는 대신 아예 지우는 이유는, DB 트랜잭션이 커밋되기 직전에 다른 요청이 캐시를 먼저 갱신해버리는 경쟁 조건을 피하기 위해서입니다. 캐시를 지우기만 하면 다음 `get_product` 호출이 DB에서 최신 값을 다시 채워 넣습니다. `ex=CACHE_TTL_SECONDS`로 TTL을 걸어두는 것도 중요한 안전장치인데, 삭제 로직에 버그가 있어 무효화를 놓치더라도 오래된 캐시가 영원히 남지 않고 일정 시간 뒤 자동으로 사라지게 합니다.',18,0.7,'APPLY','["redis-cache","cache-invalidation"]'::jsonb,'PUBLISHED'),
('python-backend-type-hints-generics','파이썬 타입 힌트로 함수 시그니처 명확히 하기','PYTHON_BACKEND','타입 힌트는 실행 시점에 강제되지는 않지만, IDE 자동완성과 정적 분석 도구(`mypy` 등)가 잘못된 사용을 미리 잡아내게 해줍니다. 특히 함수가 여러 곳에서 재사용되는 웹 백엔드에서는 인자·반환값의 타입을 명시해두는 것이 버그를 줄이는 데 도움이 됩니다.

```python
from typing import Optional

def find_user_email(users: list[dict], user_id: int) -> Optional[str]:
    for user in users:
        if user[''id''] == user_id:
            return user[''email'']
    return None

email = find_user_email([{''id'': 1, ''email'': ''a@example.com''}], 1)
if email is not None:
    send_welcome_mail(email)
```
`find_user_email`의 반환 타입을 `Optional[str]`로 명시하면, 이 함수를 호출하는 쪽에서 `None`이 돌아올 수 있다는 사실을 코드만 보고도 알 수 있습니다. 이 힌트 없이 그냥 `str`이라고만 적었다면, 호출부에서 `None` 체크를 깜빡하고 `email.split(''@'')`처럼 바로 메서드를 호출하다 런타임에 `AttributeError`가 나는 실수를 저지르기 쉽습니다. `mypy`를 CI에 연결해두면 이런 실수를 배포 전에 잡아낼 수 있습니다.',14,0.45,'UNDERSTAND','["python-type-hints"]'::jsonb,'PUBLISHED'),
('python-backend-asyncio-run-in-executor-blocking','run_in_executor로 블로킹 호출을 이벤트 루프 밖으로 빼내기','PYTHON_BACKEND','`async def` 핸들러 안에서 CPU 연산이나 동기 라이브러리 호출처럼 블로킹되는 코드를 그대로 실행하면, 그동안 이벤트 루프는 다른 어떤 코루틴도 진행시킬 수 없습니다. `loop.run_in_executor()`는 이런 블로킹 호출을 스레드풀(또는 프로세스풀)로 위임해, 이벤트 루프가 계속 다른 요청을 처리할 수 있게 해줍니다.

```python
import asyncio
import time

def blocking_task():
    print(''Start blocking task...'')
    time.sleep(5)  # 실제로는 CPU 연산이나 동기 라이브러리 호출
    print(''Blocking task complete.'')

async def main():
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, blocking_task)  # None이면 기본 ThreadPoolExecutor를 쓴다
    print(''Back to the event loop'')

asyncio.run(main())
```
`run_in_executor(None, blocking_task)`에서 첫 번째 인자가 `None`이면 이벤트 루프의 기본 `ThreadPoolExecutor`(기본 워커 수는 CPU 코어 수 기반)를 사용합니다. `blocking_task`가 실행되는 동안에도 이벤트 루프 자체는 막히지 않으므로, 같은 프로세스의 다른 코루틴들은 계속 진행됩니다. 다만 이는 GIL(Global Interpreter Lock) 때문에 순수 CPU 바운드 작업에는 한계가 있습니다 — 스레드로 옮겨도 GIL을 쥔 스레드 하나만 실제로 파이썬 바이트코드를 실행할 수 있으므로, 진짜 CPU 병렬성이 필요하면 `ProcessPoolExecutor`를 대신 넘겨야 합니다. I/O 대기가 대부분인 블로킹 호출(동기 DB 드라이버, 파일 시스템 접근 등)에는 스레드풀만으로도 충분합니다.',20,0.85,'ANALYZE','["python-asyncio","asyncio-blocking-calls"]'::jsonb,'PUBLISHED'),
('python-backend-asyncio-semaphore-connection-limit','asyncio.Semaphore로 외부 API 동시 호출 수 제한하기','PYTHON_BACKEND','`asyncio.gather()`로 수백 개의 외부 API 호출을 한꺼번에 실행하면, 상대 서버의 레이트 리밋에 걸리거나 우리 쪽 커넥션 풀이 고갈될 수 있습니다. `asyncio.Semaphore`는 동시에 실행 중인 코루틴 수를 지정한 개수로 제한해 이를 막습니다.

```python
import asyncio
import aiohttp

async def fetch_one(session, url, semaphore):
    async with semaphore:  # 세마포어를 획득해야 다음 줄로 진행한다
        async with session.get(url) as resp:
            return await resp.text()

async def fetch_all(urls, max_concurrent=10):
    semaphore = asyncio.Semaphore(max_concurrent)
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_one(session, url, semaphore) for url in urls]
        return await asyncio.gather(*tasks)
```
`asyncio.gather(*tasks)`에 넘기는 태스크는 1,000개일 수 있지만, `fetch_one` 안의 `async with semaphore:` 블록에는 최대 `max_concurrent`개(여기서는 10개)만 동시에 들어갈 수 있습니다. 11번째 태스크는 앞선 10개 중 하나가 세마포어를 반납(블록을 빠져나감)할 때까지 그 지점에서 대기합니다. 세마포어 없이 `gather`만 쓰면 1,000개의 요청이 순식간에 동시에 나가버려, 상대 서버가 429(Too Many Requests)를 대량으로 반환하거나 우리 쪽 이벤트 루프의 파일 디스크립터가 고갈될 수 있습니다. `max_concurrent` 값은 상대 API의 레이트 리밋과 우리 쪽 네트워크·메모리 여유를 함께 고려해 정해야 합니다.',20,0.82,'APPLY','["python-asyncio","rate-limiting"]'::jsonb,'PUBLISHED'),
('python-backend-celery-acks-late-at-least-once','Celery acks_late와 최소 1회 실행 보장의 트레이드오프','PYTHON_BACKEND','Celery는 기본적으로 워커가 작업을 ''받는'' 즉시 브로커에 ack를 보냅니다(`acks_late=False`). 이 상태에서 워커 프로세스가 작업 도중 죽으면, 브로커는 이미 ack를 받았으므로 그 작업이 처리 중이었다는 사실 자체를 잊어버려 작업이 조용히 유실됩니다. `acks_late=True`로 바꾸면 작업이 ''끝난 뒤''에 ack를 보내므로, 워커가 죽으면 브로커가 그 작업을 다른 워커에게 다시 배정합니다 — 대신 최소 1회(at-least-once) 실행이 되어, 같은 작업이 두 번 실행될 가능성을 감수해야 합니다.

```python
from celery import Celery

app = Celery(''tasks'', broker=''redis://localhost:6379/0'')

@app.task(bind=True, acks_late=True, max_retries=3)
def charge_order(self, order_id: int, idempotency_key: str):
    if Payment.objects.filter(idempotency_key=idempotency_key).exists():
        return  # 이미 처리된 경우 재실행을 무해하게 만든다
    payment_gateway.charge(order_id, idempotency_key=idempotency_key)
    Payment.objects.create(order_id=order_id, idempotency_key=idempotency_key)
```
`acks_late=True`는 ''작업이 최소 한 번은 실행된다''는 것만 보장할 뿐, ''정확히 한 번만'' 실행되는 것은 보장하지 않습니다. 워커가 결제 처리를 끝냈지만 ack를 브로커에 보내기 직전에 네트워크가 끊기면, 브로커는 작업이 실패했다고 판단해 다시 큐에 넣고 다른 워커가 같은 결제를 또 실행할 수 있습니다. 그래서 `acks_late`로 유실을 막는 대신, 태스크 자체를 멱등하게 설계해 중복 실행이 안전하도록 만드는 것이 항상 함께 가는 짝입니다. 둘 중 하나만 있으면 ''유실은 없지만 중복될 수 있는'' 시스템이거나 ''중복은 없지만 유실될 수 있는'' 시스템이 됩니다.',20,0.88,'EVALUATE','["celery","celery-reliability"]'::jsonb,'PUBLISHED'),
('python-backend-django-select-for-update-race-condition','Django select_for_update로 재고 차감 경쟁 조건 막기','PYTHON_BACKEND','두 요청이 동시에 같은 상품의 재고를 차감하면, 둘 다 재고가 1개 남은 것을 읽고 각자 차감해 실제로는 -1이 되어야 할 상황에서도 애플리케이션 레벨에서는 이를 감지하지 못하는 경쟁 조건(race condition)이 생길 수 있습니다. `select_for_update()`는 해당 행에 데이터베이스 수준의 잠금을 걸어, 한 트랜잭션이 끝날 때까지 다른 트랜잭션이 같은 행을 읽지 못하게(정확히는 잠금이 풀릴 때까지 대기하게) 만듭니다.

```python
from django.db import transaction

@transaction.atomic
def decrement_stock(product_id: int, quantity: int) -> bool:
    product = Product.objects.select_for_update().get(id=product_id)
    if product.stock < quantity:
        return False
    product.stock -= quantity
    product.save()
    return True
```
`select_for_update()`는 반드시 `transaction.atomic()` 블록 안에서 써야 합니다 — 잠금은 트랜잭션이 커밋되거나 롤백될 때 풀리기 때문입니다. 두 요청이 동시에 `decrement_stock`을 호출하면, 먼저 도착한 트랜잭션이 그 상품 행을 잠그고, 나중 트랜잭션은 `select_for_update().get(...)` 시점에서 잠금이 풀릴 때까지 ''대기''합니다. 그래서 두 번째 트랜잭션이 실제로 `product.stock`을 읽는 시점에는 이미 첫 번째 트랜잭션이 반영한 최신 재고 값을 보게 되어, 두 요청이 같은 낡은 값을 기준으로 동시에 차감하는 문제가 사라집니다. 다만 잠금 대기 시간이 늘어나므로, 짧게 끝나는 트랜잭션에만 적용해야 전체 처리량이 떨어지지 않습니다.',20,0.85,'EVALUATE','["django-orm","race-condition"]'::jsonb,'PUBLISHED'),
('python-backend-drf-cursor-pagination','DRF 커서 기반 페이지네이션이 오프셋 방식보다 나은 이유','PYTHON_BACKEND','DRF의 `PageNumberPagination`(오프셋 기반)은 `LIMIT ... OFFSET ...`으로 구현됩니다. 오프셋이 커질수록 데이터베이스는 건너뛸 행까지 전부 스캔해야 해서 뒷페이지로 갈수록 느려지고, 조회 도중 새 행이 삽입되면 페이지 경계가 밀려 같은 항목이 중복되거나 누락될 수 있습니다. `CursorPagination`은 정렬 기준 컬럼의 마지막 값을 커서로 써서 이 문제를 피합니다.

```python
from rest_framework.pagination import CursorPagination

class PostCursorPagination(CursorPagination):
    page_size = 20
    ordering = ''-created_at''  # 반드시 고유하거나 tie-break가 되는 정렬 기준이어야 한다

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    pagination_class = PostCursorPagination
    serializer_class = PostSerializer
```
`CursorPagination`은 내부적으로 `WHERE created_at < :마지막으로_받은_값 ORDER BY created_at DESC LIMIT 20`과 같은 쿼리를 만듭니다. 오프셋을 세지 않고 ''어디서부터 이어서'' 가져올지를 값으로 표현하므로, 조회 도중 새 글이 올라와도 이미 받은 페이지의 경계가 흔들리지 않습니다. 대신 임의의 페이지 번호로 바로 점프하는 UI(예: ''5페이지로 이동'')는 만들 수 없다는 제약이 있습니다. `ordering`에 쓰는 컬럼이 유일하지 않으면(예: 같은 `created_at`을 가진 행이 여러 개) 커서가 정확한 위치를 가리키지 못해 항목이 중복되거나 스킵될 수 있으므로, 보통 `id`처럼 유일한 컬럼을 tie-breaker로 추가한 복합 정렬을 씁니다.',20,0.8,'ANALYZE','["django-rest-framework","pagination"]'::jsonb,'PUBLISHED'),
('python-backend-fastapi-background-tasks-async-callable','FastAPI BackgroundTasks가 비동기 콜러블을 처리하는 방식','PYTHON_BACKEND','`BackgroundTasks.add_task()`는 동기 함수와 코루틴 함수를 모두 받을 수 있습니다. 내부적으로 FastAPI는 응답을 클라이언트에게 보낸 뒤, 등록된 콜러블이 코루틴이면 현재 이벤트 루프에서 `await`하고, 일반 함수면 스레드풀에 위임해 실행합니다.

```python
from fastapi import FastAPI, BackgroundTasks
import asyncio

app = FastAPI()

class EmailService:
    async def send_email(self, message: str):
        await asyncio.sleep(2)  # 실제로는 SMTP 서버와의 비동기 I/O
        print(f''Sending email with message {message}'')

email_service = EmailService()

@app.post(''/send-email'')
def send_notification(message: str, background_tasks: BackgroundTasks):
    background_tasks.add_task(email_service.send_email, message)
    return {''status'': ''accepted''}
```
중요한 점은, `send_notification` 자체는 동기 함수인데도 비동기 콜러블(`email_service.send_email`)을 백그라운드 작업으로 등록할 수 있다는 것입니다. 응답이 나간 ''이후''에 백그라운드 작업이 실행되지만, 이는 여전히 API 서버와 ''같은 프로세스, 같은 이벤트 루프'' 안에서 실행됩니다. 따라서 이 작업이 오래 걸리거나 실패하면 서버 프로세스의 리소스를 계속 점유하고, 재시도·실패 알림·작업 이력 조회 같은 운영 기능도 전혀 없습니다. 응답 후 몇 초 안에 끝나는 가벼운 후속 작업에는 적합하지만, 재시도가 필요하거나 오래 걸리는 작업이라면 Celery 같은 독립된 워커로 옮겨야 서버 프로세스와 장애가 격리됩니다.',18,0.72,'ANALYZE','["fastapi-background-tasks"]'::jsonb,'PUBLISHED'),
('python-backend-redis-cache-stampede','Redis 캐시 스탬피드와 확률적 조기 만료','PYTHON_BACKEND','인기 있는 캐시 키 하나가 만료되는 순간, 그 키를 기다리던 수백 개의 요청이 동시에 캐시 미스를 겪고 한꺼번에 DB로 몰려가는 현상을 캐시 스탬피드(cache stampede) 또는 thundering herd라고 부릅니다. TTL만 걸어둔 단순한 캐시-어사이드 패턴은 이 문제에 취약합니다.

```python
import random
import time

def get_with_stampede_protection(key, fetch_fn, ttl=300, beta=1.0):
    cached = cache.get(key)
    if cached is not None:
        value, delta, expiry = cached[''value''], cached[''delta''], cached[''expiry'']
        # 만료 시각에 가까워질수록 ''조기에'' 미리 갱신할 확률이 높아진다
        if time.time() - delta * beta * _log_random() < expiry:
            return value

    start = time.time()
    value = fetch_fn()
    delta = time.time() - start  # DB 조회에 걸린 시간
    cache.set(key, {''value'': value, ''delta'': delta, ''expiry'': time.time() + ttl}, ex=ttl)
    return value

def _log_random():
    import math
    return math.log(random.random())
```
이 기법(XFetch)의 핵심은, 캐시 값이 실제로 만료되기 ''전''에 일부 요청이 확률적으로 미리 값을 갱신하게 만들어, 정확히 만료되는 그 순간에 모든 요청이 동시에 DB로 몰리는 것을 분산시키는 것입니다. `delta`(원본 조회 소요 시간)가 클수록, 그리고 만료 시각에 가까워질수록 조기 갱신 확률이 높아집니다. 더 간단한 대안은 캐시 미스가 났을 때 짧은 분산 락(`SET key value NX EX 5`)을 걸어, 락을 획득한 요청 하나만 DB를 조회하고 나머지는 짧게 대기했다가 갱신된 캐시를 읽게 하는 방법입니다. 트래픽이 매우 큰 키 하나에는 확률적 조기 만료가, 구현 단순성이 중요하면 락 기반 방식이 더 적합합니다.',22,0.9,'EVALUATE','["redis-cache","cache-stampede"]'::jsonb,'PUBLISHED'),
('python-backend-sqlalchemy-session-pool-exhaustion','SQLAlchemy 세션 수명 관리와 커넥션 풀 고갈','PYTHON_BACKEND','SQLAlchemy의 `Session`은 커넥션 풀에서 커넥션을 빌려 쓰고, `session.close()`가 호출돼야 그 커넥션을 풀에 반납합니다. 세션을 명시적으로 닫지 않은 채 요청이 계속 들어오면, 풀에 남은 커넥션이 하나씩 줄어들다가 결국 고갈됩니다.

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(''postgresql://localhost/mydb'', pool_size=10, max_overflow=5)
SessionLocal = sessionmaker(bind=engine)

# 위험한 패턴: 예외가 나면 session.close()가 실행되지 않는다
def get_user_bad(user_id):
    session = SessionLocal()
    user = session.query(User).get(user_id)  # 여기서 예외가 나면 아래 close()에 도달하지 못한다
    session.close()
    return user

# 안전한 패턴: 예외가 나도 반드시 반납된다
def get_user_safe(user_id):
    session = SessionLocal()
    try:
        return session.query(User).get(user_id)
    finally:
        session.close()
```
`pool_size=10, max_overflow=5`는 기본으로 10개, 순간적으로 최대 15개까지 커넥션을 허용한다는 뜻입니다. `get_user_bad`처럼 예외 경로에서 `close()`를 건너뛰는 코드가 반복 호출되면, 풀의 커넥션이 하나씩 새어나가다가(connection leak) 결국 `TimeoutError: QueuePool limit ... reached`가 발생해 애플리케이션 전체가 응답 불가 상태에 빠집니다. FastAPI의 `Depends(get_db)` + `yield` + `finally: session.close()` 패턴이 널리 쓰이는 이유가 바로 이 반납을 프레임워크 차원에서 강제하기 위해서입니다.',20,0.85,'EVALUATE','["sqlalchemy","connection-pool"]'::jsonb,'PUBLISHED');


INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`asyncio.gather()`는 여러 코루틴을 동시에 실행하고, 모두 끝날 때까지 기다렸다가 결과를 리스트로 모아줍니다. 코루틴을 하나씩 `await`하면 순서대로 실행되지만, `gather`로 묶으면 I/O 대기 시간이 겹쳐서 전체 소요 시간이 줄어듭니다.

```python
import asyncio

class DataFetcher:
    async def fetch_data_1(self):
        await asyncio.sleep(1)
        return ''Data 1''

    async def fetch_data_2(self):
        await asyncio.sleep(1)
        return ''Data 2''

async def main():
    fetcher = DataFetcher()
    results = await asyncio.gather(
        fetcher.fetch_data_1(),
        fetcher.fetch_data_2(),
    )
    print(results)  # [''Data 1'', ''Data 2'']

asyncio.run(main())
```
`fetch_data_1`과 `fetch_data_2`를 각각 `await`로 따로 호출했다면 총 2초가 걸렸겠지만, `gather`로 묶으면 두 `sleep(1)`이 동시에 진행되어 약 1초 만에 끝납니다. 외부 API 여러 개를 순서와 상관없이 동시에 호출해야 할 때 자주 쓰는 패턴입니다.', '[-0.459100,0.536874,-2.822399,-0.970115,1.541158,-0.994744,0.082278,0.319468,-0.667440,-0.522999,-0.979576,0.764137,1.679858,0.482372,0.222719,-0.658815,-0.113365,-0.919967,-0.041325,0.795424,-0.231382,-0.124169,0.506683,-0.740939,1.280078,0.698156,0.568578,0.231206,-1.182250,0.048063,-0.312936,0.508107,0.883206,-0.606989,-0.590637,0.061376,-0.240297,-0.500589,-0.249742,0.380011,-0.055488,-0.868174,1.002258,0.282650,0.865572,0.234505,0.766760,0.310302,0.754964,-1.589839,0.703953,0.171845,-0.414860,-0.070389,1.931226,0.331064,0.626241,0.057119,0.430300,-1.136063,0.812059,1.630870,-0.150646,0.957008,0.913162,0.276558,0.592663,1.473787,0.066970,0.307896,1.032256,0.124698,0.342192,-0.797155,0.042739,0.409535,-0.052116,-1.561964,-0.563214,1.647310,-0.755057,-0.103068,0.495203,0.323999,0.302553,-0.722126,-0.548258,-0.096776,-0.045724,1.262642,-0.029810,-0.377137,0.354339,-1.189269,-1.090499,0.750577,-0.420830,0.632139,-0.626743,-0.231772,0.177401,-0.062917,0.246972,-0.704095,0.080953,0.822085,0.016699,0.521617,-0.436315,-0.808165,-0.234739,0.517084,-1.148364,0.048934,0.016961,-0.308198,0.645274,0.730277,-0.208449,-0.198474,0.304093,-0.505494,-0.698221,1.108599,1.165415,0.766196,-0.388153,0.859534,0.735263,-0.832240,1.084315,-1.068790,-1.590348,0.047254,0.329441,0.217337,-1.140815,0.276460,0.738207,-0.136072,0.459874,0.150257,-0.060856,-0.722876,-0.554602,0.203106,0.737748,-0.256394,-0.572914,0.145099,-0.337572,0.589890,0.664907,0.018939,0.785089,-0.656338,0.215534,-0.064704,0.616080,0.292090,1.765099,-0.020383,-1.187230,0.674082,-0.490288,0.020699,0.661759,0.727494,-0.141459,0.721090,-0.861790,-1.268827,-0.521805,0.003536,-0.208715,0.638191,0.913320,-0.955553,0.783516,-0.511528,-0.241124,-1.739686,1.360149,-0.016127,-0.839278,-0.375055,-0.125330,0.118101,-0.881567,-0.509100,-0.043687,0.203252,-0.395846,0.177165,-0.620879,-0.146987,-0.231819,-1.099684,0.478956,-0.590664,-0.284200,-0.601208,-0.315801,0.221115,-1.288577,0.967082,-0.006505,0.470789,-0.520617,0.316138,1.527003,-0.011216,-0.009154,0.209172,-0.474573,0.273434,-0.379631,-0.406515,-0.118439,-0.684168,0.276072,-0.784286,-0.244740,0.791298,0.323714,-0.242491,-0.616916,-0.005977,-0.778913,-0.043737,-0.269514,-2.215006,0.255688,0.378416,0.404532,0.917291,0.343962,1.918205,0.158228,-0.968049,-0.878700,0.096248,0.347279,-0.610994,-1.510520,0.665335,-0.629238,0.224322,-0.686012,1.004623,-0.278495,0.584805,-0.202745,0.900586,0.337671,-1.388580,0.786657,-0.025127,0.367594,0.121996,0.058586,-0.946164,0.555838,-0.760088,-0.069836,-0.314753,0.254327,0.066495,0.102421,-0.511297,-1.273639,-0.397222,0.937512,0.688055,0.044086,-0.005318,0.642086,0.861230,0.032813,0.099385,-0.261518,-0.371958,-0.469542,0.312801,0.021031,0.568316,-0.048612,-0.161338,0.744821,-0.314952,0.515083,-0.111083,-0.699283,0.953680,-0.103862,1.208834,0.783527,0.458007,-0.410837,-0.712808,0.530428,0.827678,1.089449,-0.092159,0.253692,-0.301819,0.179875,-0.103188,0.061061,-0.448997,-0.167277,-0.287326,-0.447357,0.932638,-0.434128,1.015844,0.621389,0.710078,0.121354,-0.367014,0.325752,-0.634055,-0.070757,-1.105654,-0.320227,0.708574,-0.092679,0.626664,0.150154,-0.225731,1.118940,0.063740,0.537299,-1.257862,-0.300551,-0.014303,0.109663,-0.114479,-0.150963,0.720451,-0.191550,-0.882050,0.220153,-0.372374,-0.728566,0.234053,-0.065187,-0.767576,0.732852,1.049553,-1.327705,0.871183,-0.933293,-0.030800,-0.315505,-0.333935,-0.225827,0.039534,-1.067595,-0.277635,0.659798,-0.065745,0.739674,0.537652,0.091099,-0.356924,-0.024897,0.887575,0.611432,0.216694,0.345135,-1.357881,0.027149,0.465150,0.243090,-0.345258,-0.678234,0.551448,-0.798504,0.651391,1.277267,-0.032754,-0.333006,-0.274751,0.656346,0.045762,-0.039942,0.637015,-0.142275,0.714349,0.084955,-0.482519,0.080471,0.054231,1.023483,-0.941712,0.741944,-0.032902,-1.509033,0.577018,-0.573786,-0.355643,0.299344,-0.176638,0.012134,0.197418,-0.690227,0.003916,1.012398,0.243609,-0.244647,0.059430,0.332824,-1.554760,-0.549604,0.116055,1.896113,0.547306,-0.297110,-0.355550,-0.520065,0.454723,0.535127,-0.165802,-0.312257,0.899473,-0.016625,0.634219,-0.196313,-1.171950,0.618461,-0.029200,0.976524,0.352612,-1.284821,0.366085,0.868326,1.411440,-0.384443,1.066890,0.788877,-0.026360,-0.531796,-0.347435,0.736030,1.013437,1.305500,-0.925605,-0.051842,0.243997,-0.611682,0.495614,0.606140,-0.543443,1.234917,-0.131180,-0.005413,-0.103275,-0.294978,0.552770,0.360417,-0.570073,-0.365010,-0.614990,-0.051799,-0.213104,0.518740,-0.140273,0.344147,0.811146,-0.906174,0.108560,0.007401,-0.810823,0.855836,-0.221118,-0.282625,0.064502,0.766904,0.790316,0.187014,-0.576036,-1.762783,-0.283888,-0.299312,1.281064,0.532406,-0.412331,0.050730,-0.130429,0.321165,0.127476,0.025896,0.082084,0.246137,0.161081,-0.083910,1.271908,0.450574,-0.381545,0.117058,0.685737,-0.841036,-0.177121,0.590721,0.466471,0.154955,0.094289,-0.567775,-0.595802,0.248955,-0.118228,0.595272,0.704051,1.754860,-0.259477,0.812192,-0.513211,-0.880879,0.141642,0.609682,-0.919615,0.446819,-1.400282,-1.059685,0.388529,-0.553576,-0.318355,0.817771,-0.023113,-0.414239,-0.608259,-0.214659,-0.757881,0.480131,-0.872801,0.194236,0.988212,-0.105824,0.301095,0.053542,0.741486,-0.525291,0.308183,0.091526,-0.950818,-0.066337,0.074596,0.744520,-0.722540,0.736908,0.644342,-0.242197,-0.560854,0.766402,-1.164645,-0.100128,-0.922996,0.285853,-1.322622,-0.092256,0.044214,1.044354,-0.457930,0.443912,-1.348224,-0.575136,0.658020,0.537332,1.819659,0.587596,-1.464028,0.464323,-0.770292,0.008185,-0.079562,0.391121,-0.338472,-0.331512,-1.766319,0.062000,-0.921521,0.703352,0.242139,-0.819536,0.708997,-0.060225,-0.391205,0.448809,-0.755986,-0.557651,0.442485,0.524196,-0.557611,-0.280545,0.483112,-0.879376,-1.727936,-0.602794,-0.167604,-0.144049,0.355688,0.490561,-0.558999,-0.612303,1.270521,-0.701973,0.024269,-0.761126,-0.567065,-0.343427,0.251009,-0.835039,0.025973,0.246181,-1.200488,0.619453,0.436671,0.722769,-0.951555,-0.436692,-0.651966,0.987008,-0.328414,1.262709,0.484440,-0.949933,-0.178932,1.314597,1.430829,-0.601011,1.216029,-2.677487,0.224629,-0.256707,0.307980,-0.265336,0.267764,0.466544,1.059092,1.184765,0.239170,0.142798,0.820831,-0.402749,-0.971017,0.838840,1.386917,0.822878,-1.068969,0.801960,0.911115,0.607444,-0.002299,0.953635,-0.188076,0.704021,-1.276435,-1.211802,-1.002882,-0.011756,-1.269075,-1.199494,0.423012,0.795989,-0.227345,-0.038036,0.252262,-0.623875,-1.369750,0.576957,0.440989,-0.460106,-1.274281,-0.209784,-0.124355,0.376656,0.214766,-0.569681,-0.943353,0.084822,-0.519793,0.659482,0.116051,1.448943,-0.273662,-0.358054,-0.690046,-0.483640,-1.093555,-0.907400,0.063462,-0.329221,-0.645547,-1.005875,0.345073,-0.413208,-0.738150,-0.751704,0.495927,-0.354563,0.543948,0.209721,-0.102276,0.442997,-0.144733,0.208060,0.074866,-0.273621,0.276164,-0.553115,0.635413,-0.534414,0.937828,-0.461224,0.845229,-0.886404,0.359652,-0.247215,0.313370,0.787763,-0.204105,-0.867370,0.158594,-0.277370,-0.129250,-0.072165,0.317832,0.954936,-0.689335,0.647924,0.038021,-0.553733,0.453131,0.541696,1.122447,-0.056704,-0.612666,-1.641449,-0.938661,-0.629604,0.314506,0.368204,0.009803,-0.127496,0.013079,-1.145108,0.798069,0.361214,-0.420410,-0.234676,-0.621842,-0.561392,1.007205,0.401355,0.030361,0.217443,0.692441,2.000655,0.702473,0.330660,-0.104358,-0.759844,0.226670,-0.769219,-0.040498,-0.875797,-1.124496]'::vector, 'b1d87612ac34a375ce16400e352ac89304e03b55dfe558c1f29e04480d5b79b8', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-asyncio-gather-basics';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Python에서 클래스 메서드는 `@classmethod` 데코레이터를 사용하여 정의되며, 첫 번째 파라미터로 클래스 자체(`cls`)를 받습니다. 인스턴스 메서드는 첫 번째 파라미터로 인스턴스(`self`)를 받아 그 객체의 상태를 읽거나 바꿉니다.

```python
class MyClass:
    class_var = 0

    @classmethod
    def increment_class_var(cls):
        cls.class_var += 1
        return cls.class_var

    def increment_instance_attr(self, value):
        self.instance_var = value

a = MyClass()
b = MyClass()
MyClass.increment_class_var()
print(a.class_var, b.class_var)  # 1 1 — class_var는 모든 인스턴스가 공유한다

a.increment_instance_attr(10)
print(a.instance_var)            # 10
print(hasattr(b, ''instance_var''))  # False — instance_var는 a에만 있다
```
`class_var`는 클래스 자체에 속한 상태라 어떤 인스턴스로 바꾸든 모든 인스턴스에서 같은 값이 보입니다. 반면 `increment_instance_attr`로 설정한 `instance_var`는 그 인스턴스에만 존재합니다. 여러 요청이 같은 클래스를 공유하는 웹 백엔드에서 클래스 변수에 요청별 상태를 실수로 저장하면 요청 간에 상태가 새는 버그가 생깁니다.', '[-0.408879,0.056981,-2.974521,-1.818679,1.575277,-0.267581,0.360882,-0.312386,-0.754463,-0.779243,-0.518908,1.512883,1.386679,0.259380,-0.066211,-1.351395,-0.784324,-1.115037,-0.559740,0.958314,0.481950,-0.829461,-0.359106,-1.387426,1.544045,1.475946,-0.141263,0.058376,-0.275472,-0.344721,0.020462,0.002721,0.822496,-1.185230,-1.136268,-0.116865,1.751967,0.536388,1.018716,-0.363419,0.551499,-0.378669,0.913212,-0.301627,0.913084,-0.015366,0.378745,0.152654,0.180295,0.034139,0.616262,-0.432399,0.011637,0.317950,1.484311,0.754038,-0.301656,0.831157,0.588758,-0.966606,0.891695,1.049461,-0.279886,0.724737,0.228865,0.376579,-0.161090,0.351664,-0.881067,-0.134809,0.443080,-0.489412,0.258235,-0.876081,-0.372679,0.288325,-0.155616,-0.471243,-0.169635,1.294091,-0.885876,0.786387,1.265556,-0.535123,1.053814,-0.153971,-0.655680,0.407631,-0.424660,0.878604,-0.691604,-0.513288,-0.021726,-0.470403,-0.940837,-0.058467,0.335769,0.836333,-0.419040,0.016334,0.049966,-0.160167,0.912450,-0.819582,0.024898,0.742520,0.630648,-0.423336,-0.368709,-0.309518,0.444263,0.167559,-1.470986,-0.321522,-0.116445,-0.001191,1.652809,-0.021539,0.329247,-0.365219,-0.328916,-0.119778,-0.622569,1.560085,0.903691,0.388438,-0.515853,0.789182,0.592343,-0.955850,0.460772,-0.817126,-2.008300,-0.660660,0.061937,-0.138968,-0.617999,0.027953,0.291031,0.212487,0.188860,0.743314,-0.549565,-0.079605,0.243789,-0.563128,0.675495,-0.566478,-0.422140,0.199553,0.170730,0.446207,-0.488057,0.308644,-0.264049,0.295111,-0.276282,-0.308000,0.579913,0.301124,0.765188,-0.042358,-0.281526,0.540170,-0.846979,-0.017201,0.847944,0.522642,-0.821312,0.494672,-1.310203,-1.065614,0.032363,-0.097487,-0.415457,0.632085,-0.040848,-1.013324,0.840438,0.092537,0.383383,-1.151093,2.026016,0.358931,0.032310,-0.246390,-0.508427,0.059349,-0.511220,-0.293272,0.393570,0.452931,-0.447655,-1.021898,-1.077524,-0.673373,0.258152,0.082958,0.012859,-1.133528,-0.345285,-0.430417,-0.170078,0.241005,-0.557818,0.413851,0.359117,-0.399396,-0.435219,0.529749,1.301060,0.404439,-0.645380,0.628778,0.201579,-1.052305,-0.199029,-0.689656,-0.593375,-0.792133,0.904120,-0.288906,0.337093,0.406245,0.173941,0.689738,-0.812526,0.421273,-0.975401,0.590787,-0.349775,-0.906504,0.475151,0.046470,0.545490,1.495347,-0.203496,1.138278,-0.369423,0.246731,0.874099,0.189571,0.249601,-0.113573,-1.002966,-0.093169,0.108060,-0.057679,-0.622658,0.939931,0.020683,-0.044683,-0.198097,0.639365,0.452765,-0.425521,0.709420,-0.638142,0.399305,0.304469,0.475547,-0.811049,0.294356,-0.342242,-1.134005,-0.772399,-0.004136,0.333894,0.365608,-0.051042,0.257013,0.173068,0.853764,0.595047,0.092017,0.428069,0.832235,0.519616,0.016757,0.564866,-0.421794,-1.080016,0.094225,-0.191384,-0.339997,-0.337816,0.481976,-0.553360,0.622854,-0.249966,0.102108,-0.646994,-0.320575,0.899449,0.317446,0.110643,0.989500,-0.256521,0.450014,-0.350356,0.755678,0.907543,0.418642,-0.157985,0.287096,-0.756477,0.604579,0.515546,0.912943,-0.073257,-0.721591,-0.019051,-0.423796,0.878472,-0.641211,0.714910,-0.586797,0.804667,0.356615,-0.369108,-0.114470,-0.858875,0.130943,0.229297,0.230069,0.239623,-0.495808,0.884108,0.602318,-0.382396,-0.059196,1.010672,1.053310,-0.351706,0.741415,0.024167,-0.002973,0.024209,-0.371300,0.975569,0.758249,-0.075696,-0.042618,-0.416363,0.698205,0.966523,-0.074298,-0.664452,0.534789,0.464447,-0.395050,0.908733,-0.634938,0.375214,-0.200671,0.106369,-0.129008,0.651325,0.429578,0.357417,0.558165,0.003289,0.472458,-0.555536,0.568114,0.208108,0.451616,0.610977,0.911489,-0.193398,-0.746829,-0.327954,-0.366553,-0.306770,-0.024244,-0.660800,-0.713031,-0.035989,-1.292828,1.225302,0.107010,-0.408521,0.056428,-0.066760,0.027292,-0.867509,-0.647359,-0.006495,0.213943,-0.041511,0.919294,0.066362,-0.487504,0.496983,0.572654,-0.318426,0.886418,0.164952,-0.228175,1.014599,-0.432494,-0.417298,0.337089,-0.577447,-0.703219,-0.159302,-0.216703,-0.334021,0.508531,-0.203629,-0.290644,0.577532,-0.138575,-1.599123,-0.666127,0.851172,1.386715,1.206077,-0.864284,0.095895,0.728208,0.674575,0.273215,-0.140709,0.285862,0.774518,-0.055584,0.390878,-0.017263,-2.074180,-0.338234,0.773488,1.054127,0.218338,-0.305317,0.644093,1.258044,0.956685,-0.003614,0.524798,0.535524,-0.533771,-0.429629,0.309977,0.517431,0.060106,0.861665,-1.527835,-0.622771,0.323988,-0.479130,-0.088541,0.030703,0.381489,0.526361,-0.897116,-0.311391,-0.503520,-0.626804,0.466199,0.214616,0.016193,-0.639026,-0.092100,0.298229,0.099198,0.200126,-0.523949,0.165730,0.600728,-0.463502,0.544821,0.326953,-1.108198,1.771616,0.053505,0.297231,0.337492,0.204058,0.704855,0.079869,-0.986303,-1.286500,-0.396217,0.111909,1.035237,0.523074,-0.481017,0.854076,-0.173937,0.669717,0.998138,0.228627,-0.198893,-0.115566,-1.015424,-0.494954,0.575814,1.181538,0.461394,-0.176445,-0.315891,-0.162670,0.306455,0.204216,-0.460077,0.775268,-0.736138,-1.106730,-0.290519,0.672316,1.409113,1.402229,0.202153,0.823701,-1.402445,0.698758,-0.644082,-1.366892,0.297087,1.236167,-0.374013,-0.638650,-1.050897,-0.476771,0.266094,-0.167895,-1.313303,0.711761,0.269017,-0.307978,-0.132124,-0.904732,-0.675294,-0.414287,-1.318666,-0.047277,1.079996,0.090856,-0.305793,0.572190,0.469617,-0.880190,-0.132207,0.082114,-0.685363,-0.353460,0.200131,0.765943,-1.001462,0.152958,-0.042659,-0.259690,-1.192916,0.137354,-0.416099,-0.203512,-0.850359,-0.518566,-1.384116,-0.278543,-0.409667,0.982469,-0.264194,-0.206911,-0.629908,-1.016021,0.350761,0.241751,0.598997,-0.685346,-1.710742,0.746863,-0.292678,-0.628644,0.304841,0.820707,-0.082652,-0.281592,-0.970872,0.194706,-0.586391,-0.123122,0.647535,-0.679302,0.214645,-0.211673,-0.521163,0.319200,-0.322838,-0.573241,0.389395,-0.116185,0.532437,0.768758,-0.056892,-1.370663,-0.286149,0.014088,-0.789140,0.274248,0.363940,0.999035,-0.816751,-0.443786,1.220276,-0.674940,1.015245,-0.231095,0.026433,0.122471,-0.359281,-0.498676,0.389400,0.635577,-0.797583,0.400570,0.608843,-0.614739,-0.831469,-1.124173,-0.992886,0.178321,-0.713286,0.949997,0.538815,-0.502873,0.321116,0.655634,0.947580,-1.053120,0.395655,-1.930650,-0.200690,-0.367859,1.180033,-0.321829,1.193886,0.836646,1.795464,1.040066,-0.359328,-0.058173,0.407354,-0.083680,-0.818196,1.047093,1.521390,0.790505,-0.673689,1.842948,1.333805,0.698798,0.461586,0.550540,-0.370632,0.470705,-0.601159,-0.968039,0.114360,0.046473,-0.690552,-0.567483,0.551126,0.114113,0.475965,-0.726545,-0.398961,-0.723338,-1.334553,0.215608,0.862576,0.169211,-0.485315,0.834356,0.776415,0.884771,0.788719,-0.911540,-1.072979,-0.092310,-0.576005,0.371881,0.115086,0.766645,-0.718307,-0.117915,-0.688404,0.029355,-1.751950,-0.976548,-0.673976,0.089098,-0.256439,0.217280,0.541303,-0.516154,-0.746289,0.001993,1.198903,-0.665093,0.576861,-0.004380,0.682606,-0.288161,0.010075,0.310229,0.513280,-0.142912,-0.488101,-0.198484,0.591457,-0.058805,1.142596,0.025746,0.891492,-0.845754,-0.546442,-0.682270,0.728790,0.118641,-0.161505,-0.619332,0.516736,-0.246274,-0.433642,0.660020,0.285922,-0.010757,-0.750739,-0.583705,-0.744600,-0.950208,0.818651,0.327182,0.669811,0.187773,-0.457410,-1.978670,-0.615021,-1.393481,0.415755,0.146595,0.646236,-0.200777,-0.254005,-1.010116,0.455546,0.122853,-0.808061,-0.778180,-0.469282,-0.948099,0.127594,0.694018,-0.171949,0.237985,0.764050,1.518572,0.210660,0.111508,0.083927,-0.865413,0.106779,0.170154,-1.043729,-0.966157,-1.190232]'::vector, 'a64f960d88c21032e4d5c5ffe211ab51b7d7ed5bca97ee29de3c0a6f8e34bf2a', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-class-vs-instance-methods';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Python에서 컨텍스트 매니저는 `with` 문을 통해 사용됩니다. 이 구조를 이용하면 리소스를 열고 닫는 코드를 명시적으로 반복하지 않아도, 블록을 빠져나갈 때(예외가 나더라도) 자동으로 정리 작업이 실행됩니다.

다음은 파일을 열고, 프로그램이 블록을 빠져나갈 때 자동으로 파일을 닫아주는 간단한 컨텍스트 매니저입니다.

```python
class SafeFile:
    def __init__(self, filename):
        self.filename = filename
        self.filehandle = None

    def __enter__(self):
        self.filehandle = open(self.filename, ''r'')
        return self.filehandle

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.filehandle:
            self.filehandle.close()
        return False
```

```python
with SafeFile(''example.txt'') as f:
    for line in f.readlines():
        print(line)
```
`self.filehandle = None`을 `__init__`에서 먼저 초기화해두는 이유는, `open()`이 실패해도 `__exit__`이 존재하지 않는 속성을 참조하다 새로운 예외를 던지지 않게 하기 위해서입니다. `__exit__`이 `False`를 반환하면 블록 안에서 발생한 예외는 그대로 바깥으로 전파됩니다.', '[0.197108,0.191494,-2.430588,-1.381098,1.169744,-0.424149,-0.125030,0.687635,-1.365712,-0.971969,-1.184752,0.633979,1.070302,-0.041805,0.019949,-0.730450,0.146152,-1.508223,0.080273,1.131245,-0.244373,-0.168443,-0.253910,-0.981964,1.879165,0.877556,0.153018,-0.171994,-1.179957,-0.703472,0.479543,-0.206241,0.443753,-1.079979,-1.625882,-0.910957,1.111908,1.018450,0.946658,-0.014430,-0.288282,0.110430,0.639929,0.314704,0.939170,-0.724134,0.698124,0.175892,0.624910,-0.933147,0.697504,0.023344,-0.434690,0.246695,1.470239,0.932104,0.515509,-0.031385,-0.224162,-0.887576,-0.006528,1.072240,-1.124420,0.736805,1.039471,0.236698,-0.194156,0.651722,-0.170541,-0.219234,1.454609,-0.010779,0.100252,-0.697276,0.001205,0.321119,-0.460596,-0.949235,-0.514551,1.519594,-0.322393,0.559215,0.287346,-0.390261,0.924565,0.022168,-0.061814,-0.244036,-0.207064,0.623745,-0.344333,-0.505658,-0.047018,-0.171564,-0.852854,0.747542,0.021061,0.443628,-0.496581,-0.799737,1.105622,-0.599387,0.833672,-0.701681,-0.001568,0.688533,0.575081,-0.045173,-0.193231,-0.090597,-0.238297,1.200047,-0.722941,-0.719549,0.402378,-0.109931,1.746865,-0.265445,0.850170,-0.129191,-0.694362,-0.667413,-0.348682,1.349142,0.252235,1.119047,-0.000895,0.579140,0.717442,-1.358355,-0.066555,-0.382458,-1.094931,0.146867,-0.227536,0.699617,-1.131385,0.169500,0.470904,-0.534356,0.273829,0.763639,-0.159814,-0.962816,0.446872,-0.688591,0.798371,-0.364314,-0.321991,0.426958,-0.181054,0.559094,-0.934872,0.879924,0.016797,-0.106395,-0.266346,0.039862,0.556434,-0.096836,0.946510,0.603282,-0.653598,0.643290,-0.799479,-0.282169,0.585709,0.693382,-0.689173,0.571198,-1.643726,-1.061454,0.329666,0.110902,-0.075464,-0.195303,-0.267901,-0.863375,0.935873,-0.299903,0.346177,-0.963833,2.289192,0.568628,-0.508069,-0.217470,-0.394817,-0.501166,-0.634717,-0.540375,0.453103,0.298899,-0.804003,-0.892270,-0.788551,-1.047162,0.709501,0.120812,0.376361,-1.233881,-0.336199,0.137168,-0.444982,0.277218,-1.416191,-0.029829,-0.053169,0.089322,-0.094114,1.077284,1.633295,-0.105542,-0.501494,0.799170,0.427796,-0.942113,-0.012836,-0.311459,-1.649629,-0.667642,0.065398,-0.347010,0.217948,0.384683,0.616553,0.339530,-0.660392,0.191171,-0.549080,-0.188017,-0.599065,-1.739002,0.812857,0.543519,0.423665,0.194361,0.704962,1.619085,-0.268097,-0.251195,0.128154,-0.008214,-0.594853,-0.240890,-0.304806,0.227540,-0.066859,-0.469850,0.145984,0.501751,-0.850320,0.782557,-0.147035,0.685107,0.238244,0.025147,0.542859,-0.794307,0.364677,-0.333881,0.486258,-1.176992,-0.386192,-0.297769,-0.221579,-0.295794,-0.367890,0.484619,0.435382,-0.019742,0.263921,0.008518,1.220582,0.376951,0.432820,0.299228,0.559067,-0.169358,-0.934257,0.182732,-0.563393,-0.587757,-0.268656,0.693123,0.123381,0.087632,0.437997,0.099835,0.190897,-0.286224,0.803723,-0.169297,-0.395868,0.902541,0.331274,0.371823,0.945284,0.343571,0.131021,-0.356216,0.516132,0.936406,0.657086,0.042112,0.381913,-0.740463,-0.144443,-0.067359,0.293890,-0.286483,-0.995393,0.014439,-0.275404,0.981021,-0.826589,0.744083,-0.195867,0.608983,0.718984,-0.427528,-0.289838,-0.755090,0.473765,-0.419306,-0.502163,0.181452,-0.679642,0.285157,-0.184058,-0.398677,-0.509980,0.749784,0.393161,-0.395444,-0.626090,0.934311,-0.161808,0.464476,-0.311280,1.026778,1.520368,-0.643428,0.525561,-0.323700,-0.015516,0.275027,0.526113,-0.861754,0.836332,1.070332,-0.480984,0.818850,-0.405602,-0.065774,-0.447088,0.248552,0.365128,-0.024434,0.054048,-0.426081,0.815551,-0.443362,-0.064705,-0.721949,-0.322377,0.670880,0.638742,0.692072,0.383297,-0.701987,-0.209282,-0.795643,0.396720,-0.244970,-0.172266,-0.421163,-0.591001,-0.632527,-0.785788,0.942150,-0.064058,-1.083791,-0.390052,0.325392,1.279454,-1.092270,-0.139757,-0.203204,0.484326,0.636790,-0.356733,0.317198,-0.271362,0.141590,0.201762,-0.372144,0.735819,0.397794,-0.990233,0.208945,-0.804767,-0.897762,0.006856,0.120667,-0.046175,-0.116904,0.179571,0.049387,0.496557,0.050768,-0.087322,-0.014988,0.073815,-0.655653,-0.642996,0.462927,1.201113,0.922372,-0.810211,-0.806772,0.242876,0.990349,-0.237227,0.054233,0.086518,0.146825,0.846096,0.903558,0.264367,-1.118563,0.204829,0.664840,1.123023,-0.010021,-0.260495,0.452734,-0.367873,0.455858,-0.357630,0.976985,0.083634,0.018275,-0.724624,-0.014392,0.150198,0.398365,1.572871,-1.562968,-0.750641,-0.303710,-0.611521,0.386591,0.473916,0.480192,1.102467,-0.905327,-0.507705,-0.312293,-0.412335,0.511237,0.655409,-0.056108,-0.456541,0.616580,-0.066907,-0.189169,-0.141390,-0.505088,0.834385,1.274826,-0.835989,0.892799,0.625354,-0.700967,0.790963,0.600378,-0.360367,0.839975,0.216002,0.716123,0.091904,-1.108284,-1.141324,-0.248778,0.335224,0.581004,0.934467,-0.223498,0.735312,-0.250379,0.737862,1.010382,0.548346,-0.151507,-0.291712,-0.851854,-0.125350,1.449521,0.889236,0.696061,-0.133119,-0.443985,-0.697795,0.431289,0.559707,-0.013626,0.732340,-0.394019,-1.332458,-0.661335,0.086160,0.440504,-0.026481,0.688212,0.847785,-1.049419,0.716655,-0.335910,-1.613923,0.631287,1.068848,-0.720346,-0.244519,-0.616999,-0.574358,-0.094194,0.559183,-1.516684,0.696150,0.211148,0.019984,-0.334842,-0.594080,0.181087,-0.340407,-1.809623,0.106043,0.892328,-0.269066,0.174105,0.741006,0.731997,-0.703569,1.037516,-0.611247,0.007485,-0.028415,0.151156,-0.137858,-1.256999,0.796777,0.242219,-1.098893,-0.595569,0.431135,-0.939301,-0.227129,-0.660918,-0.145911,-0.864041,-0.405249,-0.653760,0.095227,0.571251,0.555053,0.043555,-0.366352,0.068554,-0.477314,0.554728,-0.422933,-1.497101,0.177890,-0.299979,-0.086040,0.240044,0.407712,-0.247218,-0.131435,-1.628847,0.670788,-0.752317,-0.018768,0.669349,-0.855382,-0.291131,0.431155,-1.035852,0.056617,0.131831,-0.149274,-0.169637,0.286671,0.941827,0.614860,0.371899,-0.671572,-1.624406,0.297315,-0.479648,0.247562,1.131608,0.642353,-1.075333,-0.658724,0.734775,-1.007699,1.400739,-0.225778,-0.585939,0.471561,0.245451,-0.486772,0.321170,0.805183,-1.513111,0.597041,0.697831,0.023768,-0.318690,-0.488950,-0.348942,0.825493,-0.197485,0.899039,1.080323,-0.768093,0.385129,0.723258,0.939442,-0.825839,0.629892,-1.801956,-0.738730,-1.398119,1.047625,-0.959481,0.851444,1.028922,2.171435,0.510940,-0.261325,0.663960,0.373140,0.015314,-0.416065,0.794359,0.915915,0.513010,-0.745592,1.753308,1.429057,0.168971,0.142937,0.997736,0.778097,0.435402,-0.405402,-2.086960,-0.622491,0.728760,-0.460828,-0.457057,-0.315461,1.026329,0.428636,-0.630784,-0.411991,-1.007865,-0.914936,0.336341,0.724121,0.152042,-0.146814,0.117284,0.411072,0.785385,0.739820,-0.729943,-0.771717,-0.877164,-0.504966,-0.039863,0.085896,0.659326,-1.124397,0.369430,-0.876767,-1.127219,-0.849712,-0.669289,-0.624659,0.287205,-0.078515,-0.398636,0.223262,-0.413494,-0.453067,-0.446147,1.190409,-0.927653,0.648620,0.174333,0.963971,-0.722711,0.149819,0.368834,0.375688,-0.626655,-0.322720,0.437340,0.218623,0.240319,1.395076,-0.253486,0.662011,-0.914065,-0.530468,-0.209853,0.704686,0.062412,-0.585456,-0.744871,0.831661,-0.542282,-0.334868,0.029228,-0.070626,0.206912,-0.561026,-0.561148,-0.430638,-0.516855,0.596736,-0.339858,0.313543,-0.033584,-0.733668,-1.825507,0.281401,-0.429737,0.921326,0.358740,0.388930,0.305530,-0.420310,-0.597089,-0.162677,0.580389,-0.200057,-0.152509,-0.161695,-0.604098,0.895337,0.437174,-0.452878,-0.631258,0.797647,1.384760,0.447945,0.319531,0.034190,-0.757922,0.260265,0.547335,-0.760754,-0.491176,-1.323659]'::vector, 'd5ab34105f4deb3e27ec0b007c34ee86f69a9b86ec56ff15d58bcaf5ceeb5cf6', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-context-managers';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Python에서 데코레이터는 함수에 행동을 추가하기 위해 사용됩니다. 예를 들어, 로깅 기능을 적용하거나 성능 측정 등을 수행할 수 있습니다.

데코레이터는 `@decorator_name` 형태로 함수 위에 정의합니다. 아래 예제에서 `my_decorator` 데코레이터는 `say_hello` 함수를 감싸서 실행 시 추가 기능을 제공합니다.

```python
import functools

def my_decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        print(''Something is happening before the function is called.'')
        result = func(*args, **kwargs)
        print(f''Something is happening after the function is called. Result: {result}'')
        return result
    return wrapper

@my_decorator
def say_hello(name):
    return f''Hello, {name}''

say_hello(''World'')
```
`say_hello(''World'')`를 호출하면 실제로는 `wrapper`가 실행되면서 원래 함수 호출 앞뒤로 로그가 찍힙니다. `functools.wraps`를 빼먹으면 `say_hello.__name__`이 `''wrapper''`로 바뀌어버리는 부작용도 있으니 데코레이터를 작성할 때는 항상 함께 사용하는 습관을 들이는 것이 좋습니다.', '[-0.726306,0.030695,-2.739453,-2.385991,0.832008,-0.751014,0.691409,0.228949,-0.871379,-1.483506,-1.390939,1.126315,1.344702,0.345425,0.905642,-1.120387,-0.025164,-1.424807,-0.491742,1.009685,0.206824,-1.067671,-0.209474,-1.212140,1.369128,0.664261,-0.144692,0.807513,-1.172909,0.159120,-0.665137,0.043024,-0.217592,-1.435265,-0.459325,-0.599182,0.570490,0.322374,0.699454,0.006970,-0.162919,0.296888,0.547521,-0.007954,0.605118,-0.390149,0.403307,-0.225105,0.091515,-0.957570,0.441181,-0.099583,-0.526862,0.139743,1.676135,0.787910,0.263011,0.783215,0.847446,-0.263756,0.562780,1.983575,-0.721499,0.468741,0.258483,-0.502327,0.219311,1.013341,-0.056073,0.581390,0.406210,-0.131402,0.372419,-0.844955,-0.196946,0.566413,-0.594839,-0.029847,-0.493266,1.006186,-0.865469,0.110637,0.367438,-0.590460,-0.121367,-0.183851,-0.764870,-0.033158,-0.531284,1.070108,0.396603,-1.570690,-0.417265,-0.281077,-1.327355,0.116918,-0.331799,0.009333,-0.529695,-0.755107,0.588534,0.016610,0.352144,-0.272220,0.225493,1.397594,0.247235,0.278250,-0.015593,-0.953638,0.148056,1.122259,-0.770099,-0.452003,0.414633,-0.113001,0.661969,-0.914494,0.091436,0.045513,-0.187644,-0.529055,-0.169328,0.047695,1.503200,0.709174,-0.399190,1.019217,0.738823,-1.215364,0.264919,-0.189906,-0.800548,-0.180138,-0.161433,0.538805,-0.541891,0.271531,0.712841,-0.136408,0.287905,0.393399,-0.648237,-0.747508,0.141616,-0.715129,0.692301,-0.705999,-0.325875,-0.269771,-0.068618,0.708105,-0.215340,0.789227,0.194817,0.300512,0.170243,-0.208451,0.226284,-0.162841,1.256295,-0.077811,-0.410408,0.628301,-0.350347,-0.268211,0.765806,0.957594,-0.822787,0.533395,-1.283608,-0.748415,-0.346309,-0.100854,-0.472858,0.023416,0.129553,-0.921563,0.965074,0.212154,0.223531,-1.314957,1.598317,0.040892,-0.410170,0.387261,-0.183350,-0.774197,-0.575168,-0.707794,0.034596,0.698943,-0.544189,-0.481243,-1.237940,-0.373123,0.099135,-0.310376,0.370019,-0.672446,-0.202115,-0.113237,-0.427580,0.200484,-0.910800,1.456182,0.067272,0.989015,-0.279874,1.019221,1.487108,0.128333,0.074334,1.030339,0.184356,-0.380460,-0.304984,0.026353,-1.003986,-0.470429,0.510534,-0.440663,0.222354,0.513224,0.480304,0.548339,-0.288146,0.750426,-1.142596,0.340140,-0.755082,-1.377523,0.847767,0.449068,0.587332,0.830226,0.370112,0.915615,0.337018,-0.354227,-0.118279,0.233995,0.590744,0.008909,-0.720266,0.245657,-0.267461,0.124655,0.088062,0.353594,-0.254246,0.520396,-0.293073,0.771093,0.257623,-0.875450,0.468294,-0.589507,0.937008,-0.595554,0.211146,-1.006678,-0.002689,-0.339318,-1.328354,-0.225493,-0.200385,0.465693,0.114671,0.283584,-0.204040,0.087281,0.587369,0.519593,0.738105,0.107731,0.648661,-0.100052,-0.180775,0.486559,-0.579265,-0.887353,-0.172419,-0.259413,-0.726545,-0.239850,-0.641928,0.020329,-0.699545,-0.441772,0.494679,0.273793,-0.396471,0.621319,0.112319,0.531648,0.760486,0.566282,-0.060753,-0.576050,0.736629,0.754635,0.805320,0.807130,0.394164,-0.207696,0.389878,0.548385,0.307978,-0.249487,-0.394328,-0.136937,-0.094768,0.557235,-0.719883,0.504581,-0.283429,1.045035,0.401897,-0.638516,-0.387862,-1.155690,0.344343,-0.349826,-0.405033,0.065107,-0.132846,1.058788,1.036864,-0.825824,0.201935,1.200037,0.109373,-0.859161,-0.197732,0.305221,-0.189303,0.604568,-0.230586,0.677887,0.789106,-0.332507,0.578635,0.001262,-0.262336,1.087561,0.173995,-0.695155,0.329262,0.999079,-0.695220,1.228778,-0.892719,0.702831,-0.119493,0.179080,0.197148,0.335766,0.224653,0.163232,0.769569,-0.061893,0.175443,-0.754788,-0.148646,0.393687,0.557469,0.942303,0.074287,-0.733923,-0.679316,-0.421698,0.255836,0.295955,0.289136,-0.060479,-0.557801,0.212606,-0.490326,0.992266,-0.689268,-0.346402,-0.246679,0.094679,0.656865,-0.164991,0.076734,-0.030399,0.218302,0.220362,0.070770,-0.174926,0.189650,0.229630,0.875631,-0.795133,0.616432,0.593308,-0.920738,0.602336,-0.870114,-0.570536,0.689107,-1.150107,-0.600319,-0.257174,-0.077684,-0.188760,0.631084,-0.167942,-0.366275,-0.041539,0.897044,-0.988092,-0.820853,0.508016,1.014698,0.892386,-0.969609,-0.692379,0.091345,1.040811,0.824740,0.885949,-0.307733,-0.037005,0.727889,0.607608,-0.478014,-1.555590,-0.265400,0.576043,0.888676,0.350460,-0.671257,0.248860,0.232739,0.815690,-0.217553,0.900307,0.784622,-1.126287,-0.794810,0.169318,0.274216,0.835216,0.557663,-1.207697,-0.958241,0.442785,-0.671207,0.427111,-0.228614,0.134970,0.906392,-0.376496,0.180091,-0.789442,-0.613192,0.940698,-0.107132,-0.094349,-0.967209,0.006817,-0.440396,-0.224550,0.524757,-0.818302,0.975980,1.447803,-0.902204,0.449051,0.010858,-0.962994,1.291770,0.488543,0.428374,0.672490,0.154614,0.775903,0.037369,-0.900968,-1.608005,-0.101580,0.338351,0.611360,0.880366,-0.811505,0.593132,0.021069,0.361549,0.385054,0.518512,0.133338,0.700829,-0.234120,-0.349687,1.557952,0.789291,0.036298,0.282277,-0.070584,-0.873144,0.735515,0.485864,0.505144,1.077124,-0.199730,-0.953313,-0.291107,0.734143,0.433215,0.316065,-0.105638,0.874227,-0.441876,0.598351,-0.565082,-1.626883,0.503449,0.479540,-1.084972,-0.007199,-0.434826,-0.796426,0.442078,0.371618,-1.482833,-0.078305,0.016638,-0.309691,0.102762,-1.166765,-0.257441,0.317146,-0.943034,0.194785,0.936424,0.255063,-0.240794,0.545994,0.808627,-0.378211,0.302663,-0.964040,0.144414,-0.084269,0.415688,0.289966,-1.135662,0.295157,-0.685391,-0.344849,-1.211414,0.289817,-0.616264,-0.463980,-0.860171,-0.065412,-0.903436,-0.264560,-0.134142,0.156603,0.024582,0.398463,-0.258469,-0.360882,0.713229,-0.507937,0.710439,-0.139819,-1.735972,0.425672,-0.364937,-0.582587,0.267294,0.948221,-0.615035,-0.686042,-1.343455,0.479696,-1.052998,0.353802,1.017342,-0.698964,0.054913,0.542843,-0.941439,0.462741,-0.355844,-0.741983,0.539383,0.541626,0.900784,0.959266,0.876396,-0.591791,-0.930493,0.460265,-0.562617,0.509422,0.287389,1.009959,-1.062151,-0.858459,0.322532,-0.893040,1.103133,-0.067528,-0.530745,0.802146,-0.005483,-0.399893,0.560347,0.178410,-0.871247,0.461607,0.512131,0.555069,-0.659049,-0.640458,-0.517039,0.227619,-0.512315,0.567705,0.581342,-0.908401,-0.311426,-0.296720,0.741904,-0.474244,0.539991,-2.067004,-0.080485,-0.512797,1.230782,-0.814628,0.426062,0.432304,1.805681,1.124922,0.061509,0.634728,1.074584,-0.044911,-1.251948,1.226208,1.334580,0.128452,0.009108,1.404133,1.010273,1.041770,0.878487,0.802618,0.027121,1.161508,-0.780740,-1.639148,-0.508080,0.322573,-1.170962,-0.642225,0.533993,0.615398,0.042757,-0.662692,0.456841,-0.662699,-1.193944,0.233558,0.674042,-0.031537,-0.452614,0.926696,0.247673,1.197227,0.741017,-0.554759,-0.623136,-0.621803,-0.122084,-0.635599,0.119253,0.277606,-1.066496,0.216122,-1.071130,-0.618951,-1.159400,-1.121003,0.216643,0.343755,-0.964732,-0.178728,0.667128,-0.078117,-1.451411,-0.806845,1.147864,-0.461426,0.560189,0.491839,-0.102250,0.043109,0.736810,-0.087776,0.090693,-0.706942,0.223495,0.278168,0.118142,-0.382688,1.363822,-0.945664,1.080082,-0.526677,-0.893039,-0.242674,0.455210,0.003926,-0.634851,-0.923757,1.078059,0.015945,0.072945,0.460627,-0.049396,-0.368876,-0.527272,-0.238265,0.099878,-1.119939,0.427668,-0.270055,0.339395,0.579848,-1.151824,-0.726993,0.191244,-0.160331,-0.086081,0.177353,0.588725,0.469012,-0.595865,-1.372823,0.666763,0.388947,-0.546841,-0.270307,0.135616,-1.114811,0.632198,0.497882,-0.049753,-0.257562,1.054774,1.664158,0.629844,-0.386806,0.346905,-0.589025,-0.119379,-0.084233,-0.661415,-0.813429,-1.189042]'::vector, '540db17ce6a7b7d64ff171066b8556f011c10b0015392f6171bccc78ff4161a6', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-decorators-use';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '트랜잭션은 여러 데이터베이스 작업을 하나의 원자적 단위로 묶어, 중간에 실패하면 전부 취소(롤백)되도록 보장합니다. Django는 `transaction.atomic()`으로 이 범위를 지정합니다.

아래 `create_user` 함수는 유저 생성과 프로필 생성, 두 가지 작업을 수행합니다. 둘 중 하나라도 실패하면 다른 하나도 저장되지 않아야 합니다.

```python
from django.db import transaction

def create_user(username, email):
    with transaction.atomic():
        user = User.objects.create_user(username=username, email=email)
        Profile.objects.create(user=user)  # 여기서 실패하면 user 생성도 롤백된다
```
`with transaction.atomic():` 블록 안에서 예외가 발생하면 Django는 블록 시작 시점의 상태로 데이터베이스를 되돌립니다. 즉 `Profile.objects.create`가 실패해도 이미 실행된 `User.objects.create_user`가 커밋된 채로 남지 않습니다. 이 보장이 없다면 유저는 있는데 프로필은 없는 반쪽짜리 데이터가 생길 수 있습니다.', '[-1.408016,1.866743,-2.278560,-1.313982,1.451806,-0.685092,0.197460,0.497480,-0.193858,-0.275836,-1.774273,1.262403,1.583639,-0.982050,-0.118585,-0.897940,-0.765767,-1.212892,-0.119960,1.248807,0.406477,-0.859206,-0.246750,-1.585816,1.542384,-0.188144,-0.343280,0.290005,-1.468222,-0.083395,0.154745,0.410712,-0.184678,0.219080,-0.354595,-0.779695,0.747102,0.765467,0.542170,0.116940,-0.141588,0.061439,-0.052365,-0.408565,0.190742,-0.007446,1.385282,-0.261505,0.552205,0.715549,-0.250815,-0.190164,-0.209784,-0.126038,2.025896,1.286514,-0.471876,-0.492532,-0.097770,-0.992333,0.980497,0.821685,-0.475786,2.009184,1.637879,-0.218357,-0.375555,1.283895,-0.005807,-0.051781,0.576927,0.558161,-0.897775,-0.395510,0.903402,-0.066823,-0.920240,-0.769278,0.293256,0.899345,0.353230,0.570674,1.614917,0.027966,0.783198,-0.592162,-1.345759,-0.287674,0.104792,0.722146,0.138223,-0.631374,0.304922,-0.057355,-1.235238,0.321982,-0.817127,0.698030,-1.235848,-1.251301,0.129875,-0.304348,0.784937,-0.129943,0.143990,0.503566,-0.496066,0.506162,-0.314905,0.022341,0.012775,1.403343,-0.643423,0.173136,0.482781,-0.472281,0.239493,-0.018351,0.107094,0.466453,-0.018457,-0.415645,-0.600367,0.469154,1.041251,0.014156,-1.293386,0.266932,0.827182,-1.439188,-0.372379,-0.575854,-0.757839,-0.528663,-0.328007,0.245052,-0.642718,-0.270185,0.266697,-0.606401,0.291242,1.467843,-0.905718,-0.462365,-0.359500,-0.651705,0.948321,-0.033771,-0.614178,0.473121,0.142552,0.810386,-0.211515,-0.268288,-0.426393,-0.134141,0.806829,-0.877537,0.067511,0.169403,1.154186,0.289648,-0.068310,0.541948,-0.585211,-1.208105,1.866203,0.225310,0.049681,0.825170,-0.455672,-0.661331,-0.858425,0.476107,0.355501,0.528078,-0.777667,-1.020033,1.536164,-0.409164,0.221454,-2.572418,2.207685,0.682615,-0.433961,-0.225652,-0.068241,-0.626831,0.065046,-0.742176,0.759747,-0.444726,-0.528002,-0.986739,-0.997631,-0.976863,0.955822,-0.025889,0.693909,-1.336767,-0.275717,0.024309,-0.471843,0.198033,-0.355300,0.741463,-0.099862,0.389658,-0.711171,0.479666,1.275425,0.130431,-0.050961,-0.060311,0.431485,-0.802525,-0.204240,-1.281542,-0.892484,0.344689,0.238223,-0.213270,0.503639,0.351217,0.643051,-0.531279,-0.295940,0.721844,-1.048292,-0.138839,-0.506057,-1.221095,0.353022,-0.731025,1.058144,0.395155,-0.103043,1.194771,-0.592318,-0.361168,-0.308881,0.307750,0.051720,-0.149321,-1.174830,-0.689175,-0.286977,-0.231266,0.431011,1.050485,0.000305,-0.446172,-0.682960,0.014792,0.251582,-0.092054,-0.101817,-0.008325,0.981487,-0.228678,0.226892,-0.552951,0.094415,-0.456904,-0.342764,-1.219413,-0.887308,-1.133433,0.405783,0.658767,0.002043,0.346236,-0.144883,0.856670,0.147205,-0.963765,0.898118,-0.025433,0.055757,1.307868,-0.398805,-1.038247,-1.209062,0.590242,0.215527,0.718549,-0.181516,0.543841,-0.529389,-0.066617,0.478010,0.085586,-0.976418,0.304943,-0.020071,0.480136,0.629907,0.156265,0.063692,0.363327,0.582837,0.521503,1.478170,1.243005,-0.441663,-0.256833,0.462500,0.359256,0.125517,-0.570911,-1.394823,-0.356573,-0.967087,0.579093,-0.193629,1.057282,-0.033362,1.254357,0.528584,-1.312208,-0.417524,-1.114462,0.246951,-0.704759,0.473041,0.591077,-0.820949,0.617346,0.362213,-0.345376,-0.300640,1.108968,0.281156,-1.033795,-0.209405,0.533559,-0.233589,-0.517145,-0.230127,1.253738,1.046581,-0.255481,0.539139,-0.552189,-0.561271,0.176734,-0.290190,-0.275780,0.787820,0.754671,-0.889251,0.925763,-0.289603,0.491956,-0.583711,-0.693587,0.396152,0.827767,0.014506,-0.312544,0.774601,-0.131046,0.524799,-0.415017,-0.112892,1.291230,0.333962,-0.138275,1.587537,0.302913,-0.831195,-0.912264,0.267664,-0.864453,0.381207,0.214207,-0.145385,-0.063307,-1.056928,0.915271,-0.283477,-0.377844,0.158305,1.347353,0.662988,-0.830925,-0.464144,-0.500466,0.291209,0.268471,-1.313105,0.214610,-1.048910,0.352959,0.944683,-0.431939,0.269750,0.331814,-0.151935,1.077473,-0.713796,-1.118064,-0.268163,-0.943156,-1.163699,-0.093850,0.141936,0.085896,0.976671,-0.317869,-0.645876,-0.339504,-0.386417,-0.411295,-1.062853,0.589989,1.062899,0.899329,-0.297135,-0.930309,0.392051,0.713555,0.785884,0.801899,0.124172,0.668703,1.153071,0.831668,0.166578,-1.230868,-0.807943,1.576659,0.899304,0.405802,-1.247238,0.101709,1.088445,0.751130,0.574656,0.647986,1.617177,-0.544138,0.137738,-0.127818,0.631849,1.217366,1.081538,-1.967575,-0.695599,1.139639,-0.048281,0.993015,0.131865,-0.000466,0.925777,-0.061812,0.088968,-0.655824,-0.021067,0.579235,-0.257854,0.104920,-0.861534,-0.402124,-0.427480,-0.580952,0.924407,-0.196224,0.928058,0.687648,-0.476282,0.210744,0.761731,-0.844704,1.059987,0.555874,0.460363,-0.301606,0.656854,0.335356,0.425914,0.169791,-0.596126,-0.863118,0.614821,0.067178,0.774537,0.033168,0.895324,0.240330,0.702373,0.141486,0.263784,-0.612877,-0.814433,-0.604794,-0.599630,1.368266,0.772950,-0.344742,-0.186719,0.199694,-1.230546,0.512613,0.641213,-0.749629,1.603538,0.283281,0.108291,-0.805029,-0.235768,0.147581,-0.275796,-0.478307,-0.063770,-0.465916,0.285085,-0.133141,-2.260434,0.318879,0.537933,0.262616,0.259563,-0.164512,-1.025327,0.216732,-0.156393,-1.436607,0.961013,0.308396,0.063652,0.738008,-0.165575,-0.814659,0.361470,-0.936183,0.098637,1.352813,0.052950,0.849268,1.195604,0.194054,-0.283135,-0.009742,0.173199,-0.429673,-0.091432,0.679993,0.159465,-0.762377,0.728242,-0.739650,-0.223173,-1.163061,0.923206,-1.011278,-0.271547,0.354897,-0.577780,-0.616285,0.281869,0.481353,0.825148,0.004230,0.427868,-1.953735,-0.446374,-0.373877,-0.239840,0.823321,-0.393162,-0.713367,-0.089008,-1.178552,-0.236512,0.521571,0.581958,-0.645249,-0.752660,0.113865,0.041450,-1.161294,-0.135512,1.377770,-0.287263,-0.226830,0.123275,-0.867198,0.060797,-1.422056,-0.088840,0.619869,0.344172,-0.402403,0.165227,0.722058,0.045220,-1.734273,-0.076764,-0.992093,0.472901,-0.109164,0.208924,0.207264,-0.477249,0.193585,-0.552398,1.413234,-0.223279,-1.159096,0.047828,0.798346,-0.192433,-0.048111,0.489255,-1.140182,1.417298,0.803860,0.381763,-0.648376,-0.950708,-0.909151,0.665002,-0.144264,0.782319,0.706529,-1.006073,-0.226935,0.014672,0.710276,-0.385907,0.692104,-1.960588,-0.306645,-0.625173,2.031325,-0.804258,0.172309,1.061282,1.649318,1.147619,-0.010748,0.350233,0.604405,0.169588,-0.818621,0.709927,1.631353,0.340629,-0.911425,1.842340,0.896440,0.342583,0.722576,0.767369,-0.636117,0.593751,-0.171675,-1.667883,-0.600767,0.053186,-0.006369,-0.847530,-0.050636,0.694912,0.076532,-0.186736,0.165218,-0.773752,-1.053655,-0.004403,1.074739,0.566056,-0.135061,0.513952,0.339854,1.496058,0.667222,-0.293880,-1.529831,-0.834022,0.769919,-0.272816,-0.603601,0.250688,-1.425545,0.115309,-0.637918,0.140266,-1.083427,-1.003470,-0.474066,0.076592,0.370343,-0.716507,0.764920,0.267623,-0.361235,-0.189581,1.584536,-0.660915,0.180231,-0.369345,0.282438,-0.458151,0.061466,-0.056066,0.581651,0.075260,-0.657695,-0.421206,-0.113305,-0.050680,0.716570,-0.392223,0.800536,-0.654060,-0.525280,-0.428897,0.750800,0.364128,-0.359240,-0.675815,-0.210385,-0.762545,-0.834972,0.513311,-0.157094,0.268864,-0.681393,0.761636,0.144761,-1.847396,0.964182,0.009995,0.214105,-0.819374,-0.542026,-0.477816,-0.495678,-0.688922,0.264752,-0.134150,0.299778,0.239165,-1.253421,-1.412870,0.782117,0.783666,-0.638286,-0.311101,-0.763313,-0.533836,0.535524,0.479648,-0.190467,0.403774,0.801346,1.360354,0.827722,0.629061,0.533563,0.295676,-0.000927,0.231859,-0.513255,-0.405883,-0.463403]'::vector, '2454abfe5a5523311faeda3d89fb200bf442c633bdefced1cee94bb64c9ede81', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-transaction-atomic-basics';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'FastAPI에서 `Depends`는 경로 함수(라우트 핸들러)가 필요로 하는 자원을 함수 시그니처만으로 선언적으로 받아오게 해주는 의존성 주입 도구입니다.

```python
from fastapi import Depends, FastAPI
from sqlalchemy.orm import Session

app = FastAPI()

def get_db_session():
    session = Session()
    try:
        yield session       # 요청이 처리되는 동안 이 세션을 사용한다
    finally:
        session.close()     # 응답이 끝나면 자동으로 세션을 닫는다

@app.get(''/users/{user_id}'')
def read_user(user_id: int, db: Session = Depends(get_db_session)):
    return db.get(User, user_id)
```
`Depends(get_db_session)`을 파라미터 기본값으로 쓰면, FastAPI가 요청마다 `get_db_session`을 호출해 세션을 만들고 `read_user`에 전달합니다. `get_db_session`이 제너레이터인 이유는 `yield` 이후의 `finally` 블록이 응답을 클라이언트에게 보낸 뒤 실행되어, 요청마다 세션이 확실히 닫히도록 보장하기 때문입니다. 이렇게 하면 각 라우트 함수가 세션 생성·종료 로직을 직접 반복하지 않아도 됩니다.', '[-0.110910,0.696597,-3.103417,-1.355930,0.876622,-1.419284,0.458316,-0.861017,-0.184015,-0.837840,0.103070,1.121496,1.079350,-0.676462,0.245055,0.426589,-0.270670,-1.654077,-0.291499,0.883749,-0.276697,0.224751,-1.131327,-0.231873,1.522889,-0.176941,-0.131563,0.262255,-1.601215,-0.147762,0.494590,0.202978,0.271266,-1.390067,-1.315117,-0.864600,0.752952,0.069978,0.729501,0.409412,-0.648089,0.023056,1.082392,-0.366196,0.825457,-0.699065,1.524244,0.255780,0.699985,-1.191648,-0.217631,-0.059779,0.062787,-0.637323,2.441972,0.958729,-0.783545,1.061968,-0.078815,0.231963,2.009934,0.057733,-0.872529,0.763384,0.664243,-0.539907,-0.057129,1.107790,-0.398027,-0.074362,0.925712,0.230187,0.079506,-0.658495,-0.222199,0.248572,-0.578993,-1.508008,-0.550801,1.347211,-0.278012,0.430554,0.798964,-0.361258,0.182238,-0.047428,-0.289069,0.493934,0.247095,0.550774,0.240860,-0.381658,0.020013,-0.514611,-1.414866,0.139366,-0.031439,0.371757,-0.751657,-0.405172,0.335261,0.038206,0.235850,-0.692110,0.089752,0.873219,-0.481333,0.696758,0.114503,-0.117297,-0.344143,0.798132,-0.212118,-0.733378,0.185649,-0.766696,0.410582,0.533665,-0.185020,-0.189524,-0.357924,-0.884449,-0.695823,1.289155,0.536736,0.727160,-1.051045,1.588036,0.290722,-0.772882,0.109541,-1.193394,-0.690222,0.737069,0.203353,-0.063571,-0.990704,-0.181681,0.234905,0.028266,0.462862,1.157910,-0.644346,0.352194,-0.058704,-0.633350,1.196550,-0.240041,-0.375100,0.387008,0.234882,0.228483,0.017515,1.382989,-0.139986,-0.722990,-0.106604,-0.050161,0.881570,-0.179826,1.229524,0.334475,-0.502443,0.675126,-0.599222,-0.467725,1.473521,1.160699,-0.035486,0.632416,-0.859135,-1.438749,0.104526,-0.873228,0.199770,0.327006,0.131637,-0.338244,1.885435,-0.465662,-0.314388,-1.778308,0.871832,0.485974,-1.011313,0.513884,-0.252268,0.506322,0.218754,-1.377568,0.274249,0.111402,-0.312611,-0.709050,-1.069297,-0.808630,0.798532,-0.435983,1.251726,-0.609693,-0.776272,0.507494,-0.926603,0.307490,-0.213937,0.451955,-0.072923,0.020443,-1.101124,0.290789,1.729626,0.409553,-0.576283,0.525838,0.374266,-0.457970,-0.005634,-0.501402,-0.594797,0.577077,1.206886,0.133048,0.638416,-0.587644,0.404466,0.443252,-0.561270,0.231769,-0.636928,0.697436,-0.814313,-1.702805,0.017909,0.740705,0.263898,0.351098,0.553210,1.164416,0.698155,-0.241515,-0.312613,-1.012505,-0.013797,0.130362,-2.280279,-0.209950,-0.309546,-0.767380,-0.195747,1.084513,-0.243534,0.316512,0.177698,0.101132,-0.006337,0.475067,0.331177,-0.372346,0.995894,-0.656533,0.950421,-0.656747,0.322564,0.514154,0.256706,-0.122980,-0.131509,-0.196117,-0.761628,-0.021816,0.612470,0.079770,0.302896,0.391041,0.630368,0.332350,0.558050,-0.051359,-0.035694,0.468927,-0.586899,-1.159670,-0.729729,0.448631,-0.691903,0.242088,-0.279900,-0.194449,0.544055,0.173458,1.406223,-0.283061,-1.212992,0.789802,0.022934,0.441506,0.626237,-0.583383,0.165787,0.127688,0.211874,1.620516,1.124483,0.802754,0.245486,-0.126089,0.112104,-0.251190,1.030109,-0.108761,-0.695677,-0.529260,-0.054029,0.667147,-0.935353,1.010178,0.122484,0.347322,1.119262,0.113334,0.048900,-1.294771,0.341687,-0.066649,-0.752854,0.019720,-1.118464,0.655306,0.011864,-0.702709,0.187842,0.372717,0.491508,-1.276002,-0.689739,0.115497,0.813348,0.275384,-0.180530,1.114933,0.543904,-0.656185,1.278037,-1.161100,-0.699757,0.114004,-0.349485,0.111462,0.752648,0.392626,-0.313604,0.221471,-1.402066,0.558817,-0.084980,-0.558857,0.799812,0.467818,-0.108740,-0.027229,0.977766,-0.676309,0.340276,-0.209188,-0.022007,0.500756,0.751059,0.710005,0.389608,-0.153702,-0.451983,-1.234042,0.029873,0.388051,-0.405808,0.476092,-0.827932,-0.731274,-0.868052,0.583551,0.191323,-0.871679,-0.381020,0.877476,0.525274,-0.723721,0.137543,0.218397,-0.625815,0.521282,0.316267,-1.264584,-0.457828,0.571878,0.450048,-0.178458,1.002395,0.525129,-0.629494,1.187781,-1.065778,-1.158322,-0.201157,-0.151954,-0.473388,0.254577,-1.250233,-0.906615,0.134106,0.198841,0.000275,-0.639494,0.127299,0.407173,0.037765,0.608563,1.797562,0.650571,-0.428977,-0.480993,0.588035,0.487155,0.423015,0.360877,-0.051958,0.168909,0.485441,1.179072,-0.065439,-1.524835,0.101564,1.064530,0.620593,-1.009024,-0.524831,0.824966,0.393730,1.550629,0.004064,0.631860,0.509306,0.507456,-0.907522,0.110532,-0.001849,1.631781,0.846103,-0.863576,-0.000405,-0.080495,-0.991258,0.282128,0.606242,-0.380374,1.041587,-1.119896,-0.040779,0.410576,0.495257,1.447856,-0.171381,0.937523,-0.867869,0.197440,-0.719603,0.468441,0.420630,-0.417193,0.528866,1.172467,-1.233932,0.089070,0.563688,-0.770113,0.736832,0.762822,-0.610470,-0.423206,0.434796,0.888537,0.516971,-1.083665,-1.004565,-0.560170,-0.137146,0.229336,0.827537,-0.443424,0.456020,-0.100538,0.498819,0.482011,0.376170,0.009725,0.023926,0.013367,0.115111,0.782857,0.204832,-0.341763,-0.657842,0.177493,-0.367198,-0.352244,0.084681,-0.312489,1.304121,-0.875952,-0.348115,-0.265918,-0.719349,0.618666,0.593484,0.468632,0.784989,-0.594695,1.479764,0.410431,-1.019744,0.922178,0.472452,-1.142785,0.244966,-1.301226,-1.742989,-0.539791,-0.140621,-1.078644,0.405264,-0.313470,-0.403614,-0.013237,-1.244673,-0.590845,0.661671,-0.536932,-0.533404,0.675967,0.997323,0.256161,0.614903,0.765002,-0.139860,0.123210,-0.087323,-0.305286,-0.267095,-0.069222,0.511905,-0.554724,0.707282,-0.247361,-0.614236,-0.912799,0.326844,-0.652008,0.091910,0.100954,0.020512,-0.081646,0.451978,-0.686593,0.565949,0.150159,0.500258,-1.590778,-0.351847,0.708004,-0.707049,1.566245,-0.118944,-1.194406,0.449082,-0.778165,0.674434,0.477831,0.059219,-0.361353,0.107971,-1.183317,0.601473,-1.032596,0.520311,0.785769,0.052309,0.031210,0.608414,-0.194309,-0.207776,-0.917369,-0.516742,0.568515,0.319624,-0.335376,0.089544,0.939464,-0.727527,-1.763968,-0.119941,-0.644901,0.142601,0.674305,0.836383,-0.150466,-0.348201,0.380793,-1.337463,0.579173,-0.733919,-0.960345,0.649685,-0.417519,-0.191114,-0.037506,0.677938,-0.655939,0.663440,0.259081,-0.306046,-0.315207,-0.308614,-0.412126,0.900568,-0.903425,0.383622,0.614194,-0.907835,-0.554327,-0.050152,0.374231,0.212983,0.967892,-1.592522,-1.077837,-1.368021,1.900862,-1.096142,0.885745,-0.184026,1.448986,1.268429,-0.243899,-0.102315,0.311379,0.450690,-0.387357,0.289343,1.534681,1.208412,-0.482279,1.900108,0.712616,0.980907,0.342229,1.544352,0.275496,0.669300,-0.567547,-1.605401,-0.756258,-0.360646,-0.961654,0.143572,0.596780,0.621730,0.433716,-0.231613,-0.532680,-0.585531,-0.168323,0.121290,0.143962,-0.532914,-1.423274,1.192535,0.433009,0.669011,0.471582,-1.193368,-0.385499,0.201657,-0.788227,0.352844,0.137630,-0.663675,-0.600724,0.380508,-1.426867,-0.225979,-1.246102,-2.036883,-0.819576,-0.584596,0.692794,-0.152916,0.229527,-0.219179,-0.188229,0.412444,1.185596,-0.187255,0.287653,1.010501,0.801931,-0.343210,-0.240077,-0.342669,0.669876,0.185265,-0.607908,-0.044439,-0.043078,-0.915829,0.798224,-0.227467,0.042963,-0.687217,-0.704637,-0.633355,0.065930,0.182587,-0.282598,-1.069175,0.729415,0.066598,-0.713246,-0.114305,0.026398,0.445536,-0.745759,0.427395,-0.848025,-1.192023,0.367672,0.074238,0.390519,-1.297561,-1.009672,-1.955512,-0.285587,-0.291015,0.270836,-0.353262,0.579337,-0.370316,-0.309617,-1.048658,0.205949,1.059788,-0.145381,0.013308,-0.798098,-0.992556,1.370122,0.636539,0.303632,-0.824082,1.073952,2.408439,1.016649,0.263992,-0.107699,0.389583,0.020906,0.251733,-0.655195,-0.617469,0.074045]'::vector, 'dfa8bc94e29c8403e5021fb80e671696c512cec9653069c5f44c79fd8d3e9f3b', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-fastapi-depends-basics';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Python에서는 객체를 복제할 때 얕은 복사와 깊은 복사를 구분합니다. 차이는 중첩된(nested) 객체까지 새로 복사하는지에 있습니다.

얕은 복사는 바깥쪽 컨테이너만 새로 만들고, 그 안의 요소는 원본과 같은 객체를 참조합니다. 깊은 복사는 중첩된 요소까지 재귀적으로 복사해 원본과 완전히 독립된 객체를 만듭니다.

```python
import copy

class Box:
    def __init__(self, value):
        self.value = value

original_list = [Box(1), Box(2)]

shallow_copied = original_list[:]        # 얕은 복사
deep_copied = copy.deepcopy(original_list)  # 깊은 복사

shallow_copied[0].value = ''changed by shallow''
deep_copied[1].value = ''changed by deep''

print(original_list[0].value)  # ''changed by shallow'' — 같은 Box 객체를 참조하므로 원본도 바뀐다
print(original_list[1].value)  # 2 — deep_copied는 완전히 별개의 Box 객체라 원본은 그대로다
```
`shallow_copied[0]`을 바꾸면 원본의 `Box(1)`도 함께 바뀌지만, `deep_copied[1]`을 바꿔도 원본의 `Box(2)`는 영향을 받지 않습니다. 가변 객체를 담은 리스트를 함수 인자로 넘기거나 캐시에 저장할 때 이 차이를 모르면 의도치 않게 원본 데이터를 오염시키는 버그로 이어집니다.', '[-0.569700,0.203997,-2.653549,-1.854139,1.091426,-0.068970,-0.004885,0.537913,-1.200380,-0.598116,-1.428380,2.061133,1.297611,-0.952335,-0.499819,-0.877040,-0.593766,-1.529052,-0.112187,1.607061,0.670652,-0.465445,-0.214852,-1.617145,1.213963,-0.007704,0.589262,-0.112623,-1.271755,-0.009286,-0.137763,-0.305026,0.229621,-1.247789,-1.129822,0.724202,1.138972,-0.241179,1.369262,0.515685,0.091746,0.125845,0.176245,-0.525516,0.856509,0.056986,0.733816,-0.733292,0.793918,-1.247283,0.247538,0.498881,0.165600,-0.388569,1.172044,0.725063,-0.927110,0.512056,1.195313,-0.939282,0.484923,0.883414,-0.751967,1.221424,0.603636,-0.350122,0.873504,1.159380,-0.199197,-0.494281,1.012032,0.488293,0.164781,-0.550884,0.084618,-0.078566,-0.381022,-0.144547,-0.098696,0.761967,-0.666579,0.718347,0.920986,0.403800,1.390169,0.059615,-0.029574,0.722090,-0.416509,0.994672,-0.582312,-0.377444,0.319842,-0.246798,-0.856647,0.302629,-0.674695,0.676790,-0.422131,-0.758538,0.005085,-0.924993,0.235114,-1.180325,0.066371,0.767788,0.870086,0.175006,-0.818745,0.090919,-0.480162,0.477090,-0.810546,-0.284332,0.307128,-0.740404,0.765931,0.434878,0.208431,0.306440,-0.002036,-0.832071,-0.448328,0.726927,0.756587,-0.123937,-1.007702,0.531223,0.487692,-1.031740,0.194558,-0.344589,-0.344372,-0.045752,-0.413587,-0.302068,-0.743169,-0.113280,0.712982,-0.413494,-0.219034,1.528629,-0.095623,-0.544379,0.589511,0.161471,0.552618,-0.762265,-1.362349,0.263296,0.467023,0.823081,-0.189968,0.010614,0.481921,0.083847,-0.139228,-0.110926,0.290101,0.174699,0.812934,0.330380,-0.139701,0.770793,-0.216578,-0.481146,0.463314,-0.079809,-0.446635,0.564448,-1.201057,-0.875891,0.201955,0.253587,-0.343613,0.429228,0.290169,-1.076292,1.059179,0.005397,-0.329271,-0.266848,1.415747,0.544731,-0.492307,-0.012548,-0.539999,-0.425757,-0.468319,-0.782582,-0.057251,0.702078,-0.220578,-0.375921,-0.287165,-0.445469,0.715786,-0.451281,0.205178,-0.984389,-0.977470,-0.317826,0.088254,0.149335,-1.020390,1.575605,-0.119568,0.512558,-0.819595,1.119147,0.438608,0.201329,-0.227119,0.296345,0.704797,-0.705521,-0.640622,-0.092865,-0.462798,0.026093,0.435396,0.252540,0.548265,-0.594685,1.221347,0.839371,-0.356585,0.246741,0.184275,0.067515,-0.123908,-0.787009,0.442870,-0.440300,0.455457,0.338183,0.061993,1.127710,-0.267658,-0.726778,-0.022605,0.836958,0.314428,-0.317797,-1.285981,0.214180,0.087528,-0.753896,0.270146,1.361503,0.045582,-0.208033,-0.208268,0.739398,0.375948,0.351129,0.407929,-0.075515,1.176533,-0.396633,0.593470,-1.340505,0.223942,-0.312833,-0.371552,-0.796982,0.503438,-0.252915,-0.092095,0.647535,0.363350,0.257477,1.189421,-0.140286,0.971607,-0.172036,0.613192,-0.659335,-1.095764,0.272289,-0.369497,-1.217133,-0.422694,-0.092617,-0.241190,-0.328479,-0.632595,-0.323411,-0.129131,0.321719,0.367526,-0.162970,-0.282368,0.339646,0.441050,1.056485,1.120165,0.151152,-0.090343,0.294385,0.040928,1.294986,1.957036,0.525817,0.156815,-0.450799,0.388892,0.176281,0.364314,-0.176771,-0.658558,-0.349126,-0.273854,1.064874,-1.067604,0.552628,0.202125,0.199103,0.811352,-0.630454,-0.469565,-0.556850,0.586820,-0.422195,-0.165459,1.128771,-1.186009,1.427090,0.460664,-0.264014,-0.450413,0.652687,0.226378,-0.284024,-0.526561,0.313307,-0.510225,-0.043802,0.814628,1.038087,1.454026,0.015064,-0.092000,-0.195276,0.136800,0.361627,0.645651,-0.541776,-0.406775,0.735512,-0.840656,0.442010,-0.504946,0.108567,-0.323495,0.094283,-0.247563,0.257669,0.216759,0.065580,1.374284,-0.347695,1.049631,0.205049,0.061234,0.115011,0.005995,-0.055578,1.224344,0.062041,-1.018506,-1.018295,-0.080246,-0.119413,0.124283,0.146818,-0.161337,0.030064,-1.707579,0.561918,0.085971,-0.953466,-0.699647,-0.332007,0.598014,-0.856180,-0.134321,-0.021314,0.061648,0.548756,0.336871,0.292874,-0.946162,0.137680,1.210048,0.150862,0.608262,0.384653,-1.233261,0.167256,-0.697472,-0.803884,0.407131,-0.335064,-0.796587,-0.267870,-0.051050,0.070045,0.530994,0.028312,-0.531860,-0.318863,0.165974,-0.663567,-0.387204,0.838919,1.531369,1.275207,-0.363762,-0.577551,0.729964,0.853589,-0.414008,-0.048945,0.249052,0.481784,0.329376,0.903601,0.354888,-1.941701,0.279384,0.866146,1.250675,0.481031,-0.866017,0.075888,0.217119,0.482097,-0.343371,0.121476,1.190615,-0.748758,-0.623159,0.133083,0.557518,1.107657,0.539310,-1.291312,-0.619380,-0.128962,0.288279,0.165057,0.744075,0.432231,1.190799,-0.107018,0.229385,-1.039286,-0.987602,0.449570,0.444374,0.316232,-1.184488,-0.595004,-0.393422,-0.553231,0.029319,0.018280,0.877685,0.867118,-0.336936,0.377261,0.088720,-0.841579,1.078976,0.653553,-0.583425,-0.095387,0.422747,0.030197,-0.259766,-0.762083,-1.007021,-1.064021,0.252651,0.721421,0.168305,-0.234393,0.747877,-0.590726,0.250443,1.046134,0.663227,0.330824,0.172128,-0.751262,0.272839,1.974283,1.000878,0.087391,0.158830,0.570781,-0.211746,0.784400,1.139417,-0.305528,1.019239,-0.163630,-1.360507,-0.299050,-0.219327,0.229274,0.910843,0.425237,0.678080,-1.176254,0.706005,-0.374134,-1.579955,-0.303151,1.803378,-0.505618,-0.158725,-0.791948,-0.526768,-0.035137,-0.427978,-1.779858,0.228915,-0.136118,0.024003,0.672657,-0.640709,-0.121229,-0.280636,-1.680067,-0.467398,0.684456,0.042918,-0.782630,1.034205,0.538646,-0.494772,0.218715,-0.932708,-0.296707,-0.142630,-0.434026,0.044430,-1.025521,0.375597,-0.155654,-0.187514,-0.533700,0.706384,-1.194295,-0.593326,-0.477775,0.406886,-0.978702,0.273136,0.351779,0.379501,0.006011,0.367821,-0.610500,-1.037166,0.305221,0.209176,0.471396,-0.637769,-1.920168,0.301418,-0.273370,-0.727202,-0.402967,0.273222,0.060511,-0.814809,-1.076388,0.330019,-1.090439,0.229356,0.393802,-0.886124,0.512897,-0.146371,-0.286195,0.580314,-0.077905,-0.492690,0.415838,-0.332150,1.047774,1.008877,0.741006,-0.456114,-0.858990,0.223070,-1.019224,-0.109502,0.496981,0.630923,-0.692403,0.459072,1.145146,-1.547605,0.731968,-0.769164,-0.269817,0.193844,-0.118772,-0.641488,0.244547,0.343266,-0.868787,0.505366,0.173854,-0.284016,-0.802080,-0.831230,-0.862928,0.374000,-0.872349,1.099467,0.986002,-1.654048,0.263276,0.844207,1.561145,-1.265256,0.264534,-1.887798,-0.120256,-0.774248,1.011103,-0.698099,1.856584,0.034516,1.745787,0.916044,-0.161268,0.637102,0.090013,-0.274285,-0.705952,0.960381,1.031293,0.730623,-0.510033,0.551773,1.008827,0.544049,0.382638,0.823107,0.440224,0.525136,0.035716,-0.880798,-0.287272,-0.143290,-0.174580,-0.638474,0.544555,0.426560,-0.024221,-0.473499,-0.460833,-0.756416,-1.071119,0.480798,0.379164,0.315625,-0.426721,0.848978,0.445924,1.226038,-0.018296,-0.459727,-0.774410,-0.601198,-0.441333,0.002743,-0.176343,0.630762,-1.022882,0.234771,-0.837898,-0.102950,-1.217012,-0.884764,-0.699412,-0.106811,-0.263242,-0.335130,1.083605,-0.824701,-0.624139,-0.211832,1.715969,0.271660,0.866584,-0.288610,-0.286887,-0.916852,0.240175,0.113951,0.519992,0.136050,-0.112513,0.099177,0.199534,0.364707,1.604058,0.038367,0.763694,-0.690169,-1.055560,-0.868201,0.906224,0.526707,-0.470474,-1.152851,0.786723,0.387595,-0.367947,0.026976,-0.642956,0.264685,-0.502548,0.213084,-0.515384,-1.377859,0.965312,0.728659,0.669186,-0.678462,-0.613552,-1.095494,-0.909963,-0.070271,0.606367,0.368727,-0.305413,-0.413652,-0.248118,-2.338013,0.308145,0.339339,-0.765078,-0.138165,-1.031436,-0.462715,1.207843,0.266978,-0.137762,0.315920,0.805705,1.159818,0.436913,-0.232413,0.156325,-0.064323,-0.191108,-0.221370,-0.333730,-1.121197,0.304457]'::vector, '8eaf71c69f549d6580290662aabc05b3e801fc708a9345d6de603050aa8a99f5', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-shallow-vs-deep-copy';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Python에서 스레드를 사용하면 여러 작업을 운영체제가 스케줄링하는 별도의 실행 흐름으로 동시에 진행할 수 있고, `asyncio`를 사용하면 하나의 스레드 안에서 협력적으로(cooperatively) 여러 작업을 번갈아 실행할 수 있습니다.

```python
import threading
import asyncio
import time

def blocking_io_bound_task():  # 스레드로 실행
    print(f''Starting blocking task in thread {threading.current_thread().name}'')
    time.sleep(2)
    print(''Completed blocking task'')

async def non_blocking_io_bound_task():  # 코루틴으로 실행
    print(''Starting async task'')
    await asyncio.sleep(2)
    print(''Completed async task'')

thread = threading.Thread(target=blocking_io_bound_task)
thread.start()

asyncio.run(non_blocking_io_bound_task())
thread.join()
```
`time.sleep(2)`는 스레드를 점유한 채로 대기하므로, 그 스레드 안에서는 다른 작업을 끼워 넣을 수 없습니다. 반면 `await asyncio.sleep(2)`는 대기하는 동안 이벤트 루프의 제어권을 다른 코루틴에 넘겨줍니다. 그래서 I/O 대기가 많은 웹 백엔드에서는 스레드를 늘리는 것보다 `asyncio`로 협력적 동시성을 쓰는 편이 자원을 더 적게 쓰면서도 많은 요청을 처리할 수 있습니다.', '[-0.077113,0.955436,-2.400027,-1.289520,1.371898,-1.200848,0.642525,-0.224042,-0.536579,-0.336181,-0.535156,0.972407,1.286833,0.025384,-0.083061,-0.839635,0.446167,-0.754436,-0.339891,0.604843,-0.344942,-0.261025,0.226756,-1.046454,2.360708,0.622058,0.414952,-0.611270,-0.987899,0.283136,0.122110,0.375444,0.764652,-1.523368,-0.270549,-0.537525,0.477017,0.229640,0.201852,0.497681,-0.147264,-0.884711,1.293713,0.518263,0.962031,-0.372614,0.130631,-0.348944,0.613648,-1.596403,0.262730,0.440190,-1.039012,0.105008,2.020822,0.568964,0.763550,0.339692,0.141969,-0.457304,0.565391,1.185778,-0.502334,1.176743,0.718457,-0.433737,0.943712,1.072134,0.264330,1.172426,0.979007,-0.086701,0.681766,-0.383750,-0.845495,0.388622,-0.196330,-0.656928,-0.435762,1.799653,-0.938527,-0.084758,0.484008,0.109933,0.626061,-0.745023,-1.113917,-0.261209,-0.453266,1.168474,0.039043,-0.243076,0.046236,-0.899121,-0.341222,1.316123,-0.083593,1.134311,-0.662471,-0.057802,-0.514984,-0.171216,0.194624,-1.098683,-0.345018,0.391590,0.406760,-0.374314,-1.289727,-0.590600,-0.334487,0.792104,-1.288276,0.075183,0.490657,-0.834178,0.561417,-0.219229,0.469692,-0.664056,-0.191443,-0.687986,-0.767747,0.885260,0.808951,0.765779,-0.496626,0.768537,1.223452,-1.472260,0.928798,-0.571414,-1.242240,0.382067,-0.446826,0.339905,-1.190009,-0.154342,0.771932,0.046989,0.288357,0.379732,-0.626963,-0.534934,-0.527397,0.026511,0.294225,-0.293020,-0.893021,0.149972,-0.059615,1.032358,-0.223458,0.100950,0.237693,-0.732270,0.038167,-0.468979,0.664425,-0.092770,1.659141,0.660442,-0.851227,0.661921,-1.135578,0.160532,0.762017,1.097485,0.247247,0.082507,-1.213917,-0.928239,-0.223296,0.417279,0.411990,0.960526,-0.008471,-0.784262,0.887500,0.259488,0.091496,-1.374380,1.449970,0.033459,-1.115259,-0.226607,-0.820771,-0.408779,-1.763497,0.289823,-0.049406,0.586046,-0.112906,-0.529643,-1.329786,-0.657602,0.862762,-0.657841,0.508753,-1.519192,-0.544883,-0.395353,-0.336120,-0.309825,-0.949242,0.849469,0.052973,0.046287,-0.146918,0.779332,1.518851,-0.115708,-0.254136,0.478607,0.083125,-0.670621,-0.293635,0.479885,-0.488792,-0.027995,0.185940,-0.806072,-0.040743,0.726642,0.547294,-0.728025,-0.706042,0.548721,-0.939882,0.024426,-0.588432,-1.656443,0.504560,-0.541517,0.530808,0.954504,0.311798,2.050889,-0.300798,-0.835804,0.027503,0.273869,0.240848,-0.308116,-1.194579,0.166111,-0.136209,-0.477781,-0.413244,1.076028,-0.404404,-0.209770,-0.508093,0.748839,0.511678,-0.762601,0.861815,0.133199,0.640093,0.061604,0.184045,-0.810403,0.301997,-0.991302,0.098035,-0.591653,-0.136494,-0.332711,-0.027172,-0.164325,-0.388186,0.127928,0.679863,0.531913,0.571505,0.185218,0.684230,0.735081,-0.479611,0.829670,-0.416114,-0.500541,-0.729754,0.622419,-0.112053,0.094370,0.175366,0.239216,0.324054,-0.700146,-0.069294,0.346147,-0.740739,0.836011,0.405104,1.190273,1.073737,0.373956,-0.436141,-0.486750,0.147303,1.112039,0.919235,0.412410,0.526258,-0.836981,-0.497521,-0.531174,-0.161941,-0.172978,0.332456,0.101688,-0.037633,0.860215,-0.966093,0.808013,-0.043430,0.919552,0.013922,-0.383070,-0.063254,-0.075954,0.004543,-0.696843,-0.591590,0.631281,0.248712,0.542541,-0.376205,0.334487,-0.108886,0.407482,1.904058,-0.990233,-0.467457,-0.087752,0.050117,0.269892,-0.400740,0.899217,0.748137,-1.245039,0.736998,-0.308208,-0.785680,0.344480,0.205081,-0.543041,0.338161,1.074337,-0.967617,0.946598,-1.455790,-0.419122,0.369593,-0.085669,0.337797,0.618288,-0.033937,-0.537570,0.651924,-0.270413,0.289937,0.053015,-0.675863,0.282694,0.653276,1.064415,0.054614,-0.534761,0.235954,-0.597057,0.189890,0.152063,0.276982,-0.132877,-0.574463,0.080828,0.105755,1.284885,0.759430,-0.721064,-0.918395,0.019983,1.269745,-0.587046,0.350777,0.288199,-0.090765,-0.128450,0.351078,-0.552172,-0.279131,-0.042473,1.670734,-0.138456,0.964149,-0.287597,-0.722027,0.212673,-0.518402,-0.278846,-0.383822,-0.417841,0.104733,1.103818,0.243762,0.111054,1.283726,0.486776,-0.145798,0.446116,0.491551,-1.338794,-0.500191,0.352222,1.493952,1.526414,-0.733683,0.178054,-0.897433,1.140995,0.172363,-0.152531,-0.278673,0.485874,0.065197,0.610483,0.147290,-1.096255,0.082673,0.491827,1.078894,0.236236,-0.404960,0.095146,1.410292,0.938977,-0.621036,1.075215,-0.156740,-0.272948,-0.253497,0.315760,0.557819,0.946282,1.240308,-1.488417,-0.966714,-0.090919,-0.067933,0.561134,0.308623,-0.219583,-0.173355,-0.639077,0.058680,0.990015,-0.673304,0.729468,-0.102766,-0.322193,-0.425940,-0.616524,-0.309678,0.138347,0.435348,0.012487,0.139866,0.828309,-0.226934,0.088442,-0.106046,-0.927642,0.565680,0.171357,-0.173978,0.265910,0.949186,1.194678,0.443602,-0.803914,-0.976159,-0.198454,0.446456,0.792917,0.558755,-0.031848,-0.132216,0.356276,0.631065,0.574815,0.035320,0.160036,-0.152463,0.562080,-0.096525,1.560270,-0.012324,0.225222,0.015935,0.306502,-0.636515,0.118387,0.079270,0.726973,0.452441,-0.062338,-0.357064,0.009019,0.071639,0.309134,-0.027249,-0.081855,1.206545,-1.164451,1.366577,-1.013785,-1.233566,-0.118795,0.726211,-0.356557,-0.007158,-0.870984,-1.191897,0.389846,-0.247785,-0.300287,0.653087,-0.608748,-0.567819,-0.950095,-0.313910,-0.607152,0.257619,-1.980595,0.633196,0.575966,0.342847,-0.681354,-0.104581,0.256324,0.085974,0.145611,-0.893936,-0.107200,0.096191,-0.262337,0.150435,-1.286610,0.690230,0.177221,-0.251699,-0.442013,0.652322,-0.305167,0.415233,-0.420249,0.530782,-0.807456,0.150384,-0.495858,0.313542,0.014904,0.842007,-1.542867,-0.900058,0.033141,0.320284,1.548378,0.033227,-1.697006,0.392718,-0.558999,-0.925389,0.158334,0.214303,-0.471935,-0.757504,-1.288646,-0.162169,-0.783707,0.047677,0.884489,-0.270461,0.458052,0.175709,-0.118583,0.531648,-0.277106,-0.764658,0.501225,0.312377,-0.118088,-0.026030,0.928908,-0.668597,-1.523538,-0.368432,0.117796,-0.087436,0.675501,1.250896,-0.971569,-0.390656,1.801507,-0.672560,0.747289,-0.979169,-0.389065,0.093475,0.414147,-0.295119,1.104645,0.673670,-1.377670,0.801684,0.431530,0.160212,-0.753701,-0.457170,-1.055271,0.918002,-0.351162,0.997491,0.016223,-0.823625,-0.059138,0.945712,0.875595,-0.624833,-0.024535,-2.262409,-0.282686,-0.817838,0.932507,-0.940356,0.314275,0.909750,1.489132,1.073801,0.154419,0.402282,0.525912,-0.184760,-0.986093,0.623359,1.676859,0.268275,-0.485327,1.186419,1.548071,-0.583074,0.624443,0.959847,-0.050544,0.638358,-1.390310,-1.414829,-0.949545,-0.186317,-0.533216,-1.586126,0.489489,0.122755,0.444920,-0.453316,0.265303,-0.889723,-1.859680,-0.155979,0.589012,-0.329519,-1.204310,-0.443295,0.104663,1.006799,-0.071344,-0.526254,-1.370574,0.291617,-0.441124,-0.086364,0.756889,0.680479,-0.566699,0.541702,-1.159796,-0.621592,-1.266980,-0.281563,0.399332,-0.610494,-0.567693,-0.684653,0.341653,-0.107549,-0.949084,-0.517531,1.468430,-0.277747,0.774068,0.339730,-0.103205,-0.289048,0.207555,0.172052,0.348898,-0.537072,-0.230932,-0.633395,0.834116,-0.512058,0.971162,-0.266933,-0.133928,-0.656111,-0.196804,-0.428207,1.113769,0.886803,-0.378597,-0.846115,0.452655,-0.449484,-0.355481,0.680319,0.001925,0.637614,-1.010512,0.775982,0.184359,-0.295948,0.225507,-0.285287,1.184623,0.137212,-0.850205,-1.780437,-0.346725,0.040108,-0.228328,-0.088972,-0.078304,0.191422,-0.719896,-0.931428,0.057414,0.464531,-0.513682,0.057426,-0.547565,-0.788173,0.657505,0.775636,0.106473,-0.575598,0.681732,1.526069,0.695373,0.428886,-0.320542,-0.769841,0.271931,0.188507,-0.261645,-0.506726,-1.054882]'::vector, '858d2cbe39145c540f11717b243d8639c1cb4a86b282f742bb6604e8d4b624be', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-threading-vs-asyncio';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`async def` 안에서 `requests` 같은 동기(블로킹) 라이브러리를 그대로 호출하면, 그 요청이 끝날 때까지 이벤트 루프 전체가 멈춥니다. 같은 이벤트 루프에서 동시에 처리되던 다른 요청들도 함께 대기하게 됩니다.

```python
import asyncio
import aiohttp
import requests

async def fetch_async(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            return await resp.text()

async def fetch_blocking(url):
    # requests.get은 동기 함수라, 이 호출이 끝날 때까지
    # 이벤트 루프에 등록된 다른 코루틴은 전혀 진행되지 못한다.
    return requests.get(url).text
```
FastAPI 같은 ASGI 애플리케이션에서 `fetch_blocking`처럼 동기 라이브러리를 `async def` 핸들러 안에 그대로 쓰면, 한 요청이 느려질 때 서버 전체의 다른 요청까지 함께 지연됩니다. 해결책은 두 가지입니다. `aiohttp`나 `httpx.AsyncClient`처럼 진짜 비동기 라이브러리로 바꾸거나, 부득이하게 동기 라이브러리를 써야 한다면 `await asyncio.to_thread(requests.get, url)`로 별도 스레드에 위임해 이벤트 루프를 막지 않게 해야 합니다.', '[-0.481305,1.631712,-2.637300,-1.363012,1.879413,-1.046252,0.160896,0.604528,-0.204362,-0.808589,-0.125148,1.170715,1.373953,-0.511617,-0.047224,-0.497006,0.555056,-0.693775,-0.562869,-0.021888,0.030630,-0.614721,-0.157871,-1.181720,1.947404,0.505902,0.628931,0.323930,-1.974587,0.216746,-0.086972,-0.409459,0.400713,-1.334169,-0.290812,-0.249689,0.638593,-0.181892,-0.308565,0.353002,0.130906,-0.321027,0.902816,0.787362,0.556807,-0.142432,-0.153057,0.374063,0.598937,-1.249774,0.571552,-0.142651,-0.477837,-0.289090,2.163919,0.335271,0.491466,0.398781,0.358059,-0.574250,0.187872,1.767993,-0.611314,1.001610,1.080353,0.080030,0.706728,1.188144,0.148709,0.314370,0.771297,0.078008,0.031527,-0.741259,-0.587134,-0.007181,-0.556159,-1.409548,0.003826,1.703084,-0.575879,-0.044880,0.922585,-0.441359,0.923317,-0.161880,-0.501637,0.821318,0.001560,1.068101,-0.455566,-0.603016,0.167274,-0.759632,-1.424856,1.042260,-0.710500,0.651281,-1.184981,-0.159622,0.249046,0.406243,0.546727,-0.733636,0.134367,0.933969,0.516966,0.519878,0.223648,-0.536448,-0.095669,1.117754,-0.867957,-0.165327,0.304575,-0.487778,0.548121,0.856177,0.077848,0.536248,-0.260448,-0.285676,-0.720917,1.168919,1.307075,0.623429,-0.523966,0.989446,1.018646,-0.748385,0.788156,-0.870977,-1.125839,0.056910,-0.060595,-0.388306,-0.169002,-0.623558,0.976823,0.047313,0.802093,0.547446,-0.371432,-0.562805,-0.376824,-0.248570,0.540114,-0.451140,-0.575264,0.300322,0.014091,1.024392,0.433879,0.653803,1.071119,-1.018027,0.494527,0.022371,-0.184872,0.555418,1.020259,0.411463,-1.093691,0.969951,-0.635375,-0.109391,0.199352,1.121572,0.109170,0.979034,-0.395007,-0.515804,-0.193227,0.331829,0.017740,0.694313,0.374946,-1.146746,0.955817,-0.707632,0.200865,-2.123315,1.439649,0.188168,-1.149600,0.095938,-0.595202,-0.541052,-0.930268,-0.358810,-0.358651,0.045497,-0.465112,-0.468689,-0.544359,-0.490570,0.733078,-1.119615,0.536736,-0.721400,0.211466,-0.362730,-0.366275,-0.533001,-1.270109,1.282727,-0.726297,0.749976,-0.062563,0.376258,1.835789,-0.117220,-0.413317,0.264786,-0.295437,0.006561,-0.171819,-0.390520,-0.371053,0.044797,0.183347,-0.545633,-0.390959,0.681463,0.316127,-0.277912,-0.522909,0.496296,-0.328533,0.061212,-0.279072,-2.289635,0.632041,-0.292319,0.357826,1.370132,0.417770,1.989267,-0.026663,-1.126567,-0.601014,0.195691,0.131692,0.227311,-1.433851,0.009451,-0.255142,-0.476122,-0.155219,1.121681,0.027294,0.743499,-0.131730,0.245771,0.471520,-0.560863,1.911910,-0.119736,0.472512,-0.119438,-0.103826,-1.276797,0.136265,-1.257424,-0.287223,-0.053457,0.074301,0.450025,-0.333334,-0.075804,-0.304200,0.244099,0.289572,0.249062,0.671199,0.055054,0.415248,0.494186,-0.389167,0.824018,-0.751447,-0.595541,-0.656517,-0.018679,-0.115543,0.553539,0.190316,0.520351,-0.138752,-0.877864,0.459274,-0.111237,-1.051568,0.762170,-0.020966,0.728065,0.993965,-0.387456,-0.979046,-0.241011,0.337534,1.205835,1.285872,0.180960,0.118607,-0.611314,0.209645,-0.123068,0.354229,0.263832,-0.416612,-0.391086,-0.122845,0.440415,-0.611785,1.065850,0.687864,0.633912,0.336500,0.180527,-0.198913,-0.731775,0.026798,-0.462420,-0.588732,0.053143,-0.309668,0.795561,0.025111,-0.663286,0.619574,0.028310,1.167147,-1.550360,-0.504812,-0.299429,-0.087773,0.669528,-0.049397,0.466445,0.150875,-0.959976,0.825606,-0.465371,-0.608360,0.218252,-0.224374,-0.260607,0.920835,0.858220,-0.923072,0.782484,-0.633722,-0.079762,-0.044313,-0.517613,0.069753,0.576904,0.051995,-0.482425,1.098780,-0.338799,0.905744,-0.059479,-0.046736,0.264208,0.270956,0.277917,-0.098309,-0.042040,0.916409,-1.406544,-0.159941,0.382297,0.607758,-0.293320,-0.850950,-0.027673,0.085916,0.767349,0.833437,-0.826361,-1.152014,-0.096953,1.061888,-0.594384,-0.013253,0.419745,-0.017000,-0.000134,0.630550,-0.883225,0.270787,0.053440,1.023977,-0.750645,0.707342,-0.127468,-1.368265,0.508315,-0.944831,-0.835095,-0.010678,-0.208796,-0.551295,0.280739,-0.408849,-0.385673,2.098994,0.189121,0.017406,-0.144318,0.038279,-1.375447,-0.247449,0.423783,1.514912,0.438183,-0.432064,-0.193472,-0.233164,0.359787,0.565587,0.259850,-0.199176,0.764388,0.375710,0.595668,0.206058,-1.097493,0.448405,0.122177,0.635710,-0.306084,-0.538165,0.287066,1.079641,1.078278,-0.673992,0.660045,0.770928,0.157200,-0.167035,-0.171771,-0.047039,1.216986,1.274670,-0.680750,-0.555925,0.065697,-0.601418,0.106075,0.598131,-0.356381,0.830957,-0.569661,0.263548,0.262280,-0.184795,0.817972,0.194893,0.062661,-0.579407,-0.078877,-0.204272,0.023313,0.490444,-0.084327,0.610683,0.831436,-0.835654,0.057221,0.188221,-0.262046,1.153818,-0.014240,-0.412695,0.317757,-0.042137,0.792796,-0.146655,-0.394100,-0.629701,-0.320937,-0.337507,0.694210,0.477279,0.092320,-0.346537,0.477659,0.343830,0.257142,-0.602914,0.100151,0.243233,0.205337,-0.511338,1.362684,0.485096,0.273991,0.327320,0.080309,0.041918,-0.266411,0.615555,0.621594,0.476477,-0.104144,-0.579039,-0.809808,-0.162928,-0.226597,0.771362,-0.046363,1.603212,-0.439841,0.809913,-0.546767,-0.911543,-0.211078,0.755544,-0.519669,0.176078,-1.630450,-1.510233,0.756242,-0.337695,-0.790552,0.228909,-0.653038,-1.518242,-0.507890,-0.273221,-0.745226,0.721532,-0.836502,0.703714,0.122917,0.429472,-0.299644,-0.207166,0.262072,-0.064905,0.020617,-0.478070,-0.425697,-0.068451,-0.340443,0.183538,-1.449610,0.575176,-0.706301,-0.303163,-0.626688,0.851772,-1.139360,0.396282,-0.324656,0.440794,-0.845274,0.122259,0.164095,0.455185,-0.331460,0.574493,-0.995054,0.223927,0.579705,0.409074,1.554463,0.018547,-1.029391,0.196511,-0.639992,-0.199929,0.378396,0.334793,-0.075982,-0.723590,-1.271943,-0.397894,-0.816946,0.514439,0.707600,-0.169104,-0.209072,0.086313,-0.152625,0.882961,-0.886684,-0.820018,0.119446,0.094465,-0.518552,-0.164278,0.748361,-0.712546,-2.092184,-0.600537,0.145224,0.252009,1.018092,0.423635,-1.118410,-0.276359,1.101251,-0.002021,0.313345,-1.203388,-0.533887,0.338276,0.569626,-0.571374,0.394415,0.134191,-1.343032,0.616271,0.657016,0.149646,-0.652382,-0.467506,-1.333717,1.269252,-0.474182,1.170742,0.105586,-1.058974,0.130961,0.204203,0.753090,-0.241179,0.685286,-2.357059,-0.481587,-1.069977,0.946447,-1.038121,0.048447,-0.008319,1.174480,2.328518,0.284597,-0.326834,0.576728,0.334655,-0.648048,1.032679,1.209655,0.462199,-0.586224,1.574345,1.408685,0.377944,0.369436,1.152481,-0.180887,0.573446,-1.130883,-1.282789,-0.707750,0.056541,-0.735842,-0.883290,0.743719,0.574952,-0.325136,0.076622,-0.345498,-0.432822,-0.866511,0.129275,0.295395,-0.377537,-1.039213,0.161207,-0.249733,0.775179,0.454781,-0.758306,-1.471331,-0.392857,0.081541,0.395197,0.614186,0.673321,-0.893697,-0.483394,-0.998697,-0.620976,-0.578560,-0.740987,-0.207217,-0.311154,-0.536700,-0.512644,-0.019446,-0.515227,-1.121500,-1.113923,0.469280,-0.378167,0.651982,0.342854,0.469517,0.330861,0.001752,0.620430,0.736701,-0.020536,-0.496840,-0.186843,0.312820,-0.886721,1.159263,-0.140943,0.342944,-0.462558,0.174126,-0.652641,-0.027689,0.854433,-0.109235,-1.044671,0.084614,-0.407643,-0.330045,0.761578,-0.217796,1.027120,-1.192520,0.040931,0.201006,-0.138609,0.722960,-0.178705,0.950489,-0.101363,-0.771842,-1.645451,-0.661023,-0.258455,-0.029634,-0.334931,0.339841,0.523258,0.003324,-1.218692,0.142833,0.390260,-0.530145,0.436876,-0.334353,-0.520322,0.926924,0.182858,-0.071505,-0.657650,0.802320,1.503360,0.681711,0.813631,-0.176854,-0.359717,0.268188,0.116363,-0.698551,-1.314219,-1.075346]'::vector, 'bab562f0ad31449594f2eec4441b3a7407bc0590b7ff09e38a8012268f25927c', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-async-blocking-http-clients';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`asyncio.gather()`는 여러 코루틴을 동시에 실행하지만, 이것이 실제 CPU 병렬 처리를 의미하지는 않습니다. `asyncio`는 단일 스레드에서 협력적으로 작업을 번갈아 실행할 뿐이라, CPU를 많이 쓰는 연산에는 도움이 되지 않습니다.

```python
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor

def compute_heavy_task(n):
    time.sleep(1)  # CPU 바운드 작업을 흉내낸다
    return n * n

async def main_gather(num_tasks):
    # compute_heavy_task는 async 함수가 아니므로 이렇게 그냥 호출하면
    # gather는 ''코루틴이 아닌 값''을 넘겨받아 TypeError를 던진다.
    # asyncio로 CPU 바운드 작업을 병렬화하려면 to_thread로 감싸야 한다.
    tasks = [asyncio.to_thread(compute_heavy_task, i) for i in range(num_tasks)]
    return await asyncio.gather(*tasks)

def synchronous_main(num_tasks):
    with ThreadPoolExecutor(max_workers=num_tasks) as executor:
        futures = [executor.submit(compute_heavy_task, i) for i in range(num_tasks)]
        return [future.result() for future in futures]
```
`asyncio.gather()`만으로는 동기 함수를 병렬로 돌릴 수 없습니다. `compute_heavy_task`처럼 블로킹되는 일반 함수를 넘기려면 `asyncio.to_thread`로 감싸 별도 스레드에서 실행해야 하며, 이는 결국 `ThreadPoolExecutor`를 내부적으로 쓰는 것과 원리가 같습니다. asyncio 자체의 이점은 I/O 대기가 많은 작업(네트워크 호출 등)을 적은 스레드로 많이 동시에 처리하는 데 있지, CPU 연산을 빠르게 만들어주는 것이 아닙니다.', '[0.134988,1.240025,-2.744328,-0.996793,1.288562,-1.274005,0.360209,-0.270695,-0.876245,0.262594,-0.637922,0.682205,1.471318,0.423779,0.092843,-0.632228,-0.149763,-0.614184,-0.012932,1.012567,-0.229715,-0.394445,0.316106,-0.714108,1.506085,1.093843,0.081097,0.069092,-0.749476,0.259924,-0.306407,0.090894,0.245290,-0.971731,-0.480638,-0.211797,0.654668,-0.626688,0.348241,-0.311444,-0.276373,-1.160747,0.814039,0.273927,0.660573,0.498320,0.772543,-0.170673,0.279421,-1.606614,0.299739,0.663662,-0.437094,-0.076411,2.003801,0.503886,0.694553,0.186062,0.767098,-0.247055,1.179994,1.327612,-0.251842,0.899442,1.014077,0.013880,0.795305,1.368065,-0.313887,0.776310,0.889217,-0.355798,0.366718,-0.274290,-0.306028,0.443009,-0.230148,-1.283020,-0.030348,1.548759,-0.732168,-0.118791,0.765412,0.084204,0.241858,-0.552842,-0.603323,0.259580,-0.034667,1.175664,0.329096,-0.185919,0.601573,-0.552516,-0.953506,0.743666,-0.233692,1.311498,-1.102130,-0.233839,-0.077229,0.058445,0.109410,-1.331897,0.029185,0.868481,-0.073446,0.162668,-0.758550,-0.731712,-0.173434,0.586372,-1.544194,0.083441,-0.242637,-0.688558,0.451745,0.425062,0.284276,-0.077299,0.204398,-1.152660,-0.886774,1.290702,0.666753,1.053085,-0.328036,0.688283,1.440489,-0.950847,1.212448,-0.838248,-1.079019,0.570347,0.504161,0.203340,-1.747421,0.346891,0.611886,0.142195,0.763387,-0.285421,-0.515197,-0.440747,-0.532570,-0.004939,0.245771,-0.497227,-0.722324,-0.248955,-0.406085,0.780957,0.170462,-0.351308,0.654791,-0.511815,-0.241345,-0.991819,0.344536,0.030254,1.352273,0.271255,-1.066834,0.591674,-0.706214,-0.251047,0.552484,1.078880,0.323857,0.694597,-1.403599,-1.126715,-0.426809,-0.372891,0.512832,0.728376,0.535781,-0.795600,1.007124,-0.418622,-0.274791,-1.213836,1.312131,0.330913,-1.329815,-0.047136,0.168813,-0.106205,-1.156579,-0.039113,-0.000761,0.539794,-0.073183,0.283959,-0.827496,-0.340498,0.519849,-1.288703,0.246786,-1.370793,-0.158345,-0.825639,-0.158603,0.158129,-1.046666,0.846953,0.271102,0.393625,-0.256566,0.388246,1.582697,0.283145,-0.180847,0.181235,-0.269466,-0.161711,-0.841114,-0.153005,-0.161256,-0.074518,0.408851,-1.188766,-0.116510,0.890326,0.215771,-0.575197,-0.580764,0.131964,-0.299063,0.359929,-0.224220,-1.520323,0.533662,0.078576,0.296582,0.553241,0.211356,2.299748,-0.262651,-0.513700,-0.409602,0.314316,0.133713,-0.966488,-1.520568,0.148488,-0.148203,0.067361,-0.332412,1.061402,0.019157,0.206732,-0.487676,0.973618,0.388371,-1.243294,0.432094,0.215757,-0.161002,-0.062415,0.419087,-0.619331,0.546637,-0.799453,0.082920,-0.174415,0.153517,-0.932515,-0.063656,-0.091431,-1.146196,-0.162551,0.682958,1.045979,0.064327,0.112333,0.610764,0.884614,0.223698,0.425093,-0.693855,-0.599735,-0.497707,0.354732,-0.115904,0.138566,-0.006871,0.125705,1.049298,-0.442549,0.690345,-0.043049,-0.735651,0.900758,0.396855,1.372509,1.153877,0.213472,-0.373748,-0.867587,0.256141,0.503759,1.092341,0.326319,0.650376,-0.244431,-0.628425,-0.449811,-0.354841,-1.128913,-0.236099,-0.500854,-0.281054,0.625880,-0.748971,1.097452,0.873297,0.637862,-0.120691,-0.525746,0.290233,-0.175520,0.152118,-1.079651,-0.309468,0.744638,0.130923,0.466138,-0.073864,0.492041,0.592744,0.052985,1.127333,-0.619853,-0.819440,-0.246124,0.114811,0.140978,-0.002765,0.523483,0.553432,-0.780594,0.367516,-0.403176,-0.588850,0.350754,-0.177195,-0.316312,0.416149,1.204673,-0.870004,0.535948,-0.943913,-0.373171,0.445659,-0.213020,-0.094385,0.354235,-0.860969,-0.338480,0.640107,-0.126494,0.689419,0.718916,-0.078364,-0.099157,0.444297,0.756813,0.428663,-0.196356,0.114298,-0.851079,0.192237,0.385069,-0.502858,-0.257579,-0.478744,0.025366,0.061829,0.606677,0.949649,-0.453968,-0.745765,-0.228635,0.535450,-0.015909,-0.183178,0.250906,-0.516824,0.592006,0.177168,-0.809618,0.091751,-0.181075,0.922373,-0.549746,0.686266,-0.226084,-1.110204,0.133683,-0.174158,0.029158,0.263464,-0.240720,0.022627,0.593082,-0.326287,-0.274869,0.780178,-0.022649,-0.094411,0.597408,0.441565,-1.576170,-0.357247,-0.191697,1.760110,0.634384,-0.232062,0.170034,-0.432253,0.502026,0.533864,-0.030124,-0.278215,0.761263,-0.187558,0.448414,-0.259333,-1.190979,0.339075,0.475040,1.240422,0.267220,-0.840189,0.251710,1.133086,1.039077,-0.606724,0.961418,0.654833,-0.172126,-0.521415,0.077277,0.664568,0.668191,0.881635,-1.516531,-0.444231,-0.013569,-0.279176,0.967574,0.347601,-0.399421,0.616194,-0.784462,0.336945,0.213158,-0.404259,0.693450,0.211715,-0.337163,-0.611454,-0.639611,-0.281022,0.185297,0.722528,-0.314663,0.296390,0.663386,-0.877774,-0.240078,0.137153,-1.218575,0.639798,-0.017660,-0.018801,-0.188386,0.783967,1.295967,-0.040199,-0.497197,-1.364912,-0.194548,-0.747500,1.271687,0.260914,-0.411391,0.046291,-0.039859,0.353317,0.125363,-0.132121,0.255710,0.331947,0.233686,-0.055992,1.321592,0.760750,0.068156,0.549381,0.790837,-1.117144,-0.504929,0.419756,0.716613,0.405337,0.001351,-0.442535,0.013687,0.316776,0.281407,0.423298,0.242748,1.565894,-0.852022,1.145358,-0.557218,-1.065472,0.090891,0.780449,-0.639845,0.239683,-1.337949,-1.278149,0.362348,-0.526827,-0.534230,1.031887,-0.412140,-0.198798,-1.017229,-0.041650,-0.300359,0.251597,-0.667031,0.297331,0.826206,0.406045,-0.055988,0.069894,0.214443,-0.602950,0.547783,-0.175183,-0.559463,0.113940,-0.302643,0.734520,-1.338561,0.719052,0.404627,0.201077,-0.654982,0.748194,-0.670001,0.115048,-0.936388,0.328241,-0.746128,-0.188645,-0.131356,0.786791,-0.506215,0.600821,-1.421922,-0.916429,0.411678,0.366587,2.256011,0.587182,-1.437779,0.567192,-0.774757,0.085920,-0.165037,0.351409,-0.305797,-0.460911,-1.743179,0.032335,-0.940153,0.111336,0.813369,-0.454790,0.813276,0.155586,-0.146671,0.065031,-0.580240,-0.832906,0.455382,0.574242,-0.497158,-0.153630,1.042331,-0.660558,-1.458626,-0.916442,-0.337284,-0.482119,0.651817,0.601994,-0.654753,-0.646612,2.004643,-0.685204,0.277206,-1.147693,-0.248073,0.203678,0.167902,-0.170102,0.357474,0.516111,-0.861505,0.873528,-0.021495,0.510522,-0.708321,-0.044106,-0.745067,0.840103,-0.560711,0.929988,0.104654,-0.771990,-0.365831,1.315482,1.487350,-0.611322,1.133699,-2.078206,-0.001641,-0.571012,0.758060,-0.875081,0.312170,0.614022,0.692086,1.254521,-0.215966,-0.378248,0.554436,-0.051554,-1.227878,0.996044,1.564132,0.466556,-0.607272,0.747837,0.993221,0.068484,0.406241,0.591900,-0.298786,0.915203,-1.393911,-1.034640,-1.087111,-0.092257,-0.821153,-1.176415,0.702341,0.680835,-0.127910,0.257559,-0.009648,-0.888340,-1.881967,0.031420,0.480316,-0.731358,-1.463433,0.170010,-0.273994,-0.062371,-0.020852,-0.599993,-0.681856,0.089207,-0.485640,0.453820,0.247432,1.088505,-0.733768,-0.104378,-0.185547,-0.582030,-1.099562,-0.786993,0.317650,-0.254593,-0.670464,-0.771707,0.898685,-0.386581,-1.107581,-0.142740,0.967163,-0.411034,0.970826,0.250888,0.020847,-0.336809,0.275284,-0.082845,0.054401,-0.058114,0.078265,-0.752622,0.720488,-0.507579,0.315410,-0.015896,0.370058,-0.731142,-0.565311,-0.271579,0.862545,0.593546,-0.520759,-1.317842,0.064465,-0.159972,-0.173725,0.419306,0.068039,0.644237,-1.014935,0.635957,-0.063726,-0.874948,0.044766,0.440631,0.846536,0.106169,-0.584690,-1.403104,-0.604960,-0.745792,-0.385909,0.217379,-0.174019,-0.210498,-0.139584,-0.857667,0.257536,0.547638,-0.371215,0.194640,-0.361306,-0.386252,0.732265,0.837147,0.202218,0.446075,0.737952,1.772781,0.625815,0.143870,-0.357553,-0.444926,0.427339,-0.229840,0.117867,-0.966056,-1.123850]'::vector, 'cc374355e62e200a743e9f3e8a6cded351198c7c15f413603a9984f521f9e0e8', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-asyncio-gather-vs-threadpool';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Celery 워커는 네트워크 오류나 일시적 장애로 작업이 실패하면 자동으로 재시도할 수 있습니다. 문제는 재시도 도중 작업이 ''부분적으로는 이미 성공''했을 수 있다는 점입니다 — 예를 들어 결제 승인 요청은 실제로 처리됐는데, 그 직후 응답을 받기 전에 네트워크가 끊겨 태스크가 실패로 처리되고 재시도되는 경우입니다. 같은 작업을 몇 번 실행해도 결과가 달라지지 않는 성질을 멱등성(idempotency)이라 하며, 재시도 가능한 태스크라면 반드시 이를 보장해야 합니다.

```python
from celery import shared_task

@shared_task(bind=True, max_retries=3, default_retry_delay=10)
def charge_order(self, order_id, idempotency_key):
    order = Order.objects.get(id=order_id)

    # 이미 이 idempotency_key로 처리된 결제가 있는지 먼저 확인한다
    if Payment.objects.filter(idempotency_key=idempotency_key).exists():
        return  # 이미 처리됐으므로 다시 결제하지 않는다

    try:
        result = payment_gateway.charge(order.total, idempotency_key=idempotency_key)
        Payment.objects.create(order=order, idempotency_key=idempotency_key, status=result.status)
    except PaymentGatewayTimeout as exc:
        raise self.retry(exc=exc)
```
`idempotency_key`를 결제 게이트웨이와 우리 쪽 `Payment` 레코드 양쪽에서 같이 사용하는 것이 핵심입니다. 태스크가 재시도되어 `charge_order`가 다시 실행돼도, 이미 같은 키로 결제가 기록돼 있으면 함수 맨 앞의 조회에서 걸려 중복 결제를 막습니다. `self.retry(exc=exc)`는 태스크를 즉시 실패시키는 대신 `default_retry_delay` 뒤에 다시 큐에 넣습니다.', '[-0.191837,1.278772,-3.384470,-0.608811,1.052532,-1.649346,-0.240812,0.162300,-0.725711,0.547679,-1.112017,0.406891,1.199547,-0.023045,0.221341,-0.024378,0.360592,-0.024012,-0.880275,1.168792,0.018926,-0.386506,-0.491771,-1.201654,1.151806,0.140499,0.439584,0.648931,-1.095012,0.015901,-0.171656,0.001058,0.581920,-1.377827,-0.984717,-0.601418,0.940915,-0.203912,0.453096,0.102175,0.089684,-0.376971,1.304065,-0.768746,0.923011,0.478429,1.652282,0.491046,1.234598,-1.341104,-0.121015,-0.110097,0.145974,-0.404807,1.602701,0.953648,0.156667,0.853790,-0.535440,0.337052,0.576431,1.276691,-0.613961,1.010333,0.655142,-0.799604,-0.758888,0.821234,0.039702,-0.419764,0.473914,-0.403889,0.557967,-0.858170,0.330749,-0.478452,-1.063978,-0.640287,0.860612,0.841974,-0.583806,0.452222,0.544263,-0.200379,0.278280,-0.927013,0.186531,-0.491609,-0.206601,1.373446,-0.187661,-0.436565,-0.262408,0.133808,-0.883357,0.585046,-0.170691,0.295889,-0.306610,-0.131215,0.030134,-0.525699,-0.094260,-0.279839,-0.064663,1.394935,0.307393,0.204584,-0.121223,0.696082,-0.807734,0.217735,-0.219797,-0.095756,0.887378,0.074533,0.877867,-0.529043,-0.127784,0.071622,0.169142,-0.395959,0.236887,0.988466,0.266501,1.131312,-1.063014,0.353269,0.757515,-0.783508,0.455022,-0.193265,-0.579332,0.219153,-0.029148,-0.465508,-0.546802,-0.313010,0.122938,0.015158,0.080416,0.257003,-0.526266,-0.038400,0.108459,-0.792923,0.341137,-0.325916,-1.089595,-0.560694,0.452084,0.460018,0.050061,0.784178,0.375515,-0.501778,0.392030,-0.136095,0.739543,0.365286,0.742666,0.324868,-0.082030,0.650306,-0.571446,-0.961254,0.960902,0.822571,-0.313076,0.481014,-0.899022,-1.129928,-0.740323,0.017512,0.162916,-0.138560,0.678143,-0.542218,1.419321,-0.565558,-0.034615,-0.878363,1.534940,0.750120,-0.960320,-0.098127,0.552877,0.062933,-0.618560,-0.780107,0.276612,0.756463,-1.148574,-0.017840,-0.573072,-0.725653,0.497645,-0.216596,0.295567,-1.218034,-0.039926,-0.465469,-0.587729,0.487457,-0.944036,1.196580,-0.310424,0.964641,0.078782,0.358896,1.205960,0.088156,-0.115500,0.455399,0.597988,-1.278538,0.630740,-1.048406,-0.441780,-0.600091,0.117577,-0.685246,0.660796,0.366131,0.045380,0.054685,0.247491,-0.101427,-0.153248,-0.292065,-0.453163,-1.410879,0.236315,-0.327717,0.383334,0.765019,-0.483374,0.775337,-0.018584,-0.160217,0.006729,-0.410119,0.603220,-0.403095,-1.124905,0.281850,1.234637,-0.972314,0.174501,0.627037,-0.336338,-0.364991,-0.098502,0.407387,0.546023,-0.674683,0.388585,0.024241,0.992221,0.258708,-0.435757,-1.362349,1.510439,-0.486297,-0.664803,-0.990483,-0.512756,0.203263,-0.228688,-0.014506,0.172110,0.229244,0.255363,0.549071,0.407425,-0.039918,-0.424263,0.304607,-0.558501,1.188353,0.284876,-1.251558,-0.682616,0.342261,-0.931934,0.344126,-0.490898,0.176486,0.223879,0.638989,0.403908,0.108320,-0.129074,0.966249,0.129926,0.496244,0.787113,0.245217,-0.330000,-0.577944,0.028712,0.649391,0.438659,0.525394,-0.155670,-0.085045,-0.286043,0.611008,0.839914,-0.494637,-0.536262,-0.282258,-1.559411,0.207390,-0.017741,0.436404,0.379931,0.901728,0.329499,-0.321024,0.181125,-0.639967,-0.332236,-0.095846,0.751234,0.709434,-0.614029,0.863454,0.160887,-0.479910,0.096701,0.486970,1.452662,-0.640534,-0.344571,0.243679,-0.143198,0.295491,0.278887,1.692244,1.073128,-0.554429,0.365050,-0.651677,-0.646167,-0.494736,-0.472233,0.005011,0.473178,0.453048,-0.627393,0.258455,-0.221156,0.023949,0.793172,0.254756,-0.113806,-0.195579,-0.590594,-0.001676,0.989968,0.120688,0.921137,-0.160965,-0.312947,0.920014,0.882608,0.141843,0.648838,-0.582145,-0.926323,0.098536,-0.266447,0.294157,0.298794,-0.583192,-1.400769,-0.304043,-0.681133,0.552687,0.018966,-0.625878,0.065275,0.071073,1.201035,-0.732804,0.171108,-0.171947,-0.230277,-0.284612,0.073415,-0.405036,-0.227487,0.295767,1.464557,-0.680184,1.132015,0.369313,-0.557457,0.014735,-0.520516,-1.079317,0.140628,-0.599295,-0.154539,-0.171482,0.002960,0.195746,0.130294,0.411566,-0.083271,0.512131,0.172200,-0.594275,-0.464911,-0.127928,1.766634,0.549639,-0.231711,-0.704942,0.517111,0.441023,0.620148,-0.350174,0.603405,0.580740,0.315412,0.844483,-0.238735,-2.130699,-0.296930,1.179882,0.622281,-0.455828,-0.496107,-0.134847,0.461014,0.547123,-0.813965,0.941725,0.272717,0.449338,-0.281438,-0.839631,0.085856,0.908790,0.870925,-1.698865,-0.234129,-0.268211,0.283022,0.426113,0.447120,0.223540,1.394321,-0.169135,0.485618,-0.658429,0.093976,0.165585,-0.165712,0.540065,-0.990037,-0.300845,0.556463,-0.263362,0.595978,-0.438037,0.880908,1.277342,-0.183379,0.293517,0.901408,-0.518945,0.396344,0.162595,-0.476741,0.774721,0.041938,0.919332,-0.395856,-1.684733,-1.374534,-0.422784,0.259377,1.107684,0.847801,-0.161399,-0.120505,-0.291338,0.745604,0.553399,0.145631,-0.263236,0.057666,-0.113124,-0.273190,1.609706,0.219040,0.049919,-0.197687,0.877550,-0.545193,0.036850,0.367231,-0.161821,0.315078,-0.241833,-0.550988,-0.538843,-0.391251,0.919867,0.817797,0.216204,0.538429,-0.660526,0.238745,-1.002816,-0.634822,-0.412218,1.180369,-0.926349,0.498601,-0.645249,-1.000599,0.124820,0.359044,-0.802700,0.914131,-0.238111,-0.578784,-0.184912,-0.615556,-0.945586,-0.459240,-0.992230,0.129873,0.692921,0.307572,0.080283,0.167606,-0.093729,-0.492706,0.315059,0.103348,-1.042537,-0.115341,-0.448692,-0.551737,-1.231584,0.781663,-0.325687,0.175170,-0.697470,0.870930,-1.288969,0.255613,-0.261465,-0.824372,-0.863623,1.114837,0.706809,1.052684,0.903366,0.628768,-1.136000,-0.104386,-0.471780,0.139787,0.721034,-0.013126,-1.218061,1.025835,-0.513445,0.220805,0.854056,-0.161057,-0.223161,-0.998580,-1.180231,-0.009961,-0.268456,0.476257,2.062249,-0.299503,0.410099,0.177037,-0.867838,0.426899,-0.571886,0.176352,0.733416,0.505400,-0.880480,0.239504,1.196320,-0.174743,-0.593830,0.091933,-0.341493,-0.314266,0.300920,0.242128,-0.827575,-0.348528,1.052043,-0.082819,0.924210,-0.270456,-0.806560,0.284896,-0.033822,-0.001202,-0.472022,0.476667,-0.328669,0.599553,0.074495,0.147516,-0.586894,-0.540525,0.218578,0.098680,-0.353303,1.177781,0.872857,-1.052110,-0.490043,0.627414,0.767520,-0.438622,0.008753,-1.596844,-0.952453,-0.536239,0.944167,-0.161827,0.574482,0.296139,1.219012,1.034397,0.370524,0.414462,0.373268,0.643307,-1.256816,1.263974,1.037363,0.894288,-1.000600,0.958052,0.718952,0.929269,0.366044,0.843862,-0.424858,0.308040,-0.716916,-1.735986,-0.571347,-0.025004,0.202339,-1.460726,0.144578,-0.140724,-0.438657,-0.225259,-0.429534,-0.895473,-1.596185,0.243240,0.753473,-0.348268,-0.471015,0.015426,0.453189,0.972468,0.757796,-0.720100,-0.568525,0.336750,0.523700,0.936955,0.332170,-0.061587,-1.079165,-0.008087,-0.253179,1.175210,-1.238920,-1.220371,-0.508682,-0.484081,0.041204,-0.435750,0.674822,-0.179730,-0.447996,-1.094169,1.346302,-0.137663,0.845420,0.026661,0.150343,-1.360640,-0.426783,-0.369570,0.717520,-0.585348,0.380764,-0.328350,0.293227,-0.533451,1.167793,0.497539,0.534708,-1.475779,-0.414852,-0.419570,1.136099,0.745566,-0.503485,-0.662228,0.044892,-0.520498,-0.666677,-0.157850,-1.169507,0.431409,-0.002457,0.135687,0.093577,-0.688816,1.112622,-0.341681,0.825033,-0.523563,-1.365612,-0.690250,-0.113775,-1.219070,0.259747,-0.162689,-0.001640,0.376685,-0.848833,-1.166893,0.244751,0.634355,-0.188847,0.411797,-1.067735,-1.208630,0.339793,0.095767,-0.074595,-0.191658,1.100255,0.807199,0.909944,0.741958,-0.452062,0.049670,0.329637,-0.190387,-0.655501,-1.100284,-1.299630]'::vector, 'a04ada202193f466256c9f714650ac890808b779dc22d3db26b97d825fae8bda', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-celery-task-retry-idempotency';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '미들웨어는 모든 요청이 뷰에 도달하기 전, 그리고 모든 응답이 클라이언트로 나가기 전에 공통으로 거치는 지점입니다. 인증 확인, 로깅, 요청 헤더 검사처럼 여러 뷰에 반복되는 로직을 한 곳에 모을 때 씁니다.

```python
from django.shortcuts import redirect
from django.utils.deprecation import MiddlewareMixin

class RequireLoginMiddleware(MiddlewareMixin):
    EXEMPT_PATHS = {''/login/'', ''/signup/''}

    def process_request(self, request):
        if request.path in self.EXEMPT_PATHS:
            return None
        if not request.user.is_authenticated:  # 메서드가 아니라 프로퍼티다
            return redirect(''/login/'')
        return None
```
`request.user.is_authenticated`는 함수가 아니라 불리언 값을 담은 프로퍼티라서, `is_authenticated()`처럼 괄호를 붙여 호출하면 `TypeError: ''bool'' object is not callable`이 납니다. `process_request`가 `None`을 반환하면 Django는 요청 처리를 계속 다음 미들웨어와 뷰로 넘기고, `HttpResponse`(여기서는 `redirect`)를 반환하면 그 지점에서 요청 처리를 멈추고 바로 응답합니다. `EXEMPT_PATHS`처럼 로그인 페이지 자체는 검사에서 빼지 않으면 로그인 화면으로도 못 들어가는 무한 리다이렉트에 빠지기 쉽습니다.', '[-1.486389,0.859750,-2.780817,-0.893156,1.529065,-0.739913,0.430656,0.854439,0.374777,-1.038110,-1.469157,0.964421,0.978672,-0.239975,0.123224,-0.454949,-0.582880,-0.714170,-0.158397,0.404684,0.152990,-0.696055,-0.215549,-1.449071,2.206039,-0.421444,0.236943,0.411566,-1.485723,0.337396,-0.228794,-0.550925,0.623528,-0.391136,-0.984498,-0.349836,0.044098,-0.126068,0.066823,0.368758,-0.284048,-0.077639,0.107972,-0.466646,0.343745,-0.079855,0.937325,-0.506966,0.895911,-0.511928,1.063734,-0.648827,-0.107063,-0.149663,1.193264,0.687553,0.328432,0.170377,-0.521648,-0.656900,0.540278,1.230003,-0.454386,1.206102,0.413059,0.182650,-0.249367,0.712056,-0.199031,0.214847,0.806789,0.217022,-0.755964,-0.421770,0.256518,0.122412,-0.597777,-1.433021,0.259514,0.579704,-0.209847,0.354851,0.880403,-0.044627,0.474688,0.116708,-0.772959,0.044287,-0.064614,0.997879,0.091943,-1.135131,0.065928,-0.115785,-0.998137,0.640892,-0.570284,0.708133,-0.502537,-0.589649,-0.167885,-0.416119,-0.002594,-0.723836,0.242568,1.184916,-0.036788,0.429892,0.166681,-0.420346,-0.411757,1.352476,-0.882878,-0.101591,0.874840,-0.780408,0.930591,0.216000,0.835718,0.801923,0.203831,-0.703861,-0.545309,1.130633,0.963921,1.101293,-1.691201,0.207713,0.790465,-0.530829,0.297553,-0.507894,-0.942814,-0.059417,-0.357462,-0.097806,-0.164069,-0.285494,-0.075030,-0.173317,1.071039,1.003845,-0.153106,-0.475770,0.425438,-1.066153,1.289753,-0.332619,0.086513,0.296851,-0.199121,0.839513,0.061187,0.293702,0.134850,-0.640102,0.384556,-0.606901,0.203184,0.115617,0.729766,0.106786,0.614945,1.167624,0.026445,-1.147613,0.930659,0.697821,-0.555739,0.714837,-0.828783,-0.496979,-0.673424,0.440967,-0.258607,0.366115,-0.636706,-0.802816,0.676171,-0.631333,0.266097,-1.162655,1.889394,0.796191,-0.598150,-0.060177,0.245135,-0.278773,-0.056819,-1.628609,0.027769,0.464467,-1.080943,-1.070658,-0.698251,-0.677062,-0.139609,0.242849,1.207742,-1.207255,-0.070183,-0.714891,-0.776834,0.200599,-1.102489,1.135978,0.138525,0.660686,-0.782414,-0.094334,1.988139,0.436949,-0.131526,-0.149997,-0.112363,-0.963423,-0.364554,-0.716963,-0.505359,-0.439306,0.468540,-0.427051,0.426457,-0.055594,0.981904,0.493716,-1.200283,0.213782,-0.538211,-0.176763,-0.148959,-1.867613,0.533986,-0.212949,1.019852,0.393101,0.462585,0.995815,0.291537,-0.643260,-0.205462,-0.067273,0.357212,-0.039151,-0.779684,-0.053782,-0.298352,-0.393759,0.398638,1.476384,-0.074522,-0.022753,-0.322090,-0.115007,-0.319117,0.109625,0.523649,-0.259990,0.640733,0.000988,-0.038808,-1.451598,0.305850,-0.442397,0.074876,-0.201919,-0.252743,0.131090,0.479154,-0.191140,0.188818,0.336497,0.622559,1.091761,0.505208,0.034323,0.665692,0.161553,-0.475312,1.798138,-0.513006,-1.015320,-0.687993,0.027861,0.275715,0.526825,-0.495675,0.749147,-0.325009,0.365315,0.669951,-0.598659,-0.748751,1.617096,-0.236791,-0.069107,0.031768,-0.063849,0.095664,-0.459270,0.400423,1.118431,0.752964,0.953457,0.598172,-1.019582,0.698073,0.096552,0.405555,-0.112569,-1.725325,0.823545,-0.355127,0.792632,0.369415,0.876417,-0.409332,0.794371,0.957446,-0.551384,-0.696745,-0.916466,-0.413062,-0.154074,0.078282,0.239354,-0.351237,0.682501,-0.592841,-0.119033,0.381608,0.994744,0.280201,-1.033296,-0.296201,0.043871,-0.002958,-0.237402,0.295511,0.864036,0.722747,-0.926253,-0.012341,-1.045470,-0.377851,-0.106998,-0.727678,0.093450,0.767888,0.865532,-1.088657,0.882082,-0.424933,0.414708,-0.137490,-0.326182,-0.050102,1.131120,0.167188,0.331863,0.777342,-0.414666,0.137117,-0.332352,0.639344,1.126728,0.298853,-0.194307,1.050880,-0.126701,-0.312170,-0.315930,-0.306935,0.043247,-0.392637,0.203599,-0.769056,0.238014,-1.169234,1.260033,0.211646,-0.674493,-0.242769,0.741032,0.796720,-0.583049,-0.552712,-0.260157,-0.171095,0.797456,-0.825608,0.520533,-0.946489,0.710017,1.110128,-0.289873,0.330016,-0.021006,0.254563,0.706951,-0.487055,-0.896121,0.185395,0.299059,-0.628776,0.469717,-0.122668,-0.119051,1.315750,-0.047520,-0.246641,-0.579607,-0.469018,-0.658699,-0.255264,0.226227,1.162994,0.403821,-1.448926,-0.525542,0.967450,0.060864,-0.233508,0.485005,0.442681,0.205255,0.655013,0.293049,-0.149691,-1.450881,0.050703,1.561277,0.381014,-0.120863,-0.807975,0.177009,-0.023612,1.304208,-0.321533,0.792710,0.448052,-0.368604,-0.222494,-0.416547,0.520131,0.833683,1.212187,-1.364447,-0.304395,0.303541,0.147437,0.943590,-0.019709,0.263714,1.460926,-0.612678,-0.091610,-0.033789,-0.483052,0.675934,0.305113,0.206821,-0.409470,-0.267256,-0.828335,-0.318185,0.388534,-0.176618,0.711839,1.248724,-0.545030,0.462681,0.253264,-0.631311,0.546175,0.813337,-0.060740,0.615625,0.142007,1.169536,-0.597285,-0.851224,-1.201163,-0.587687,0.195247,0.764716,0.568869,0.093696,0.134796,0.343669,0.748594,0.131325,-0.462585,-0.229748,0.222405,-0.543892,-1.070912,1.032279,0.096424,-0.303431,-0.058365,-0.173520,-0.498477,0.388734,0.255308,-0.341751,1.270680,-0.550058,-1.093835,-0.838074,-0.428166,-0.420137,0.311471,0.024349,0.825083,-0.052135,0.357517,-0.560210,-1.315719,0.522134,0.582076,-0.670873,0.597113,-1.044791,-0.885923,0.020149,0.487631,-0.719473,0.503338,-0.247538,0.006732,0.532779,-0.398042,0.350068,0.189102,-1.319684,0.369662,0.782582,-0.136884,0.596706,0.565990,0.246809,-0.118577,-0.035505,-0.418812,0.166545,-0.267830,0.133266,-0.381315,-1.017616,0.269806,-0.667065,-0.604336,-0.779696,0.183382,-1.422595,-0.119552,0.081724,-0.210105,-0.379313,0.379406,-0.637200,0.058778,0.569184,0.517752,-1.171184,-0.238113,-0.001930,-0.138281,1.186814,-0.969642,-1.051966,-0.029413,-0.259899,-0.309704,0.425402,0.224985,-0.306629,-0.976089,-0.904954,-0.067680,-0.221971,0.678119,1.002538,-0.177513,0.680686,-0.036725,-0.942794,0.052862,-0.326584,-0.425779,0.816779,0.043669,-0.204141,-0.196558,0.849322,-0.571992,-0.882293,0.297266,-0.416001,0.112463,-0.391714,-0.285379,-0.057884,-0.309731,0.994458,-0.409143,1.128376,-0.962611,-1.016597,0.427091,0.396695,-0.230002,-0.399239,0.013903,-1.093175,0.022019,0.587319,-0.312274,-0.378804,-0.629346,-1.422777,1.303726,-0.054845,0.524746,0.733049,-1.169001,-0.520256,0.232319,1.035275,-0.770269,0.665744,-2.003109,-0.810315,-0.782142,1.163061,-0.892037,-0.005178,0.502886,1.330534,1.477838,-0.392761,-0.376086,0.338354,0.923656,-1.032766,1.064802,1.645340,0.958867,-0.343978,1.340114,1.250824,0.417215,0.335780,0.795131,-0.010002,0.377943,0.410432,-1.535341,-0.890120,0.335735,-0.165605,-1.198225,-0.382374,0.446735,-0.086511,-0.348115,-0.181994,-1.421143,-0.520184,0.285423,0.428774,1.022866,-0.008881,-0.107481,-0.157789,1.373862,1.271214,-0.394468,-0.605020,-0.563030,-0.136458,0.665618,-0.436612,0.207018,-0.985378,0.594168,-0.938512,0.185259,-0.935394,-0.688085,0.130319,0.106803,-0.489807,-0.255406,0.498909,-0.221105,-0.545104,-0.472208,1.331705,-0.278930,0.944546,-0.724775,0.618214,-0.433540,0.160068,-0.021424,0.772765,-0.417942,-0.372041,0.120289,0.688277,-0.947937,1.533246,-0.380057,0.798035,-1.084318,0.042148,-0.472150,0.489732,1.298678,-0.006343,-0.610174,-0.183648,-0.277731,-0.912586,-0.236913,0.017648,-0.066445,-0.536845,1.091265,0.316391,-0.621868,1.102162,-0.252198,0.136742,-0.711973,-0.168238,-0.877594,-0.506199,-0.785698,0.741503,-0.157249,0.503578,0.389600,-0.284777,-1.022912,0.758554,-0.218049,-0.474880,0.335721,-0.053881,-0.298109,0.470497,-0.343910,-0.041242,-0.031251,0.982707,1.558004,0.722771,0.351742,0.040489,0.106188,-0.095653,-1.020316,-0.986623,-0.772381,-0.252636]'::vector, 'b61a07601b764d46c87d574e0fcb0a6dee06c34026637c79df767a1d092867b7', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-middleware-auth-check';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '두 메서드 모두 N+1 쿼리 문제를 줄이기 위한 것이지만, 적용 대상이 다릅니다. `select_related()`는 `ForeignKey`·`OneToOneField`처럼 ''하나''를 참조하는 관계에 `JOIN`을 걸어 한 번의 쿼리로 가져옵니다. `prefetch_related()`는 `ManyToManyField`나 역방향 `ForeignKey`처럼 ''여러 개''를 참조하는 관계에 쓰며, 관련 객체를 별도 쿼리로 가져온 뒤 파이썬에서 묶어줍니다.

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)

class Book(models.Model):
    title = models.CharField(max_length=100)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
    tags = models.ManyToManyField(''Tag'')

# author는 ForeignKey이므로 select_related로 JOIN 한 번에 가져온다
books = Book.objects.select_related(''author'').all()
for book in books:
    print(book.author.name)  # 추가 쿼리 없음

# tags는 ManyToManyField이므로 prefetch_related로 별도 쿼리 한 번에 가져온다
books = Book.objects.prefetch_related(''tags'').all()
for book in books:
    print([tag.name for tag in book.tags.all()])  # 추가 쿼리 없음
```
`select_related(''author'')`를 빼먹으면 `book.author.name`을 호출할 때마다 쿼리가 하나씩 나가는 전형적인 N+1이 됩니다. 반대로 `ForeignKey`에 `prefetch_related`를 쓰는 것도 동작은 하지만, `JOIN` 한 번으로 끝날 일을 굳이 별도 쿼리로 나눠 처리하는 셈이라 `select_related`보다 비효율적입니다.', '[-1.402909,1.568311,-2.677330,-1.321632,1.044510,-0.702450,0.261522,0.343258,-0.351076,-0.307113,-2.173841,0.275358,1.626326,-0.188177,-0.083205,-0.616126,-0.685169,-0.555757,0.189543,0.652562,0.252617,0.143591,0.107683,-0.664954,0.883439,0.733471,-0.036651,-0.201595,-0.906671,0.652365,-0.876418,-0.100044,-0.390687,-1.535916,-1.025965,-0.057508,0.211991,0.512615,0.010874,0.745054,0.496039,0.801821,0.360333,-1.301908,0.613218,-0.189686,0.929354,0.000100,1.210448,0.128751,0.088637,0.316232,0.113878,-0.589062,1.680006,1.489320,-0.410806,0.229118,0.728903,-0.566155,0.593924,0.922401,-1.403554,1.653266,0.162918,0.492544,-0.086749,0.837113,0.098585,-0.661790,-0.077056,0.600791,-0.602201,-0.143731,0.017518,0.202671,-0.156757,-0.974476,0.071594,0.773956,0.159582,0.699686,1.088840,0.466286,0.383061,0.082700,-1.022482,0.347760,-0.645523,0.417363,0.141346,0.053433,0.182294,-0.575439,-1.050042,1.588045,-0.763993,0.322275,-0.648699,-1.566740,0.438454,-0.478405,-0.125047,-0.247766,0.254581,0.837056,-0.365536,0.467669,-0.094860,-0.160096,-0.481024,0.993344,-0.679380,-0.078166,-0.074563,-0.626460,0.266045,0.124363,-0.245251,-0.017154,-0.071308,-0.994975,-0.518501,0.890397,0.142333,0.121436,-1.302133,0.487612,0.486977,-0.827451,-0.675301,-0.583638,0.022129,0.254010,-0.308165,0.587989,-1.122531,0.802123,-0.097779,-0.582510,0.047187,1.064742,-0.283476,-0.548859,-0.004062,-0.329835,0.686464,-0.038125,-1.118573,0.710514,0.066229,0.814960,-0.466146,0.104238,-0.036164,-0.141637,0.255833,-0.937153,-0.339102,-0.884274,0.920764,0.310259,0.384583,0.621317,-0.213149,-0.943257,1.495503,0.271361,-0.589028,1.086630,-0.943177,-1.080514,-0.124788,-0.138570,0.658671,-0.033593,0.068263,-0.448056,0.662925,-0.633223,0.454329,-2.060280,2.116738,0.204025,-0.754213,0.469008,-0.315664,0.203497,0.358549,-0.372198,0.082651,-0.518054,-0.612086,-0.588517,-0.563481,-0.565884,0.113186,-0.127974,0.331837,-1.134233,-1.029992,-0.413240,-0.795861,0.317754,-0.344449,0.951985,0.600076,0.564005,-0.089365,0.537860,0.414638,0.005181,0.021940,0.856310,0.487165,-1.036983,0.224892,-0.198343,-0.700016,-0.189379,0.390615,0.159272,0.869578,0.034640,0.724577,0.265670,-0.273065,0.475541,-1.138545,0.433627,-1.180882,-1.296058,0.916990,-0.187127,0.458864,-0.086316,0.183555,0.937208,-1.199091,-0.429174,-0.084232,0.346777,0.150039,-0.304596,-1.915178,-0.240857,0.345622,0.175325,0.400493,1.230099,-0.184885,0.127823,-0.669132,0.481017,0.243310,-0.127787,0.036948,0.370454,1.096886,-0.593634,0.052094,-0.877185,0.600066,-0.509855,-0.550951,-0.098371,-0.470586,-0.768206,-0.117506,-0.339598,-0.254807,-0.062520,0.590479,0.439233,0.509169,0.014252,0.431541,-0.485832,-0.026962,0.102932,-0.850689,-1.143360,-0.360507,-0.526053,-0.128078,0.592089,-0.542543,0.359671,0.068247,-0.063335,0.442055,0.096909,-0.074137,0.271735,0.764725,0.363764,0.457589,0.352905,0.826809,0.474701,0.453710,1.047629,1.370450,1.232721,0.008191,-0.494969,-0.476594,0.346631,0.495847,-0.481778,-1.344027,-1.102955,-0.067179,0.751224,-0.804374,0.283873,0.534151,1.184033,0.721357,-1.108097,0.144651,-0.392250,0.149396,-1.372208,0.504553,1.234823,-0.729100,0.729565,-0.126823,-0.431575,0.022677,0.933332,0.435947,-0.878808,-1.200414,0.503155,-0.330201,-0.258901,0.066713,1.291695,1.310268,-0.318540,0.601428,-0.409552,-0.828318,0.509931,-0.177875,-0.197998,0.899671,1.104258,-1.334689,0.785897,-0.941246,0.238712,0.271208,-0.202533,-0.276137,0.206639,-0.659244,-0.102411,1.454119,0.224533,0.186461,0.021577,-0.277970,0.524233,0.815016,0.194003,1.258742,-0.564944,-0.869158,-1.328902,-0.066653,0.143586,0.498823,-0.125566,-0.531589,-0.005016,-1.190096,0.860425,-0.259084,-0.228988,-0.721219,0.452675,0.748619,-0.689005,-0.168358,-0.283602,0.234805,0.919902,-1.209631,0.174577,-1.084686,0.402863,0.908319,-0.348764,0.367127,0.677140,-0.154919,0.943769,-0.456917,-1.001392,0.131497,-0.150080,-0.552287,-0.040672,-0.047289,0.301458,0.223507,0.048129,-0.141371,-0.665373,-0.446514,-0.593799,0.019399,0.575680,1.505196,0.655110,-0.703805,-1.087160,0.336064,0.474961,0.195761,0.324002,0.495036,0.149551,0.597294,0.229027,0.162394,-0.815103,-0.397361,0.953857,0.433366,-0.162655,-0.709096,0.149155,0.921009,1.079143,0.165815,0.718555,0.576714,-0.279728,-0.972101,-0.004083,0.455741,0.665176,0.812985,-0.728402,-0.723718,0.458131,-0.460442,0.438769,-0.019035,0.960116,1.304161,-0.143898,0.292568,-0.136791,0.433918,0.356653,0.118028,0.107249,-0.599690,-0.495433,-0.399943,-0.755571,0.576175,0.053637,0.411173,0.868852,-0.450671,0.435565,-0.055544,-1.029450,0.961141,0.832403,-0.227235,-0.082992,0.802023,0.031156,0.252863,-0.764345,-1.021660,-0.711661,0.440507,-0.414549,0.997652,0.149073,0.744412,0.291935,0.602201,0.199024,0.573634,0.135554,-0.359202,-0.577658,0.320199,1.346511,0.855631,-0.815962,0.256684,0.150097,-0.708982,0.152495,0.510169,-0.585534,0.823078,-0.323723,-0.306245,-0.389461,-0.134572,0.292269,0.239971,0.000920,0.339116,-0.876710,-0.057320,-0.921552,-1.239736,-0.145891,1.305855,-1.456447,0.109024,-0.840092,-0.881815,0.014132,0.360628,-1.834355,0.336377,-0.234545,-0.083278,0.648495,-0.394299,0.597281,0.579696,-1.203253,-0.405632,0.665217,0.218271,-0.143959,0.428600,0.192919,0.451476,-0.136758,-0.222413,-0.025542,0.462054,-0.105296,0.251345,-0.558802,0.116535,-0.267728,0.061919,-0.572889,0.333240,-0.884477,-0.419078,-0.179197,-0.456754,-0.296184,0.145670,0.257601,0.874288,0.070977,0.687621,-0.548778,-1.215598,-0.234664,-0.212548,0.658057,0.032158,-2.311297,0.019606,-0.478337,-0.052201,1.065906,0.582072,0.052566,0.050133,-1.089562,-0.135958,-1.185058,0.577709,0.183591,0.030717,0.456776,0.079920,-0.865527,-0.080419,-0.643793,-0.299991,0.830530,0.931477,-0.261848,0.559138,0.733248,-0.193083,-0.363773,-0.162207,-1.391325,0.494263,-0.094523,0.876824,-0.561957,-0.026502,0.786084,-1.244570,0.842902,-0.399425,-0.188350,0.173639,0.309979,-0.241898,-0.535263,0.864978,-1.428664,0.909572,0.450215,-0.499341,-0.359743,-0.863086,-0.718414,-0.306178,-0.339978,0.616409,0.946143,-1.251008,-0.207009,0.391655,0.750143,-0.758978,0.463249,-1.616789,-0.603012,-0.103245,1.012351,-0.832707,-0.067992,0.348216,1.539781,0.626345,-0.036399,-0.047557,0.842736,0.784108,-1.160677,0.379536,1.198135,0.772428,-0.756672,1.590408,1.502544,-0.345652,0.029579,0.761536,-0.166632,0.949820,-0.356764,-1.495533,-0.322570,-0.301649,-0.136907,-0.711948,0.103321,0.479821,0.337811,-0.168741,-0.080056,-0.788721,-0.205443,-0.529132,0.693439,0.661824,-0.180283,0.062973,0.109411,0.654303,0.240710,0.427606,-1.040160,-0.283386,0.059562,0.379910,-0.477008,0.052744,-0.891412,-0.220387,-0.905397,0.303989,-0.899528,-0.759236,-1.185185,0.303669,0.017796,-0.024370,0.611497,-0.088388,-0.534349,0.068946,2.072847,0.397429,0.902494,-0.164568,0.044535,-0.842679,0.097727,0.396212,0.272477,0.760280,-0.123914,-0.890600,0.495361,-0.194104,1.188691,-0.268607,0.444787,-0.944053,-0.016919,-0.780209,1.004847,0.424041,-0.276782,-0.436724,1.103167,-0.131844,-0.308991,-0.165220,-0.186282,-0.164529,-0.136927,-0.067342,-0.588692,-1.548927,1.608905,-0.108578,0.076848,-0.683521,-0.869252,-0.497567,-0.253622,-0.541786,0.800854,0.386321,0.339792,0.129554,-0.797597,-1.450578,0.594597,0.228547,0.479156,-0.227567,-0.566974,-0.142844,-0.029485,-0.035156,0.014566,0.039437,0.472453,1.792671,0.214074,0.519492,0.611827,0.375871,0.704800,0.282749,-0.196171,-0.354881,-0.151072]'::vector, '03d4e3f28e04dd9b24263a50c16e828ea522d949793e481c007f2c53a5dd57c9', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-select-related-vs-prefetch-related';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '개발·테스트·운영 환경마다 데이터베이스 주소나 `DEBUG` 값이 달라야 하는데, 이를 하나의 `settings.py`에 조건문으로 다 넣으면 파일이 금방 지저분해지고 실수로 운영 설정이 개발 환경에 섞이기 쉽습니다. 공통 설정을 `base.py`로 뽑고 환경별로 상속하는 구조가 일반적입니다.

```python
# settings/base.py
INSTALLED_APPS = [''django.contrib.admin'', ''django.contrib.auth'']
DEBUG = False

# settings/local.py
from .base import *
DEBUG = True
DATABASES = {''default'': {''ENGINE'': ''django.db.backends.sqlite3'', ''NAME'': ''db.sqlite3''}}

# settings/production.py
import os
from .base import *
DATABASES = {''default'': {
    ''ENGINE'': ''django.db.backends.postgresql'',
    ''HOST'': os.environ[''DB_HOST''],
    ''PASSWORD'': os.environ[''DB_PASSWORD''],
}}
```
실행 시점에는 환경 변수 `DJANGO_SETTINGS_MODULE`을 어떤 파일로 가리키느냐로 환경을 전환합니다. 예를 들어 `DJANGO_SETTINGS_MODULE=myproject.settings.production python manage.py runserver`처럼 실행하면 `production.py`가 로드됩니다. `production.py`가 비밀번호 같은 값을 코드에 직접 적지 않고 `os.environ[''DB_PASSWORD'']`로 읽어오는 것도 중요한 습관인데, 이렇게 하면 운영 자격 증명이 저장소에 커밋되는 사고를 막을 수 있습니다.', '[-0.776513,1.519145,-2.792206,-0.719373,0.936459,-0.573077,0.375296,0.137870,-0.495696,-1.056680,-0.511357,0.348372,0.677379,0.005684,-0.277434,-0.564737,0.168284,-0.525189,0.698574,0.388678,-0.053908,-1.626203,-0.475937,-1.101692,2.027865,0.606353,-0.195814,0.433179,-0.210753,0.011633,-0.616895,0.097009,0.126380,0.068441,-0.957823,-0.812456,-0.121440,0.237867,0.389129,0.347251,0.149058,0.032932,0.189077,-0.339233,-0.474183,-0.011337,0.185333,-0.107339,0.344848,-0.172441,0.843462,-0.037376,-0.420617,-1.120444,2.125045,0.972537,0.055012,0.223620,0.169683,-1.015340,1.248345,0.579572,-1.031283,1.754730,0.218981,-0.642691,-0.191535,0.418313,-0.043834,-0.493779,-0.050060,0.655779,-0.784008,-0.275565,0.083568,-0.483508,-0.507352,-0.659151,-0.459833,0.974434,0.134001,0.524371,1.334203,-0.444504,0.341230,-0.268498,-0.453911,0.076120,-0.959903,0.837095,-0.222080,-0.616579,-0.645153,-0.423456,-0.778639,1.038251,-0.317436,0.856103,-0.167271,-0.764389,-0.000098,0.128169,-0.327067,-0.575172,0.186573,1.580953,-0.308458,0.325738,-0.689707,0.111670,-0.097721,1.877556,0.224850,0.038003,0.459884,-0.281878,0.971071,0.030109,-0.003262,0.378096,-0.520732,-0.568119,-0.878718,0.176047,0.803745,0.522810,-2.025759,-0.164951,0.858443,-0.755717,0.294855,-0.628822,-1.321628,0.540562,0.647505,0.752372,0.199584,-0.389327,-0.223997,0.089147,0.037263,1.289707,-0.500674,-0.145606,-0.376935,-0.534419,1.092713,-0.239240,-0.294212,0.379221,-0.108649,0.357745,1.138337,-0.158852,0.122759,-0.552343,-0.513661,0.147448,0.762698,0.076007,1.418690,0.156957,0.375620,0.567725,-0.081401,-0.338478,0.671606,1.206677,-0.707392,0.663924,-0.827557,-0.527615,-0.461573,0.205129,0.147574,0.445462,-0.446836,-0.694958,1.316437,-0.364775,0.991154,-0.907110,1.295975,0.501662,-1.458906,0.243984,-0.163043,-1.165042,-0.359860,-0.786706,1.422375,0.509263,-0.986026,-1.425589,-0.951771,-1.629747,0.079350,0.334417,1.462869,-1.188317,-0.952784,-0.477556,-0.194197,0.175336,-0.668945,0.284676,0.120613,1.158704,-0.436180,0.428519,0.959512,0.069722,0.420786,0.878570,0.299251,-1.144092,0.036385,-0.954329,-0.639413,-0.126864,-0.085607,0.078645,1.093885,1.205553,1.424130,0.287379,-0.716630,0.542304,-0.225372,-0.065050,0.138831,-1.744207,0.144909,-0.474324,0.677214,0.921980,0.044737,0.576752,-0.210355,0.302339,-0.228698,-0.139876,0.304155,0.613070,-1.114908,0.162222,-0.380798,-0.487162,0.080613,0.917037,0.063586,-0.042457,-0.022781,-0.145487,-0.148407,-0.310393,-0.663974,-0.352458,0.957463,-0.343961,-0.558761,-1.302268,0.318898,-0.379090,-0.297966,-0.157519,-1.046339,-0.724837,-0.077951,-0.404355,0.963958,0.670629,0.367982,1.014844,0.633414,-0.089135,0.987440,-0.266100,-0.519205,0.463936,-0.453704,-1.342226,-0.666690,0.348088,0.537527,-0.321911,-0.670489,0.156651,-0.515789,0.462215,0.196731,-0.459906,-0.024261,0.683412,-0.499623,0.336801,0.337567,0.471627,0.571548,-0.350217,0.441443,0.849362,0.936241,1.151246,-0.078588,-0.660971,-0.092513,0.783455,-0.046589,-0.362161,-1.523098,-0.691343,0.031677,0.955510,-0.564986,0.735108,-0.124064,-0.125079,0.509844,-1.102794,0.174293,-1.302272,-0.246864,-0.225902,0.171486,0.124586,-0.329793,1.180916,-0.208323,-0.303941,0.708419,0.412036,0.541875,-0.862839,-0.470032,0.708294,0.594201,0.185375,-0.024150,0.870860,1.572088,-0.821370,0.416389,-0.378266,-1.071489,-0.374171,-0.286751,-0.309746,-0.113144,1.646268,-0.544134,0.750150,-0.390047,0.036000,-0.453935,-0.504222,0.160881,0.466022,-0.408388,0.610002,0.938276,0.538406,0.165952,-0.739670,0.009764,1.162043,0.387255,-0.183152,0.725919,-0.112482,-0.613757,0.098632,-0.070971,0.011424,0.071598,-0.745108,-0.097629,0.187994,-0.386134,1.228607,0.286112,-0.141675,-0.470182,1.056547,0.934639,-0.999838,0.434571,0.181613,-0.216091,0.814970,-0.907343,0.667245,-0.504439,1.081007,0.609595,0.175441,0.559858,0.867532,0.022858,0.400619,-1.221001,-0.698243,0.076817,-0.314352,-0.947884,-0.167745,0.002394,-0.226244,0.563138,0.315117,0.106440,-0.558280,-0.065980,-0.254866,-0.292964,1.014111,1.025473,0.935730,-0.700798,-0.260304,0.665501,1.092379,0.101180,-0.280873,0.274178,0.254210,0.277151,0.298479,0.488655,-1.367465,0.069029,0.674880,0.042813,0.506534,-0.565522,0.400587,0.680537,1.260902,0.324937,0.196588,0.934699,-0.356165,-0.759952,-0.630463,-0.483920,1.428220,1.667785,-1.352347,-0.150135,0.441105,-0.211837,0.562384,0.296439,0.090121,0.624755,-0.932869,0.248180,0.383454,-0.749460,0.504356,0.327627,-0.042321,-1.645104,0.205526,-0.276759,-0.481976,-0.385623,0.135699,0.433547,0.746079,-0.928818,-0.083336,0.317357,-0.616556,1.006361,0.503921,0.617741,0.353325,0.883230,0.609362,-0.110040,-0.503635,-1.049170,-0.165070,-0.047808,0.211301,0.533341,-0.496451,-0.167819,0.012645,0.716968,-0.274638,0.810794,-0.471779,-0.362949,-0.235290,-0.000116,0.806264,0.882883,-0.177010,-0.159473,0.516436,0.091196,0.444042,0.435476,0.173345,1.713415,-0.240534,-0.984483,-0.469160,0.700800,0.782328,0.354311,0.330549,0.629001,-0.589000,0.524782,-0.335936,-2.014227,-0.103081,1.015032,-0.664698,0.687741,-1.346441,-0.804005,0.498810,0.593698,-1.382093,0.381792,0.069984,0.386024,-0.339018,-0.549226,-0.283555,-0.017328,-0.896504,-0.649037,0.768908,0.323127,1.174398,0.144407,-0.363521,0.184240,0.182794,-0.221713,0.072013,-0.194299,0.958587,-0.858774,-0.562006,0.627375,-0.270884,-0.147699,-0.865428,-0.142604,-0.340073,-0.215271,0.741185,-0.380233,-0.612296,0.052047,0.211130,1.022980,0.883917,0.996652,-0.240781,-0.139087,0.128263,-0.149712,0.629115,-1.199841,-1.592547,0.099454,-0.465398,-0.237108,0.748277,0.191299,-0.130483,-0.111357,-0.526136,-0.282191,-0.849872,0.403496,1.042535,-0.492804,0.471547,0.009995,-0.424839,-0.124920,-0.681789,-0.000651,0.624940,0.247190,0.003577,0.100503,0.918649,0.139268,-0.600592,-0.177573,-1.552768,0.443149,-0.241090,0.987615,-0.736158,0.190815,0.402276,-0.356882,1.116028,-0.896275,-0.906728,0.573979,0.066212,0.130571,-0.473397,0.212016,-1.494859,0.411236,1.049358,0.409419,0.542176,-0.618110,-1.068474,0.653874,-0.542781,0.874663,0.118863,-0.373691,-0.236799,0.905028,0.565445,-0.366501,-0.406795,-2.317635,-0.989953,-0.863845,0.592613,-0.677838,0.519639,0.836342,0.373369,1.071413,-0.141666,-0.217762,0.530190,-0.133260,-0.679805,0.069561,0.739284,1.015248,-0.479212,1.549454,0.556981,-0.273957,0.493585,0.361187,0.389965,0.354455,-0.681713,-0.851208,-1.290166,0.535334,-0.162794,-0.490531,0.590498,0.818087,0.158548,-0.196860,0.093194,-0.930229,-0.894049,-0.489664,0.792157,0.265035,-0.144415,0.205336,0.618884,0.903069,0.238571,-0.011820,-0.355691,-0.301775,-0.356810,0.079937,-1.063187,-0.259488,-1.127636,0.291585,-1.054043,-0.104762,-0.980081,-0.965823,-0.270721,-0.148989,0.354020,-1.117632,0.488321,0.378935,-0.575730,-0.182152,0.723658,0.337545,-0.009182,-0.159735,0.557007,-0.984630,-0.135135,0.329005,0.968524,0.128946,0.160851,-0.713032,-0.614490,-0.217667,0.963114,-0.404546,1.255246,-0.930884,-0.701694,-0.931623,1.083646,0.241196,-0.766251,-0.408579,0.693912,0.482998,-1.249626,0.874095,-0.997318,0.409563,-0.932709,0.348116,-0.252764,-1.200709,1.105000,-0.556446,0.206257,-0.168954,-1.133566,-0.883367,-0.136945,-1.110302,0.234542,-0.231403,0.745178,0.412232,-0.279291,-0.902762,0.460593,0.526139,-1.261540,0.233013,-0.807334,-0.514907,0.198681,-0.253457,-0.802142,0.380196,0.178074,1.211619,0.194380,-0.193300,0.231934,0.252490,0.015267,-0.237617,-0.401965,-0.325472,-0.396283]'::vector, '81c1f70a48511b538be0356d440a20975fbfdfd0171f2aa93fa9982350834129', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-settings-separation';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`@transaction.atomic`을 함수에 데코레이터로 붙이면, 함수 전체가 하나의 데이터베이스 트랜잭션으로 실행됩니다. 함수 안에서 예외가 발생하면 그 함수 안에서 이미 실행된 변경 사항까지 전부 롤백됩니다.

```python
from django.db import transaction

@transaction.atomic
def create_order(user, products):
    order = Order.objects.create(customer=user)
    for product in products:
        if product.stock <= 0:
            raise ValueError(f''{product.name} 재고가 없습니다'')
        product.stock -= 1
        product.save()
        OrderItem.objects.create(order=order, product=product)
    return order
```
상품 목록 중간에 재고가 없는 상품이 있어 `ValueError`가 발생하면, 그 이전에 이미 실행된 `Order.objects.create`와 재고 차감, `OrderItem` 생성까지 전부 롤백됩니다. `@transaction.atomic`이 없었다면 주문은 생성됐는데 일부 상품의 재고만 차감된 반쪽짜리 상태가 데이터베이스에 남았을 것입니다. 여러 테이블에 걸친 쓰기 작업을 하나의 비즈니스 로직으로 묶을 때는 항상 이 경계를 명확히 그어야 합니다.', '[-1.170606,2.066572,-2.548736,-1.368903,1.951984,-0.913904,-0.363640,0.240281,-0.191109,-0.504307,-1.455331,1.392924,1.476533,-0.961056,-0.009153,-0.593623,-0.844049,-0.764236,0.151289,1.438211,0.798103,-0.581994,-0.906616,-1.727785,1.450330,-0.037476,-0.651120,-0.055015,-1.517797,0.156219,0.284877,0.107748,0.056397,-0.462785,-0.546143,-0.799730,0.864561,0.777388,0.463085,-0.176388,0.056107,-0.080375,0.690262,-0.693997,0.679490,-0.095179,1.152695,-0.320794,0.432182,0.217910,0.256114,-0.081690,-0.157787,0.349340,1.988024,1.748810,-0.145754,0.041895,-0.278829,0.024484,0.735799,0.836838,0.937826,1.162469,1.582791,-0.121105,-0.533722,1.251240,-0.287666,0.095987,0.499731,-0.020544,-0.798440,-0.788200,0.427905,0.056651,-0.475895,-0.564644,0.559408,0.867883,-0.227194,0.510262,1.247052,-0.143332,0.027574,-0.281484,-1.033540,-0.463597,0.135951,1.237685,0.417427,-0.252959,0.398625,-0.373919,-1.202982,0.197469,-0.441961,0.799717,-1.229264,-1.484950,-0.486513,-0.023953,0.507695,-0.185209,0.361700,0.769295,0.570206,0.598348,-0.439761,-0.101306,-0.029825,1.241685,-1.036381,0.022541,0.903680,-0.405057,0.623239,0.167442,-0.312116,0.294299,0.284786,-0.512385,-0.107100,0.416616,1.050478,-0.108411,-0.863261,0.754225,0.898991,-1.537167,-0.200150,-0.739685,-0.307967,-0.531188,-0.538210,0.115035,-0.333116,-0.031678,0.545519,-0.623223,0.251423,1.222046,-0.949196,-0.179107,-0.042387,-0.981340,0.929433,0.059597,-0.656089,-0.008563,0.195279,0.603808,-0.262732,0.585082,0.006659,-0.097097,1.068388,-0.692649,0.467017,-0.025416,1.503007,0.259359,-0.468171,0.554246,-0.444982,-0.747741,1.891873,0.482112,0.172894,0.750348,-0.990983,-0.917090,-0.665810,0.602245,0.635672,0.906620,-0.718228,-0.954612,1.580292,-0.542301,0.148996,-2.053785,2.010790,0.482522,-0.555755,-0.215035,-0.399999,-0.433466,-0.229611,-0.491050,0.924000,0.086355,-0.924707,0.019000,-0.977991,-0.942086,0.408153,-0.394313,0.559424,-0.869938,0.063424,-0.011305,-0.887743,-0.289178,-0.302191,0.879755,-0.215920,0.590017,-0.512421,0.715377,1.410432,0.037756,-0.081527,-0.004402,-0.054051,-0.680044,0.167080,-0.970765,-0.771760,0.090634,0.044842,-0.141281,0.253625,0.329585,0.651585,-0.251340,0.075909,0.494226,-0.720201,-0.380761,-0.867466,-0.726955,0.056663,-0.770625,0.854851,0.430653,-0.007029,0.952417,-0.050569,-0.201939,0.136787,0.033148,0.393411,-0.085234,-1.264289,-0.370551,0.181444,-0.010037,0.410355,0.806306,0.378715,-0.589205,-0.051576,-0.011320,0.530766,-0.493911,-0.405415,0.242383,0.617733,-0.377957,-0.200481,-0.484487,1.022166,-0.615607,-0.614501,-0.977001,-0.955483,-0.931032,0.501338,0.358792,0.008369,0.104537,-0.211091,0.140133,0.273305,-0.596486,0.808181,-0.234488,0.273134,1.503666,-0.413556,-0.820982,-1.421642,0.275049,-0.114115,0.804328,-0.404683,0.534553,-0.381379,-0.121426,0.401786,0.169099,-0.788251,0.372469,-0.048131,0.487876,1.116733,0.493670,-0.037970,0.050288,0.193633,0.419044,1.392322,1.227605,-0.525940,0.066928,0.475362,0.258906,0.097920,-0.460210,-0.657950,-0.403858,-1.204749,0.738007,-0.448285,0.985666,0.419919,0.977892,0.560901,-1.527218,-0.501816,-0.753554,0.236142,-0.816278,0.215842,0.391353,-0.850876,1.138865,0.550839,-0.708477,0.044806,0.624504,0.207057,-0.766893,-0.760776,-0.070876,-0.134232,-0.203109,0.066620,1.041847,0.969494,-0.398945,0.694583,-0.365320,-0.694775,-0.117162,-0.513446,-0.371948,0.671054,0.508478,-0.847344,0.482900,-0.246815,0.277306,-0.517183,-0.013312,0.688180,0.798854,0.454776,-0.134320,1.039015,-0.090598,0.498895,-0.436432,-0.076103,1.131529,-0.175761,0.155749,1.305281,0.005488,-1.144835,-0.385275,0.001417,-0.538192,0.150811,-0.240000,-0.426834,0.009233,-1.181166,0.592959,0.154934,0.046856,-0.167648,0.776220,0.514360,-0.449394,-1.004292,-0.947609,-0.073933,-0.215985,-0.496967,0.320386,-0.723711,0.403419,0.983738,-0.650510,0.425435,0.431853,-0.553862,0.889899,-0.973212,-1.450270,-0.696126,-1.209398,-1.097589,-0.465881,0.197579,0.019346,1.197080,-0.009675,-0.209125,0.038930,-0.314449,-0.821380,-0.925617,0.615606,1.205461,0.817399,-0.124415,-0.937939,0.575192,0.478587,1.506388,0.541136,0.658607,0.491355,0.675990,0.522842,0.272295,-0.953331,-0.767438,1.342298,0.872175,0.345965,-1.437806,0.207869,0.793046,0.875297,0.559221,0.843056,1.791808,0.093304,-0.510315,0.185509,0.602875,0.760596,1.075988,-1.491816,-0.555981,0.524738,-0.248144,0.800496,-0.006715,-0.157535,0.918291,-0.391356,0.233891,-0.524424,-0.506862,0.818977,-0.504436,0.399806,-1.316494,0.057820,-0.445128,-0.231270,0.852472,-0.046807,0.670245,1.286841,-0.685067,0.248789,0.673070,-1.111856,1.535489,0.480682,0.319868,-0.235223,0.121899,0.359925,-0.148948,-0.330505,-0.608628,-0.772818,0.157045,0.313159,0.572177,-0.134248,0.564453,-0.168862,0.408955,0.179973,0.233938,-0.580803,-0.928506,-0.783030,-0.580224,0.724997,0.546866,-0.453684,-0.392044,0.382395,-1.218664,0.530720,0.425101,-0.081364,1.262426,0.452320,0.034357,-0.710316,-0.149515,0.320175,0.015041,-0.763293,0.522685,-0.594486,0.822772,-0.244126,-2.334280,0.321925,0.697232,0.209441,0.258564,-0.771089,-0.852442,0.146645,0.088244,-0.994550,0.521799,-0.306724,-0.086692,0.738053,0.042792,-0.837180,0.268378,-0.820640,-0.049183,1.329262,0.247714,1.216528,0.915677,0.367786,-0.761595,0.052417,0.341420,-0.717151,-0.197856,0.385706,-0.137993,-0.761363,0.977924,-0.639759,-0.126453,-1.364752,1.016317,-0.803056,-0.607452,-0.111243,-0.515046,-1.164400,0.371098,0.860084,0.911002,0.490074,0.480690,-1.489729,-0.232203,-0.051276,0.159016,0.858469,-0.292997,-0.465112,0.132021,-0.797997,-0.186862,0.181020,0.044723,-0.632384,-0.650995,0.350147,-0.142621,-1.210724,-0.430563,1.431556,-0.611498,-0.344222,0.198472,-1.390424,0.378179,-1.363029,-0.251674,0.802024,0.507963,-0.439606,0.500145,0.801803,-0.017631,-1.372649,0.079551,-0.813256,0.333715,-0.088764,0.526068,-0.364509,-0.240951,0.452276,-0.396826,1.888440,-0.744582,-0.971371,-0.036141,0.280224,-0.595615,-0.345109,0.155455,-0.997533,1.269712,0.685222,0.387185,-0.426732,-0.861572,-0.199875,0.204538,-0.442334,1.000829,0.688108,-0.635049,-0.272174,0.531896,0.925743,-0.318436,0.692594,-2.100915,-0.324954,-0.538003,2.092425,-0.687138,0.219441,0.813425,1.519119,1.157753,-0.397077,0.306906,1.014284,-0.555863,-0.605631,1.132421,1.311186,0.448022,-0.640741,1.523505,0.752485,0.642984,0.920657,0.444874,-0.104059,0.426671,-0.300162,-1.540897,-0.772461,0.311948,0.007577,-0.844984,0.417420,0.489252,0.079784,-0.513491,-0.541843,-0.879363,-1.551153,-0.148713,0.685651,-0.077320,-0.441395,0.675056,0.516701,1.391604,0.889911,0.038233,-1.315026,-0.442955,0.958237,0.044204,-0.536554,0.035869,-0.593229,-0.361066,0.094884,0.143266,-1.258400,-0.687334,-0.320045,-0.154814,0.046079,-0.416921,0.473451,0.072150,-0.699312,-0.533821,1.080793,-0.601626,0.488337,-0.296956,0.254118,-0.556471,-0.040105,0.529792,0.566437,0.190657,-0.639931,-0.360369,-0.240161,0.036896,0.930295,-0.374683,0.480034,0.092916,-1.015198,-0.737044,1.245920,-0.005494,-0.464975,-0.610781,-0.089657,-0.957712,-0.506137,0.775000,0.140975,-0.250906,-0.693566,0.546227,0.230364,-1.624296,0.993339,0.154123,0.572299,-0.592860,-0.973530,-0.725938,-0.428715,-0.546251,-0.017672,0.018316,0.093163,0.068122,-0.986591,-1.613750,0.839480,0.863347,-0.606752,-0.364065,-0.952498,-0.755974,0.461693,0.493944,-0.352826,0.188242,0.918097,1.400883,0.561460,0.521906,0.104931,0.302559,-0.225268,0.421732,-1.075928,-0.959551,-0.745812]'::vector, 'b9ca9f2e2058ce56f9a136836c175d65fd6b204ad51ebfc4684ff5f6f41dbd9f', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-transaction-atomic-decorator';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Django REST Framework의 `ModelSerializer`는 관계 필드를 중첩해서 표현할 수 있어 편리하지만, 뷰셋의 쿼리셋을 최적화하지 않으면 Django ORM의 N+1 문제가 API 응답 하나마다 그대로 드러납니다.

```python
from rest_framework import serializers, viewsets

class AuthorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Author
        fields = [''id'', ''name'']

class BookSerializer(serializers.ModelSerializer):
    author = AuthorSerializer()  # 중첩 serializer

    class Meta:
        model = Book
        fields = [''id'', ''title'', ''author'']

class BookViewSet(viewsets.ModelViewSet):
    serializer_class = BookSerializer
    queryset = Book.objects.select_related(''author'')  # 이게 없으면 책 N권마다 author 쿼리가 하나씩 나간다
```
`BookSerializer`가 책 목록을 직렬화할 때마다 `book.author`에 접근하는데, `BookViewSet.queryset`에 `select_related(''author'')`가 없다면 책이 100권이면 저자를 가져오는 쿼리도 100번 추가로 나갑니다. 목록 API처럼 여러 행을 한 번에 직렬화하는 엔드포인트에서는 `ModelSerializer`에 중첩 필드를 추가할 때마다 그 관계가 `select_related`(FK) 또는 `prefetch_related`(M2M·역참조)로 이미 로드돼 있는지 반드시 확인해야 합니다.', '[-1.201943,0.955517,-3.288227,-1.575379,0.974377,-1.368257,0.203415,0.120595,-0.113885,-1.289231,-0.833931,0.031994,1.402000,-0.757609,-0.827815,-0.657683,-0.576979,-0.635880,-0.400182,0.265352,0.199478,-0.062073,0.140892,-1.524449,1.208650,0.811508,-0.404260,0.147449,-0.379703,0.785436,-0.200173,-0.105598,-0.403558,-0.464223,-0.209160,-0.350316,0.651222,0.947455,-0.497743,0.476257,0.045698,0.252182,0.928096,-0.433349,1.073594,-0.017231,0.385806,0.395153,0.530893,0.542724,-0.348419,0.136152,0.254886,-0.818052,1.765951,1.126821,-0.497987,0.349926,-0.562918,-0.986711,1.107338,1.474566,-1.248015,1.864120,0.296078,0.463110,-0.314122,1.001338,-0.036193,-0.974879,-0.305143,1.453575,-0.857915,-0.051073,-0.854453,0.567699,-0.554532,-1.151519,-0.884190,0.268465,0.043166,0.559002,0.686965,0.911197,0.024071,-0.540979,-0.879253,0.543755,-0.602700,1.124044,-0.168494,-0.618363,0.339380,-0.488578,-1.033297,0.105288,-0.457912,1.013620,-1.400187,-0.887914,-0.190037,-0.064611,-0.280226,-0.194354,-0.370997,0.667032,0.325380,0.627656,0.038839,-0.594186,-0.307006,0.992340,-0.992479,0.382907,-0.040978,-0.334237,0.834168,0.119984,-0.078449,-0.070371,0.257121,-0.284293,-0.468560,0.528905,0.395304,-0.265986,-1.139026,1.315469,0.138770,-0.524949,0.065270,-0.474809,-0.418281,0.018784,-0.117141,0.435763,-0.941972,0.462851,0.074698,0.165785,0.382284,0.839116,-0.283283,-0.235126,-0.047421,-0.864771,1.377117,-0.328966,-0.976790,0.909459,0.220096,0.758874,-0.115365,-0.288662,0.056849,-0.732922,0.319245,-0.688132,0.508346,-0.438538,0.814378,0.806516,0.612611,0.603840,-0.414568,-1.052051,1.435137,0.272123,-0.604974,0.418952,-1.259691,-0.226483,-0.496065,0.032540,0.907240,0.512774,-0.386513,-0.476058,0.662792,-0.953466,0.510682,-1.601498,1.696415,0.448851,-1.453348,0.375691,-0.269960,-0.680359,0.354825,-0.827677,0.985505,-0.335417,-0.699501,-0.466846,-1.045246,-0.824865,0.378046,0.179531,0.271701,-1.085279,-0.261352,-0.576454,-0.986722,0.623373,-0.601930,0.008084,-0.359667,0.615291,-0.691248,0.487533,0.773073,0.431230,0.335304,0.593606,0.029808,-0.445102,-0.192045,-0.907200,-0.801193,0.374779,0.593745,-0.688772,0.457521,0.050407,0.763205,-0.954208,-0.151618,0.468921,-1.054899,0.753503,-0.399303,-1.477122,0.606299,-0.116489,1.325599,0.500221,0.126833,0.516232,-0.390916,-0.584485,-0.337108,0.547050,0.483186,-0.383166,-1.314805,-0.081893,-0.236422,-0.616733,0.723225,1.353143,0.897281,-0.590937,-0.129675,-0.115050,-0.286971,-0.799402,0.013241,-0.516228,1.161577,-0.639209,0.086245,-0.174343,0.369880,0.092784,-0.609345,-1.140673,-0.129916,-0.381105,-0.470056,-0.360001,0.641652,0.424899,0.858159,-0.128649,0.160975,-0.300593,0.746232,-0.345883,-0.610023,0.116084,0.216340,-1.160026,-0.409388,-0.302470,0.190768,0.259533,-0.773956,-0.071873,0.180222,-0.084917,0.530943,-0.221266,-0.448995,0.112524,0.439527,-0.248048,0.242688,0.046908,0.811904,0.702774,0.735147,0.991441,1.143742,1.087639,-0.429839,-1.039054,0.142066,0.520923,0.447011,0.257599,-1.141892,-0.894340,-0.674908,0.687976,-0.519936,0.511119,-0.924093,-0.256965,0.402148,-0.957680,-0.022238,-0.809033,0.434141,-0.947134,0.252225,0.978024,-1.028028,1.084727,0.134486,-0.040742,0.266542,0.765999,0.239995,-1.319098,-0.037833,0.854249,-0.060228,0.339346,0.829242,0.741412,0.752690,0.154147,0.987927,-1.028337,-1.859466,0.604859,-0.627197,-1.165827,1.149496,0.801815,-1.097640,1.363815,-0.677138,0.542413,-0.387914,-0.178126,0.481120,0.305463,0.515997,0.038485,1.374795,-0.056213,0.137803,-0.668650,-0.062170,0.126321,0.425076,-0.222886,1.144012,-0.114812,-0.138614,-0.383041,0.278504,0.659047,0.358919,0.028318,0.030817,0.130476,-1.120608,0.557315,0.109084,-0.765065,-0.287623,1.168770,0.391316,-0.323317,-0.231249,-0.127371,0.014793,0.396999,-0.756284,-0.203723,-1.153367,0.463033,0.926446,-0.573095,0.334925,1.217930,0.671201,0.908935,-0.694772,-1.030358,-0.507914,-0.376754,-0.314873,0.559317,-0.445239,-0.079549,1.231611,-0.879031,-0.138324,0.053916,-0.013676,-0.867983,0.704299,0.406060,0.878915,0.593553,-0.815854,-0.805226,0.330000,0.605942,-0.029122,0.559710,0.488128,0.325268,1.126965,0.239942,-0.059076,-1.536797,-0.325515,1.586630,0.451777,0.361543,-1.362675,-0.249806,1.362856,1.127834,-0.247342,0.362413,0.135132,-0.538183,-0.127495,-0.650730,0.048861,1.100371,0.958561,-1.260689,-0.712528,0.596643,0.368245,0.549683,-0.479379,0.517679,1.023104,-0.012797,-0.019523,0.527694,0.087401,0.644351,-0.286383,0.108089,-0.395462,0.073581,-0.267021,-0.441924,0.376049,-0.180244,0.520296,1.044746,-0.194769,0.093999,0.212114,-1.135339,0.366419,0.818505,0.351351,-0.192305,0.792267,0.223562,-0.040016,-0.243784,-0.403050,-1.155310,0.489695,-0.322824,0.670107,-0.082443,0.139085,-0.570657,0.482954,0.514799,0.786645,-0.021516,-0.513635,0.451033,0.518846,0.781672,0.776107,-0.386007,0.238645,1.065604,-0.029545,0.357670,0.324543,-0.397907,1.216689,-0.054435,-0.187282,-1.077904,-0.072656,0.951284,-0.326126,0.351787,0.266581,-1.205414,0.377366,-0.310134,-0.847904,0.178300,0.709596,-1.359952,0.681616,-0.870546,-0.893252,0.585096,0.721703,-1.586147,1.083144,-0.443011,0.707722,0.190354,-0.824242,-0.252850,0.285287,-0.420853,-0.115848,1.140585,0.646006,0.085182,0.187749,0.724714,0.554799,-0.712027,-0.093522,-0.353417,-0.038056,0.215855,1.191114,-1.112164,0.645499,-0.216507,0.119669,-1.188242,0.345155,-0.738431,-0.328280,-0.360225,-0.710787,-0.636813,0.065598,-0.032911,1.200098,0.574521,0.391966,-0.093519,-0.480128,-0.021770,0.316794,0.479732,0.260126,-1.125425,0.151786,-0.212451,-0.113775,1.143965,0.750620,-0.473968,-0.645183,-0.548671,0.336193,-1.583085,0.573983,0.903799,-0.340637,0.415730,-0.242668,-0.857016,0.004313,-0.826755,-0.073212,0.385510,1.053109,0.015092,0.566570,0.884202,0.518026,-0.382864,-0.161367,-1.327608,0.203244,-0.261205,1.082327,-0.823696,-0.315618,0.978944,-1.166901,0.605656,0.287748,-0.453981,0.574153,0.402781,-0.252934,-0.353388,0.759937,-1.639469,0.211783,0.630437,-0.389249,-0.489990,-0.919525,-0.698723,0.523555,0.114161,0.407618,0.649260,-0.990065,-0.346181,0.567661,0.469170,-0.869146,0.165503,-1.522674,-0.721710,-0.587357,0.858929,-1.013790,-0.307653,1.390491,1.715688,0.648696,0.052254,-0.358586,0.763477,-0.122745,-1.457089,0.929065,1.893550,0.630893,-0.739559,1.136266,1.256837,-0.587982,0.570342,0.514259,-0.233464,0.796002,-0.668836,-1.867556,-0.787810,-0.477944,-0.069273,-0.033864,-0.537720,0.333995,0.563753,-0.444452,0.456956,-1.325123,-0.276835,0.182358,0.122507,0.447234,-0.505369,0.354346,0.562602,0.762474,0.705292,0.457056,-0.840493,-0.248945,0.164169,0.696099,-0.659958,-0.418229,-0.973942,1.029504,-1.150464,0.326965,-1.279088,-0.898718,-0.463366,-0.232206,-0.058226,-1.264175,0.507175,-0.369526,-0.357298,-0.356473,1.633070,0.153778,0.183685,0.142020,0.304812,-0.012482,0.084792,0.468433,0.104324,0.218810,-0.820431,-0.858291,0.402389,-0.450405,1.080313,-0.200432,0.035352,-0.799019,0.321081,-0.885830,-0.334067,0.590577,-0.966041,-0.457267,0.780975,-0.167510,-0.150554,0.682357,-0.797147,-0.162622,-0.268586,0.456236,0.439815,-1.782203,1.665061,-0.401451,0.719749,-0.324935,-0.548491,-0.619313,-0.498637,-0.575741,0.704373,-0.103080,0.662807,-0.138879,-0.711861,-0.943769,0.457452,0.450269,-0.373725,0.299029,-0.403265,-0.247762,0.148910,0.312089,-0.423752,0.480619,0.848613,1.817805,0.822381,0.509194,0.728649,-0.144993,0.088226,-0.251818,-0.517037,-0.068464,-0.128452]'::vector, 'c6ee6835c29d197b91c79f4003c0e1ebd7dc0d0f5ba0c21d06bcf97c41cd306c', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-drf-nested-serializer-n-plus-one';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`BackgroundTasks`를 쓰면 클라이언트에게 응답을 먼저 보낸 뒤, 응답과 무관한 후속 작업(이메일 발송, 로그 적재 등)을 이어서 실행할 수 있습니다. 사용자가 이메일이 실제로 전송될 때까지 기다릴 필요가 없어집니다.

```python
from fastapi import BackgroundTasks, Depends, FastAPI
from sqlalchemy.orm import Session

app = FastAPI()

def send_email(to: str, subject: str):
    # 실제로는 SMTP 클라이언트나 이메일 API를 호출한다
    print(f''sending email to {to}: {subject}'')

@app.post(''/orders/'')
async def create_order(user_id: int, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    order = Order(customer_id=user_id)
    db.add(order)
    db.commit()
    db.refresh(order)

    background_tasks.add_task(send_email, ''user@example.com'', ''주문이 접수되었습니다'')
    return {''order_id'': order.id}
```
`background_tasks.add_task(...)`는 작업을 큐에 등록만 할 뿐 즉시 실행하지 않습니다. FastAPI는 `return` 문으로 응답을 클라이언트에게 보낸 ''이후''에 등록된 태스크를 실행합니다. 다만 이 태스크는 API 서버와 같은 프로세스 안에서 동기적으로 실행되므로, 시간이 오래 걸리는 무거운 작업이라면 Celery 같은 별도의 작업 큐로 옮기는 것이 낫습니다. `BackgroundTasks`는 어디까지나 응답 직후에 끝나는 가벼운 후속 작업에 적합합니다.', '[0.547685,0.889863,-3.149055,-1.433495,0.633016,-0.964306,0.926942,-0.721602,0.000712,-1.022756,-0.095065,1.736065,1.024386,0.285344,-0.315212,0.241238,-0.377908,-1.416839,-0.495586,0.647969,0.461860,0.168987,-0.330566,-0.978444,0.998828,0.346151,0.412435,-0.360656,-1.607994,-0.471438,0.636102,0.651646,-0.870220,-0.885488,-0.345121,-0.207204,0.439542,0.117076,-0.122337,-0.013614,0.319129,-0.405935,0.386800,-0.994063,0.872175,-0.311588,1.210067,-1.024486,0.902453,-0.857802,-0.682704,-0.002205,-0.322002,-0.169262,1.862771,0.577675,0.694960,1.172569,0.885927,0.353657,1.654373,0.430487,-0.665113,1.345102,0.996171,-0.442891,0.081925,1.501809,-0.520005,0.641875,0.793073,0.577087,-0.776588,-0.221071,-0.286052,0.104053,-0.679915,-0.703635,-0.014988,1.428256,-0.041940,0.381922,0.674552,-0.175244,1.070108,-0.206222,-0.208591,0.414065,-0.681518,1.063915,-0.367783,-0.002632,-0.407792,-0.754796,-0.946979,0.346123,-0.247403,-0.086371,-0.655693,-0.586588,-0.021415,0.016034,-0.028237,-0.405037,0.261459,1.065871,-0.197252,0.868302,0.284917,0.231032,-0.140701,0.802648,-0.656092,-0.014331,0.422367,-0.773324,0.414928,-0.008009,-0.507488,0.747396,-0.438838,-0.417084,-0.317323,-0.193459,1.208640,0.671313,-0.898554,0.617085,0.521797,-0.920211,1.059520,-1.205866,-1.321831,0.324120,0.116121,0.066216,-0.756968,-0.210315,0.238661,0.282525,0.282652,0.739696,-0.523550,-0.201575,-0.686460,-0.255519,0.437631,-0.035624,-0.887530,0.257892,-0.145400,0.372839,0.183811,1.137000,0.455508,-0.622171,-0.533788,-0.305666,0.536641,0.126440,1.589128,0.237760,-0.307396,0.804746,0.071745,-0.447904,0.338836,1.305276,0.235463,1.110277,-0.213656,-0.978949,-0.093296,-0.548674,-0.192667,1.111529,0.504764,-0.440656,2.346246,-0.318041,-0.113942,-1.292378,0.648762,0.455618,-1.227239,-0.677164,-0.660122,0.210840,-0.567099,-0.818740,0.395142,0.369434,-0.438560,-0.068506,-1.022745,-0.710796,0.481986,-0.887044,1.281561,-1.571241,0.200101,0.415022,-1.090018,0.164070,-0.118692,1.205357,-0.151817,0.223272,-0.365228,0.084855,1.134696,0.419925,0.295535,0.261575,0.215552,-0.249399,-0.209663,-0.277440,-0.410659,-0.036615,0.405701,-0.130750,0.485625,-0.406205,0.383399,0.480944,-0.064176,0.539483,-0.383366,0.834048,-0.740372,-1.170892,0.167980,0.182634,0.500784,0.499986,0.399800,1.493094,-0.244940,-0.094966,-0.339347,-0.450448,0.546300,0.312365,-1.717115,-0.298710,0.052476,-0.644338,-0.424989,0.668627,-0.527488,0.099522,0.387014,0.203939,-0.170425,-0.447096,-0.212709,-0.208510,0.714529,-0.687095,0.485480,-0.680123,0.704388,0.038602,-0.014482,-0.965606,-0.748419,0.241642,-0.161325,0.032744,0.323578,0.318163,0.115880,0.152679,0.132149,0.381803,0.549911,0.069590,0.409621,1.142871,-0.258503,-1.628499,-0.793770,0.299930,-0.702711,0.279581,-0.301513,0.737870,0.561791,-0.637954,1.198452,-0.309854,-0.471825,-0.131131,0.789455,0.871264,1.556237,-0.438393,0.038123,0.045710,0.192622,0.721323,1.814499,0.481284,-0.478093,-0.273093,-0.287158,-0.934422,0.534683,0.399900,-0.959435,-1.128974,-0.712850,1.167275,-0.326513,1.359629,0.131048,0.893777,1.041469,0.373041,-0.075719,-0.339034,0.402378,0.002815,-0.101081,0.414947,-1.265695,1.359834,0.468893,-0.211131,1.109994,0.363154,0.218034,-1.382674,-0.339175,-0.067617,0.555215,0.095340,-0.225300,0.829489,1.283331,0.004021,1.425757,-1.246664,-0.603939,-0.201243,0.259167,-0.239835,0.423318,0.946475,-0.548536,0.213230,-0.678041,0.259782,0.212464,-0.316720,0.311390,0.525509,0.360655,-0.492802,0.879086,-0.205133,0.371102,-0.211534,0.365156,0.254683,-0.223832,0.039262,0.212988,-0.246591,0.232567,-0.704657,0.051210,0.869861,0.439293,-0.019337,-1.072283,-0.410655,-0.713990,0.412782,0.166994,-0.526316,-0.736933,0.338312,0.202506,0.067787,-0.249037,-0.212686,-0.183237,0.756599,0.386591,-0.840062,-0.633093,0.278193,1.108037,-0.403989,0.523448,0.236677,0.037086,1.135923,-0.628538,-1.070062,-0.421227,-0.470106,-0.531553,-0.127220,-0.596969,-0.077656,0.451436,-0.332310,0.390820,-0.055918,-0.142008,-0.210306,0.272920,0.247260,1.690151,0.649442,-0.545879,-0.777607,-0.041958,0.816383,0.119645,-0.311891,-0.297106,0.527175,0.473956,1.017896,-0.529123,-1.429502,-0.084556,0.931133,1.364818,-0.334300,-0.592144,-0.274438,0.588449,0.627062,-0.573749,1.068118,0.423784,-0.160796,-1.256122,0.080534,-0.091603,0.932935,0.712647,-1.204207,-1.085966,-0.582737,-1.083905,0.948037,0.210192,-0.147440,0.953064,-0.613681,0.560185,-0.217186,-0.463079,0.922533,-0.246820,0.492258,-0.489416,0.155382,-0.575862,0.061078,0.722216,-0.073765,0.967530,1.064527,-0.664203,-0.241009,0.929309,-0.438644,0.120986,0.420330,-0.528320,0.255902,0.140367,1.365654,0.374756,-0.626183,-0.747955,-0.781863,-0.811417,0.264087,0.269185,-0.265906,0.315838,0.054769,0.234317,0.422818,-0.125440,-0.600605,-0.016481,0.019542,-0.279504,1.555432,0.192228,0.140202,0.214400,0.458497,-0.902920,-0.113012,0.512240,-0.075107,0.449665,-1.126320,-0.665258,0.300305,-0.438891,0.867885,0.127292,-0.778008,0.433592,-0.830816,0.935997,-0.696685,-1.418052,0.752003,0.045069,-0.423091,0.430838,-0.711249,-1.391949,-0.009534,-0.015773,-1.599068,0.481397,0.107013,-1.423254,0.372736,-0.320488,-0.919499,0.482318,-1.186886,-0.744975,1.193566,0.499216,0.332574,0.581639,0.101449,-0.247675,0.971402,-0.307476,-0.087355,0.348260,0.410805,0.147971,-1.741520,0.919458,-0.423129,-0.473265,-1.194953,-0.129685,-0.793388,-0.185022,-0.779306,-0.356884,-1.392797,-0.126577,-0.280937,0.722902,0.359951,0.786503,-1.615957,-0.806671,0.662198,0.034411,0.763234,0.019849,-1.396618,0.299442,-0.509511,-0.037625,0.084657,-0.008906,-0.222196,-1.017234,-1.223673,0.560209,-0.418703,0.759508,1.623414,0.118612,-0.451938,0.091611,0.211275,0.501624,-0.255244,-0.689252,0.504099,0.169688,-1.065869,0.477085,1.049361,0.012131,-1.018155,-0.013210,-0.627613,-0.074671,0.278132,0.298101,-0.051328,-0.157083,1.383449,-0.392567,0.266634,-0.581123,-0.398777,0.218802,-0.803204,-0.627792,0.314643,0.673754,-1.013553,0.687735,0.579943,0.361248,-0.706960,-1.083567,0.105715,1.388399,-0.851560,0.783358,0.180409,-0.572306,-0.001625,0.037716,1.020075,-0.298821,0.774539,-2.424846,-0.442389,-1.307055,1.263148,0.340897,-0.438338,-0.756848,1.160127,0.559205,-0.029162,0.171726,0.210143,-0.059510,-0.874195,1.274614,1.187098,1.489766,-0.712174,1.087725,0.980884,1.220667,0.124461,0.641277,-0.049522,1.016996,-0.060345,-1.238357,-1.446238,-0.361542,-0.192440,-0.771644,0.228491,1.046360,0.467729,0.099644,0.311656,-0.217625,-0.472212,0.484455,0.254029,0.018635,-0.727519,0.852716,0.210252,1.337227,0.372198,-0.292208,-0.525629,1.055656,0.015028,0.117252,0.609127,-0.546497,-0.624165,-0.013261,-0.863300,0.042037,-1.240310,-0.856217,-0.468950,-0.867805,0.032678,-0.233178,0.245062,-0.828758,-0.590333,-0.106891,1.013096,0.088323,0.467356,1.013713,-0.000933,-0.306236,-0.348945,0.164710,0.367502,0.120248,-0.452583,-1.232997,0.095859,-0.565720,0.868470,-0.060490,0.268060,-0.802331,-0.519983,0.051239,0.204596,0.346710,-0.406776,-1.425679,0.869798,0.974294,-0.281972,0.283221,-0.470286,0.768417,-0.957805,-0.011278,-0.515686,-1.202213,0.266088,-0.012231,0.162071,-0.906565,-1.711783,-0.748585,-0.526367,-0.139786,-0.378290,-0.845728,0.216301,-0.229881,-0.396022,-0.790378,0.163657,0.558891,-0.783610,1.117212,-0.536474,-1.000313,0.818171,0.529799,0.483956,0.335338,1.035653,1.796648,0.525659,0.421556,0.324739,-0.021619,-0.183588,-0.493828,-0.842441,-0.878822,-0.301728]'::vector, 'f9eecc58ae82f86611b3e9633198a60048537ae9d0b3219f4c257076795e00fa', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-fastapi-background-tasks';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '의존성 주입은 라우트 핸들러가 필요로 하는 자원(DB 세션, 인증된 사용자 등)을 함수 시그니처 선언만으로 받아오게 하는 패턴입니다. FastAPI는 `Depends`로 이를 지원하며, 의존성 함수를 조합해서 재사용할 수 있다는 점이 핵심입니다.

```python
from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(db: Session = Depends(get_db), token: str = ''''):
    user = db.query(User).filter(User.token == token).first()
    if user is None:
        raise HTTPException(status_code=401, detail=''Unauthorized'')
    return user

@app.get(''/items/'')
def read_items(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(Item).filter(Item.owner_id == user.id).all()
```
`get_current_user`가 다시 `get_db`에 의존하는 것처럼, `Depends`는 서로 중첩될 수 있습니다. FastAPI는 요청 하나를 처리하는 동안 같은 의존성을 여러 곳에서 요구해도 기본적으로 한 번만 평가한 뒤 결과를 캐시해서 재사용하므로, `get_db`가 여러 핸들러에서 동시에 요구돼도 세션이 중복 생성되지 않습니다.', '[0.033954,0.890321,-2.748214,-1.303050,0.894102,-0.953447,0.315846,-0.288747,0.378895,-0.689578,-0.082865,1.523838,0.661467,-0.961863,-0.075682,0.012514,-0.172665,-1.410103,-0.345391,0.469868,-0.272701,-0.192576,-0.958025,-0.567743,1.781803,-0.395813,-0.076653,0.182299,-1.387901,0.005119,-0.061052,0.174362,0.031794,-1.162712,-1.274130,-0.793587,0.275712,-0.065734,0.446417,0.638751,-0.281777,-0.256168,0.666279,-0.724610,0.587567,-0.404179,1.295325,-0.011641,0.979528,-1.129602,-0.140633,-0.356514,0.331633,-0.721750,2.183072,1.112846,-0.729484,0.667616,0.010054,-0.555271,1.778980,0.404379,-0.692615,0.991538,0.688363,-0.539458,-0.438556,1.344757,-0.460834,0.252733,0.936948,0.586224,-0.329485,-0.362075,-0.167423,0.294232,-0.714312,-1.308330,0.237208,0.993269,-0.128244,0.294510,0.593845,-0.343993,0.119828,0.115689,-0.648277,0.698873,0.153974,0.543820,0.125292,-0.604264,0.050109,-0.255163,-1.341357,0.672952,0.091564,0.097361,-0.732514,-0.371154,0.170789,0.005299,0.446070,-0.397219,0.028118,1.220857,-0.390715,0.789896,-0.021001,0.090276,-0.554335,0.509981,-0.386429,-0.444652,0.239656,-0.632397,0.440126,0.612117,-0.415520,0.181333,-0.276967,-0.650420,-0.424553,1.430842,0.573703,0.936058,-0.937548,1.476906,0.337345,-1.061395,-0.312129,-1.300341,-0.343637,0.363252,0.314811,-0.226268,-0.823746,-0.274568,0.021587,-0.212849,0.753889,1.015946,-0.732998,0.425984,0.172497,-0.413404,1.341390,0.076692,-0.610006,0.234827,0.087899,0.769121,0.118340,1.031984,-0.138851,-0.869532,0.190152,-0.096319,0.878199,0.106745,1.362283,0.796435,-0.169374,1.136405,-0.403926,-0.426416,1.092565,1.072706,-0.143298,0.901883,-0.907582,-1.145771,-0.016350,-0.395463,-0.033720,0.608369,0.250486,-0.414293,1.564418,-0.344303,-0.188073,-1.931178,1.215630,0.702231,-0.884046,0.350471,-0.313722,0.053653,-0.151353,-1.722719,0.251580,-0.028575,-0.295550,-0.738422,-1.345181,-0.873578,0.661775,-0.398284,1.331169,-1.087577,-0.705939,0.658708,-0.501749,0.027650,-0.475596,0.434979,-0.333290,0.213395,-0.703390,0.447308,1.483479,-0.019737,-0.348737,0.230862,0.018213,-0.329727,-0.329389,-0.337212,-0.700452,0.130320,1.199543,0.284772,0.745955,-0.305364,-0.071836,0.194001,-0.419428,0.535873,-0.614662,0.440429,-0.538435,-1.910704,0.038425,0.548056,0.715020,0.991737,0.393745,1.049724,-0.016304,-0.208974,-0.598324,-0.558228,-0.289687,0.362823,-1.482287,-0.465827,-0.387819,-0.606993,-0.492407,1.006153,-0.580262,0.203846,0.524352,0.345306,-0.012745,0.074619,0.427065,-0.603313,0.910452,-0.740305,1.063573,-0.614929,0.218199,0.338960,-0.043266,-0.827658,-0.299368,-0.521749,-0.145935,-0.079096,0.363122,-0.052581,0.122430,0.394883,0.783319,0.528004,0.504867,-0.304632,-0.331584,0.374098,-0.493465,-0.612661,-0.642845,0.433005,-0.144659,0.454464,-0.338803,-0.209018,0.760674,0.197115,1.153358,-0.472115,-1.489963,0.967877,0.342639,0.464391,0.809939,-0.599852,0.124363,0.280068,0.374900,1.019184,1.113470,0.844775,-0.054608,-0.262762,0.515392,-0.203942,0.925116,-0.265075,-1.096482,-0.520861,-0.036741,0.826957,-0.631929,1.269092,0.153111,0.725458,1.320837,0.395733,0.124358,-1.256587,0.202450,-0.575509,-0.454472,-0.240492,-1.171616,0.595266,-0.174305,-0.845694,0.181661,-0.035762,0.935710,-1.141859,-0.584367,0.104075,0.727889,0.124983,0.430890,1.147649,0.879008,-0.875913,0.742136,-1.145081,-1.017326,0.299265,-0.571214,0.109741,0.756949,0.438037,-0.407418,0.501095,-0.884074,0.103096,-0.032786,-0.671409,0.677759,0.445538,-0.178110,0.002651,0.702255,-0.464761,0.316624,-0.058365,-0.061011,0.844740,0.455015,0.204086,0.398765,0.014690,-0.400518,-1.207398,0.341621,0.150040,0.220721,0.251564,-0.620073,-0.096998,-0.916098,0.698620,0.431776,-0.614807,-0.473547,0.957742,0.217110,-0.648470,0.012547,0.378410,-0.721985,0.709779,0.479567,-0.867543,-0.445720,0.357877,0.363366,-0.249155,0.663210,0.401292,-0.154311,1.407665,-0.741598,-0.978065,-0.063175,0.004311,-0.443632,0.536778,-0.766379,-0.637829,0.209091,-0.057905,-0.460852,-0.408333,-0.398303,0.527321,-0.129466,0.451386,1.592911,0.821122,-0.495351,-1.090665,0.366256,0.171812,0.359051,-0.041003,-0.031217,0.152588,0.839836,0.686007,-0.113376,-1.172433,-0.009274,1.201492,0.651396,-0.735308,-0.588925,0.798023,0.652310,1.230666,-0.268505,0.460136,0.854783,0.369050,-0.785235,-0.199926,-0.240854,1.471895,1.077813,-1.013060,0.063415,-0.111995,-1.248283,0.260508,0.605220,-0.405462,0.901617,-1.047239,0.054658,0.081759,-0.241157,1.234854,-0.234106,0.629566,-1.211059,-0.167088,-0.572715,0.327708,0.553529,-0.767941,0.547691,0.753052,-0.922868,0.060912,0.567813,-0.702053,0.915136,0.858968,-0.547442,-0.494552,0.394975,0.798105,0.083235,-0.667566,-0.927582,-0.568016,-0.127947,0.065255,0.622360,-0.329066,0.143534,0.021314,0.271471,0.336590,0.198303,0.258507,-0.107107,-0.182419,0.172276,0.874080,-0.023580,0.006650,-0.305304,0.144925,-0.354167,-0.154157,-0.095779,-0.290207,0.799726,-0.624842,-0.329317,-0.932368,-0.276542,0.675664,0.427720,0.475058,0.710857,-0.354826,1.398451,0.357908,-1.202347,0.837419,0.344342,-0.487591,0.425830,-1.209544,-1.565055,-0.368831,-0.051154,-0.893174,0.237331,-0.321550,-0.166538,0.225972,-1.232205,-0.543683,0.555874,-0.806748,-0.709262,0.493981,0.542000,0.301470,0.640977,0.732722,-0.369847,0.130363,0.045290,-0.478915,-0.324776,-0.435128,0.467100,-0.421849,0.719071,-0.088250,-0.615144,-0.354150,0.269534,-0.584013,0.292364,0.044038,-0.125926,-0.342732,0.674776,-0.517098,0.397473,0.135033,0.509180,-1.644324,-0.222492,0.848039,-0.446177,1.033586,-0.566339,-0.965403,-0.043015,-0.980488,0.904522,0.845793,-0.087636,-0.512023,0.224990,-1.152962,0.316074,-0.505739,0.800681,1.022564,0.017423,-0.105231,0.380796,0.208008,0.145990,-1.026708,-0.440164,0.680971,0.085610,-0.530059,0.146817,1.154910,-0.180773,-1.845863,-0.270126,-0.830786,0.463481,0.107317,0.566455,0.138922,-0.399031,0.292814,-1.020879,0.292753,-1.059887,-1.141435,0.484140,-0.252255,0.090188,-0.166500,0.448322,-1.022559,0.723117,0.598889,-0.224134,-0.443888,-0.572192,-0.128335,0.798339,-0.442466,0.448069,0.680071,-1.008936,-0.658988,-0.333086,0.688887,0.067161,1.209876,-1.478387,-1.249750,-1.273308,1.506914,-0.536946,0.883601,0.268831,1.434268,1.803250,0.054310,-0.213318,0.629637,0.294841,-0.552692,0.571254,1.541745,1.033566,-0.467975,1.887034,0.824972,0.877426,0.505514,1.277564,0.023111,0.940064,-0.588235,-1.501358,-0.594677,-0.431984,-0.707482,0.197819,0.204139,0.341583,0.150350,0.000571,-0.816319,-0.393632,-0.386873,0.330830,-0.091921,-0.119087,-1.272938,0.897464,0.584344,0.670704,0.195586,-1.217587,-0.374199,0.068896,-0.106265,0.480635,-0.177138,-0.820857,-0.335681,-0.217896,-1.288869,0.238989,-0.983484,-1.771825,-0.668560,-0.457459,0.494188,-0.305777,0.270013,-0.018551,-0.520366,0.156702,0.990272,-0.226755,0.620680,0.986903,0.487354,0.036980,-0.247587,-0.519667,0.469138,0.106158,-0.931980,0.167410,0.301053,-0.737657,0.695268,-0.337637,0.651273,-0.512780,-0.515467,-0.618604,0.100854,0.491327,-0.062657,-0.947576,0.147759,-0.172652,-0.475218,0.140537,-0.045344,0.537225,-0.759297,0.435620,-0.789974,-1.391043,0.775404,0.079156,0.509833,-1.239985,-0.762743,-1.518926,-0.705335,-0.618923,0.292733,-0.164005,0.293265,-0.170562,-0.052053,-1.052159,0.129908,0.686679,0.013672,0.420113,-0.441793,-0.830879,1.279971,0.289591,-0.118218,-0.858487,0.986013,1.874509,1.406093,0.287770,0.082943,0.331195,0.183148,0.128768,-0.770294,-0.792582,-0.106405]'::vector, '3622471506e5470c98a4f2b39d80938f97f0b946c248e8b61902b2fbde4ba562', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-fastapi-dependency-injection-depends';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Pydantic 모델을 요청 바디 타입으로 선언하면, FastAPI가 요청이 들어올 때마다 자동으로 JSON을 파싱하고 필드 타입·필수 여부를 검증합니다. 검증에 실패하면 핸들러 코드가 실행되기도 전에 422 응답이 반환됩니다.

```python
from typing import Optional
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float = Field(gt=0)
    description: Optional[str] = None

@app.post(''/items/'')
def create_item(item: Item):
    return {''name'': item.name, ''price'': item.price}
```
`price`에 음수나 0을 보내면 `Field(gt=0)` 조건에 걸려 FastAPI가 자동으로 422 응답과 함께 어떤 필드가 왜 실패했는지 알려주는 에러 메시지를 돌려줍니다. `create_item` 함수 안에는 이 검증 로직을 위한 `if` 문이 전혀 없다는 점이 핵심입니다 — 핸들러가 호출된 시점에는 이미 `item`이 유효하다는 것이 보장되므로, 비즈니스 로직과 입력 검증을 분리해서 작성할 수 있습니다.', '[-0.406350,1.070475,-3.093765,-1.982767,1.449320,-0.737254,-0.043831,-0.904740,-0.825647,-1.125974,-0.200024,0.566994,1.858556,-0.602645,-0.299110,0.301127,0.140667,-0.949968,-0.435706,0.471362,0.309162,-0.258078,-0.272455,-0.813695,1.449349,-0.345064,0.035075,0.344300,-1.227031,-0.271340,-0.149520,0.496733,-0.314552,-1.206664,-0.989105,-0.620280,1.266590,0.553421,-0.091280,0.153504,-0.565600,0.724248,0.742769,0.217194,0.744595,-0.207041,1.229542,-0.272204,0.449586,-0.688208,0.703611,0.151810,-0.156424,-1.193295,1.026765,1.183198,0.283857,0.134080,0.366139,0.326212,0.713167,1.270810,-0.714214,1.584843,1.459106,-0.143548,0.008608,0.540997,-0.584838,0.131750,0.423385,0.156610,0.226943,-0.078036,0.478202,0.419067,-0.720679,-0.844584,-0.379390,1.026457,0.565356,0.538863,0.772811,-0.398072,0.777377,-0.530927,-0.894778,0.659881,-0.218596,0.559921,-0.491679,-0.332223,-0.058765,-0.436704,-0.846825,0.598342,-0.757329,0.719900,-1.518319,-0.973383,0.638529,-0.139696,-0.013152,-0.617331,-0.047399,1.297724,0.097436,0.284686,0.242280,-0.462539,-0.326881,1.033725,-0.202900,-0.349718,0.036421,-0.926738,0.789448,0.290446,0.605236,0.225675,-1.034829,-0.625470,-0.295484,0.921807,-0.081936,0.017524,-1.038515,0.685220,0.188422,-1.246803,0.459307,-1.053017,-1.095100,-0.028052,-0.147640,0.336377,-0.775095,0.361598,0.974130,-0.135635,0.272412,0.784783,-0.462459,-0.484331,-0.149238,-0.458639,0.966533,-0.264122,-0.679990,0.395744,-0.034822,0.954583,0.594530,0.585334,-0.073710,-0.548314,0.480354,0.434615,1.083015,-0.515183,1.145971,0.512116,0.045065,0.712508,-0.186843,-0.567420,1.176438,0.895091,-0.130774,0.826106,-0.570474,-1.025221,-0.274883,0.029911,0.257495,0.130680,-0.084770,-0.579492,0.780987,-0.411834,0.332298,-1.517606,1.877045,0.480431,-1.445586,0.206881,-0.315066,0.058855,-1.009345,-0.236157,0.511859,1.084372,-1.253667,-0.230292,-0.760049,-0.741879,1.171455,-0.777836,0.570463,-1.476683,-0.181736,-0.276202,-0.683788,-0.127635,-0.635788,-0.150510,0.195665,0.829079,-0.503491,0.235925,1.251050,0.141388,-0.545888,0.681680,0.468247,-0.525147,-0.326847,-0.611637,-0.818303,0.173309,0.823215,0.297396,0.623180,-0.289894,0.428584,0.408589,-0.068767,0.210698,-0.438609,0.427456,0.281297,-1.706313,-0.215124,-0.071995,0.375043,0.223779,0.124910,1.242370,0.234194,-0.779525,0.040160,-0.126155,0.227957,0.472534,-1.291285,-0.292164,0.294058,-0.644199,0.114936,1.530458,0.212325,0.082475,-0.453213,-0.068718,0.091410,-0.148912,0.522532,-0.679703,0.433386,-0.797899,0.439517,-1.016569,0.453109,-0.020262,-0.529087,-0.375149,-0.446860,-0.299374,-0.195036,0.519273,-0.165799,-0.446591,0.653924,0.161036,-0.071904,0.137228,0.728714,-0.481705,-0.298839,0.641650,-0.111107,-2.216904,-0.752203,0.251088,-0.960973,0.078785,-0.292026,-0.155176,0.203542,-0.007183,0.776694,-0.001868,-1.150808,0.238193,-0.200053,0.423274,0.273961,-0.012131,0.915370,-0.183021,0.592348,1.105710,1.860728,0.718352,-0.212535,-0.755432,-0.464162,-0.581440,0.643762,-0.215416,-0.770966,0.319753,-0.533122,0.932381,-1.046951,0.829078,0.238128,0.667421,1.128962,-0.107172,0.192165,-0.888734,0.138023,0.170206,-0.191921,0.504941,-0.900707,0.761198,0.530070,-0.610555,0.892576,0.297092,0.872867,-0.801067,-0.871610,0.737629,0.029158,0.534722,-0.114655,0.539799,1.096540,-1.146737,0.586440,-1.205139,-0.959491,-0.011203,0.250640,-0.999767,0.665251,0.686661,-0.733015,0.293386,-0.359691,0.153463,-0.264252,0.391054,0.404926,-0.124371,0.923591,0.234451,0.995243,-0.676244,1.027484,-0.077897,-0.674167,0.369311,0.197457,-0.203245,0.412279,-0.311147,-0.019451,-1.062854,-0.092464,0.230972,-0.336803,-0.494550,-0.701642,-0.677531,-1.564185,0.775225,-0.158676,-0.336440,0.348592,0.758309,0.433385,-1.157761,0.084146,0.190120,0.164836,0.295080,0.137986,-0.582235,-0.599908,0.510041,0.587015,0.448357,0.593796,0.515206,-0.302884,1.174414,-1.175179,-0.288334,0.272731,-0.870960,0.270302,-0.493864,-0.358255,-0.901716,0.072288,-0.528765,-0.120141,-0.135013,0.081429,-0.572683,-0.028351,0.742468,1.019673,0.945987,-0.464778,-1.318608,0.608250,0.492392,0.391361,0.004392,0.488615,0.485202,1.265032,0.601071,-0.328676,-1.704575,0.193448,0.577749,0.551185,-0.254155,-0.512225,0.255077,0.500366,0.973376,0.438877,-0.000338,1.205549,0.019579,0.108800,-0.416457,-0.415349,1.181295,0.755172,-1.754604,-0.727643,0.316490,0.423403,0.283036,0.542853,0.583445,0.830586,-0.352694,-0.133566,0.199415,0.213006,0.834756,-0.164421,0.021523,-1.686825,0.289736,0.349314,-0.017453,0.566636,-0.482442,1.190111,0.934934,-0.684790,-0.012199,0.316663,-0.708063,0.701484,1.101865,-0.178426,-0.252789,-0.055847,0.294309,-0.067114,-0.357447,-0.765845,-0.842304,0.183993,0.146687,0.139180,0.245781,0.023042,-0.240375,-0.018304,0.396315,0.414938,-0.466156,-0.396473,-0.728042,0.423255,0.903711,0.124245,0.077532,-0.841876,0.430162,-0.121244,0.287196,0.662151,-0.345706,1.238144,-0.092432,-0.107420,0.451078,0.812254,1.247479,0.485981,0.278875,0.611412,-0.526650,1.508052,-0.580586,-1.810443,-0.157329,0.779659,-1.211545,-0.005701,-1.052489,-1.142783,0.002286,0.766550,-1.803309,0.703813,-0.420799,0.018053,0.479411,-0.746099,-0.456148,-0.136707,-1.080375,-0.087895,1.038782,0.816268,-0.220341,0.519475,0.214405,0.441522,-0.055451,-0.208143,-0.239236,0.239369,-0.050187,0.280758,-1.109617,1.323414,0.157947,0.081397,-0.679672,0.760639,-0.710483,-0.541105,-0.116403,0.089743,-1.383209,0.339811,0.090097,0.548960,0.795459,0.724372,-0.741284,-0.368201,-0.356907,0.001957,0.938565,-0.137696,-0.833660,0.876040,0.578218,0.449588,0.332890,0.790864,0.357259,-0.970361,-0.350834,0.219768,-0.605011,-0.039546,0.547535,-0.116555,-0.308732,0.395287,-1.074652,-0.246924,-0.429261,-0.554531,0.349815,0.284979,-0.475536,0.624068,0.714562,-0.745577,-1.366381,-0.200763,-0.419136,-0.035537,0.185165,0.774719,-0.442101,-0.653839,1.461299,-1.153687,0.802497,-0.619922,-0.893367,0.218337,-0.290830,-0.297890,-0.469678,0.493790,-0.908536,1.140270,0.367880,-0.098163,-0.297059,-1.086053,-0.258816,0.523253,-1.013632,0.766143,0.512550,-0.361632,0.260369,0.271171,0.356694,0.053734,0.244571,-1.632013,-0.342226,-1.276086,1.579520,-0.427511,1.325697,0.544538,1.173631,1.841803,0.469459,-0.028199,0.310516,0.671445,0.136331,0.458993,1.513373,0.702917,-0.487471,1.688718,1.156916,0.550684,-0.252159,1.445293,0.164231,0.918005,-0.472108,-1.409003,-0.590385,-0.353769,-0.279417,0.205196,-0.452817,1.252103,0.269125,-0.655068,0.103205,-0.703471,-0.408351,0.142209,0.457487,-0.978878,-0.686689,1.082209,-0.090924,1.078984,0.675030,-0.565004,-1.421235,0.104172,-0.103735,0.376939,-0.328835,0.059285,-0.472523,0.061006,-0.318777,0.355964,-1.188300,-0.934091,-1.032864,-0.330132,0.338094,-0.307741,0.110321,-1.132155,-0.428726,-0.145872,0.998141,-0.180721,0.321913,0.749170,0.338206,-0.485576,0.815360,0.091583,-0.155154,-0.151575,-0.777891,-0.760338,-0.082395,-0.573442,0.819493,-0.384922,0.289702,-0.364256,-0.619812,-1.267124,0.802813,-0.134723,-1.013256,-1.142475,0.394192,0.255668,-0.760526,-0.191629,-0.348074,0.586604,-0.555008,-0.189338,-0.042461,-1.478240,0.957046,-0.519450,0.213725,-0.392483,-1.247413,-0.739220,-0.355667,-1.040015,-0.381552,0.368470,-0.063569,-0.417053,-0.607933,-1.797468,1.028993,0.649972,-0.685560,-0.055871,-0.348667,-1.022217,0.435325,-0.021934,0.206775,0.281371,1.339089,1.527762,0.464411,0.813385,0.299578,0.806956,-0.234576,0.296783,-0.711672,-0.238610,-0.694714]'::vector, '685fd441523249d30aa4966dbf79ae1b551d507f8ed0c3c2b6d44c6b97659fe9', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-fastapi-pydantic-validation';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '제너레이터는 `yield`를 사용해, 전체 결과를 한 번에 리스트로 만들지 않고 값을 필요할 때마다 하나씩 계산해서 내보내는 함수입니다. 큰 데이터를 다룰 때 메모리 사용량을 크게 줄일 수 있습니다.

```python
def load_rows_list(path):
    rows = []
    with open(path) as f:
        for line in f:
            rows.append(line.strip())
    return rows  # 파일 전체를 메모리에 다 올려야 반환할 수 있다

def load_rows_generator(path):
    with open(path) as f:
        for line in f:
            yield line.strip()  # 호출 시점이 아니라 for 루프가 값을 요청할 때 실행된다

# 100만 줄짜리 파일이라도 한 줄씩만 메모리에 올라간다
for row in load_rows_generator(''big_file.csv''):
    process(row)
```
`load_rows_list`는 함수를 호출하는 순간 파일 전체를 읽어 리스트에 담으므로, 파일이 크면 그만큼 메모리를 차지합니다. `load_rows_generator`는 `yield`를 만나는 순간 실행을 멈추고 값을 하나 돌려준 뒤, 다음 값이 요청될 때까지 그 지점에서 대기합니다. 그래서 `for` 루프가 몇 번째 줄까지 갔든 메모리에는 항상 한 줄 분량만 있으면 됩니다. 대용량 로그나 CSV를 처리하는 배치 작업에서 특히 유용한 패턴입니다.', '[-0.139547,1.288729,-3.407634,-1.446471,1.277373,-0.920064,0.120854,0.815476,-1.418432,-0.701255,0.096267,0.368544,1.607857,-0.226245,0.462669,-0.124563,-0.351416,-1.089719,0.270784,1.011086,0.037247,-0.362512,-0.761329,-1.066401,1.484408,0.632536,-0.167161,-0.365898,-1.162922,-0.168353,-0.303016,-0.963451,-0.038340,-1.614023,-1.674968,-0.217328,0.584737,0.029222,1.914338,-0.178832,-0.102054,-0.519779,0.894002,-0.407806,-0.063436,-0.358071,0.747319,0.328414,0.124794,-0.926771,0.692224,0.581266,0.068675,-0.650310,1.397382,0.919294,-0.152333,-0.330103,0.127360,0.239191,0.396569,1.038421,-1.274746,0.606534,0.830321,-0.686520,0.503773,0.436966,-0.244618,0.053134,1.718613,0.602473,-0.256788,-1.621594,0.082440,-0.388426,-0.982703,-0.482127,-0.817543,0.883366,-0.036974,0.491427,0.761265,0.781442,0.610548,0.233764,0.342628,0.602456,0.481695,1.298199,0.367147,-0.448469,0.212280,0.015558,-1.305856,-0.043923,-0.393570,0.204317,-1.182704,-0.755712,0.672745,0.064012,0.627324,-1.321479,0.216915,0.948201,0.428523,0.060660,-0.035612,-0.014048,-0.481935,1.423715,-0.503839,-0.405067,0.407139,-0.191146,1.329184,0.394585,-0.435484,0.828860,0.638213,-0.335687,-0.211737,1.217160,0.703371,1.300075,-1.110130,1.076339,1.028782,-0.582348,0.565142,-0.714490,-1.212842,0.100599,0.829902,0.309404,-1.303943,0.494495,-0.029207,-0.164643,0.068111,0.569014,0.108973,-0.582880,-0.168508,-0.468149,-0.204140,-0.266529,-0.468253,0.679027,0.143937,0.799305,-0.557006,-0.075232,0.729453,-0.192157,-0.490084,-0.904967,-0.768422,0.304620,0.792134,0.634382,-0.364646,0.301446,-0.957259,-0.815357,1.285653,0.086804,-0.788917,0.516553,-1.180148,-0.847124,0.186046,-0.190721,-0.276149,-0.454773,0.545666,-0.607252,1.274770,0.282041,0.410762,-1.278301,2.180542,0.392463,-0.724389,-0.310386,0.178269,-0.603021,-0.540942,-0.371714,0.239691,1.119174,-0.680807,-0.285016,-0.457417,-0.938692,0.350069,-1.304604,1.167328,-1.433213,-0.786253,-0.622389,-0.480839,0.136745,-1.063911,1.411835,0.188354,0.369231,-0.152163,0.360488,1.576325,-0.262245,0.342092,0.548460,0.175416,-0.871162,-0.379124,-0.662264,-1.123044,-0.233897,0.975506,-0.704951,-0.034613,0.959026,0.678579,0.341183,-0.457294,0.299183,-0.125880,0.164790,-0.146724,-1.209092,0.212009,0.110924,0.054852,0.156949,0.541248,1.776801,-0.044587,-0.290045,0.240505,-0.013212,0.160861,-1.053614,-1.175916,0.248656,0.047221,-0.683185,-0.241022,0.846369,0.066640,0.153200,0.542176,1.274814,0.992693,-0.114055,0.230562,-0.068902,0.631870,-0.164933,-0.267776,-0.787813,0.471451,-0.440455,-1.065239,-0.224374,-0.795371,-0.184383,-0.268487,0.262331,-0.176762,-0.207460,0.526841,0.545895,0.434857,0.008280,0.628227,0.541846,-0.362030,0.365364,0.326604,-1.070354,-0.334633,0.806118,-0.687228,-0.017584,-0.083347,-0.333477,0.147262,1.182321,0.103941,-0.751453,0.373181,-0.124147,-0.235690,0.140377,1.237913,-0.026794,0.106344,-0.948257,0.441707,0.698557,0.833414,0.326132,0.211537,-0.288152,-0.088249,-0.179139,0.836908,-0.259577,-0.927975,-0.523635,-0.111030,1.003253,-0.262490,0.112967,0.842337,0.677346,0.939642,-0.414647,-0.352005,-0.721594,-0.114485,-0.230386,-0.553584,0.280098,-0.457114,0.973712,0.436665,-0.242460,0.049840,0.640316,0.087940,-1.086864,-0.276420,1.129533,0.345124,0.501244,0.144381,0.481169,0.244590,-0.143197,0.019477,0.230818,-0.527791,0.145210,-0.702082,-0.205266,-0.069551,0.791168,-1.087084,0.343830,-0.046788,0.405582,0.134847,0.402586,0.648680,-0.516529,-0.154955,-0.063891,0.894307,0.370915,0.577244,0.351654,-0.345255,0.843983,1.005708,0.423191,1.121239,-0.341034,-0.524271,-0.473441,0.122753,0.564968,-0.755237,0.434545,-1.124895,0.020394,-0.911267,1.288083,0.449408,-1.050577,-0.939152,1.047620,-0.170682,-1.485201,-0.237642,-0.373159,0.652087,0.462226,-0.245791,-0.162783,-0.681045,0.184381,0.342295,-0.702556,0.279133,0.902347,-0.741152,0.295177,-0.371491,-0.553302,0.587166,0.059345,-0.798508,0.123595,-0.141558,-0.357910,0.262517,0.398473,0.279903,-0.414529,0.161335,-0.951110,-0.210528,0.646784,1.775456,1.253315,-0.277647,-0.215523,0.241427,0.701343,0.243466,-0.497515,0.287391,1.040732,0.079085,0.448093,0.295924,-1.998126,-0.299964,1.451914,0.834755,-0.680070,-0.641722,1.090189,0.091218,0.884162,-0.739673,0.479666,0.817499,-0.757722,-0.625457,-0.103610,0.496664,0.979054,1.493311,-1.811417,-0.679893,-0.387304,-0.102274,0.132080,0.476772,-0.450758,1.940661,-0.466546,-0.164205,-0.774151,0.206075,0.636047,0.272420,1.009156,-0.666924,-1.175951,-0.056700,0.028820,-0.134147,-0.651270,0.904820,0.995367,-0.665080,0.010921,0.397669,-1.162314,0.858110,-0.030483,-0.021060,0.551603,0.532021,0.814084,-0.138884,-1.178367,-1.911643,-0.485941,0.109430,1.038909,0.902627,-0.338465,0.906536,-0.542601,0.857458,1.051786,-0.060290,0.291492,0.405363,-0.407071,0.526662,1.051129,0.436085,-0.330999,0.201275,0.078473,-0.109478,-0.128197,0.479370,-0.165526,0.904701,-0.866693,-1.314232,-1.116617,-0.708200,0.626300,0.554193,-0.181933,0.428527,-1.336099,0.914439,0.018467,-1.274315,0.773747,1.189124,-1.084573,-0.022553,-1.038080,-0.467412,0.088088,-0.791782,-1.858694,0.948082,-0.438354,-0.052504,-0.558352,-0.288941,-0.432042,-0.605543,-1.131431,0.714134,0.905599,0.307934,-0.427705,0.315724,0.301938,-0.350146,0.189755,-0.063497,-0.788642,0.247019,-0.295670,-0.375786,-1.577927,0.335670,-0.286636,-0.109262,-0.541281,0.111065,-1.125712,-0.087065,-0.861720,-0.055047,-0.234425,-0.435759,-0.174450,0.482587,0.091553,0.834687,-0.746283,-0.476755,0.404846,-0.551956,1.286960,-0.288649,-1.396765,0.928986,-0.124894,-0.807415,-0.002473,0.832460,-1.129065,-0.889870,-0.905122,0.780034,-1.286736,-0.131565,0.925987,-0.505006,0.714892,0.288777,-0.549394,0.593764,-0.765642,-0.967036,0.475094,0.958686,0.432584,-0.090175,0.985007,-0.750229,-0.825142,0.208673,-0.821282,-0.420715,1.169346,1.276692,-1.184039,0.123594,0.189456,-0.791425,0.850161,-0.754340,-0.479593,0.319897,-0.102829,-0.805453,-0.078574,1.122266,-1.062034,0.953675,0.423977,0.264846,-0.813278,-0.411271,-0.393149,0.803351,-0.542899,1.126328,0.400263,-1.112863,-0.299813,0.695130,1.115838,-1.041691,0.642550,-2.244806,-0.293596,-0.780273,1.053276,-1.058115,1.149640,0.622431,1.675434,0.907463,0.010248,0.057429,0.020504,0.069492,-0.981453,0.074148,0.445120,0.659310,-1.137228,0.931222,1.259434,0.536105,0.266510,0.723637,0.403260,0.510110,-0.178121,-1.166560,-0.163695,0.520005,-0.108581,-0.150299,-0.238836,0.766069,-0.327492,-0.363793,0.048092,-1.076198,-0.578015,0.664795,0.882418,0.586323,0.359270,0.922389,0.528147,0.414404,1.026733,-0.678567,-0.820840,-0.452808,-0.206776,0.628059,-0.415828,0.505080,-1.390219,-0.013192,-1.216703,-0.262255,-0.945090,-0.879677,0.419424,0.420830,0.346946,-0.869440,1.028113,-0.097674,-0.692156,-0.072118,1.970782,-0.261141,0.804074,-1.159217,0.260606,-0.255138,-0.196289,-0.396278,0.359647,-0.400021,-0.070149,-0.056249,0.105996,-0.292708,1.708755,0.033192,1.031129,-1.027103,-0.314128,-0.794897,1.329497,0.346648,-0.910712,-0.819877,1.371649,-0.157341,0.041571,0.249374,-0.707555,1.004107,-0.394809,0.094336,-0.861916,-0.420435,0.316569,-0.635821,0.321303,-0.396732,-0.256770,-1.598083,0.270560,-0.292673,0.032023,-0.107265,0.418390,-0.187081,0.139530,-0.931055,0.851038,0.272548,-0.096844,0.786533,-0.919120,-0.581582,0.851468,0.800892,0.024746,-0.625727,1.071100,0.871090,0.591532,0.236304,0.042964,-0.325193,0.263864,0.393968,-0.745086,-1.260111,-1.175332]'::vector, '0f8593e62ec0f3500ff58663261ad6cf17e5367cdca048685389151c7e2f5c90', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-generators-yield-memory';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '캐시-어사이드(cache-aside)는 가장 흔히 쓰는 캐싱 패턴입니다. 읽을 때는 캐시를 먼저 확인하고 없으면(cache miss) DB를 조회해 캐시에 채워 넣고, 쓸 때는 DB를 갱신한 뒤 해당 캐시를 지워 다음 읽기에서 새로 채워지게 합니다.

```python
import json
import redis

cache = redis.Redis()
CACHE_TTL_SECONDS = 300

def get_product(product_id: int) -> dict:
    key = f''product:{product_id}''
    cached = cache.get(key)
    if cached is not None:
        return json.loads(cached)

    product = db.query(Product).get(product_id)
    data = {''id'': product.id, ''name'': product.name, ''price'': product.price}
    cache.set(key, json.dumps(data), ex=CACHE_TTL_SECONDS)
    return data

def update_product_price(product_id: int, new_price: float) -> None:
    product = db.query(Product).get(product_id)
    product.price = new_price
    db.commit()
    cache.delete(f''product:{product_id}'')  # 캐시를 갱신하지 않고 지운다
```
`update_product_price`가 캐시 값을 새 값으로 덮어쓰는 대신 아예 지우는 이유는, DB 트랜잭션이 커밋되기 직전에 다른 요청이 캐시를 먼저 갱신해버리는 경쟁 조건을 피하기 위해서입니다. 캐시를 지우기만 하면 다음 `get_product` 호출이 DB에서 최신 값을 다시 채워 넣습니다. `ex=CACHE_TTL_SECONDS`로 TTL을 걸어두는 것도 중요한 안전장치인데, 삭제 로직에 버그가 있어 무효화를 놓치더라도 오래된 캐시가 영원히 남지 않고 일정 시간 뒤 자동으로 사라지게 합니다.', '[-0.089701,0.788326,-2.602710,-1.681232,1.267041,-0.197835,0.172475,1.085790,-0.521802,-0.366560,-1.421501,1.665528,1.613307,-0.792946,0.174485,0.074314,-0.460356,-0.449272,-0.389514,1.598157,-0.257836,-0.381017,-0.696946,-1.608547,1.589136,0.291224,-0.388602,0.440311,-1.550153,0.895645,0.021114,-0.141546,-0.015447,-1.209692,-1.046197,-0.930952,1.410601,-0.816502,0.435659,-0.374757,-0.046378,0.586278,0.742759,-0.278938,0.914994,-0.156138,0.577326,-0.104714,1.464051,-1.260957,0.564582,0.187311,-0.019211,-0.306083,1.217463,0.397548,0.018750,0.062786,0.013501,-0.969801,1.164406,0.537334,-0.411263,0.822688,0.573882,-0.918812,-0.019875,1.371169,-0.091585,-0.007250,0.636204,1.103102,-0.879179,-0.010304,-0.141158,-0.093525,-1.421048,-0.304608,-0.402352,1.042147,-0.119311,0.238359,1.442678,-0.388017,0.614925,0.369568,-0.865982,0.685819,-0.305878,0.553128,-0.493684,0.154859,0.388249,-0.145284,-0.390607,0.561962,0.653725,0.287852,-1.682197,-0.619374,0.310979,-0.354899,-0.788600,-1.224204,0.201792,0.792083,-0.236750,0.539766,-0.766509,0.469125,-0.358936,0.721435,-0.388766,0.160221,-0.074904,-0.134230,1.293054,0.062423,0.078128,-0.497896,-0.938239,-0.142243,-0.465401,0.967754,1.001279,0.335272,-1.145127,0.535536,0.562139,-0.775221,-0.734669,-0.127072,-0.700534,0.425952,-0.052437,-0.081834,-0.622225,-0.270449,-0.135995,-0.538827,0.049307,1.245234,-0.057919,-0.795533,0.253431,-1.475611,0.179213,-0.092725,-0.841755,-0.161441,0.158760,-0.020613,-0.192014,0.290929,0.402992,-0.183952,0.164064,-0.343546,0.578695,0.491588,0.876101,0.554255,0.015089,1.128561,-0.818258,-0.604218,1.401588,0.742081,0.154946,0.701756,-0.648853,-1.107934,-0.497102,0.114144,-0.625061,0.905335,0.735578,-0.365445,0.544110,-0.280945,-0.194652,-1.005469,2.155147,1.707778,-0.464058,-0.475718,-0.461280,0.129532,-0.418676,-1.186183,0.493551,0.062603,-0.292659,-0.068584,-0.959898,-0.640968,0.075566,-0.874416,0.650973,-1.176402,-0.752464,-0.517710,-0.656755,0.107170,-0.593814,0.528458,-0.229918,0.798600,-0.226951,1.001195,1.397403,-0.139464,-0.309087,0.666914,0.549776,-0.598273,-0.339320,-0.246812,-0.352991,-0.116875,0.110012,-0.225465,0.784226,0.249018,0.860097,0.809286,-0.070486,0.092136,0.010846,-0.015987,-0.581501,-1.972196,0.429204,-0.059950,0.648634,1.300572,0.014520,1.452328,-0.216316,0.674166,-0.493532,0.182903,-0.270070,0.458078,-0.819547,0.032288,0.335498,-0.479940,-0.412576,0.373323,-0.291957,0.071401,0.347350,-0.610631,1.065125,-0.370001,0.808183,-0.481553,0.323041,0.009920,-0.049425,-1.302012,0.660058,-0.134415,-0.253571,-0.691717,-0.765020,-0.662382,0.384849,-0.215990,-0.093752,0.409504,0.583025,0.864628,0.192350,0.713022,0.651959,-0.269740,-0.635823,0.731081,-0.449459,-0.361575,0.216696,0.724490,-0.705300,0.836317,-1.136181,0.044902,0.379694,0.301958,0.618085,-0.353257,-0.418296,0.852304,0.970262,0.650773,0.897306,-0.478449,0.614564,-0.152012,1.156295,0.912086,1.082419,-0.153894,-0.310523,-0.237838,0.567241,-0.565752,0.213260,-0.737477,-0.929768,-0.152118,-0.388642,0.751707,-0.290121,0.728499,0.521870,-0.175609,1.299061,-0.423976,0.177749,-0.874339,0.240985,-0.208602,0.528657,0.794785,-1.258684,0.734996,-0.184814,-0.416560,-0.044365,0.436643,0.399370,-0.937607,-1.157399,0.685977,0.139524,0.251948,-0.108627,0.581704,1.006684,0.283887,0.513071,-0.600374,-0.223987,0.420557,-0.447632,0.049705,0.608225,-0.021534,-0.544976,0.141837,-0.175660,-0.021015,-1.048414,0.365212,-0.085696,-0.148395,0.348289,0.444048,0.943911,-0.436026,0.708357,0.087978,-0.209008,0.679255,0.692549,0.206169,0.540683,-0.461017,-0.190901,-0.265018,-0.246337,-0.288841,0.906596,-0.446583,-0.660967,0.103141,-0.694250,0.963866,-0.205568,-0.612408,-0.266610,0.397114,0.801749,-1.580292,-0.234643,0.084782,-0.410386,0.643502,0.042848,0.260689,-0.551000,0.582238,0.570892,-0.607468,0.192821,0.468177,-1.021870,0.408551,-0.253780,-0.391701,-0.177206,0.089437,-0.323020,-0.072604,0.069287,-0.426036,0.092209,0.091915,-0.558377,0.026956,-0.102879,-0.402203,-0.269707,0.381666,1.086819,1.117077,0.191613,-0.437067,0.263094,0.817975,0.264910,0.356434,0.435110,0.429136,0.465914,0.258952,0.375463,-1.670205,0.192346,0.526446,0.940002,-0.045797,-0.603843,0.494438,0.889362,1.121506,-0.587160,0.728472,0.537860,-0.625014,-0.655923,-0.302298,-0.067722,1.380849,1.193881,-1.732178,-0.757201,-0.406952,0.068067,0.528510,0.233956,-0.088125,1.198379,-1.096301,-0.644515,-0.364424,-0.356751,1.156652,-0.203657,0.377748,-0.744142,-0.284415,-0.231405,-0.693571,0.809798,-0.487187,0.677878,1.064844,-0.602730,0.647413,0.806091,-0.084080,1.201406,1.022270,0.159106,0.667853,0.852443,1.206084,-0.244036,-0.718853,-1.022806,-0.670165,0.046538,0.522992,0.694006,-0.519055,0.516748,0.392342,0.644085,0.386276,0.803575,-0.622456,-0.146566,-0.353136,-0.932201,0.958818,0.166627,0.638142,0.250248,0.219725,-0.600436,0.775997,0.364697,0.175673,0.400462,-0.863726,-1.300804,-0.552094,-0.454634,0.816236,0.306415,0.484833,0.988142,-0.527503,1.218822,-0.621748,-1.357157,-0.419586,0.950357,0.453417,-0.178916,0.006511,-0.754600,-0.265286,0.277724,-0.588808,0.152710,-0.434606,-0.057465,0.340495,-0.413214,0.029192,-0.398946,-1.403758,-0.699485,1.115484,0.361891,-0.515134,-0.133960,0.492712,-0.874227,0.423076,-0.184667,-0.236351,0.204154,-0.370374,0.124204,-2.172172,0.800433,-0.665753,0.340041,-0.805008,0.739191,-1.385535,0.078010,0.383119,-0.624698,-1.289318,-0.758135,-0.021424,1.019438,-0.185526,1.101493,-1.110207,-0.083523,0.354754,0.062548,0.940701,-0.412546,-1.778587,0.199606,-0.120341,0.293744,1.097176,-0.092434,-0.272615,-0.473761,-1.640679,0.155213,-0.945932,0.896542,0.944485,-1.009861,0.588382,0.288366,-0.645090,1.459316,0.064913,-0.055183,0.656777,0.284509,-0.468401,0.474517,0.102673,-1.031052,-0.915265,-0.371916,-1.026229,0.518586,1.167963,-0.186784,-0.928911,-0.448837,1.357524,-0.799771,0.372033,-0.762354,-0.874046,0.271897,-0.180930,-0.377145,-0.177255,1.155455,-1.365476,0.781939,0.568182,-0.510254,-0.295841,-0.715884,-0.739040,0.748833,-0.346841,0.917958,0.792957,-0.572325,-0.310032,0.055330,0.297288,-1.357632,0.367801,-1.759645,-0.878402,-1.655603,1.524168,-1.022619,1.189808,-0.105001,1.000127,1.237728,-0.951198,-0.017375,0.527112,0.439954,-0.262590,1.046139,1.095114,0.558649,-1.171077,1.384037,1.685748,0.547091,-0.383069,0.472547,-0.155728,0.202542,-0.314399,-1.418392,-0.436707,-0.640936,0.116117,-0.377440,-0.133429,0.518304,-0.340490,-0.237866,0.051624,-0.935055,-1.261611,-0.204679,0.258009,0.563185,-0.475137,0.640960,0.804571,0.940822,0.356481,-0.461659,-0.374517,-0.645437,-0.222851,0.386214,-0.626431,-0.053134,-0.892114,0.015844,-0.054036,0.011002,-1.072546,-1.202074,-0.672522,0.200675,-0.243049,-0.071238,0.524245,-0.161742,-1.297727,0.445216,0.978703,0.316514,0.246819,0.338203,0.399715,-0.574281,0.062413,0.434779,-0.094783,-0.345769,-0.142956,-0.056527,-0.154464,0.032533,0.632809,-0.018404,0.221695,-0.243277,-0.206945,-0.694898,1.121328,0.385897,-0.666982,-0.986668,0.459407,-0.558013,-0.288677,-0.036345,-0.371271,0.370947,-0.205029,0.056969,0.069951,-1.336777,1.069560,1.010154,0.657692,-1.576442,-0.732862,-1.371562,0.120849,-1.599116,-0.388944,0.474603,-0.046570,-0.138505,-0.799352,-1.114998,0.511837,0.968189,-0.620093,0.340101,-0.121185,-1.139720,0.621419,0.122933,0.133581,0.212165,0.713184,1.324563,0.475298,0.354859,0.444393,-0.249107,-0.146555,-0.009241,-0.829091,-0.442821,-0.735149]'::vector, '0a5f9cdbc78e1339422e17dc81a40a774b9c0b730547c98baa0bfb63acbda05b', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-redis-cache-aside-invalidation';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '타입 힌트는 실행 시점에 강제되지는 않지만, IDE 자동완성과 정적 분석 도구(`mypy` 등)가 잘못된 사용을 미리 잡아내게 해줍니다. 특히 함수가 여러 곳에서 재사용되는 웹 백엔드에서는 인자·반환값의 타입을 명시해두는 것이 버그를 줄이는 데 도움이 됩니다.

```python
from typing import Optional

def find_user_email(users: list[dict], user_id: int) -> Optional[str]:
    for user in users:
        if user[''id''] == user_id:
            return user[''email'']
    return None

email = find_user_email([{''id'': 1, ''email'': ''a@example.com''}], 1)
if email is not None:
    send_welcome_mail(email)
```
`find_user_email`의 반환 타입을 `Optional[str]`로 명시하면, 이 함수를 호출하는 쪽에서 `None`이 돌아올 수 있다는 사실을 코드만 보고도 알 수 있습니다. 이 힌트 없이 그냥 `str`이라고만 적었다면, 호출부에서 `None` 체크를 깜빡하고 `email.split(''@'')`처럼 바로 메서드를 호출하다 런타임에 `AttributeError`가 나는 실수를 저지르기 쉽습니다. `mypy`를 CI에 연결해두면 이런 실수를 배포 전에 잡아낼 수 있습니다.', '[-1.168073,0.380975,-3.003511,-1.831212,1.187520,-0.507450,-0.482391,0.626099,-0.744257,-0.980220,-0.729433,1.372692,0.648473,-0.753398,0.142664,-0.367850,-0.052468,-1.456928,-0.260166,1.545460,0.087252,-0.459393,-0.323303,-0.504920,1.441419,-0.298386,0.902274,0.073476,-1.188309,0.311217,-0.169292,-0.138572,0.576862,-0.926883,-0.654487,-0.186938,0.890936,0.757278,0.439587,0.758265,-0.165208,-0.422981,0.240989,-0.005669,0.833727,-0.661342,0.352304,-0.349012,1.213974,-0.545476,0.555308,-0.319734,0.224350,-0.654649,0.872068,0.521381,-0.597910,0.221609,0.104564,0.032503,1.576941,1.219525,-1.399646,1.085844,1.213641,0.096010,0.159255,0.236888,0.496090,-0.263179,0.936689,0.412937,0.365628,-0.183370,-0.134748,0.116200,-1.016920,-1.234398,0.251704,1.026206,0.154940,0.364099,1.310555,-0.933236,0.691459,-0.025719,-0.600209,-0.010347,0.059258,0.691424,-0.444768,-0.167884,0.056139,-0.882503,-0.540690,1.088353,0.022278,0.391013,-0.468269,-1.388828,0.733644,-0.191591,0.294721,-0.877829,0.574690,0.812806,-0.327720,0.100668,-0.429290,0.074750,0.008990,0.593238,-0.042892,-0.327897,0.970739,-0.175927,0.934341,-1.071555,0.066247,0.344341,-0.100190,-0.247019,-0.668353,1.156756,0.940393,0.346814,-0.871852,0.527195,0.324366,-0.781810,0.106416,-0.838618,-1.497576,-0.349212,-0.765852,-0.243429,-1.390559,-0.532558,0.904709,-0.033952,0.148757,0.674827,-0.770952,-0.895689,0.201074,-0.537743,-0.007247,-0.345492,-0.872285,0.738221,-0.207682,0.861349,-0.274815,-0.185852,0.293353,-0.495894,-0.364705,0.209183,0.205844,-0.195470,0.771585,-0.301934,0.481651,1.370280,-0.202311,-0.428636,0.690878,0.703267,-0.471139,0.490337,-0.140731,-1.208166,-0.004485,-0.231804,-0.820926,0.324871,0.233876,-0.842416,1.309609,0.003757,0.049067,-1.626231,2.358879,-0.205105,-0.494519,-0.869013,0.189107,0.112130,0.482953,-0.164062,0.492336,0.360422,-0.766568,-0.419372,-0.555353,-0.959325,0.644360,-0.179843,0.570066,-0.652594,-0.705806,-0.695532,-0.705278,-0.235359,-1.225787,0.604960,0.609102,0.668397,-0.528873,0.175615,1.156998,0.156400,-0.371953,0.476808,0.363659,-0.980597,-0.152655,-0.291574,-0.745797,-0.584828,0.772978,-0.038258,0.394012,0.364561,0.622267,0.849033,-0.353563,0.779381,-0.894048,0.558857,-0.095758,-1.231779,1.366209,0.128259,0.851936,1.122102,-0.289393,1.350091,-0.076164,-0.033883,0.019897,0.008250,0.276983,0.767801,-0.608384,0.382714,-0.436933,-0.747277,-0.206098,0.608517,-0.503951,0.481477,-0.544568,0.520149,-0.096746,-0.427463,-0.177667,-0.500479,0.920880,-0.158732,0.465715,-1.156976,0.231641,-0.092603,-0.981562,-0.871983,-0.093665,-0.299971,-0.102369,0.078842,-0.488314,0.328491,0.418014,0.104605,0.362723,0.460445,0.766218,0.642636,-0.794765,1.055684,0.398027,-0.719004,-0.682096,1.014341,-0.110530,-0.391566,-0.033609,0.280903,0.115721,-0.813697,0.933110,-0.448297,-0.628101,0.196366,0.275682,1.119884,0.691917,0.169183,0.483369,-0.171243,0.494215,0.969776,1.607000,0.112990,-0.081403,-0.853381,-0.535987,-0.250494,0.620689,0.113138,-0.918873,-0.086565,-0.125842,1.206547,-0.843358,1.179441,-0.084943,0.249341,0.663838,-0.019970,-0.121443,-1.381659,0.358904,0.002096,0.380478,0.834055,-0.592911,1.283873,-0.158209,-0.612410,-0.398847,1.135110,0.795889,-0.808376,-0.922707,1.202677,-0.061668,0.472303,0.260756,0.855612,1.242112,-0.133892,-0.304838,-0.144957,-0.139856,-0.489349,0.124432,-0.278379,0.975728,0.988556,-0.984375,0.852121,-0.747602,-0.046651,-0.425430,-0.490078,-0.049904,-0.147051,0.284241,0.306267,0.705313,0.290073,0.724792,-0.591303,-0.272009,0.972971,0.432695,-0.158107,1.209575,-0.243613,-0.273156,-0.845885,0.250346,-0.252845,-0.277114,-0.230751,-0.598614,-0.448860,-0.890753,1.179094,-0.973849,-0.799117,-0.513721,0.742339,1.106317,-0.885592,-0.196469,-0.118684,0.143213,0.569099,-0.144658,-0.451477,-0.768725,1.260519,0.557546,-0.503003,0.060124,0.709920,-0.399310,0.523959,-0.928328,-0.686048,0.300867,-0.465159,-0.007911,0.084400,-0.450809,0.316289,0.801611,0.192830,-0.838766,-0.316567,0.153057,-0.281347,-0.914340,0.656434,1.497546,0.028131,-1.031966,-1.085613,0.354740,-0.185887,0.374315,0.054839,-0.025580,0.149086,0.785480,0.507126,-0.231537,-1.662255,-0.574595,0.373010,0.636750,-0.137861,-0.701950,0.800484,0.745505,0.453101,-0.707979,0.677146,1.149688,-0.418082,-0.491795,0.293423,0.447329,0.703342,1.167837,-1.360719,-0.644330,0.284639,-0.026089,0.101568,0.512456,0.053098,1.702653,-0.420337,-0.106913,-0.523432,0.036372,0.892017,0.231177,0.214995,-0.582955,0.161527,-0.364837,-0.314996,0.662331,-0.348948,0.399083,0.691743,0.106533,0.738239,0.819504,-0.958963,0.465696,1.075455,-0.201083,-0.422298,-0.218335,0.889639,-0.555985,-0.560450,-1.478323,-0.268255,0.397098,0.793256,0.773537,-0.387999,0.323444,-0.407071,0.857194,0.870847,0.223725,-0.573678,-0.501515,-1.047235,-0.360875,1.435678,0.562335,0.086944,-0.095393,-0.003882,-0.566368,0.822492,0.878471,-0.315636,1.124097,-0.555101,-1.329078,-0.029953,0.696796,0.109974,0.835224,0.193984,0.056690,-0.596839,0.831308,0.426306,-1.558956,0.757544,0.896307,-0.673765,0.039895,-0.722970,-1.248141,0.419533,-0.503716,-1.529846,1.062847,0.090867,-0.110638,0.431632,-1.422869,-0.043690,0.027947,-1.297990,-0.681878,0.930473,-0.098865,0.187665,0.428492,-0.056577,0.044363,-0.230701,-0.332727,-0.673868,0.065814,-0.048786,0.017304,-0.646202,0.793327,-0.465846,-0.133448,-0.238573,0.598151,-1.065663,-0.378381,-0.043302,-0.243473,-0.993912,-0.440382,-0.343501,0.080897,1.037760,0.335019,-0.806975,-0.293774,-0.529371,-0.210572,0.639274,-0.438133,-1.488829,0.693037,-0.233510,-0.096893,0.254961,0.332608,0.181192,-1.210533,-1.687137,0.498631,0.050986,0.353703,0.990617,-0.612205,-0.198372,0.610243,-0.977879,0.215117,-0.136456,0.059949,-0.023246,0.122972,0.249907,-0.394270,0.810422,-0.190948,-1.650382,-0.055466,-0.363581,0.486690,0.015974,0.769408,-0.188031,-0.274181,0.363971,-1.124123,1.225149,-0.179540,-0.835203,0.104650,0.208005,-0.717995,-0.296069,0.446201,-1.010782,0.110237,0.463428,-0.050520,-0.457336,-0.802331,-0.702408,0.579453,-0.986265,1.388690,0.855449,-0.981226,-0.031817,-0.154266,0.794207,-0.463675,0.517471,-1.379916,-0.298151,-0.903323,0.419425,-0.026669,1.073857,0.904483,1.760293,1.530206,-0.327517,0.300643,0.680873,0.048533,-0.242805,0.627113,1.488969,1.035061,-1.037652,1.931483,1.997456,0.054982,0.299569,1.197388,0.075895,0.452957,-0.687916,-1.227067,-0.226186,-0.326258,-0.337218,-0.443337,0.239636,0.518345,0.509913,-1.052779,-0.465481,-0.227965,-0.667686,0.059503,0.600612,0.220525,-0.277283,0.443430,0.602666,0.647191,0.224922,-1.011266,-0.615145,0.236032,-0.016542,-0.346853,-0.114903,-0.226597,-0.430608,0.529649,-0.767985,-0.026665,-0.864204,-1.859653,-0.890623,0.097324,-0.269867,-0.639663,0.222553,-0.292481,-0.576993,-0.547198,1.843195,-0.261250,1.077029,0.511031,0.545912,-0.603164,0.101975,0.083474,0.003815,-0.219971,-0.477861,0.387951,0.606363,-0.409872,0.855203,0.451870,1.085220,-1.299286,-0.729918,-0.234193,0.424306,0.307431,-0.859587,-0.471009,-0.023654,-0.033271,-0.576200,0.536631,-0.144925,0.549667,-0.309725,0.128327,0.160573,-0.851552,0.598455,-0.204143,0.721420,-0.132420,-0.921152,-1.370618,-0.215511,-0.492941,0.715318,-0.023056,-0.167688,-0.289667,-0.635370,-1.188262,0.125032,0.401476,-0.312764,0.050563,-0.971459,-0.231086,1.288244,-0.133142,0.458588,0.127839,0.561872,0.943551,1.435955,0.013065,-0.371592,-0.374071,0.715125,-0.153016,0.054318,-0.852857,-0.947314]'::vector, '23251a80b05f7b386d56362828b611ddc1b440c3b9d61a4e221bd15d0cb6cfdf', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-type-hints-generics';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`async def` 핸들러 안에서 CPU 연산이나 동기 라이브러리 호출처럼 블로킹되는 코드를 그대로 실행하면, 그동안 이벤트 루프는 다른 어떤 코루틴도 진행시킬 수 없습니다. `loop.run_in_executor()`는 이런 블로킹 호출을 스레드풀(또는 프로세스풀)로 위임해, 이벤트 루프가 계속 다른 요청을 처리할 수 있게 해줍니다.

```python
import asyncio
import time

def blocking_task():
    print(''Start blocking task...'')
    time.sleep(5)  # 실제로는 CPU 연산이나 동기 라이브러리 호출
    print(''Blocking task complete.'')

async def main():
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, blocking_task)  # None이면 기본 ThreadPoolExecutor를 쓴다
    print(''Back to the event loop'')

asyncio.run(main())
```
`run_in_executor(None, blocking_task)`에서 첫 번째 인자가 `None`이면 이벤트 루프의 기본 `ThreadPoolExecutor`(기본 워커 수는 CPU 코어 수 기반)를 사용합니다. `blocking_task`가 실행되는 동안에도 이벤트 루프 자체는 막히지 않으므로, 같은 프로세스의 다른 코루틴들은 계속 진행됩니다. 다만 이는 GIL(Global Interpreter Lock) 때문에 순수 CPU 바운드 작업에는 한계가 있습니다 — 스레드로 옮겨도 GIL을 쥔 스레드 하나만 실제로 파이썬 바이트코드를 실행할 수 있으므로, 진짜 CPU 병렬성이 필요하면 `ProcessPoolExecutor`를 대신 넘겨야 합니다. I/O 대기가 대부분인 블로킹 호출(동기 DB 드라이버, 파일 시스템 접근 등)에는 스레드풀만으로도 충분합니다.', '[0.450417,1.680765,-2.565124,-1.145937,1.491665,-0.766503,1.035223,0.374194,-0.862230,-0.682370,-0.748404,1.326599,0.764303,0.574840,0.069675,-0.428487,0.215707,-0.868421,-0.176074,0.368364,0.214480,-0.519074,-0.523345,-0.678632,2.164378,1.338944,0.853271,-0.804425,-1.269487,0.257053,0.286614,0.291537,0.351341,-1.229869,-0.645062,-0.670408,0.589211,0.360536,0.236204,0.143060,-0.518304,-0.405384,0.982967,0.400426,0.485049,0.105307,0.502641,0.168026,0.741726,-1.586741,0.245795,0.477184,-0.345187,-0.167723,1.659529,0.351171,0.330609,0.864516,0.312710,-0.526562,0.653166,0.933374,-0.362756,0.234635,0.341415,-0.766108,0.691740,1.304102,0.354916,1.028079,0.951562,-0.102778,0.426517,-0.720197,0.172871,0.616102,-0.190287,-0.445485,0.343041,1.729568,-0.903335,-0.056093,0.860292,0.251992,0.576110,-0.123059,-1.383216,-0.622107,-0.386501,0.935113,0.149719,-0.088748,-0.266247,0.170341,-0.903158,0.979375,-0.256205,0.578074,-1.064910,0.142787,0.115280,-0.375032,0.386063,-1.409845,0.117193,0.977510,0.533790,0.019761,-0.727448,0.021722,0.017730,0.760183,-1.367786,-0.066516,-0.163761,0.018501,1.217916,-0.745405,-0.036234,-0.039022,-0.143176,-0.421243,-0.839849,0.673000,1.332483,0.523010,-0.603198,0.353456,1.128945,-1.272095,0.696159,-0.585981,-1.205454,0.605128,0.485516,0.392451,-0.793370,-0.020758,0.521791,-0.376849,0.441847,0.574138,-0.930490,-0.158098,-0.601537,-0.107361,0.197515,-0.742677,-1.144481,-0.491524,0.132815,0.683808,-0.755921,0.229551,0.986243,-0.507669,0.112057,-0.094080,0.450394,0.649596,1.470327,0.955758,-0.837795,1.353934,-1.018497,-0.333041,0.200684,1.076031,0.605376,0.408081,-1.319616,-0.698984,-0.635246,0.083595,-0.207959,0.617439,-0.168598,-0.767944,0.989038,-0.118215,0.117145,-1.419132,1.396136,0.547893,-1.043117,-0.102829,-0.385887,-0.294637,-1.309048,-0.033684,0.502161,0.543299,0.217212,-0.079213,-0.884837,-0.914701,0.622207,-1.133478,1.125634,-1.615145,0.131919,-0.718911,-0.229294,0.082758,-0.806523,0.541667,0.125419,0.641385,0.023327,0.617747,1.886393,0.164455,-0.206437,0.095351,1.042662,-0.945692,-0.391427,-0.204715,-0.548767,-0.316561,0.203729,-0.590107,-0.137674,0.483229,0.170021,-0.323601,-0.622609,0.028523,-0.228993,-0.013882,-0.217850,-1.854383,0.727701,-0.362296,0.745986,0.506283,0.521144,1.788599,-0.314948,-0.229433,-0.250882,0.550958,-0.318367,-0.392660,-0.792810,-0.189473,-0.436442,0.121527,-0.207734,0.519438,-0.422546,0.414823,-0.440686,0.743764,0.619173,-1.066460,0.429299,-0.365940,0.613338,-0.387572,-0.200689,-0.710774,0.269825,-0.427354,0.155281,-0.345342,-0.663795,-0.325121,0.500436,-0.168952,-0.301636,0.167124,-0.189434,0.764806,0.479189,-0.003704,0.481661,0.381837,-0.330121,0.635519,-0.835175,-0.572269,-0.550554,0.750534,0.211296,0.486036,0.589306,0.562830,0.596204,-1.049898,0.090373,-0.136956,-0.927412,0.878126,0.153221,1.188144,0.784190,0.168088,0.049858,-0.605949,0.398997,0.732067,0.783694,0.697837,0.053891,-0.675483,-0.121757,-0.147347,-0.247628,-0.791643,0.204610,-0.048930,-0.617316,0.309724,-0.966018,1.041481,0.421127,0.882864,0.157764,-0.070501,-0.180937,-0.057597,0.084888,-0.348742,-0.555222,0.457679,0.169210,0.722429,-0.187027,-0.013539,-0.077952,0.115229,1.127289,-0.928774,-0.508391,-0.567916,-0.238293,0.885720,-0.191196,0.632018,0.520640,-1.230135,0.255452,-0.318992,-0.624634,-0.029558,-0.154348,-0.628997,0.312532,1.113041,-0.639433,0.359585,-1.142097,-0.253813,0.634342,-0.223041,0.408494,0.385258,-0.186421,-0.548875,0.801647,-0.211236,0.594979,0.016354,-0.436379,0.348573,0.386881,0.464342,-0.630738,-0.334760,0.648048,-0.709630,0.442045,0.064458,0.175804,-0.462863,-0.938415,0.476516,0.319219,1.127723,0.424681,-1.035640,-0.568028,0.113945,0.405380,-0.762045,0.110031,0.379595,-0.032540,0.330090,0.099894,-1.012424,0.156593,0.469567,1.081554,-0.358747,0.866999,-0.296463,-0.559794,0.626945,-1.022452,-0.794178,0.461569,-0.032150,0.012904,0.918726,0.005993,-0.394568,0.909719,-0.226536,-0.356336,0.761442,0.120872,-1.162992,-0.481153,-0.244956,1.819080,1.226439,-0.269490,-0.099391,-0.498939,0.516289,0.138523,0.396681,-0.015455,0.639690,0.327869,0.490574,0.001276,-1.013071,0.101078,0.055465,1.343520,0.153729,-0.270407,0.138957,1.280719,1.068738,-0.802026,0.947978,0.748789,-0.407475,-0.641172,0.454202,0.205355,0.751918,1.318699,-1.084270,-0.222890,-0.167426,-0.053664,0.615749,-0.171279,-0.223950,0.058886,-0.419033,0.382430,-0.191460,-0.609465,0.916095,0.099724,-0.304497,-0.623880,-0.154217,-0.125864,0.084589,0.579502,-0.334582,0.550912,0.803880,-0.410139,-0.246858,0.357805,-0.661025,1.001141,0.334668,0.151287,0.269313,0.465776,1.342765,-0.125094,-0.128607,-1.000663,-0.014943,0.019824,0.965993,0.378530,-0.144493,-0.200498,0.817731,0.593315,0.619239,-0.063496,0.252343,0.467789,0.479181,-0.061477,1.270590,0.844700,-0.269029,0.194002,0.355316,-0.844516,-0.646632,0.361862,1.135569,0.361543,-0.096422,-0.627515,-0.290891,0.101830,0.292624,0.385224,0.082605,1.168569,-0.881069,0.611594,-0.818976,-1.154803,-0.270357,0.288498,-0.576536,-0.109888,-0.589852,-1.167934,0.002701,0.086562,-1.104603,0.160640,-0.133384,-0.492351,-0.587768,-0.738502,-0.719298,0.175809,-1.652287,0.481129,0.425064,0.112756,-0.108702,0.032465,0.363923,-0.124995,0.767005,-1.117929,0.044030,0.012729,-0.156578,0.226142,-2.027228,0.729711,0.285707,-0.546478,-0.328502,0.904161,-0.360616,0.557820,-0.535350,-0.481903,-0.687191,-0.109858,0.242373,1.122180,-0.368272,1.043217,-1.211529,-0.807010,0.262214,0.221135,0.990265,0.011713,-1.554797,0.081665,-0.132194,-0.292395,0.435506,0.374875,-0.406417,-0.309102,-1.276366,-0.244648,-0.479572,0.357414,0.534289,-0.101397,0.374604,-0.004525,0.072169,0.766906,-0.201756,-0.270691,0.622886,0.268125,0.372684,0.556805,1.044001,-0.356350,-1.566651,-0.214187,-0.886317,-0.127145,0.863797,0.177379,-1.048733,-0.929493,1.470499,-0.728624,0.507974,-1.371876,-0.259771,0.566419,0.218916,0.263826,0.100592,0.130626,-0.772182,0.590660,-0.254623,0.354535,-0.472336,-0.568466,-0.514064,1.161716,-0.305506,1.316982,0.659676,-1.028603,-0.458520,1.229199,1.121170,-0.695570,0.349792,-2.141484,-0.478791,-1.539984,1.076201,-0.812519,0.570894,0.331800,0.868985,1.400827,-0.060841,-0.466861,0.488305,-0.257974,-0.999154,0.988991,1.582458,0.398106,-0.560852,1.271039,1.545324,0.044926,0.124674,0.787233,0.199283,0.531081,-1.092085,-1.602807,-1.246917,-0.431831,-0.622192,-0.940569,0.091101,0.762805,-0.051828,0.166395,-0.036883,-0.608079,-1.477360,-0.445104,0.037847,-0.764134,-1.172180,0.277716,0.484283,0.410996,0.271700,-0.821482,-0.865805,-0.636986,0.292329,0.285204,0.224611,0.465224,-0.793451,0.301621,-0.806017,-0.378886,-0.090098,-0.875358,0.527287,-0.298243,-0.899456,-0.580013,0.598732,-0.366006,-1.091319,-0.579192,0.922474,-0.410894,0.842550,0.280184,0.525584,-0.666291,0.051690,0.278080,0.101472,-0.449955,0.405102,-0.305074,0.535876,-0.601794,0.842878,0.076025,0.021230,-0.354626,-0.429627,0.084124,0.668910,0.707602,-0.402131,-1.088252,0.591302,-0.546849,-0.249885,0.365551,-0.009486,0.657336,-1.422196,0.084082,-0.499028,-0.613715,0.485684,-0.449913,0.080494,-0.107937,-0.767843,-1.977720,-0.232459,-0.650315,-0.258500,-0.188674,0.190928,0.669832,-0.431751,-0.302510,-0.176112,0.351829,-0.436764,0.347256,-0.578446,-1.447192,0.302671,0.742853,-0.387634,-0.359270,0.298346,1.447396,0.783807,0.058420,-0.037060,-0.327093,0.426347,0.431439,-0.563142,-0.768851,-1.437236]'::vector, '934ec039277482efa86980c50f4a7cb99d2477259e8e55822c286a075b3d1a23', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-asyncio-run-in-executor-blocking';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`asyncio.gather()`로 수백 개의 외부 API 호출을 한꺼번에 실행하면, 상대 서버의 레이트 리밋에 걸리거나 우리 쪽 커넥션 풀이 고갈될 수 있습니다. `asyncio.Semaphore`는 동시에 실행 중인 코루틴 수를 지정한 개수로 제한해 이를 막습니다.

```python
import asyncio
import aiohttp

async def fetch_one(session, url, semaphore):
    async with semaphore:  # 세마포어를 획득해야 다음 줄로 진행한다
        async with session.get(url) as resp:
            return await resp.text()

async def fetch_all(urls, max_concurrent=10):
    semaphore = asyncio.Semaphore(max_concurrent)
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_one(session, url, semaphore) for url in urls]
        return await asyncio.gather(*tasks)
```
`asyncio.gather(*tasks)`에 넘기는 태스크는 1,000개일 수 있지만, `fetch_one` 안의 `async with semaphore:` 블록에는 최대 `max_concurrent`개(여기서는 10개)만 동시에 들어갈 수 있습니다. 11번째 태스크는 앞선 10개 중 하나가 세마포어를 반납(블록을 빠져나감)할 때까지 그 지점에서 대기합니다. 세마포어 없이 `gather`만 쓰면 1,000개의 요청이 순식간에 동시에 나가버려, 상대 서버가 429(Too Many Requests)를 대량으로 반환하거나 우리 쪽 이벤트 루프의 파일 디스크립터가 고갈될 수 있습니다. `max_concurrent` 값은 상대 API의 레이트 리밋과 우리 쪽 네트워크·메모리 여유를 함께 고려해 정해야 합니다.', '[0.161894,1.070723,-2.721865,-0.920595,1.526611,-1.451052,0.180881,0.779051,0.327534,1.315342,-0.722131,0.138396,1.749541,0.533443,0.065116,-1.072406,-0.308795,-0.723831,-0.546496,0.519212,-0.345915,0.001546,0.838334,-0.503044,1.321678,0.840139,0.477912,-0.019055,-1.051002,0.179482,-0.346301,-0.288488,0.523715,-0.334780,-0.523892,0.282464,0.884215,-0.641541,-0.356379,0.505482,0.191310,-1.271804,1.023061,0.181569,0.795367,0.034449,0.526244,0.427475,0.520041,-1.206561,0.095568,0.261133,-0.551457,-0.118874,1.987614,0.438426,0.507520,-0.196438,0.229345,-0.746910,0.899966,1.084242,-0.157164,0.950312,1.083985,-0.027788,0.317814,0.743173,-0.478726,0.339247,0.878561,-0.524744,0.114939,-0.737447,-0.370484,0.007578,-0.353488,-1.574672,-0.475214,1.636831,-0.462315,-0.130026,0.543136,-0.334196,0.633686,-0.683901,-0.185746,-0.247856,-0.299521,1.019840,0.124085,-0.478895,0.343757,-1.380689,-1.174031,0.689738,-0.213446,0.399305,-0.368567,-0.166559,0.384951,0.538249,0.294585,-0.403396,-0.447847,0.240706,-0.074631,0.322518,0.235749,-0.711479,-0.254721,0.410296,-1.329517,-0.460376,-0.012133,-0.732352,0.465606,0.770188,0.180485,0.067922,0.444077,-0.882410,-0.887415,1.351083,0.961284,1.622244,-0.550617,0.977462,0.991424,-0.496450,0.603589,-1.056400,-1.276580,0.392334,0.604932,-0.074449,-1.571163,-0.359569,0.219351,-0.427517,0.792116,0.028550,0.276662,-0.436572,-0.621297,-0.196579,0.869565,-0.075935,-0.402526,-0.099078,-0.430906,0.652835,0.316914,-0.096869,0.569317,-0.892588,0.049062,-0.343767,-0.047188,0.346662,1.276994,-0.104092,-0.839650,0.493046,-0.770841,-0.470816,0.969320,0.783745,-0.113341,0.588232,-0.673557,-0.985498,-0.349763,-0.163263,0.141531,0.720681,1.222778,-1.449976,0.700890,-0.109121,0.355345,-1.849427,1.038312,0.310470,-1.069142,-0.110171,-0.299183,-0.464182,-1.228065,-0.187155,-0.181795,0.178703,-0.514573,0.324837,-0.918181,-0.032632,0.816714,-1.120981,0.087794,-0.769070,0.352969,-0.271409,-0.587369,-0.166268,-1.071623,1.081895,-0.106946,0.119096,-0.152340,0.367805,1.404972,-0.134954,-0.073443,0.394425,-0.753617,0.197115,0.104898,-0.820503,0.142844,-0.318769,0.941068,-0.492923,-0.461877,1.257679,0.426711,0.140401,-0.530463,0.302174,0.071625,0.232307,-0.485748,-1.700471,0.478744,-0.118077,0.287457,0.975024,0.407530,1.964225,-0.094200,-0.917717,-0.626965,0.087194,-0.045500,-0.513668,-1.501847,0.465123,-0.314503,-0.430313,-0.755234,1.224254,-0.279011,0.486361,0.050042,0.616193,0.523303,-1.004177,1.026598,0.484689,-0.036028,0.003475,-0.297326,-0.887583,0.654880,-1.053573,0.195032,-0.389975,0.244163,-0.039025,-0.006668,-0.316619,-1.039077,-0.163575,0.263437,0.474753,-0.523422,0.244602,0.416407,0.346042,0.072859,0.074859,-0.679286,-0.675487,-0.112962,0.365081,-0.284009,0.059386,0.837851,0.813949,0.049801,0.362015,0.792450,-0.378594,-0.755297,0.772296,0.026141,1.166305,0.807617,0.018383,-0.489178,-0.570566,0.345550,0.429663,1.205025,0.421561,0.456243,-0.211160,-0.354047,0.038780,0.208537,0.284707,-0.254400,-0.181826,-0.696257,0.990350,-0.095324,1.508173,0.648206,0.327672,-0.158974,0.014005,0.063543,-0.619530,-0.370114,-1.033472,-0.271306,0.399318,-0.108875,0.541353,-0.184367,-0.147993,0.266723,0.387451,1.331595,-0.862240,-0.535848,-0.005122,0.179330,-0.027454,0.021326,0.504116,0.143562,-0.619784,0.690652,-0.652737,-0.423960,0.567708,-0.064799,-0.083518,0.658163,0.622970,-1.326084,0.149880,-0.647311,-0.110701,-0.038873,-0.527642,0.054808,0.533035,-0.818146,-0.611572,1.097703,-0.129176,0.908236,0.699359,0.229505,-0.115298,0.578461,0.607433,0.689128,0.069072,0.091648,-0.996913,-0.333446,0.239449,-0.126873,-0.080070,-0.473034,0.211603,-0.282738,0.449489,1.068680,-0.798220,-0.386687,0.055803,0.719289,0.031781,0.290393,0.074597,-0.168929,0.367610,0.520202,-1.018426,0.439513,-0.406254,0.893991,-0.622023,0.262713,0.105250,-1.195803,0.694000,-0.209171,-0.710909,-0.146404,-0.257217,-0.203083,0.053735,-0.449110,0.264065,0.997887,0.040580,0.345507,0.525824,0.183979,-1.529122,-0.391375,0.364424,1.209156,0.278360,-0.151260,0.378449,-0.241550,0.266330,0.111195,0.077097,-0.405150,0.697195,-0.509620,0.874533,-0.033254,-0.365953,0.348373,0.486543,0.652496,-0.157515,-1.113195,0.413208,1.197126,1.352419,-0.098907,0.729545,0.563824,0.234461,-0.328786,-0.187361,0.837296,0.974905,0.732949,-1.142854,-1.058783,0.466743,-0.816702,0.178151,0.337710,-0.086987,1.150243,-0.923654,0.022047,0.855035,0.013395,0.868430,-0.013369,0.139168,-0.748997,-0.210810,0.607053,0.030912,0.269285,-0.291683,0.345129,0.797294,-1.144549,0.170192,0.478796,-0.758037,0.534933,-0.677878,-0.178659,0.720709,0.083571,0.664019,-0.178436,-0.851295,-1.645114,-0.334716,-0.749715,1.675475,0.012341,-0.446088,0.108049,-0.042387,0.039899,0.248232,-0.691579,0.025245,0.356597,-0.466226,-0.395952,1.415181,0.664776,-0.047244,0.520594,0.868252,-1.019139,-0.410444,0.204408,0.546198,0.385066,0.180700,-0.694027,-0.520007,0.085690,-0.227948,0.443069,-0.287218,1.433528,-0.560723,0.639246,-0.014248,-0.996341,-0.170996,0.853808,-0.174178,0.149452,-1.636255,-1.097661,0.346483,-0.554781,-0.200503,1.230902,-0.291080,-0.701749,-1.039691,-0.233879,-0.758838,0.392541,-0.527329,0.523719,1.100034,-0.136949,0.109185,0.738406,0.587810,-0.474254,0.574429,-0.297973,-0.961330,-0.227473,-0.246441,0.713334,-1.242293,0.643863,0.287203,-0.275046,-0.549204,0.426528,-1.399410,0.114354,-0.385713,0.177993,-0.821062,0.080614,0.130655,1.113148,-0.299917,0.163247,-1.528274,-0.295470,0.292478,0.354378,2.420522,0.596369,-1.237964,0.308162,-0.888084,0.127763,-0.057032,0.260110,-0.078538,-0.353975,-1.299209,-0.644889,-0.686795,0.494871,0.911221,0.040548,0.751683,-0.462480,0.176286,0.258820,-0.857260,-0.403882,0.196594,0.501325,-0.404921,0.302946,0.383313,-0.601531,-1.351235,-0.959005,0.153050,0.264269,0.480030,0.495578,-0.786596,-0.329454,1.261021,0.061431,-0.045037,-0.979708,-0.158719,0.054325,0.025360,-0.473274,0.325672,0.055958,-0.884254,0.894824,0.276880,0.475986,-0.639449,-0.164758,-0.894252,1.102316,-0.293601,0.864217,-0.244401,-0.492977,-0.799029,0.882045,1.110670,-0.612376,1.412997,-2.184340,-0.004488,-0.321318,0.432241,-0.883232,-0.244008,0.157176,0.905697,1.069994,-0.238803,-0.351771,0.901229,-0.041975,-1.591163,0.529861,1.475522,0.921867,-0.868469,1.479717,0.908102,-0.064657,0.122661,0.463404,-0.181532,0.192606,-0.864039,-1.044548,-0.461995,0.357633,-0.601145,-1.014877,0.510268,0.734335,0.062722,0.528962,-0.182119,-0.828725,-1.237947,0.606610,0.865236,-0.340608,-1.173703,-0.352004,0.185622,0.162826,0.140763,-0.467893,-1.214403,0.354777,-0.506928,0.713697,0.154161,0.744035,-1.091134,-0.652698,-0.228825,-0.590947,-1.234560,-0.731915,-0.067470,-0.263376,-0.511354,-0.492670,0.855642,-0.260035,-1.149511,-0.205474,0.640932,-0.707551,0.653986,-0.027104,0.285373,0.327457,0.011706,-0.077782,0.075200,0.072846,0.191547,-1.298427,0.966205,-1.044987,0.364633,-0.075842,0.679295,-0.998030,0.290469,-0.274385,0.217657,0.708114,0.328837,-1.325367,-0.556015,-0.560323,0.229327,0.866545,-0.468016,1.312331,-0.814481,0.283937,-0.135755,-1.070904,0.597515,0.204494,0.648185,0.136948,-0.727334,-1.778547,-0.866661,-0.748866,-0.218846,0.110695,0.017601,-0.035350,0.556545,-0.625116,0.337540,0.368619,-0.306455,-0.313623,-0.023885,-0.185468,1.057881,0.923594,0.086307,0.433010,0.626188,1.793421,0.761029,0.471733,-0.849342,-0.443004,0.176587,-0.265466,-0.432617,-0.697747,-0.666569]'::vector, 'a1ce92830ab54d73d517ac0ab3698d0ac94ff0bee27e7d29b1e68a0c33597619', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-asyncio-semaphore-connection-limit';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'Celery는 기본적으로 워커가 작업을 ''받는'' 즉시 브로커에 ack를 보냅니다(`acks_late=False`). 이 상태에서 워커 프로세스가 작업 도중 죽으면, 브로커는 이미 ack를 받았으므로 그 작업이 처리 중이었다는 사실 자체를 잊어버려 작업이 조용히 유실됩니다. `acks_late=True`로 바꾸면 작업이 ''끝난 뒤''에 ack를 보내므로, 워커가 죽으면 브로커가 그 작업을 다른 워커에게 다시 배정합니다 — 대신 최소 1회(at-least-once) 실행이 되어, 같은 작업이 두 번 실행될 가능성을 감수해야 합니다.

```python
from celery import Celery

app = Celery(''tasks'', broker=''redis://localhost:6379/0'')

@app.task(bind=True, acks_late=True, max_retries=3)
def charge_order(self, order_id: int, idempotency_key: str):
    if Payment.objects.filter(idempotency_key=idempotency_key).exists():
        return  # 이미 처리된 경우 재실행을 무해하게 만든다
    payment_gateway.charge(order_id, idempotency_key=idempotency_key)
    Payment.objects.create(order_id=order_id, idempotency_key=idempotency_key)
```
`acks_late=True`는 ''작업이 최소 한 번은 실행된다''는 것만 보장할 뿐, ''정확히 한 번만'' 실행되는 것은 보장하지 않습니다. 워커가 결제 처리를 끝냈지만 ack를 브로커에 보내기 직전에 네트워크가 끊기면, 브로커는 작업이 실패했다고 판단해 다시 큐에 넣고 다른 워커가 같은 결제를 또 실행할 수 있습니다. 그래서 `acks_late`로 유실을 막는 대신, 태스크 자체를 멱등하게 설계해 중복 실행이 안전하도록 만드는 것이 항상 함께 가는 짝입니다. 둘 중 하나만 있으면 ''유실은 없지만 중복될 수 있는'' 시스템이거나 ''중복은 없지만 유실될 수 있는'' 시스템이 됩니다.', '[0.260682,0.763949,-3.236371,-0.836426,1.375632,-1.900571,-0.024754,0.171308,-0.692898,0.372586,-1.199952,0.779799,1.299174,-0.123117,0.210230,-0.298189,0.351111,-0.325054,-0.652803,1.272987,0.183396,0.010766,0.107956,-0.979250,1.160765,0.161921,0.059514,1.027900,-1.078750,0.278221,0.380145,-0.496645,0.482398,-1.423116,-0.974392,-0.850365,1.010124,-0.343123,0.791370,-0.299380,0.656379,0.034867,1.249285,-0.337259,0.713260,0.306806,1.370630,0.506198,0.990476,-1.592630,0.001248,-0.630570,0.068387,0.121953,1.622883,1.289439,0.324470,1.678445,-0.331287,0.732924,0.463508,1.383864,-0.844392,1.087034,0.811947,-0.481875,-0.174043,0.766066,0.032836,-0.590015,0.733924,-0.477042,0.237079,-0.547380,0.320726,-0.254913,-1.106931,-0.779064,0.197122,1.254061,-0.603244,0.893497,0.241022,-0.378943,0.313563,-0.879550,0.320868,-0.314231,0.324821,1.064348,-0.632619,-0.704085,0.000800,0.350183,-0.807919,0.624004,-0.150138,0.540141,-0.650764,0.030699,-0.168317,0.176807,0.080863,-0.637474,-0.232445,1.122854,0.108976,0.274868,-0.033497,-0.178149,0.036891,0.684871,0.276601,-0.498977,0.914983,0.481626,0.960203,-0.237201,0.340280,0.469597,-0.010997,-0.722133,-0.250479,0.971551,0.413178,0.938867,-0.759674,0.916684,1.193261,-0.809083,0.500505,-0.324579,-0.767262,0.030471,-0.067869,-0.009340,-0.318184,-0.487843,0.439254,0.011388,0.027218,0.283863,-0.094644,-0.276068,0.254778,-0.698062,0.255549,-0.515420,-0.733286,-0.104384,-0.014702,0.457848,-0.361540,1.242173,0.197435,-0.256401,0.998432,-0.046792,0.861935,-0.086421,1.285713,0.341671,0.729980,1.066353,-0.376084,-0.656698,0.418067,0.952232,-0.706436,0.872564,-1.199486,-0.629184,-0.586863,-0.441701,0.430903,-0.241933,0.259036,-0.241759,1.331527,-0.575288,-0.019179,-0.765522,1.290178,0.835631,-1.175351,-0.743330,-0.256763,-0.515601,0.244048,-1.025383,0.256202,0.645935,-1.028130,-0.146855,-0.833049,-0.655679,0.628989,-0.190745,0.608617,-1.172798,-0.287633,-0.540052,-0.536385,0.595769,-1.259757,0.927708,-0.601180,1.154242,-0.242790,0.626618,1.422270,0.128729,-0.510657,0.544265,0.637174,-1.219339,0.450365,-0.746479,-0.881998,-0.568039,0.487506,-0.513980,0.967763,0.552752,0.469021,0.228743,0.166109,0.007084,-0.727035,-0.452436,-0.155227,-1.531203,0.445538,-0.217004,0.459977,0.386664,-0.479538,0.888295,0.369200,-0.123105,0.211285,-0.371801,0.330600,-0.331435,-1.146703,0.526403,1.230488,-1.081077,0.042030,0.420407,-0.578966,0.204251,0.020341,0.942415,0.727402,-0.307070,0.615861,0.019200,1.086612,0.143633,0.051724,-1.002592,1.254273,-0.855692,-0.390666,-0.620363,-1.373189,0.411953,-0.048388,0.354131,0.326790,0.425256,0.587163,0.107563,0.493752,-0.663711,-0.336307,0.013932,-0.604946,1.418817,-0.257625,-1.200787,-0.490108,0.203277,-1.259041,-0.143808,-0.693398,0.295748,0.118853,0.330464,0.114522,-0.105696,-0.056926,1.313723,-0.297404,0.684528,0.770014,0.441771,-0.189521,-0.451662,0.711121,0.469693,0.648033,0.503201,0.103273,-0.402861,-0.152958,0.488175,0.734322,-0.801833,-0.952451,-0.441400,-1.163446,0.082798,-0.285316,0.418473,-0.594255,0.733096,0.031578,-0.743946,0.568112,-0.972681,-0.337433,-0.212872,1.038244,0.209280,-0.943035,0.838739,-0.056454,-0.626613,-0.021897,0.372716,1.205786,-0.992434,-0.606991,-0.033046,0.020142,0.102553,0.100840,1.841484,0.629649,-0.109898,0.632765,-0.421373,0.032560,-0.321593,-0.520854,-0.152140,0.970768,0.595381,-0.815484,0.027206,0.115508,-0.287774,0.555853,0.330139,0.472571,-0.046135,-0.123405,-0.046518,1.509712,-0.132995,0.896288,-0.498466,0.061446,1.312616,0.456560,0.733936,1.000420,-0.530668,-0.488626,0.186024,0.029011,0.379668,0.106941,-0.936736,-1.652289,-0.094553,-0.420838,0.447000,-0.103685,-0.551967,-0.039192,-0.115555,1.098370,-0.662815,0.085935,-0.159812,-0.366420,-0.309412,0.062501,0.005653,-0.491487,0.503913,1.068198,-0.477453,0.811354,0.167046,-0.847204,0.077976,-0.491062,-1.033110,0.205229,-0.653260,0.056795,-0.412118,0.311730,0.359657,0.309773,0.295790,-0.157285,0.193646,0.180414,-0.672031,-0.130598,-0.168075,1.813025,1.186868,-0.413205,-1.047100,0.822205,0.755097,0.243711,-0.326710,0.427943,0.735829,-0.028223,0.782408,0.004386,-2.218146,-0.242449,0.936371,0.561021,-0.436082,-0.099698,-0.314057,0.193689,0.562484,-0.459135,0.768598,-0.014812,0.543208,-0.318173,-0.457408,-0.103017,0.707716,0.940594,-1.257218,0.087705,0.002256,0.187594,0.190383,0.680131,0.595424,1.957744,-0.265251,0.558537,-0.562159,-0.113497,0.137041,-0.176196,0.031253,-0.803215,0.081995,0.359306,-0.294376,1.232313,-0.761928,0.791155,0.791361,-0.735635,0.453659,0.519140,-0.343112,0.680753,-0.260636,-0.181176,1.008778,0.053790,1.639071,-0.174293,-1.628243,-1.463499,-0.380263,-0.205756,0.929068,0.722590,-0.145408,0.094215,-0.289525,1.060272,0.615225,0.428731,-0.274218,0.134961,0.325047,-0.748195,1.573033,-0.315422,0.177312,-0.906264,0.629614,-0.221640,-0.041286,-0.081153,-0.551162,0.179197,-0.463285,-0.974560,-0.503293,-0.132603,1.225614,0.778806,-0.207683,0.326800,-0.697594,0.337188,-0.641168,-1.191280,-0.313342,1.127888,-0.720823,0.057809,-0.216021,-1.000080,0.032515,0.565803,-1.383366,0.780708,-0.192683,-0.590250,-0.154189,-0.541316,-0.573885,-0.301293,-0.856346,0.121439,0.441746,0.001851,-0.176940,0.411255,-0.384040,-0.493453,0.034055,0.019094,-0.979217,0.015368,-0.088036,-0.344671,-0.994153,0.659704,0.144020,-0.098730,-0.694460,0.776738,-1.497629,-0.059289,-0.231291,-0.545271,-0.828144,0.672143,0.552046,1.011502,0.476624,0.788981,-0.669363,-0.274108,-0.106810,0.055248,0.710688,-0.541857,-0.987140,0.727589,-0.917487,0.467091,0.454823,0.011644,-0.223909,-0.911315,-1.099083,0.243300,-0.221722,0.684826,1.618204,0.193070,0.094319,0.500197,-0.767914,0.289615,-0.439139,-0.043593,0.777480,0.387394,-0.456694,0.241428,1.431400,-0.270368,-0.852862,0.002241,-0.843005,-0.106633,0.124362,0.578751,-0.642247,-0.282924,0.707832,-0.120684,0.991908,-0.523996,-0.492958,-0.252648,-0.164396,0.317497,0.101688,0.432775,-0.285974,0.499369,0.139042,-0.323701,-0.804943,-0.057164,0.092997,0.174214,-0.467021,1.166068,0.971840,-0.934057,-0.203901,0.496416,0.807093,-0.744682,-0.113128,-1.240610,-1.326930,-0.625740,0.974009,-0.509080,0.529046,0.320986,1.276175,0.845490,0.305765,0.124308,0.496324,0.919360,-1.305649,1.269672,0.895308,0.727352,-0.818872,0.950378,1.112762,1.425068,0.012196,0.874416,-0.892984,0.241591,-0.128973,-1.699367,-0.675545,-0.200293,-0.190906,-1.252199,0.485816,0.289914,-0.454263,-0.234949,-0.448849,-0.826565,-1.848891,0.438128,0.532175,0.250819,-0.840680,0.566472,0.053850,1.269396,0.809732,-0.294012,-0.791458,-0.235476,0.249540,0.842835,0.216574,-0.405673,-1.101659,-0.155363,-0.378963,0.851037,-1.978340,-1.265297,-0.713223,0.142388,-0.025588,-0.135235,0.335031,0.029676,-0.543748,-1.104321,1.008387,-0.036940,1.376535,-0.294244,-0.024672,-1.184701,0.120706,-0.835691,0.480562,-0.836422,0.146505,-0.569083,0.369911,-0.577241,0.702096,0.405007,0.767935,-1.535250,-1.275264,-0.592712,0.753520,0.816714,-1.032699,-1.178963,0.041178,0.261436,0.045238,-0.084217,-0.576964,-0.235846,-0.151115,0.305931,-0.164983,-0.980803,0.591279,-0.823361,0.443924,-0.901016,-0.632092,-0.658893,-0.619515,-0.963743,0.043233,0.130635,-0.114338,0.569530,-0.950350,-1.250085,0.146491,0.742892,-0.198766,0.333713,-0.807461,-0.964273,0.108249,-0.289081,0.495346,-0.263163,0.321068,1.083855,0.750499,0.460654,-0.148966,-0.220018,0.636289,-0.204925,-0.760895,-1.384239,-1.576349]'::vector, '02024ed01469cfde30920d1805d6f29e98825e0912ebb2788ca5dfb550e8ab45', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-celery-acks-late-at-least-once';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '두 요청이 동시에 같은 상품의 재고를 차감하면, 둘 다 재고가 1개 남은 것을 읽고 각자 차감해 실제로는 -1이 되어야 할 상황에서도 애플리케이션 레벨에서는 이를 감지하지 못하는 경쟁 조건(race condition)이 생길 수 있습니다. `select_for_update()`는 해당 행에 데이터베이스 수준의 잠금을 걸어, 한 트랜잭션이 끝날 때까지 다른 트랜잭션이 같은 행을 읽지 못하게(정확히는 잠금이 풀릴 때까지 대기하게) 만듭니다.

```python
from django.db import transaction

@transaction.atomic
def decrement_stock(product_id: int, quantity: int) -> bool:
    product = Product.objects.select_for_update().get(id=product_id)
    if product.stock < quantity:
        return False
    product.stock -= quantity
    product.save()
    return True
```
`select_for_update()`는 반드시 `transaction.atomic()` 블록 안에서 써야 합니다 — 잠금은 트랜잭션이 커밋되거나 롤백될 때 풀리기 때문입니다. 두 요청이 동시에 `decrement_stock`을 호출하면, 먼저 도착한 트랜잭션이 그 상품 행을 잠그고, 나중 트랜잭션은 `select_for_update().get(...)` 시점에서 잠금이 풀릴 때까지 ''대기''합니다. 그래서 두 번째 트랜잭션이 실제로 `product.stock`을 읽는 시점에는 이미 첫 번째 트랜잭션이 반영한 최신 재고 값을 보게 되어, 두 요청이 같은 낡은 값을 기준으로 동시에 차감하는 문제가 사라집니다. 다만 잠금 대기 시간이 늘어나므로, 짧게 끝나는 트랜잭션에만 적용해야 전체 처리량이 떨어지지 않습니다.', '[-0.723861,1.149898,-2.924959,-0.899396,1.322942,-0.888885,0.671562,0.682397,-0.410598,-0.166890,-0.646643,1.546572,1.318252,-0.340394,-0.028952,-0.356489,-0.934624,-1.817448,0.230482,1.381347,0.950949,-0.375303,-0.811600,-1.794103,1.428883,-0.153646,-0.326758,0.328500,-1.041610,0.127357,-0.111563,-0.373659,0.691326,-0.519862,-1.246493,-0.988978,1.739889,-0.214148,0.713684,-0.243483,0.759589,0.497041,1.207075,-1.080800,1.255812,0.307498,1.341454,-0.458158,1.264596,-0.019295,0.742041,0.378475,-0.319527,0.221467,1.523809,1.318026,-0.534607,0.218297,-0.339331,-0.718637,0.744116,0.451981,-0.377892,0.703755,1.851376,-0.771157,0.038881,0.474686,-0.395201,-0.629234,0.685521,0.922226,-0.429924,-0.421626,0.177710,-0.510070,-0.717807,-0.328354,-0.359374,0.464027,-0.003296,0.786663,1.507263,-0.080539,0.036567,0.202963,-0.281813,-0.261534,0.425289,1.207952,0.826041,0.322583,-0.045430,-0.042061,-0.770921,0.700977,-0.404805,0.806984,-0.555361,-0.855227,0.367318,-0.987736,0.347127,-1.410115,-0.108483,0.981242,-0.282652,1.008048,-0.798066,-0.552910,-0.383649,0.975167,-1.037259,-0.583640,0.452943,-0.018547,0.479456,0.214895,-0.454625,-0.123723,-0.456927,-0.920096,-0.497191,1.377295,1.097189,-0.374800,-1.644467,0.489389,0.870839,-1.479352,-0.260448,0.321750,-0.385868,0.017832,-0.929290,0.362482,-0.037345,0.610965,0.106403,-0.690481,0.435158,1.072965,-0.567359,0.453059,-0.069419,-0.586658,0.777338,-0.319682,-0.745074,-0.145925,0.326079,0.144088,-0.288377,0.249476,0.246802,0.116858,0.811752,-0.533260,-0.205208,0.267974,1.242024,0.306016,-0.125278,0.378742,-0.756041,-1.260097,1.010567,0.730618,-0.465541,1.345346,-1.117939,-0.351884,-0.026963,0.329733,0.633449,0.243176,-0.196624,-0.376100,0.659020,-0.697975,0.253449,-1.843208,2.182101,1.058059,-1.060126,-0.587130,0.361754,-0.440495,0.072613,-0.276796,0.519299,0.036113,-0.811293,-0.581307,-0.431461,-1.376657,0.574525,-0.254998,0.925116,-1.537155,-0.643634,-0.018696,-0.797844,0.273462,-0.421707,-0.449757,0.156049,0.672258,0.078561,0.189898,1.398790,-0.011786,0.172405,-0.004056,0.636811,-1.768342,0.084686,-0.970234,-0.301936,0.027398,0.519905,-0.605825,0.625741,0.899322,0.810361,0.020213,-0.441868,0.205478,-0.233613,0.510848,0.176341,-1.366726,0.074226,-0.726380,0.961517,0.466190,0.146347,1.056087,0.046487,0.185350,-0.032621,0.281966,-0.161517,0.167212,-1.411288,-0.279096,0.142187,-0.073007,0.010626,1.081052,-0.429049,-0.128050,0.205400,-0.353381,0.460301,-0.106260,0.045735,-0.107487,0.904452,0.005641,-0.276158,-0.694581,0.824521,-0.499090,-0.181441,-0.271413,-1.181884,-1.137522,0.074003,-0.084567,0.600062,0.221545,-0.053943,0.483872,0.412754,-0.841911,0.118314,-0.154067,0.158365,0.894294,-0.494090,-1.417936,-0.377385,0.084487,-0.553768,0.546835,-0.818766,-0.020124,-0.219598,0.824664,0.384288,0.302385,0.203718,-0.207264,0.944248,0.567277,0.672384,0.147171,0.471216,-0.556829,0.577987,0.272679,1.225255,0.430165,0.302724,0.164438,0.298782,0.346607,0.858719,-0.672451,-1.084522,0.540539,-0.829496,0.328741,-0.471024,0.553144,0.601710,0.690277,0.729975,-1.417829,-0.303346,-1.220400,-0.229139,-0.491008,0.213030,0.246935,-0.412070,1.230969,0.150966,0.010908,0.298952,0.629497,0.574633,-1.150403,-0.663160,0.518033,0.114359,0.307055,0.626914,0.530648,1.095598,-0.117607,0.973273,-0.100766,-0.437997,0.142360,-0.137473,0.089553,0.733126,0.910132,-0.566208,0.126852,-0.112378,0.280097,-0.177903,-0.163966,0.153621,0.867953,-0.083320,0.413053,0.592866,-0.155135,0.813666,-0.376562,0.233173,0.738693,0.454095,0.027140,1.263734,0.247027,-0.502555,0.234602,-0.445639,0.223719,-0.464203,0.246295,-0.607227,-0.010308,-1.133222,0.770396,0.364482,-0.294740,-0.409668,0.684453,0.242346,-0.985873,-0.359342,-1.129425,-0.426985,-0.314192,-0.587334,0.043771,-0.580599,0.125120,0.787825,-0.177296,0.355337,0.327399,-0.809616,0.990793,-1.152513,-0.566780,0.062763,-0.285998,-0.479024,-0.322336,-0.215250,0.048656,0.801405,0.583673,-0.553163,-0.257448,-0.524329,-0.699924,-0.851021,1.010957,1.747654,0.269201,-0.020082,-0.311057,0.849207,0.275023,-0.188824,0.486865,0.226254,0.286163,0.536165,0.851791,0.485066,-1.179800,-0.014254,1.061116,0.966930,0.277803,-1.399951,0.831266,0.371040,1.218363,-0.376841,0.262028,0.750113,-0.130649,-0.424399,-0.627669,0.423421,1.865895,0.533298,-1.781000,-0.522475,0.656744,-0.542028,0.318557,0.514831,0.325523,1.308370,-0.892954,0.257834,-0.515534,-0.140555,1.037246,0.308409,0.242600,-0.558412,-0.171380,-0.446470,-0.643047,0.871839,-0.115527,0.982514,1.465075,-1.354247,0.256858,0.575263,-0.887816,0.706538,0.613654,-0.045593,0.174204,0.684054,0.928445,-0.292223,-0.111520,-0.397503,-0.940473,-0.018363,0.383684,0.839826,-0.329444,0.203122,-0.298179,0.852792,0.543458,0.733971,-0.216528,-0.789036,0.090574,-0.503769,1.161565,0.696316,-0.461072,0.217282,-0.185333,0.228700,-0.001027,0.285167,-0.301416,1.244606,-0.269542,-0.638825,-0.716173,-0.238844,0.879817,0.568951,-0.135735,0.002592,-1.392494,1.015296,0.000225,-1.538921,-0.691915,1.070693,-0.304510,0.238902,-0.393978,-1.095711,0.015254,-0.171451,-1.569534,0.207138,-0.358106,0.403441,0.665029,-0.445815,-0.377908,-0.006859,-0.623936,0.192026,0.816724,0.248956,0.840526,0.483843,0.317343,-0.535936,0.178417,0.224727,-0.516591,-0.404316,0.535600,-0.574621,-1.567880,0.880390,-0.194176,-0.057660,-1.504589,0.596773,-1.413393,-0.004090,0.234891,-0.219456,-0.496324,-0.024219,0.023551,0.964856,0.289608,1.442373,-0.930187,-0.176567,-0.162304,-0.273400,1.271743,-0.872359,-0.712729,-0.070815,-0.905971,-0.691774,-0.300497,-0.487820,-0.602404,-0.852699,-0.518813,-0.462141,-0.986154,0.062479,1.723333,-0.499167,0.423162,-0.407049,-1.070320,0.442362,-0.714121,-0.472603,1.291681,0.313427,0.054714,0.617405,0.853935,-1.165001,-0.540240,-0.222522,-1.549604,0.237865,-0.260923,0.278864,-0.701582,-0.396828,0.132188,-0.726868,1.301751,-0.545990,-1.237923,0.070010,-0.125925,-0.672540,-0.700915,0.509853,-1.268448,1.091264,0.857034,-0.534593,-0.637617,-0.484519,-0.904542,0.518817,-0.877148,0.854361,0.386475,-0.838317,-0.672880,0.503978,1.137039,-0.646315,0.578035,-2.193156,-0.355566,-0.815490,1.131711,-0.762317,0.656508,0.749947,1.485843,0.813277,-0.186233,-0.312586,0.752737,-0.236549,-0.759405,1.511842,1.851453,1.117400,-0.401242,1.652165,1.037311,0.411145,0.502951,0.438381,-0.229512,0.009038,-0.549837,-1.258619,-1.106081,0.009549,-0.615430,-0.973318,0.406849,0.161148,-0.160035,0.073211,-0.183671,-0.686277,-1.206178,0.292574,1.032786,0.437619,-0.436089,0.904691,0.536003,1.076423,-0.087308,0.024222,-0.947007,0.051867,0.151678,0.309406,-0.558138,-0.474716,-0.313819,-0.350967,-1.076447,0.372858,-0.686915,-1.159876,-0.372762,-0.511352,0.454216,-0.843133,0.845215,-0.569149,-0.398318,-0.186545,1.813531,-0.856470,0.927688,-0.372964,0.077102,-1.192726,-0.077663,0.551111,0.066946,0.019661,-0.063720,0.204120,-0.528625,-0.285523,1.356558,0.364932,0.174441,0.107258,-1.610805,-0.786086,0.820938,0.687961,-0.313405,-1.284496,0.733223,-0.518557,-1.015866,-0.365586,-0.107275,-0.089619,-1.021605,0.389245,-0.244632,-1.338042,0.924542,0.406793,1.027831,-0.577462,-0.520171,-1.269430,-0.132546,-0.947910,-0.180187,0.536554,-0.188677,0.241415,-0.972122,-1.033659,0.807165,0.854136,-0.463011,-0.251191,-1.003029,-0.547948,0.635013,-0.206345,-0.427457,0.599264,0.591363,1.338723,0.388934,0.562649,0.274962,0.225276,0.125692,-0.054444,-0.933272,-0.671481,-0.209598]'::vector, 'd22fe0cd1e477180a5a20a7cc931f744de3a8f8e60d6c052d4db2da981000ca3', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-django-select-for-update-race-condition';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'DRF의 `PageNumberPagination`(오프셋 기반)은 `LIMIT ... OFFSET ...`으로 구현됩니다. 오프셋이 커질수록 데이터베이스는 건너뛸 행까지 전부 스캔해야 해서 뒷페이지로 갈수록 느려지고, 조회 도중 새 행이 삽입되면 페이지 경계가 밀려 같은 항목이 중복되거나 누락될 수 있습니다. `CursorPagination`은 정렬 기준 컬럼의 마지막 값을 커서로 써서 이 문제를 피합니다.

```python
from rest_framework.pagination import CursorPagination

class PostCursorPagination(CursorPagination):
    page_size = 20
    ordering = ''-created_at''  # 반드시 고유하거나 tie-break가 되는 정렬 기준이어야 한다

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all()
    pagination_class = PostCursorPagination
    serializer_class = PostSerializer
```
`CursorPagination`은 내부적으로 `WHERE created_at < :마지막으로_받은_값 ORDER BY created_at DESC LIMIT 20`과 같은 쿼리를 만듭니다. 오프셋을 세지 않고 ''어디서부터 이어서'' 가져올지를 값으로 표현하므로, 조회 도중 새 글이 올라와도 이미 받은 페이지의 경계가 흔들리지 않습니다. 대신 임의의 페이지 번호로 바로 점프하는 UI(예: ''5페이지로 이동'')는 만들 수 없다는 제약이 있습니다. `ordering`에 쓰는 컬럼이 유일하지 않으면(예: 같은 `created_at`을 가진 행이 여러 개) 커서가 정확한 위치를 가리키지 못해 항목이 중복되거나 스킵될 수 있으므로, 보통 `id`처럼 유일한 컬럼을 tie-breaker로 추가한 복합 정렬을 씁니다.', '[0.006287,1.115118,-2.993970,-1.816445,0.140487,-0.946406,1.195423,0.555036,-0.569248,-0.858754,-0.174574,-0.436630,1.058060,0.030889,0.734556,-0.116039,-0.584550,-1.230220,-1.237008,0.367050,0.172677,0.279421,-0.747726,-1.135678,1.036435,1.719465,-0.294874,-0.439613,-1.465526,0.354685,0.365077,-0.217481,-0.316804,-0.630893,-0.336129,-0.515651,1.131186,-0.202962,-0.043260,0.695091,0.338061,-0.070611,1.181915,-0.450401,0.121183,0.322119,0.803437,0.324614,0.698571,-0.147237,-0.043739,0.321284,0.075475,-0.413125,0.724874,1.129069,-0.694918,-0.222775,0.385735,-0.907819,0.587749,1.492130,-1.267428,1.264305,0.537461,-0.024267,-0.628849,0.644319,-0.461327,-0.308694,-0.010775,0.294361,-0.770470,0.014126,-0.469980,0.780002,-0.786057,-0.335007,-0.916396,1.480681,-0.276224,0.682185,0.715597,0.243702,0.787425,-0.368743,0.049217,-0.089723,-0.399705,1.061884,-0.583932,-0.289610,0.345539,-0.322776,-0.495830,0.799334,-0.197526,0.587919,-1.671570,-0.209251,0.038791,0.346743,1.095954,-0.003707,-0.323035,0.968614,0.665225,-0.776750,0.109326,-0.963837,-0.738226,0.712076,-1.289025,0.094343,0.722825,0.316586,2.198137,0.346412,-0.296322,0.563081,0.089640,-0.279571,-0.446633,0.765219,0.447136,0.102379,-0.765626,0.754661,1.191021,-0.548436,0.321436,-0.257462,-0.603975,0.428394,0.530424,0.613370,-0.114935,0.429728,0.126401,-0.141401,-0.523055,0.519935,-0.025677,-1.146320,-0.071397,-0.956144,0.879148,-0.618456,-0.625245,-0.068623,0.001760,0.327863,-1.238744,-0.028609,0.152062,-0.355910,-0.081097,-0.688351,0.366865,-0.295894,0.311312,0.346262,-1.263338,0.944005,-0.726878,-0.435989,0.845533,0.797678,-0.974857,-0.014291,-1.338320,-0.102204,-0.223935,-0.188742,-0.198142,0.782250,0.682437,-1.007657,0.790022,-0.554969,0.214019,-0.414296,1.779689,1.055015,-0.491609,-0.707260,0.298012,-0.734605,-0.813659,-0.502355,0.376252,0.173010,-0.841947,-0.483037,-0.872561,-0.816506,1.624210,-0.817064,-0.268070,-1.326547,-0.327260,-0.618325,-0.671430,0.087950,-0.377163,0.408932,-0.360928,1.732723,-0.743754,1.352065,0.397308,-0.107793,-0.199635,1.236389,0.386499,-0.593961,-0.094606,-0.253306,-0.397343,0.055857,1.010525,-0.455623,-0.014656,0.540724,0.372237,0.677149,0.050860,0.130144,-1.059539,0.543844,-1.710609,-1.787460,0.069582,-0.661219,0.312734,0.646414,0.199704,1.375726,-0.531844,-0.593834,0.053644,-0.216896,0.539459,0.303128,-0.590660,-0.331016,0.791792,-0.867365,0.182650,1.490908,1.096905,-0.229645,0.598983,0.624616,0.311197,-0.278446,-0.284744,-0.495929,0.692583,-0.366681,0.380739,0.027701,0.411075,-0.348031,-0.422081,-0.837709,-1.071807,-0.373941,-0.010813,0.233222,1.275105,0.582462,-0.250329,0.417393,0.051774,0.413487,0.601446,-0.837815,-0.648380,1.035477,0.481176,-1.487857,-0.571168,0.387255,-0.338699,0.039508,-0.083586,-0.165048,-0.689783,0.348642,0.988563,-0.146433,-0.201011,-0.531861,1.425231,-0.052325,0.621447,-0.224143,-0.302224,-0.434560,0.057493,-0.062867,1.256085,-0.231731,-0.550792,-0.755389,0.495405,-0.379907,0.304979,-0.004867,-0.722843,-0.877741,-1.017361,-0.046221,0.111866,0.208425,0.478554,0.289980,0.427170,-0.342786,0.931843,-0.494209,-0.175179,-0.125112,0.186187,0.798560,-0.973158,1.143996,0.186319,0.200990,0.416382,1.163619,0.048634,-0.548640,0.712845,0.859748,0.665335,0.264579,0.604900,0.184862,0.867326,-0.273095,1.063567,-0.554971,0.198987,0.448225,0.086715,-0.305348,-0.207976,1.075628,-0.583290,0.307141,-0.008113,0.056724,-0.180773,0.918180,-0.108848,-0.047587,0.250929,0.314518,1.193302,-0.109448,-0.125176,-0.078813,0.657087,0.123769,0.717109,0.454471,0.811697,-0.743900,-0.957222,-1.020177,-0.049988,0.116888,0.336765,0.097053,-0.526045,0.578127,-0.537760,0.398399,0.380911,-0.175746,0.664708,0.377892,-0.189840,-0.590092,-0.577562,-0.835488,-0.067582,0.450628,-0.932995,-0.776793,-0.966863,-0.251744,0.709732,-0.339443,-0.299941,1.445679,0.301713,1.009185,-0.709460,-1.538465,0.215249,-0.303091,0.124003,-0.437893,-0.099457,0.541493,0.593660,-0.429548,0.403961,0.976749,-0.401848,-0.487101,0.165518,0.368594,1.121302,0.767824,-0.246086,-0.241730,0.578938,0.991951,0.140229,-0.430720,0.547753,-0.013187,-0.144574,0.240514,-0.010463,-1.552016,-0.496818,1.326110,0.526000,0.140463,-0.355208,-0.790033,-0.179048,0.428237,0.544988,0.460993,0.089283,-0.855220,-0.063558,-0.490127,0.077250,0.796229,0.548513,-1.247180,-0.625826,0.287524,0.563246,0.085117,0.432347,0.271733,1.021293,-1.309840,-0.326707,-0.146162,-0.137956,0.428760,-0.073137,0.024755,-1.735775,-0.518378,0.245904,-0.085106,0.123466,-0.781039,-0.090055,1.172164,-0.898960,0.283362,0.383319,-0.306812,0.208500,1.048637,-0.219319,0.230697,0.120249,0.415285,-0.469203,-1.050551,-0.278055,-1.036208,0.658202,0.792549,0.795566,-0.196849,0.191414,-0.383231,0.124909,0.648141,0.417573,0.214480,-0.042737,0.096976,0.177794,0.800593,0.106998,-0.803283,0.454057,0.723815,0.302668,-0.154913,-0.326516,-0.255548,0.869819,-0.377529,-0.956380,-0.982110,0.239044,1.498666,0.353107,-0.148772,0.493797,-1.598151,0.648051,0.091204,-1.011269,-0.242239,0.644176,-0.539819,0.206968,-0.351798,-0.892706,-0.139301,0.740295,-1.612263,0.849277,-0.629349,0.010925,0.320447,-0.907724,-0.144649,-0.874662,-0.656674,-0.387353,0.474216,1.067340,-0.739704,0.369788,0.245424,0.119037,-0.043564,0.367561,-0.530927,0.031988,-0.235847,-0.257065,-2.133539,1.487663,-0.586320,0.630396,-0.795229,0.073461,-1.156668,0.157056,-0.919055,-0.309356,-1.185015,0.089416,0.071564,1.632881,0.374451,-0.104924,0.331556,0.217844,-0.231741,-0.143593,-0.196092,0.455327,-1.974614,0.574560,0.178972,-0.259502,0.407004,0.754692,0.219955,-1.642745,-0.250433,-0.408581,-0.596244,0.839513,0.962080,-0.298804,0.095043,-0.082791,-0.535223,-0.626189,-0.362732,-0.662084,0.315337,0.698771,0.074184,1.021735,0.983828,-0.132560,-0.299653,-0.563281,-0.393189,0.024365,0.982361,1.262424,-1.476435,0.145969,0.566643,-0.629977,0.452910,-0.019459,-0.953498,0.542837,0.275449,-0.188705,-0.162938,1.159590,-0.771223,0.413458,0.726258,-0.131306,-0.227620,-0.405987,-0.505228,0.789926,-0.683896,0.697788,0.825433,-0.887530,-1.168389,0.813021,0.610243,-0.598794,0.041029,-0.985436,-0.458169,-0.515376,1.014960,-1.127385,0.321932,0.736154,1.044012,1.236682,-0.708962,-0.202292,-0.208898,0.540290,-0.644924,0.363269,0.876531,0.603769,-1.181815,1.837528,1.432464,-0.290829,0.226463,0.664812,-0.087147,1.022742,-0.370652,-1.285702,-0.091678,-0.266139,0.137769,0.535107,0.031971,-0.228298,-0.220791,-0.206819,0.734665,-1.466213,-1.325673,0.905610,-0.031351,-0.120757,0.258226,0.621427,1.423693,1.996155,0.583207,-0.044591,-0.604038,-0.486905,-0.365180,0.713358,-0.674622,-0.329565,-0.521817,0.016017,-0.505534,0.201801,-0.938303,-0.713137,-0.773342,0.155059,-0.221752,-0.170533,1.014468,0.305381,-1.115174,-0.644546,1.289676,0.113652,-0.098610,0.249486,-0.291432,-0.094802,-0.235126,-0.043684,0.331239,0.266455,-0.789821,-0.031702,0.414802,-0.473815,0.749701,0.083166,0.307992,-0.843212,-0.603357,-0.756977,0.022880,0.464120,-0.986266,-0.905942,0.036698,0.176639,-0.486094,1.081048,-0.823851,0.662046,0.274341,-0.033715,0.286828,-0.759445,1.427097,-0.469092,0.911463,-0.490615,-0.734175,-1.088737,-0.664861,-0.666570,0.161521,0.617754,0.752048,0.562377,-0.594652,-1.202947,0.392267,0.950423,-0.678707,-0.567854,-1.091939,-0.173941,-0.648896,1.180129,-0.291476,0.704986,0.358447,1.419791,0.956200,0.998335,0.188543,-0.098572,-0.499440,-0.239613,-0.202203,-0.820683,-0.751632]'::vector, '67b6a89d2f5035ef5770b11cc1663d91931c34cca4db994b4076ab864bf8a83f', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-drf-cursor-pagination';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '`BackgroundTasks.add_task()`는 동기 함수와 코루틴 함수를 모두 받을 수 있습니다. 내부적으로 FastAPI는 응답을 클라이언트에게 보낸 뒤, 등록된 콜러블이 코루틴이면 현재 이벤트 루프에서 `await`하고, 일반 함수면 스레드풀에 위임해 실행합니다.

```python
from fastapi import FastAPI, BackgroundTasks
import asyncio

app = FastAPI()

class EmailService:
    async def send_email(self, message: str):
        await asyncio.sleep(2)  # 실제로는 SMTP 서버와의 비동기 I/O
        print(f''Sending email with message {message}'')

email_service = EmailService()

@app.post(''/send-email'')
def send_notification(message: str, background_tasks: BackgroundTasks):
    background_tasks.add_task(email_service.send_email, message)
    return {''status'': ''accepted''}
```
중요한 점은, `send_notification` 자체는 동기 함수인데도 비동기 콜러블(`email_service.send_email`)을 백그라운드 작업으로 등록할 수 있다는 것입니다. 응답이 나간 ''이후''에 백그라운드 작업이 실행되지만, 이는 여전히 API 서버와 ''같은 프로세스, 같은 이벤트 루프'' 안에서 실행됩니다. 따라서 이 작업이 오래 걸리거나 실패하면 서버 프로세스의 리소스를 계속 점유하고, 재시도·실패 알림·작업 이력 조회 같은 운영 기능도 전혀 없습니다. 응답 후 몇 초 안에 끝나는 가벼운 후속 작업에는 적합하지만, 재시도가 필요하거나 오래 걸리는 작업이라면 Celery 같은 독립된 워커로 옮겨야 서버 프로세스와 장애가 격리됩니다.', '[0.254411,0.647634,-2.794527,-1.296128,0.672093,-0.707121,1.076939,-0.380511,-0.023209,-1.063770,-0.298220,1.637254,0.856307,1.197000,-0.077063,-0.023646,1.015692,-1.664631,-0.982721,0.553925,0.560637,0.208321,-0.459049,-0.723589,0.970738,0.443674,0.754185,0.226526,-1.654117,-0.706094,0.547518,0.561160,-0.875701,-1.235429,0.209904,-0.121616,0.348971,-0.246162,-0.579905,-0.109717,-0.024824,-0.805889,0.257637,0.378717,1.260830,-0.248748,0.807714,-0.334453,1.324306,-1.463701,-0.228810,-0.650268,-0.453854,-0.252566,1.534944,0.309387,0.771700,0.360764,0.392323,-0.084194,1.641452,1.311266,-0.842529,1.697755,1.489316,0.077520,0.392203,1.107174,-0.202359,0.823305,1.092603,0.122750,-0.560427,-0.148774,0.198932,-0.306697,-0.573109,-0.451118,-0.498587,1.334028,0.332431,-0.260642,1.333391,-0.243090,0.985803,-0.419227,-0.525539,0.125141,-0.827118,1.026930,-0.322222,-0.273448,-0.414936,-1.038883,-0.421392,0.623163,-0.895409,0.332532,-0.838634,-0.774962,0.323393,-0.091562,-0.123967,-0.731961,0.022053,1.212545,0.079178,0.586601,0.222889,-0.082637,0.062648,0.689113,-0.712022,-0.571085,0.686341,-0.456191,0.740756,-0.539436,0.133193,1.073835,-0.244410,-0.276121,-0.555805,-0.056333,1.423913,0.411481,-0.554629,0.168028,0.362143,-1.341697,1.218818,-1.105559,-1.435396,0.230107,-0.428194,0.251504,-1.023030,0.025468,1.000792,-0.063713,0.394070,0.395319,-0.089352,-0.095195,-1.282781,0.160416,-0.024072,-0.014175,-0.568697,-0.317141,-0.401178,0.723120,0.116665,0.747810,0.563727,-0.677990,-0.812398,0.039713,0.746457,0.453213,1.652730,0.484145,-0.877201,0.920686,-0.091369,-0.272646,-0.280815,1.415949,0.056501,1.506146,-0.235252,-0.756005,-0.012121,-0.083528,-0.254427,0.611543,0.277485,-0.662413,1.882701,-0.496148,-0.496660,-1.446380,0.816196,0.310288,-1.494174,-0.826250,-0.521399,0.090533,-0.783378,-0.542105,0.047662,0.759055,-0.320820,-0.107760,-0.769258,-0.185647,0.606456,-1.134982,1.309268,-1.276668,0.439886,0.372129,-0.520547,-0.037281,-0.199236,0.990456,0.330162,0.468402,-0.081639,-0.465206,1.112573,-0.071582,0.448138,0.169105,0.932678,-0.000008,-0.018344,0.384159,-0.715591,0.082029,0.589696,-0.245097,0.220411,-0.036257,-0.100091,-0.016474,-0.635645,-0.025521,-0.819421,0.509907,-0.190331,-1.013869,0.242484,0.746069,0.352518,0.399465,0.410708,1.948488,-0.663628,-0.254410,-0.234508,-0.229722,0.413538,0.238836,-1.601511,-0.129242,-0.215289,-0.794012,-0.820610,0.707792,-0.724334,-0.028353,0.266993,0.299738,-0.230076,-0.634542,-0.221083,-0.768811,0.617130,-0.834993,0.541946,-0.687483,0.400568,-0.222000,-0.024274,-0.659155,-0.025892,0.756814,-0.404271,-0.202684,0.169193,0.612362,0.320079,0.673914,-0.299474,0.171808,0.310424,0.341551,0.303200,1.366714,-0.742503,-1.466107,-0.851693,0.456275,-0.854577,0.202714,-0.318297,1.009673,0.496814,-0.715693,1.189655,-0.461870,-0.367069,0.224972,0.260035,1.042373,1.682392,-0.386599,-0.484177,-0.329920,0.513334,0.137340,1.516734,-0.239002,-0.345887,-0.517206,-0.455134,-0.928911,0.622229,0.442553,-1.190442,-0.619461,-0.827981,0.972687,-0.624781,1.183203,0.123761,1.352284,0.919995,0.317344,0.170214,-0.122281,-0.051104,-0.336334,-0.480799,0.592120,-0.575774,1.297494,0.675535,0.340447,0.988408,0.445264,0.100760,-1.532147,-0.484393,0.082369,0.337237,0.488304,-0.255292,0.700211,0.721635,-0.312840,0.876236,-0.763553,-0.233638,-0.389154,0.906746,-0.591420,0.116692,0.781651,-1.300569,0.838641,-0.250450,0.507203,0.109470,-0.735026,-0.052666,0.462732,0.150463,-0.273890,0.526278,-0.038632,0.592561,0.824623,0.080081,-0.006254,-0.203352,-0.396965,0.469278,-0.170957,0.772702,-1.079412,-0.028293,1.007586,0.924484,-0.180077,-1.237994,-0.763795,-0.720362,0.242940,-0.081355,-0.243982,-0.570331,0.395520,0.652686,-0.125508,-0.331039,-0.265330,0.449041,0.891134,0.437575,-1.166816,-0.409619,0.873924,1.048108,-0.646489,0.352046,-0.126007,-0.471903,1.253412,-0.651603,-0.653166,-0.361720,-0.297822,-0.059703,-0.181819,-0.533726,-0.067668,0.341329,-0.016778,0.062451,-0.472159,-0.373756,-0.855783,-0.264672,0.087100,1.706823,0.762467,-0.862429,-0.227485,-0.594174,1.001667,0.057880,-0.437000,0.111142,0.845196,0.517088,0.991276,-0.550889,-1.603298,-0.050467,0.800900,1.466921,-0.330187,-0.649365,-0.547565,0.340021,0.265357,-0.264717,0.886610,1.000471,0.051091,-0.865857,-0.036115,0.081214,0.903388,0.316560,-1.462613,-0.663187,-0.102375,-0.938886,0.178312,0.435687,0.090082,0.860774,0.071333,0.271533,-0.707502,-0.752125,0.722941,0.069639,0.303311,-0.010558,-0.022340,-0.270489,0.291622,1.360770,0.307507,1.320269,0.617396,-0.464961,-0.255453,0.886993,-0.323241,-0.336690,0.205965,-0.726306,0.250773,0.254007,1.473414,0.719845,-1.040875,-0.808649,-0.586674,-1.057912,0.513492,0.218699,0.202924,0.242713,-0.543899,0.425534,0.566547,-0.665718,0.083760,0.480848,0.293083,-0.559193,1.822721,0.520420,0.387127,0.247456,0.521547,-1.111254,-0.093586,0.427133,0.045400,0.293558,-0.796270,-0.387051,0.328211,-0.313632,0.487559,0.024507,-0.702138,0.246564,-0.600646,0.711797,-0.863960,-1.500059,0.564419,0.085497,-0.840018,0.726555,-0.968751,-1.609125,-0.297418,-0.104579,-1.299562,0.204342,0.064197,-1.124238,0.783863,-0.351341,-0.634539,0.671822,-1.274663,0.181002,1.255374,0.447542,0.196479,0.484529,0.026442,-0.054067,0.889330,-0.472060,0.222410,-0.131449,0.420279,-0.118127,-2.137445,0.836775,-0.255027,-0.459207,-0.910900,0.287186,-0.980489,-0.300133,-1.291014,0.404084,-1.483235,-0.053477,-0.066900,0.555875,-0.134310,0.920837,-1.509111,-0.935823,-0.008412,0.236198,0.818140,-0.216355,-1.427936,0.159707,-0.184676,-0.623349,-0.071799,0.417546,-0.105339,-1.505763,-1.014465,0.295459,-0.186443,0.446202,1.837853,0.008510,-0.103919,-0.498394,-0.187823,0.588208,-0.164345,-0.869066,0.029233,0.064462,-0.593830,0.156329,0.807604,-0.117278,-1.291649,0.056799,0.120582,-0.644949,0.117631,0.861975,-0.239611,-1.018887,1.704968,0.147093,0.018585,-0.546849,-0.451060,0.377815,-0.299712,-0.278868,0.437732,0.751127,-1.470533,1.135430,0.066614,0.905832,-0.671816,-1.211585,-0.330782,2.008996,-0.674649,0.821380,0.062805,-0.344498,0.184228,0.117447,1.224269,-0.153151,1.059678,-2.456440,-0.853555,-0.734188,0.942463,0.910194,-0.224413,-0.382468,0.726253,0.672702,0.366089,0.238979,0.317968,0.068412,-0.697962,1.241264,1.139668,0.855796,-0.404283,1.143156,1.066945,0.850634,-0.371818,0.939532,-0.350513,1.145558,-0.063719,-1.282782,-0.946464,0.242032,-0.374438,-0.924412,0.440918,1.197257,0.463615,0.324660,0.206278,-0.597295,-0.857082,0.502717,0.830592,-0.153684,-0.689947,0.333071,0.247979,1.392226,0.106591,-0.342044,-0.707423,0.937983,-0.527529,0.102405,0.883767,0.182735,-0.364389,0.020309,-0.771747,0.407682,-0.701914,-0.631656,-0.146037,-0.440921,-0.488704,0.018320,0.143882,-1.267471,-0.872637,-0.570521,0.450671,-0.551134,0.790621,0.637229,-0.214612,-0.115836,-0.075210,0.084745,-0.021843,-0.227955,-0.578712,-0.970487,0.501217,-0.492283,0.959216,-0.043901,0.687838,-0.605494,-0.361347,-0.002384,0.020502,0.880939,-0.066427,-1.845140,0.465233,0.620659,-0.012063,0.504180,-0.398844,0.849580,-1.243574,0.574003,-0.189961,-0.751691,0.239427,-0.521592,0.205447,-0.313447,-1.547277,-0.958754,-0.133421,-0.190196,-0.525176,-0.481112,0.504576,-0.032873,-0.598662,-0.914443,-0.331475,0.599203,-0.538373,0.621538,-0.297710,-1.103778,0.811251,0.170010,0.493207,0.303034,0.917095,1.626643,0.124591,0.280274,0.319747,0.076692,-0.336190,-0.722829,-0.532330,-0.572219,-1.135734]'::vector, '20cbefd35750451825fd43f461e20cffbebb4dcababe57a41b5d4f3deb8ceead', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-fastapi-background-tasks-async-callable';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, '인기 있는 캐시 키 하나가 만료되는 순간, 그 키를 기다리던 수백 개의 요청이 동시에 캐시 미스를 겪고 한꺼번에 DB로 몰려가는 현상을 캐시 스탬피드(cache stampede) 또는 thundering herd라고 부릅니다. TTL만 걸어둔 단순한 캐시-어사이드 패턴은 이 문제에 취약합니다.

```python
import random
import time

def get_with_stampede_protection(key, fetch_fn, ttl=300, beta=1.0):
    cached = cache.get(key)
    if cached is not None:
        value, delta, expiry = cached[''value''], cached[''delta''], cached[''expiry'']
        # 만료 시각에 가까워질수록 ''조기에'' 미리 갱신할 확률이 높아진다
        if time.time() - delta * beta * _log_random() < expiry:
            return value

    start = time.time()
    value = fetch_fn()
    delta = time.time() - start  # DB 조회에 걸린 시간
    cache.set(key, {''value'': value, ''delta'': delta, ''expiry'': time.time() + ttl}, ex=ttl)
    return value

def _log_random():
    import math
    return math.log(random.random())
```
이 기법(XFetch)의 핵심은, 캐시 값이 실제로 만료되기 ''전''에 일부 요청이 확률적으로 미리 값을 갱신하게 만들어, 정확히 만료되는 그 순간에 모든 요청이 동시에 DB로 몰리는 것을 분산시키는 것입니다. `delta`(원본 조회 소요 시간)가 클수록, 그리고 만료 시각에 가까워질수록 조기 갱신 확률이 높아집니다. 더 간단한 대안은 캐시 미스가 났을 때 짧은 분산 락(`SET key value NX EX 5`)을 걸어, 락을 획득한 요청 하나만 DB를 조회하고 나머지는 짧게 대기했다가 갱신된 캐시를 읽게 하는 방법입니다. 트래픽이 매우 큰 키 하나에는 확률적 조기 만료가, 구현 단순성이 중요하면 락 기반 방식이 더 적합합니다.', '[-0.390839,1.675010,-3.790063,-1.194240,1.222780,-0.212705,0.480783,0.109547,-1.316898,-0.351283,-1.454897,1.746690,1.020495,-0.050701,0.021084,-0.859498,0.380515,-0.908299,-0.470608,1.436363,0.098929,-0.093324,-0.453154,-1.831345,1.529805,0.149576,0.203471,0.080903,-1.149952,0.263195,0.396559,-0.239892,-0.378820,-1.362120,-1.385415,-0.445943,1.010835,-1.208700,1.257648,-0.242782,-0.144692,0.132830,0.873143,0.566050,0.698490,0.539648,0.779578,0.585370,0.870862,-0.628471,0.079897,0.145803,-0.057350,-0.590679,0.520911,0.746839,-0.199164,-0.572676,0.216841,-1.001708,1.291418,0.949937,-1.037697,-0.302743,1.516443,-0.602755,0.090358,0.627528,0.621924,0.411973,0.979320,0.433833,-1.070799,-0.691061,-0.342719,0.143269,-0.654578,-0.147285,0.474841,1.151734,-0.571288,0.265867,1.141277,-0.037823,0.528184,0.663397,-0.926226,0.167354,-0.604658,0.976331,-0.525137,-0.337370,0.385436,0.245582,-0.926391,0.827963,-0.628485,0.679414,-0.829596,-0.407665,0.104676,-0.359258,-0.029402,-0.894314,-0.557343,0.529443,-1.106868,0.501054,-0.534000,0.026460,-0.443819,0.878138,-0.747854,-0.299268,0.146058,0.099585,0.727799,0.390499,-0.022365,-0.114024,0.024992,-0.602355,-1.294883,1.032552,1.210878,1.135917,-0.685938,0.367119,0.077252,-1.280452,0.172294,0.126968,-1.019297,-0.020188,-0.125274,0.662579,-0.636703,0.880110,0.403661,-0.351884,0.298088,0.559531,-0.085577,-0.660665,0.269249,-0.075189,-0.292772,-0.476227,-1.331684,-0.644168,0.032891,0.946862,-0.309178,0.167998,0.624003,0.184040,0.717617,0.215943,-0.104772,0.498741,0.725102,0.493867,0.465992,1.106154,-0.551552,-0.567682,1.133882,0.977395,-0.042956,1.091882,-0.771119,-0.942123,0.013141,0.001108,-0.732078,0.080718,0.755414,-0.351148,0.604317,-0.499092,0.223769,-1.338088,1.916169,0.379261,-0.589348,-0.592651,0.185421,0.334434,-0.309760,-1.316752,0.585458,-0.622889,-1.245072,-0.301310,-1.091638,-0.593553,0.767870,-0.332175,0.849089,-1.391909,-0.351999,-0.444179,-0.909365,-0.130466,-0.406015,0.950157,0.181994,1.063327,-0.265263,0.973621,0.813018,0.168321,-0.599002,0.450774,0.737630,-0.811345,0.330621,-0.733633,-0.531519,-1.057632,0.562257,-0.309332,-0.099363,0.635451,0.697115,0.625661,-0.165852,0.480992,0.415094,0.556868,-0.543807,-1.263744,0.451514,0.017518,0.379319,0.803894,0.704920,1.587924,-0.523034,-0.458284,-0.073995,0.639488,-0.448375,0.185992,-0.962941,-0.160135,0.392463,-0.369338,-0.453499,1.045600,-0.685386,0.293146,0.442351,0.054036,0.845219,-0.933289,0.270753,-1.294347,0.347553,0.279805,0.510980,-0.353752,0.242618,-0.773240,-0.924477,-0.460108,-0.496180,-0.735932,-0.518675,-0.003042,-0.361392,-0.263504,1.055750,0.539131,0.093902,0.092475,0.600723,-0.356478,-0.394673,-0.497445,-0.716033,-1.179174,-0.024357,1.291684,-0.833865,-0.315048,0.095200,-0.260442,0.440199,0.302091,0.459692,-0.202033,-0.351650,0.964846,0.501445,0.758907,0.845504,-0.274014,0.857440,-0.580833,0.557667,0.694772,1.090752,0.563807,-0.092234,0.685039,0.396110,-0.501992,0.319013,-0.270591,-0.518944,0.140228,-0.630331,0.236980,-0.569385,0.284849,0.302689,0.696585,1.385039,-0.254548,0.147111,-1.624629,-0.090870,-0.800173,0.255653,0.899821,-0.987794,0.869548,0.033060,-0.978223,0.610926,0.772392,0.530661,-1.119770,-1.043927,0.534118,0.188654,0.225975,-0.207044,0.615241,0.586643,-0.771281,0.063895,-0.086546,-0.458215,0.075392,0.076885,-0.842199,0.414352,0.386828,-0.313329,0.323740,-0.541799,-0.211039,-0.056147,0.542351,0.192912,0.187376,0.569996,0.184292,0.708617,-0.633242,0.660836,0.127697,-0.381907,0.702701,0.204969,0.722475,1.077813,-0.291330,-0.518948,-0.684675,-0.147645,0.648083,0.385022,0.243003,-0.872233,0.009289,-0.608009,0.779564,-0.148165,-1.054389,0.149711,-0.305579,0.832338,-0.704222,-0.012781,-0.386804,-0.207773,0.190781,0.400581,-0.242329,-0.656947,0.195325,1.109560,-0.560112,0.600673,0.107335,-0.389415,0.381049,-0.280258,-0.680956,-0.020879,-0.202449,-0.726486,0.370015,0.497003,-0.064136,0.668062,-0.110012,-0.357882,-0.057855,0.170503,-0.310838,-0.132525,0.445477,1.481194,1.178661,-0.263371,-0.083605,0.410953,0.357402,-0.104116,-0.082903,-0.119497,0.363911,0.404288,0.470365,0.077506,-1.358978,0.321271,0.387421,0.238956,0.082840,-0.339288,-0.002133,0.598699,0.823622,-0.825326,0.378177,0.757457,-1.014938,-0.136456,-0.216741,0.147744,1.345789,1.464188,-1.893037,-0.680631,0.211408,-0.573044,0.493043,0.426502,0.363531,1.408761,-0.793378,-0.315745,-0.306821,-0.257109,0.643121,-0.505478,0.408055,-0.232092,-0.596505,-0.322876,-0.893134,0.409810,-0.297667,1.770755,1.105571,-0.581044,-0.039101,0.259364,-0.631124,0.280481,0.126001,0.249076,0.277540,1.358022,0.609935,0.281800,-0.445415,-0.980175,-0.472723,0.131025,0.993666,0.230176,-0.994134,0.974719,-0.207576,0.539750,0.519666,0.737867,-0.134733,-0.026533,-1.108756,0.129770,1.472017,0.547595,0.205944,0.386333,-0.202603,-0.511364,0.244934,0.275758,-0.024553,-0.101798,-0.074016,-1.570550,-0.319285,-0.547089,1.077354,0.629605,-0.067046,0.265873,-0.977487,0.991587,-0.915016,-0.809049,-0.100946,1.312539,-0.284682,0.282664,-0.124688,-1.385337,-1.017093,0.061598,-1.519597,0.110932,-0.472417,-0.398626,-0.693944,-0.747133,-0.339122,-0.265141,-1.361973,0.129148,0.964781,-0.133385,-0.309795,0.619194,0.564092,-0.528530,0.266677,0.399039,-0.416544,0.015599,0.001497,0.024370,-2.182231,0.785254,0.002070,-0.100691,-0.476827,0.589489,-0.665899,-0.492036,-0.386743,-1.139733,-0.121346,-0.528933,0.032215,0.765486,0.284229,1.107507,-0.860965,-0.282035,0.007695,0.185308,1.136173,0.223426,-1.502527,-0.773848,0.161832,0.335619,0.590084,0.316510,0.271591,-0.298075,-1.369286,-0.184319,-1.055721,1.210547,0.686554,-0.539876,0.171493,-0.048432,-0.597646,0.723621,-0.727609,-0.361713,0.564487,0.647895,-0.340163,0.028121,0.488227,-0.134945,-1.232810,-0.285499,-0.784666,0.246779,1.154721,0.293265,-1.301789,-0.562854,0.528334,-0.770297,0.191178,-0.348286,-0.449758,0.347784,-0.362749,-0.212341,0.219203,0.239291,-0.645535,0.980949,0.167928,0.080860,-0.346421,-0.399280,-0.062077,0.654460,-0.498242,0.660110,0.457843,-1.343791,-0.267023,0.521841,0.377042,-0.720942,-0.050848,-1.180625,-0.089193,-1.417454,1.644803,-1.199087,1.491129,0.172946,1.376602,1.411590,-0.212879,0.269933,0.772503,0.577924,-0.487606,1.211719,1.650250,0.675891,-1.446408,0.834770,1.598670,0.281416,-0.060380,0.645706,0.172732,1.287460,-0.292534,-1.209756,-0.789411,-0.049087,-0.295823,-0.862691,-0.012500,1.149338,-0.533264,-0.654991,-0.317359,-0.341260,-1.103416,0.601227,0.787965,0.029444,-0.731086,0.372999,0.369296,0.755695,1.158825,0.032757,0.044360,-0.323240,-0.253430,0.053473,-0.224024,0.405197,-0.179082,0.790683,-0.771423,-0.230334,-1.226551,-0.671429,-0.380519,-0.077051,-0.388662,-0.804815,1.118241,-0.401749,-1.087244,0.192755,0.854516,-0.344142,0.859746,0.243014,0.353204,-0.171257,-0.365506,0.509206,0.088846,-0.553975,-0.130396,0.007731,-0.253081,-0.046949,1.289316,-0.262529,0.916212,-0.114595,-0.759626,-0.237173,0.821801,0.847864,-0.767100,-1.475631,0.552284,-0.049994,0.027379,-0.564154,-0.298492,0.527635,-0.610538,0.030009,-0.581422,-0.910600,1.081903,0.835365,0.931111,-0.722274,0.158337,-0.898053,0.050586,-1.229339,0.902825,0.393535,-0.103761,0.330004,-1.158282,-1.356514,0.823831,0.549533,-0.875433,0.963205,-0.458710,-0.973418,0.021008,0.355304,0.498622,-0.185481,0.459812,1.501544,0.572078,0.289916,-0.377730,0.431882,-0.093842,-0.397857,-0.167763,-0.665269,-0.875697]'::vector, '4ee8f5136e60c6b4591b9f7dc8a203ab95ab770ba3dfb09fe23e969c725f9e1d', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-redis-cache-stampede';
INSERT INTO content_embeddings (content_id, chunk_index, chunk_text, embedding, chunk_hash, status)
SELECT c.id, 0, 'SQLAlchemy의 `Session`은 커넥션 풀에서 커넥션을 빌려 쓰고, `session.close()`가 호출돼야 그 커넥션을 풀에 반납합니다. 세션을 명시적으로 닫지 않은 채 요청이 계속 들어오면, 풀에 남은 커넥션이 하나씩 줄어들다가 결국 고갈됩니다.

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(''postgresql://localhost/mydb'', pool_size=10, max_overflow=5)
SessionLocal = sessionmaker(bind=engine)

# 위험한 패턴: 예외가 나면 session.close()가 실행되지 않는다
def get_user_bad(user_id):
    session = SessionLocal()
    user = session.query(User).get(user_id)  # 여기서 예외가 나면 아래 close()에 도달하지 못한다
    session.close()
    return user

# 안전한 패턴: 예외가 나도 반드시 반납된다
def get_user_safe(user_id):
    session = SessionLocal()
    try:
        return session.query(User).get(user_id)
    finally:
        session.close()
```
`pool_size=10, max_overflow=5`는 기본으로 10개, 순간적으로 최대 15개까지 커넥션을 허용한다는 뜻입니다. `get_user_bad`처럼 예외 경로에서 `close()`를 건너뛰는 코드가 반복 호출되면, 풀의 커넥션이 하나씩 새어나가다가(connection leak) 결국 `TimeoutError: QueuePool limit ... reached`가 발생해 애플리케이션 전체가 응답 불가 상태에 빠집니다. FastAPI의 `Depends(get_db)` + `yield` + `finally: session.close()` 패턴이 널리 쓰이는 이유가 바로 이 반납을 프레임워크 차원에서 강제하기 위해서입니다.', '[0.195879,0.312015,-3.092501,-1.900322,0.817045,-1.247715,0.496454,-0.209217,-0.164242,-0.298017,-0.128399,1.286454,0.822831,-0.947269,0.285788,-0.421815,-0.656401,-1.471171,-0.648656,0.721361,-0.310977,-0.506392,-0.347532,-0.563311,1.660192,0.097261,-0.694288,-0.367236,-0.030982,0.740525,-0.196828,-0.034085,0.050885,-0.960916,-1.153631,-0.569867,-0.127096,-0.060650,0.139963,-0.026613,-0.080360,-0.646520,1.165344,-1.057706,0.386314,-0.498041,1.546312,-0.009147,0.421931,-0.938176,0.271250,-0.014651,-0.399050,-0.407195,1.567843,1.513923,-0.632142,1.214326,0.078919,-0.395220,1.698516,0.181705,-0.406655,0.938993,0.320963,-0.693415,0.088872,1.532478,0.140133,0.611923,1.051328,0.791783,-0.461673,-0.038939,-0.194659,0.543501,-0.905348,-0.593916,0.136895,1.362066,-1.171947,1.102641,0.809810,-0.618395,-0.153831,0.521934,-1.090969,-0.140606,-0.514413,0.713517,-0.360065,-0.960818,0.427351,-0.772062,-1.225363,0.651886,0.862266,0.716054,-0.515399,-0.334068,0.255461,-0.549991,-0.247778,-0.068505,-0.036738,0.735373,-0.748529,0.052040,-0.007297,0.710902,0.215883,0.999186,-1.526549,-0.010253,0.466422,-0.131524,1.110683,0.217756,0.079974,-0.225255,0.132044,-0.511292,-0.528948,0.364195,1.004299,1.243350,-0.433082,1.361001,0.338206,-0.468005,-0.258024,-0.779346,-0.539010,0.752293,0.434220,0.651526,-0.413074,-0.579541,0.274604,-0.391086,-0.108388,0.557990,-0.436616,0.338012,-0.313232,-0.291141,1.061146,-0.402803,-1.026764,0.757466,0.013073,-0.411471,0.063580,0.561703,0.262561,-0.470754,-0.123193,-0.239964,0.810149,-0.286082,0.836796,0.172457,-0.659222,0.418462,-1.110325,-1.086819,1.233972,1.128465,0.257092,-0.039868,-0.263992,-1.317786,-0.234709,0.092790,-0.241489,0.878658,0.116448,-0.934113,1.591798,-0.335076,0.907972,-1.345206,1.464905,0.389821,-0.420164,-0.162584,0.014072,-0.471896,-0.408527,-0.984577,0.438977,0.006525,-0.837393,-0.611618,-0.783820,-0.877323,0.793968,0.266362,0.185555,-1.585687,-0.937407,0.585753,-1.299784,0.167197,0.039323,0.932383,-0.332978,0.881277,-0.794950,0.678730,1.078369,0.414020,0.003320,0.188841,-0.094726,-0.665600,0.188575,0.016135,-0.414585,-0.309336,0.571717,0.022552,-0.336125,-0.016382,0.827767,0.463921,-0.316576,0.750327,-0.268987,0.382430,-0.612320,-1.268791,0.301785,-0.180458,0.068433,0.468510,-0.015505,1.415482,-0.347695,-0.873444,0.269775,-0.092422,-0.332750,-0.314443,-1.134079,-0.168359,-0.636801,-0.480942,0.019738,0.397090,0.385531,-0.191874,0.044357,0.645122,0.662843,-0.100195,0.774934,0.317662,0.815722,-0.508516,0.128430,-0.118894,0.232198,-0.848497,0.066404,-0.751773,-1.194008,-0.471511,-0.350234,0.297113,0.307383,0.097421,0.388978,1.263369,0.921000,0.631960,0.529518,0.299326,-0.581546,0.304880,-0.766009,-0.971228,-0.555537,0.958548,-0.266895,0.175903,0.501404,0.039019,0.386258,0.157464,1.075893,-0.410185,-0.594406,0.743169,0.079990,0.468785,0.520594,0.128336,0.651062,-0.386971,0.541411,1.301594,0.333703,0.643754,0.140021,-0.026694,0.041697,0.461297,0.255211,-0.176506,-0.859259,-0.972503,-0.389663,0.850246,-0.452387,1.146353,-0.080945,0.558351,0.604580,-0.808795,-0.545387,-1.204251,0.839835,-0.045326,-0.265251,0.138851,-0.858752,1.289603,-0.101355,-0.641617,-0.064624,0.687640,0.572047,-0.589015,-0.197644,0.281565,0.302317,0.110421,-0.392006,0.876467,0.685314,-0.644471,0.882264,-0.778302,-0.873470,-0.052703,-0.988648,0.131122,0.786992,0.553363,-0.319253,0.358308,-1.262720,0.207769,0.000485,-0.412580,0.054390,0.200552,0.287196,0.062556,1.006333,-0.520680,0.087087,-0.020090,0.044592,0.571001,0.893749,0.545974,0.508606,-0.800464,-0.800346,-0.594925,-0.679268,-0.254092,-0.178592,-0.038240,-0.798141,0.526717,-0.470754,1.444917,-0.254174,-1.014663,-0.377664,0.732178,0.225877,-0.281495,-0.004186,0.106955,-0.717661,0.762287,-0.347713,-0.870173,-0.327329,-0.047316,1.006906,0.133758,0.032100,0.259021,0.378278,0.319904,-0.882495,-1.283813,0.011154,0.210787,-0.288531,0.314963,-0.731105,-0.022571,0.737939,-0.139217,0.131160,0.087107,-0.088178,0.056181,-0.266224,0.803851,1.992210,0.973923,-0.430305,-0.967602,0.787588,0.777580,0.833905,0.287702,0.363963,-0.127024,0.156301,-0.088209,0.009290,-1.400864,0.354799,0.460009,1.119016,-0.242844,-0.670882,0.440685,0.910883,1.147487,-0.174243,1.172459,0.231404,-0.062885,-0.098426,0.179087,-0.023058,1.005455,0.984294,-1.618876,-0.943464,-0.068344,0.010299,0.923468,0.194352,-0.089901,0.574269,-1.032773,-0.006351,0.634450,-0.814636,1.360676,-0.550166,0.660561,-1.068033,0.384998,0.442025,0.347061,-0.144335,-0.663248,0.607896,0.349692,-0.798711,-0.111032,0.392550,-1.330285,-0.190633,0.364313,-0.002074,0.075200,0.699178,0.713681,0.785710,-0.237048,-1.115352,-0.469312,-0.061014,0.530738,1.017821,-0.166729,0.826044,0.177753,-0.044611,0.167686,0.278834,-0.314095,0.197851,-0.383611,0.286561,0.475000,0.268399,-0.144022,-0.165978,-0.225071,-0.338117,-0.031091,0.157189,-0.138486,1.128692,-0.640811,-0.939216,-0.713986,0.017503,0.363754,0.480830,0.522579,1.191075,-0.903653,0.762534,0.258352,-1.211681,0.641752,0.404405,-0.666605,0.074313,-0.173043,-1.704978,-0.031805,-0.016509,-1.065899,0.446485,-0.430737,-0.552759,0.121420,-0.933004,-0.550971,-0.044205,-1.462081,-0.639536,0.452567,0.023465,0.381967,0.469843,-0.031878,-0.316556,0.292307,0.757766,-0.145016,0.068841,0.031761,0.131552,-0.658939,0.431008,-0.050240,-0.364927,-1.062465,0.424276,-0.656342,-0.009233,-0.010834,-0.309414,0.299133,0.030390,-0.664008,0.589654,0.218008,1.253010,-0.771860,-0.669049,1.074900,-0.331212,0.932036,-0.112905,-1.497671,0.579746,-0.994814,0.519663,1.060471,0.484930,-0.212297,-0.324861,-1.148892,-0.013342,-0.758632,0.886398,1.253100,1.040350,0.040303,0.369953,-0.315816,0.385089,-0.539849,-0.487594,0.991056,0.543951,0.566221,0.452486,0.958942,-0.415901,-1.318218,-0.504211,-0.945678,0.280916,0.373424,0.072263,-0.193825,-0.349440,1.194958,-0.340320,0.558324,-0.525992,-1.108158,0.189974,-0.297731,-0.562431,-0.218094,0.372956,-1.109518,1.378848,0.080254,0.516025,-0.977426,-1.033468,-0.566206,0.819835,-0.265468,1.145741,0.617675,-1.321481,-1.181986,0.048719,0.835641,0.093448,-0.021537,-1.744530,-0.245116,-1.503303,1.166640,-0.972424,0.057299,0.574962,1.134720,1.542435,-0.312261,-0.603716,0.314224,0.049013,-1.632229,0.829675,1.500162,0.587286,-0.725570,1.573646,0.793857,0.235162,0.746858,1.064003,0.162667,0.284415,-0.309243,-1.408920,-1.015054,0.080247,-0.201317,-0.145531,-0.295457,0.920191,0.379433,-0.080591,-0.189481,-0.599800,-0.994333,-0.176339,0.250605,-0.411391,-0.915369,-0.276838,0.094711,1.371495,0.834232,-0.583050,-1.008288,0.165812,-0.464832,0.062269,0.036491,0.267856,-0.473639,0.579336,-0.695772,-0.846865,-0.790190,-1.363903,-0.750136,-0.275627,-0.256238,0.217837,0.528453,0.176081,-0.192138,0.301404,1.245535,-0.253448,0.474393,0.953799,0.912668,-0.864455,-0.583149,0.078135,0.635929,0.276166,-0.440462,-0.100423,0.607549,-0.481314,1.145977,-0.060513,-0.026763,-0.399407,-0.689957,0.166059,0.336678,-0.300214,-0.729594,-0.842559,0.802315,-0.059240,-0.331708,0.316924,-0.060827,0.225527,-0.986423,-0.059855,-0.276332,-1.569904,0.509393,-0.042721,0.086841,-1.017153,-0.984184,-0.987053,-0.399355,-0.333565,-0.346454,-0.680668,0.288108,0.512906,-0.825411,-0.816859,0.358869,0.219799,-0.174175,0.156346,-0.005424,-0.785584,0.973321,1.130256,-0.185587,0.176460,0.860123,1.368758,0.967395,-0.025259,0.192874,0.350196,0.372419,0.079637,-0.772534,-0.428178,-0.267524]'::vector, 'a5f11fb09f313e95dbc02d80ba95bff79eddb9495bddd48dda517d756435b9a8', 'ACTIVE'
FROM contents c WHERE c.slug = 'python-backend-sqlalchemy-session-pool-exhaustion';
