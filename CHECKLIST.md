# ConnexUS Task 1 Checklist (VOIP Architecture Decision)

Use this file to track progress. Mark items when completed. Links point to created artifacts.

## Task 1 Deliverables

- [x] Create docs structure and ADR
  - [x] `docs/architecture/decisions/001-voip-architecture.md`
  - [x] `docs/architecture/decisions/001-presentation.md`
- [x] Telnyx research docs
  - [x] `docs/research/telnyx/sdk_capabilities.md` (template)
  - [x] `docs/research/telnyx/implementation_analysis.md`
  - [x] `docs/research/telnyx/feature_compatibility.md`
- [x] Call handling approaches
  - [x] `docs/research/call_handling_approaches.md`
- [x] Environment templates
  - [x] `.env.example`
  - [x] `lib/config/environment.dart`
- [x] Research validation test placeholder
  - [x] `test/research_validation.dart`

## Accounts & Access

- [ ] Telnyx developer account created
- [ ] Telnyx API key generated and stored securely
- [ ] Telnyx connection ID set up

## Tools Installed (local machine)

- [ ] Flutter (3.0+)
- [ ] Git
- [ ] Node.js & npm
- [ ] markdownlint-cli (global)
- [ ] markdown-pdf (global)

## Verification Commands

- [ ] List all docs
  - PowerShell: `Get-ChildItem -Recurse -Filter *.md | Sort-Object FullName | ForEach-Object { $_.FullName }`
- [ ] Lint markdown
  - `markdownlint docs/**/*.md`
- [ ] Generate ADR PDF
  - `cd docs/architecture/decisions; markdown-pdf 001-voip-architecture.md`

## Notes

- Task 1 is research + documentation only. No Flutter build expected yet.
- Webhook URL and TURN server details to be decided in Task 9 & follow-ups.


# ConnexUS Task 2 Checklist (Design System Architecture Diagram)

Use this section to track Task 2 progress and outputs.

## Task 2 Deliverables

- [x] Create architecture directories and scaffold
  - [x] `docs/architecture/diagrams/README.md`
  - [x] `docs/architecture/components/flutter-architecture.md`
  - [x] `docs/architecture/system-architecture.md`
  - [x] `docs/api/api-specification.yaml`
- [x] High-level system overview diagram
  - [x] `docs/architecture/diagrams/system-overview.mermaid`
  - [x] `docs/architecture/diagrams/system-overview.png`
- [x] Data flow diagrams
  - [x] `docs/architecture/diagrams/call-flow.mermaid`
  - [x] `docs/architecture/diagrams/call-flow.png`
  - [x] `docs/architecture/diagrams/sms-flow.mermaid`
  - [x] `docs/architecture/diagrams/sms-flow.png`
  - [x] `docs/architecture/diagrams/ai-interaction-flow.mermaid`
  - [x] `docs/architecture/diagrams/ai-interaction-flow.png`
- [x] Sequence diagrams
  - [x] `docs/sequences/user-registration.mermaid`
  - [x] `docs/sequences/ai-call-handling.mermaid`

## Tools Installed (diagramming)

- [x] `@mermaid-js/mermaid-cli` (global)
- [ ] PlantUML CLI (optional) — skipped for now

## Commands

- Regenerate diagrams (from project root):
  - `mmdc -i docs/architecture/diagrams/system-overview.mermaid -o docs/architecture/diagrams/system-overview.png`
  - `mmdc -i docs/architecture/diagrams/call-flow.mermaid -o docs/architecture/diagrams/call-flow.png`
  - `mmdc -i docs/architecture/diagrams/sms-flow.mermaid -o docs/architecture/diagrams/sms-flow.png`
  - `mmdc -i docs/architecture/diagrams/ai-interaction-flow.mermaid -o docs/architecture/diagrams/ai-interaction-flow.png`

## Notes

- Task 2 outputs will be referenced by Task 3 (API details) and Task 4 (Flutter setup).


# ConnexUS Task 3 Checklist (Define API Structure & Endpoints)

Use this section to track Task 3 progress and outputs.

## Task 3 Deliverables

- [x] OpenAPI main file
  - [x] `api-docs/openapi/connexus-api.yaml`
- [x] Schemas
  - [x] `api-docs/openapi/schemas/user.yaml`
  - [x] `api-docs/openapi/schemas/auth.yaml`
  - [x] `api-docs/openapi/schemas/call.yaml`
- [x] Paths
  - [x] `api-docs/openapi/paths/auth.yaml`
  - [x] `api-docs/openapi/paths/users.yaml`
  - [x] `api-docs/openapi/paths/calls.yaml`
  - [x] `api-docs/openapi/paths/sms.yaml`
  - [x] `api-docs/openapi/paths/ai.yaml`
  - [x] `api-docs/openapi/paths/routing.yaml`
  - [x] `api-docs/openapi/paths/analytics.yaml`
- [x] Postman collection
  - [x] `api-docs/postman/connexus-api.postman_collection.json`
- [x] Validation and docs server
  - [x] `api-docs/test/validate-api.js`
  - [x] `api-docs/generate-docs.js`
  - [x] `api-docs/package.json` with deps

## Tools Installed (API)

- [x] Node.js & npm
- [x] `@stoplight/spectral-cli` (global)

## Commands

- Validate OpenAPI:
  - `node api-docs/test/validate-api.js`
- Lint OpenAPI (optional):
  - `spectral lint api-docs/openapi/connexus-api.yaml`
- Serve Swagger UI docs:
  - `cd api-docs && node generate-docs.js` then open `http://localhost:3001/api-docs`

## Notes

- Webhook and WebSocket events may be extended in later tasks.


# ConnexUS Task 4 Checklist (Set Up Flutter Project)

Use this section to track Task 4 progress and outputs.

## Task 4 Deliverables

- [x] Flutter project directory created (scaffolded)
  - [x] `connexus_app/pubspec.yaml`
- [x] Core structure and base files
  - [x] `connexus_app/lib/core/constants/app_constants.dart`
  - [x] `connexus_app/lib/core/errors/{failures.dart,exceptions.dart}`
  - [x] `connexus_app/lib/core/utils/logger.dart`
  - [x] `connexus_app/lib/core/config/app_config.dart`
  - [x] `connexus_app/lib/core/theme/app_theme.dart`
  - [x] `connexus_app/lib/core/routes/app_router.dart`
- [x] Domain base
  - [x] `connexus_app/lib/domain/repositories/base_repository.dart`
  - [x] `connexus_app/lib/domain/usecases/base_usecase.dart`
- [x] Presentation base
  - [x] `connexus_app/lib/presentation/screens/base_screen.dart`
  - [x] `connexus_app/lib/presentation/screens/splash/splash_screen.dart`
- [x] App entry and DI
  - [x] `connexus_app/lib/app.dart`
  - [x] `connexus_app/lib/injection.dart`
  - [x] `connexus_app/lib/main.dart`

## Next Steps to finalize platform scaffolding

- [ ] Install Flutter SDK (3.16.0+), Dart (3.2.0+)
- [ ] Run: `cd connexus_app && flutter create .` to generate android/ios
- [ ] Apply Android changes in `android/app/build.gradle` and `AndroidManifest.xml`
- [ ] Apply iOS changes in `ios/Runner/Info.plist` and `ios/Podfile`
- [ ] Run: `flutter pub get && flutter run`

## Commands

- Create missing platform folders after installing Flutter:
  - `cd connexus_app && flutter create .`
- Get packages and list deps:
  - `flutter pub get && flutter pub deps`

## Notes

- Platform config steps require Flutter SDK. Once installed, follow the file edits outlined in Task 4 to update Android/iOS.


# ConnexUS Task 5 Checklist (Configure Git Repository & Branching Strategy)

Use this section to track Task 5 progress and outputs.

## Task 5 Deliverables

- [x] Git repository initialized at project root
- [x] Initial commit created with existing project files
- [x] `.gitignore` added with Flutter/Dart/IDE patterns
- [x] `BRANCHING_STRATEGY.md` documented
- [x] GitHub PR template added: `.github/pull_request_template.md`
- [x] Issue templates added: `.github/ISSUE_TEMPLATE/{bug_report.md,feature_request.md,task.md}`
- [x] Branch protection documentation: `.github/branch-protection-config.md`
- [x] Pre-commit hook added: `.githooks/pre-commit` and hooksPath configured
- [x] `develop` branch created locally
- [ ] Remote repository connected and branches pushed
- [ ] Branch protection rules configured in GitHub UI

## Commands

- Verify repo: `git status && git branch -a && git remote -v`
- Configure hooks: `git config core.hooksPath .githooks`
- Create develop: `git checkout -b develop`
- Push branches (after remote): `git push -u origin main && git push -u origin develop`

## Notes

- Remote creation/push and branch protection require GitHub/GitLab access.


# ConnexUS Task 6 Checklist (Set Up CI/CD Pipeline Basics)

Use this section to track Task 6 progress and outputs.

## Task 6 Deliverables

- [x] CI workflows created
  - [x] `.github/workflows/ci.yml` (analyze, test, Android/iOS build, summary)
  - [x] `.github/workflows/build-release.yml` (manual tagged release builds and assets)
  - [x] `.github/workflows/pr-checks.yml` (PR title, size check, lint, tests)
- [x] CI configuration and branch protection template
  - [x] `.github/ci-config.yml`
  - [x] `.github/branch-protection.json`
- [x] Build script
  - [x] `connexus_app/scripts/ci/build.sh`
- [x] Sample test scaffolded
  - [x] `connexus_app/test/unit/sample_test.dart`

## CI/CD Notes

- Workflows are at repo root; default working-directory is `connexus_app`.
- Runners:
  - Ubuntu: analysis, tests, Android builds
  - macOS: iOS builds (no code signing, unsigned IPA artifact)
- Artifacts uploaded:
  - Android: debug/profile/release APKs and release AAB
  - iOS: unsigned IPA zip
- Coverage upload via `codecov` is best-effort (does not fail build).

## Commands

- Add and push CI/CD (from repo root):
  - `git add .github/ connexus_app/scripts/ci connexus_app/test`
  - `git commit -m "feat(ci): add CI/CD workflows, configs, scripts, and sample test"`
  - `git push origin develop`
- Local check of workflow definitions (requires `act`):
  - `act -W .github/workflows/ci.yml --list`
  - `act -W .github/workflows/ci.yml -j analyze`
- Make build script executable (on macOS/Linux):
  - `chmod +x connexus_app/scripts/ci/build.sh`

## Pending Items (Post-MVP)

- [ ] Android signing (keystore) and secure secret storage
- [ ] iOS signing (Apple Developer account, certificates/profiles)
- [ ] Store deployments (Play Console / App Store Connect / TestFlight)
- [ ] Slack/Email notifications and advanced coverage gates

## Verification

- On push to `develop`/`main`:
  - [x] Analysis runs
  - [x] Tests run with coverage
  - [x] Android builds (debug/profile/release) artifacts uploaded
  - [x] iOS unsigned build on macOS runner, artifact uploaded
- On PR:
  - [x] PR title/size checks
  - [x] Linting, analysis, tests with coverage comment
- On manual release dispatch:
  - [x] Tag and GitHub Release created (draft)
  - [x] Android APK and iOS unsigned IPA uploaded to release assets

# ConnexUS Task 7 Checklist (Create Development, Staging Environments)

Use this section to track Task 7 progress and outputs.

## Task 7 Deliverables

- [x] Environment package setup
  - [x] `flutter_dotenv` added to dependencies
  - [x] `flutter_flavorizr` added to devDependencies (for future automation)
  - [x] `pubspec.yaml` assets configured for `env/`
- [x] Multi-environment configuration
  - [x] Refactor `connexus_app/lib/core/config/app_config.dart` to load from env
  - [x] Add entrypoints: `lib/main_{development,staging,production}.dart`
  - [x] Update `lib/app.dart` to use env name/banner and appName/debug flags
- [x] Dev tooling & scripts
  - [x] VS Code launch configs: `connexus_app/.vscode/launch.json`
  - [x] Scripts: `scripts/run_dev.sh`, `scripts/run_staging.sh`, `scripts/run_prod.sh`, `scripts/build_apk.sh`, `scripts/build_ios.sh`
- [x] Environment-aware services
  - [x] `lib/data/services/api_client.dart` (Dio, baseUrl from env)
- [x] Gitignore updates
  - [x] Track non-sensitive dev/staging env files if needed
  - [x] Keep production env ignored

## Notes

- Place environment files under `connexus_app/env/`:
  - `.env.development` and `.env.staging` can be committed if non-sensitive
  - `.env.production` must NOT be committed (secrets)
- If env files are missing locally, the app falls back to safe defaults (dev).
- Android/iOS platform folders are present. Android flavors configured; iOS schemes require Xcode setup.

## Commands

- Run dev/staging/prod:
  - `flutter run --flavor development --target lib/main_development.dart`
  - `flutter run --flavor staging --target lib/main_staging.dart`
  - `flutter run --flavor production --target lib/main_production.dart`
- Build APKs:
  - `connexus_app/scripts/build_apk.sh development|staging|production`
- iOS build (macOS):
  - `connexus_app/scripts/build_ios.sh development|staging|production`

## Pending (Platform-specific)

- [x] Generate platforms: `cd connexus_app && flutter create .`
- [x] Android flavors in `android/app/build.gradle.kts` (development/staging/production)
- [ ] iOS schemes (create in Xcode). `ios/Flutter/*.xcconfig` added; Info.plist uses dynamic values

## Verification

- [x] Environment banner appears in non-production builds
- [x] App title switches per environment
- [x] API client baseUrl reflects env
- [x] Scripts and VS Code targets point to correct entrypoints

## Task 7 – Local Verification Update

- Env templates added at `connexus_app/env/README.md`. Create `.env.*` files locally.
- Flutter SDK not found on PATH locally; dev build verification pending installation.

# ConnexUS Task 8 Checklist (Set Up Cloud Provider Account)

Use this section to track Task 8 progress and outputs.

## Task 8 Deliverables

- [x] Choose cloud provider and model (GCP, single project for MVP)
  - [x] Project created (e.g., `connexus-mvp`) and set active
  - [x] Billing account linked to project
- [ ] Budgets and alerts
  - [ ] Monthly budget configured ($100) with 50% alert (MVP)
  - [ ] Cost/Anomaly detection enabled
- [x] IAM and CI
  - [x] Create CI Deployment Service Account `connexus-ci-deploy@<PROJECT_ID>.iam.gserviceaccount.com`
  - [x] Grant minimal roles: `roles/storage.admin` (bucket-scoped), `roles/iam.serviceAccountTokenCreator`
  - [x] Configure GitHub → GCP Workload Identity Federation (no keys)
- [x] Developer CLI
  - [x] Install `gcloud` and set default project and region (`us-east1`)
- [x] GCS state bucket
  - [x] Create `gs://connexus-terraform-state` (region `us-east1`, Uniform access, Versioning on, Google-managed encryption)
- [x] Networking (MVP)
  - [x] Use Default VPC (skip custom CIDRs for MVP)
- [ ] Artifact storage (containers) — optional
  - [ ] Decide whether to create Artifact Registry now (skip for MVP unless containers needed)
- [x] Project repo updates
  - [x] `.gitignore` includes cloud credentials/Terraform ignores; `config/cloud-config.json` ignored
  - [x] `config/cloud-config.gcp.example.json` added (copy to `config/cloud-config.json`, ignored)
  - [x] `.github/workflows/ci.yml` updated to authenticate to GCP via Workload Identity Federation

## Files Created/Modified (Task 8)

- Created
  - `config/cloud-config.gcp.example.json`
- Modified
  - `.github/workflows/ci.yml` (added GCP auth via WIF)
  - `.gitignore` already contains ignores for local cloud configs

## How to Complete the Manual Steps (GCP)
 
1) Create project and link billing
- In Google Cloud Console: Create project (e.g., `connexus-mvp`) in org/folder if applicable
- Link the project to your Billing Account
 
2) Configure budget and alerts
- Cloud Billing → Budgets & alerts → Create budget ($100), add 50% alert to your email(s)
- Enable Cost/Anomaly detection
 
3) Install and initialize gcloud (local)
- Install Google Cloud SDK
- Run: `gcloud init` → choose `connexus-mvp` and region `us-east1`
 
4) Create CI Service Account and minimal roles
- Create SA: `gcloud iam service-accounts create connexus-ci-deploy --display-name="ConnexUS CI Deploy"`
- Scope Storage Admin to state bucket after you create it (step 5)
- Ensure SA has `roles/iam.serviceAccountTokenCreator` (for WIF)
 
5) Create GCS bucket for Terraform state
- `gcloud storage buckets create gs://connexus-terraform-state --location=us-east1`
- Enable uniform access and versioning:
  - `gcloud storage buckets update gs://connexus-terraform-state --uniform-bucket-level-access`
  - `gcloud storage buckets update gs://connexus-terraform-state --versioning`
 
6) Configure GitHub OIDC → GCP (Workload Identity Federation)
- Create a Workload Identity Pool and Provider for GitHub
- Grant `roles/iam.workloadIdentityUser` on the CI SA to the GitHub principal set
- In GitHub repo secrets, set:
  - `GCP_WIF_PROVIDER` = full resource name of the provider
  - `GCP_WIF_SERVICE_ACCOUNT` = `connexus-ci-deploy@<PROJECT_ID>.iam.gserviceaccount.com`
  - `GCP_PROJECT_ID` = your project id
 
7) CI verification
- Push a branch/PR and confirm `.github/workflows/ci.yml` shows “Authenticate to Google Cloud” succeeded

## Verification (Post-Setup)

- [x] Local: `gcloud auth list` and `gcloud config list` show correct account/project
- [x] Storage: `gcloud storage buckets list` shows `connexus-terraform-state`
- [ ] Budget visible in Cloud Billing and alert recipient added
- [x] CI run shows successful “Authenticate to Google Cloud” step

## Notes

- `config/cloud-config.json` is intentionally ignored; copy from `config/cloud-config.gcp.example.json` and fill values.
- Store any secrets in GitHub Secrets or GCP Secret Manager (not in repo).
- For containers later, enable Artifact Registry and grant minimal writer role to the CI SA.
- Android/iOS Flutter builds are currently blocked by the legacy Android embedding warning; CI treats them as best-effort so Analyze + Tests still gate changes. Plan a separate Android embedding migration task to turn builds back into required checks.

# ConnexUS Task 9 Checklist (Configure Basic Backend API Server)

Use this section to track Task 9 progress and outputs.

## Task 9 Deliverables

- [x] Backend project scaffold created
  - [x] `backend/package.json` with scripts and engines
  - [x] `backend/tsconfig.json` (TypeScript config)
  - [x] `backend/nodemon.json` (dev runner)
  - [x] `backend/.eslintrc.json` and `backend/.prettierrc`
  - [x] `backend/jest.config.js`
- [x] Environment templates
  - [x] `backend/env.example` (copy to `backend/.env` locally)
- [x] Core server implementation (Express + TypeScript)
  - [x] `backend/src/server.ts`
  - [x] `backend/src/app.ts`
  - [x] `backend/src/config/index.ts` (config loader)
  - [x] `backend/src/config/logger.ts` (Winston logger)
  - [x] `backend/src/middleware/error.middleware.ts`
  - [x] `backend/src/middleware/validation.middleware.ts`
- [x] Routes and placeholders aligned to API spec
  - [x] `backend/src/routes/index.ts`
  - [x] `backend/src/routes/auth.routes.ts`
  - [x] `backend/src/routes/user.routes.ts`
  - [x] `backend/src/routes/call.routes.ts`
  - [x] `backend/src/routes/ai.routes.ts`
  - [x] `backend/src/routes/sms.routes.ts`
  - [x] `backend/src/routes/analytics.routes.ts`
- [x] Types and utilities
  - [x] `backend/src/types/index.d.ts`
  - [x] `backend/src/utils/constants.ts`
- [x] Tests
  - [x] `backend/src/__tests__/integration/health.test.ts`

## How to Install and Run (Local)

1) Prereqs
- Node.js v18+ and npm v9+ installed:
  - `node --version`
  - `npm --version`

2) Configure environment
- Copy `backend/env.example` → `backend/.env` and adjust values
  - For dev: keep defaults; set `CORS_ORIGIN` to your local UIs as needed

3) Install dependencies
- From repo root:
  - PowerShell:
    - `cd backend`
    - Install runtime deps:
      - `npm install express cors helmet morgan compression dotenv`
      - `npm install express-rate-limit express-validator`
      - `npm install winston`
    - Install dev deps:
      - `npm install -D typescript ts-node nodemon eslint prettier`
      - `npm install -D @types/node @types/express @types/cors @types/morgan @types/compression`
      - `npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin`
      - `npm install -D jest ts-jest @types/jest supertest @types/supertest`

4) Start the server (dev)
- `npm run dev`
- Expected logs include:
  - `🚀 Server is running on port 3000`
  - `📚 API Documentation: http://localhost:3000/api/v1/docs`
  - `🏥 Health Check: http://localhost:3000/health`

5) Run tests
- `npm test`
- With coverage: `npm run test -- --coverage`

## Quick Verification (Local)

- [x] `GET http://localhost:3000/health` returns status `success`
- [x] `GET http://localhost:3000/api/v1/docs` returns endpoints list
- [x] `POST http://localhost:3000/api/v1/auth/login` returns placeholder response
- [x] Jest tests pass
- [x] Winston logs emit to console and `backend/logs/*` (on runtime)

## Notes

- Do not commit `backend/.env`. Use `backend/env.example` as a template.
- Database connection will be added in Task 10 (files created later under `backend/src/config/database.ts` as needed).
- Authentication middleware will be added in Task 11; WebSocket server in Task 12.
- Route handlers currently return placeholders pending subsequent tasks.

## Git Commands (suggested)

- Stage and commit:
  - `git add backend CHECKLIST.md`
  - `git commit -m "feat(backend): implement basic API server structure (Task 9)"`

## Status

- [x] Basic Express server configured with TypeScript
- [x] Middleware stack implemented (security, logging, error handling)
- [x] Route structure defined with placeholder endpoints
- [x] Environment configuration system in place (template provided)
- [x] Testing framework configured (Jest + Supertest)
- [x] Development workflow with hot reload (Nodemon + ts-node)
- [x] Error handling and logging system (centralized + Winston)

# ConnexUS Task 10 Checklist (Set Up Database)

Use this section to track Task 10 progress and outputs.

## Task 10 Deliverables

- [x] Database configuration and tooling
  - [x] PostgreSQL connection settings in `backend/env.example` (DB_* variables, DATABASE_URL, pool config)
  - [x] Knex configuration file `backend/knexfile.ts` for development/staging/production
  - [x] NPM scripts for database operations in `backend/package.json` (`db:migrate`, `db:rollback`, `db:seed`, `db:status`, etc.)
- [x] Database connection module and types
  - [x] `backend/src/database/index.ts` (Knex instance, health check, pool stats, graceful shutdown)
  - [x] `backend/src/database/types.ts` (TypeScript enums and interfaces for users, calls, SMS, AI config, etc.)
- [x] Initial schema migrations
  - [x] `backend/src/database/migrations/20251125000000_initial_schema.ts` (users, phone_numbers, ai_configurations, business_hours, call_records, sms_templates, sms_messages, faq_entries, blocked_numbers, refresh_tokens)
- [x] Seed data for development
  - [x] `backend/src/database/seeds/01_development_data.ts` (test user, phone numbers, AI config, business hours, SMS templates, FAQ entries, sample call records, blocked numbers)
- [x] Repository layer (data access)
  - [x] `backend/src/repositories/userRepository.ts`
  - [x] `backend/src/repositories/callRecordRepository.ts`
  - [x] `backend/src/repositories/index.ts`
- [x] Express integration and test routes
  - [x] Updated `backend/src/app.ts` with database-aware `/health` and `/db-stats` endpoints
  - [x] Updated `backend/src/routes/index.ts` with API info root and `/test-db` endpoint (non-production only)
  - [x] Updated `backend/src/server.ts` to check DB connection on startup and close pool on shutdown

## How to Install and Run (Local, Database)

1) Prereqs
- PostgreSQL v14+ installed locally and running
- Node.js v18+ and npm v9+ installed:
  - `node --version`
  - `npm --version`

2) Configure database and environment
- In PostgreSQL (psql as superuser), create user and database:
  - `CREATE USER connexus_dev WITH PASSWORD 'connexus_dev_password';`
  - `CREATE DATABASE connexus_development OWNER connexus_dev;`
  - `GRANT ALL PRIVILEGES ON DATABASE connexus_development TO connexus_dev;`
  - `\c connexus_development`
  - `GRANT ALL ON SCHEMA public TO connexus_dev;`
- Copy `backend/env.example` → `backend/.env` and keep the default DB_* values (or adjust as needed).

3) Install dependencies (from repo root)
- PowerShell:
  - `cd backend`
  - `npm install` (will install `pg`, `knex`, and tooling added in Task 10)

4) Run migrations and seeds
- From `backend`:
  - `npm run db:migrate`      # runs latest migrations against connexus_development
  - `npm run db:status`       # shows applied/pending migrations
  - `npm run db:seed`         # inserts development test data

## Verification (API + Database)

- [ ] `npm run dev` starts the server with log output including:
  - `🚀 Server is running on port 3000`
  - `🏥 Health Check: http://localhost:3000/health`
- [ ] `GET http://localhost:3000/health` returns JSON including:
  - `status: "success"`
  - `message: "ConnexUS API is running"`
  - `environment`, `version`
  - `database.connected: true` and `database.pool` stats
- [ ] `GET http://localhost:3000/db-stats` (non-production) returns:
  - `pool.used`, `pool.free`, `pool.pending`
  - `tables.users`, `tables.phone_numbers`, `tables.call_records`, `tables.sms_templates`, `tables.ai_configurations`
- [ ] `GET http://localhost:3000/api/v1/test-db` (non-production) returns:
  - `"success": true`
  - `"data.userCount" >= 1`
  - `"data.testUserExists": true` and `"data.testUserEmail": "test@connexus.dev"`
  - `"data.callStats.total" >= 0` (basic stats for recent calls)
- [ ] In psql (`psql -h localhost -U connexus_dev -d connexus_development`):
  - `\dt` shows the 12 tables (`users`, `phone_numbers`, `ai_configurations`, `business_hours`, `call_records`, `sms_templates`, `sms_messages`, `faq_entries`, `blocked_numbers`, `refresh_tokens`, `knex_migrations`, `knex_migrations_lock`)
  - `SELECT email, first_name, status FROM users;` shows the seeded test user

## Notes

- Database configuration lives in `backend/env.example` / `backend/.env`; do not commit secrets.
- CLI commands use Knex via TypeScript (`backend/knexfile.ts`) and `ts-node` wrappers in `backend/package.json`.
- Seed password hashing uses SHA-256 for development only; production auth will use bcrypt in Task 11.

# ConnexUS Task 11 Checklist (Implement Basic API Authentication)

Use this section to track Task 11 progress and outputs.

## Task 11 Deliverables

- [x] Authentication configuration
  - [x] `backend/src/config/auth.config.ts` (JWT access/refresh secrets and bcrypt rounds)
  - [x] Environment variables added to `backend/env.example`:
    - [x] `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
    - [x] `JWT_ACCESS_EXPIRY`, `JWT_REFRESH_EXPIRY`
    - [x] `BCRYPT_ROUNDS`
- [x] Type definitions
  - [x] `backend/src/types/auth.types.ts` (JWT payload, auth request types, auth responses)
- [x] Authentication service
  - [x] `backend/src/services/auth.service.ts` (password hashing, token generation/verification, validation helpers, UUID generation)
- [x] Authentication middleware
  - [x] `backend/src/middleware/auth.middleware.ts` (JWT authentication, optional auth, basic auth rate limiting)
- [x] Authentication controller and routes
  - [x] `backend/src/controllers/auth.controller.ts` (register, login, refresh, logout, current user)
  - [x] `backend/src/routes/auth.routes.ts` (wired to `/api/v1/auth` via `backend/src/routes/index.ts`)
- [x] User repository and database support
  - [x] `backend/src/repositories/userRepository.ts` updated with `updatePassword`, `emailExists`, and `updateLastLogin`
  - [x] `backend/src/database/migrations/20251125000000_initial_schema.ts` already includes `users.last_login_at` and `refresh_tokens` table
- [x] Build and type-check
  - [x] `npm run build` from `backend` completes without TypeScript errors

## How to Install and Run (Auth)

1) Configure environment
- Copy `backend/env.example` → `backend/.env` and set:
  - `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` to strong, unique values
  - Optionally adjust `JWT_ACCESS_EXPIRY`, `JWT_REFRESH_EXPIRY`, and `BCRYPT_ROUNDS`

2) Install dependencies
- From repo root (PowerShell):
  - `cd "C:\Users\anish\OneDrive\Desktop\ConnexUS AI App\backend"`
  - `npm install`

3) Start the server (dev)
- `npm run dev`
- Expected logs include:
  - `🚀 Server is running on port 3000`
  - `🏥 Health Check: http://localhost:3000/health`
  - `📚 API Documentation: http://localhost:3000/api/v1/docs`

## Verification (Auth Endpoints)

- [ ] `POST http://localhost:3000/api/v1/auth/register`
  - Request body: `{ "email", "password", "firstName", "lastName" }`
  - Strong password required (length 8+, upper/lowercase, number, special char)
  - Response includes `success: true`, user object, and `tokens.accessToken` / `tokens.refreshToken`
- [ ] `POST http://localhost:3000/api/v1/auth/login`
  - Valid credentials return `success: true` and token pair
  - Invalid credentials return `success: false` and `message: "Invalid email or password"`
- [ ] `GET http://localhost:3000/api/v1/auth/me`
  - With `Authorization: Bearer <accessToken>` returns current user profile
  - Without/invalid token returns `401` and `success: false`
- [ ] `POST http://localhost:3000/api/v1/auth/refresh`
  - With valid `refreshToken` in body returns new access/refresh token pair
- [ ] `POST http://localhost:3000/api/v1/auth/logout`
  - Returns `success: true` and logout message (client should discard tokens)

## Notes

- Rate limiting for auth endpoints is implemented in-memory (`rateLimitAuth`) for MVP; consider `express-rate-limit` or a shared store in production.
- Passwords are hashed with bcrypt via `auth.service.ts`; the SHA-256 hashes in development seeds remain only for initial data and are superseded by Task 11 for real user accounts.

# ConnexUS Task 12 Checklist (Set Up WebSocket Server for Real-time Communication)

Use this section to track Task 12 progress and outputs.

## Task 12 Deliverables

- [x] WebSocket dependencies and configuration
  - [x] Added Socket.IO and Redis adapter dependencies in `backend/package.json`:
    - [x] `socket.io`
    - [x] `@socket.io/redis-adapter`
    - [x] `redis`
    - [x] `socket.io-client` (for local test client)
  - [x] Updated `backend/env.example` with WebSocket-related environment variables:
    - [x] `WS_CORS_ORIGIN`
    - [x] `WS_PING_INTERVAL`
    - [x] `WS_PING_TIMEOUT`
    - [x] `REDIS_URL` (optional, for horizontal scaling)
- [x] WebSocket types and core interfaces
  - [x] `backend/src/websocket/types/socket.types.ts` (client/server events, room types, connection data, errors)
- [x] WebSocket authentication middleware
  - [x] `backend/src/websocket/middleware/socket-auth.middleware.ts`
    - [x] Extracts JWT access token from handshake auth/headers/query
    - [x] Reuses `auth.service.ts` (`verifyAccessToken`) for token verification
    - [x] Looks up user via `userRepository.findById` and enforces `UserStatus.ACTIVE`
    - [x] Attaches `SocketUserData` (with `phoneNumbers` derived from `users.phone_number`) to `AuthenticatedSocket`
- [x] Connection and room management services
  - [x] `backend/src/websocket/services/connection-manager.service.ts`
    - [x] Tracks active connections per user (multi-device support)
    - [x] Provides `isUserOnline`, `getUserSocketIds`, and `disconnectUser`
    - [x] Exposes connection statistics and stale-connection cleanup
  - [x] `backend/src/websocket/services/room-manager.service.ts`
    - [x] Manages user, phone, call, and broadcast rooms
    - [x] Auto-joins user and phone rooms on connect
    - [x] Provides helpers for call rooms and broadcasting to rooms/users
- [x] WebSocket event handlers
  - [x] `backend/src/websocket/handlers/connection.handler.ts`
    - [x] Registers connections and joins user rooms
    - [x] Handles auth refresh, presence updates/typing, room join/leave, ping, and disconnect events
  - [x] `backend/src/websocket/handlers/call.handler.ts`
    - [x] Handles call initiation, answer, reject, hangup, mute, and hold events
    - [x] Provides `emitIncomingCall` for future Telnyx webhook integration
- [x] WebSocket server implementation and exports
  - [x] `backend/src/websocket/socket-server.ts`
    - [x] Creates typed `Socket.IO` server attached to the HTTP server
    - [x] Applies `socketAuthMiddleware` for all connections
    - [x] Optionally configures Redis adapter via `REDIS_URL`
    - [x] Exposes `getStats`, `broadcast`, `sendToUser`, and `shutdown`
  - [x] `backend/src/websocket/index.ts` (module exports for server, types, middleware, services, handlers)
- [x] Express integration (health and stats)
  - [x] Updated `backend/src/app.ts` to:
    - [x] Initialize `SocketServer` on top of the existing HTTP listener in `App.listen()`
    - [x] Extend `/health` to include WebSocket statistics (connections, users, rooms)
    - [x] Add `GET /ws/stats` top-level endpoint returning raw WebSocket stats
- [x] HTTP API routes for WebSocket operations
  - [x] `backend/src/routes/websocket.routes.ts`
    - [x] `GET /api/v1/ws/stats` (authenticated) – returns WebSocket server statistics
    - [x] `POST /api/v1/ws/broadcast` (authenticated) – broadcasts an event to all users, optionally excluding some
    - [x] `POST /api/v1/ws/send-to-user` (authenticated) – sends an event to a specific user
    - [x] `POST /api/v1/ws/disconnect-user` (authenticated) – force-disconnects a user
    - [x] `GET /api/v1/ws/user/:userId/status` (authenticated) – online status and connection count per user
  - [x] Updated `backend/src/routes/index.ts` to mount WebSocket routes under `/ws`
- [x] Test client and verification tooling
  - [x] `backend/tests/websocket-test-client.ts`
    - [x] Uses `socket.io-client` to connect to `ws://localhost:3000` with a test JWT access token
    - [x] Exercises `connection:established`, `ping`, `presence:update`, and `room:join` flows

## How to Install and Run (WebSocket)

1) Install dependencies (from `backend`):
- `npm install`

2) Ensure environment is configured:
- Copy `backend/env.example` → `backend/.env` and verify:
  - `JWT_ACCESS_SECRET` is set (used for WebSocket auth)
  - `WS_CORS_ORIGIN` includes your local frontend origins
  - Optionally set `REDIS_URL` if you want to test the Redis adapter

3) Start the server (dev):
- `npm run dev`
- Expected logs include:
  - `🚀 Server is running on port 3000`
  - `🏥 Health Check: http://localhost:3000/health`
  - `🔌 WebSocket server ready on port 3000`

4) Test WebSocket connectivity:
- In a separate terminal (from `backend`):
  - `npx ts-node tests/websocket-test-client.ts`
- Expected console output:
  - `Connection established: { connectionId, serverTime, user: { ... } }`
  - `Pong received, server time: ...`
  - `Presence update sent`
  - `Room join response: { success: true, roomId: 'test-room-1', participants: [...] }`

5) Verify health and stats endpoints:
- `GET http://localhost:3000/health`
  - Includes `websocket` object with `connections`, `users`, `rooms` (or `null` if not yet initialized)
- `GET http://localhost:3000/ws/stats`
  - Returns raw WebSocket `connections` and `rooms` stats
- `GET http://localhost:3000/api/v1/ws/stats` (with valid `Authorization: Bearer <accessToken>`)
  - Returns WebSocket stats wrapped in `{ success: true, data: ... }`

## Notes

- WebSocket authentication uses the same JWT access tokens as the REST API via `auth.service.verifyAccessToken`.
- Currently, `phoneNumbers` for a socket user are derived from the primary `users.phone_number` field; a dedicated phone-numbers repository can be integrated later.
- Redis integration for Socket.IO is optional; if `REDIS_URL` is not set, the server runs in single-instance mode.
- WebSocket HTTP routes are protected by the existing `authenticateToken` middleware and are intended for internal/admin use (broadcasts, user disconnects, status checks).

## Status

- [x] WebSocket server attached to existing Express HTTP server
- [x] JWT-authenticated Socket.IO connections with per-user rooms
- [x] Connection and room management services with basic stats and cleanup
- [x] Call-related event handlers ready for Telnyx integration in later tasks
- [x] Health and stats endpoints exposing WebSocket metrics
- [x] Checklist and documentation updated for Task 12
- JWT payloads include `userId`, `email`, and `type` (`access` or `refresh`); `auth.middleware.ts` attaches the decoded payload as `req.authUser` for downstream handlers.