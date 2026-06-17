## Step 1: W1 인프라 기준선
### 1.1 PostgreSQL 전환 + 중앙 스키마
- [x] MySQL→PostgreSQL(SSOT 5432 + pgvector 5433)
- [x] 중앙 Flyway 스키마(공통 규약 set_updated_at)
- [x] users 골격 + 법적 분리보관 dormant_user_archives(정보통신망법 §29)
### 1.2 GitHub Packages
- [x] shared GitHub Packages(Maven) 배포
