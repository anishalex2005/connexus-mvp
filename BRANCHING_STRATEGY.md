# Git Branching Strategy for ConnexUS Mobile App

## Branch Structure

### Protected Branches

#### `main` (Production)
- **Purpose**: Production-ready code
- **Protection Rules**: 
  - Requires pull request reviews (minimum 1)
  - Requires status checks to pass
  - No direct pushes
  - Administrators included in restrictions

#### `develop` (Development)
- **Purpose**: Integration branch for features
- **Protection Rules**:
  - Requires pull request reviews
  - Requires status checks to pass
  - No force pushes

#### `staging` (Pre-production)
- **Purpose**: Testing environment before production
- **Created from**: develop
- **Merges to**: main

### Working Branches

#### Feature Branches
- **Naming**: `feature/task-{number}-{short-description}`
- **Example**: `feature/task-13-telnyx-integration`
- **Created from**: develop
- **Merges to**: develop

#### Bugfix Branches
- **Naming**: `bugfix/task-{number}-{issue-description}`
- **Example**: `bugfix/task-45-call-audio-routing`
- **Created from**: develop
- **Merges to**: develop

#### Hotfix Branches
- **Naming**: `hotfix/{version}-{description}`
- **Example**: `hotfix/1.0.1-critical-crash-fix`
- **Created from**: main
- **Merges to**: main AND develop

#### Release Branches
- **Naming**: `release/{version}`
- **Example**: `release/1.0.0`
- **Created from**: develop
- **Merges to**: main and back to develop

## Workflow

### Feature Development
1. Create feature branch from develop
2. Implement feature (reference task number in commits)
3. Push feature branch
4. Create PR to develop
5. Code review
6. Merge to develop

### Release Process
1. Create release branch from develop
2. Final testing and bug fixes
3. Update version numbers
4. Merge to main (tagged)
5. Merge back to develop

### Hotfix Process
1. Create hotfix branch from main
2. Fix critical issue
3. Test thoroughly
4. Merge to main (tagged)
5. Merge to develop

## Commit Message Convention
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build process or auxiliary tool changes

### Examples
```
feat(calling): implement incoming call UI (Task #19)

- Add incoming call screen with caller info
- Implement answer/decline buttons
- Add slide-to-answer gesture

Closes #19
```
```
fix(auth): resolve token refresh race condition

Multiple simultaneous API calls were causing token refresh
to fail. Implemented mutex lock for token refresh.

Fixes #67
```

## Pull Request Process

1. **Title Format**: `[Task #X] Brief description`
2. **Description**: Use PR template
3. **Review Requirements**: At least 1 approval
4. **Checks**: All CI/CD checks must pass
5. **Merge Method**: Squash and merge for features

## Version Tagging

- **Format**: `v{major}.{minor}.{patch}`
- **Example**: `v1.0.0`
- **When to Tag**: Every merge to main
- **Tag Message**: Include release notes

## Branch Protection Setup Commands
```bash
# These will be configured in GitHub/GitLab settings
# Document here for reference
```


