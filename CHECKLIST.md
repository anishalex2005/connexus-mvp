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