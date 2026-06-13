FROM flyway/flyway:11-alpine
# SQL 마이그레이션을 이미지에 내장한다. CI가 SHA 태그로 push하고
# gitops job.yaml의 이미지 태그를 교체하면 ArgoCD가 Job을 재실행한다.
COPY src/main/resources/db/migration /flyway/sql
