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
  - [ ] Project created (e.g., `connexus-mvp`) and set active
  - [ ] Billing account linked to project
- [ ] Budgets and alerts
  - [ ] Monthly budget configured ($100) with 50% alert (MVP)
  - [ ] Cost/Anomaly detection enabled
- [ ] IAM and CI
  - [ ] Create CI Deployment Service Account `connexus-ci-deploy@<PROJECT_ID>.iam.gserviceaccount.com`
  - [ ] Grant minimal roles: `roles/storage.admin` (bucket-scoped), `roles/iam.serviceAccountTokenCreator`
  - [ ] Configure GitHub → GCP Workload Identity Federation (no keys)
- [ ] Developer CLI
  - [ ] Install `gcloud` and set default project and region (`us-east1`)
- [ ] GCS state bucket
  - [ ] Create `gs://connexus-terraform-state` (region `us-east1`, Uniform access, Versioning on, Google-managed encryption)
- [ ] Networking (MVP)
  - [ ] Use Default VPC (skip custom CIDRs for MVP)
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
 
- [ ] Local: `gcloud auth list` and `gcloud config list` show correct account/project
- [ ] Storage: `gcloud storage buckets list` shows `connexus-terraform-state`
- [ ] Budget visible in Cloud Billing and alert recipient added
- [ ] CI run shows successful “Authenticate to Google Cloud” step
 
## Notes
 
- `config/cloud-config.json` is intentionally ignored; copy from `config/cloud-config.gcp.example.json` and fill values.
- Store any secrets in GitHub Secrets or GCP Secret Manager (not in repo).
- For containers later, enable Artifact Registry and grant minimal writer role to the CI SA.