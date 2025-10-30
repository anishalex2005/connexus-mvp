# Branch Protection Configuration

## GitHub Settings Configuration

### For `main` branch:
1. Go to Settings → Branches
2. Add rule for `main`
3. Enable:
   - ✅ Require pull request reviews before merging
     - Required approving reviews: 1
     - ✅ Dismiss stale pull request approvals
     - ✅ Require review from CODEOWNERS
   - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date
     - Status checks: flutter-analyze, flutter-test
   - ✅ Require conversation resolution before merging
   - ✅ Include administrators
   - ✅ Restrict who can push to matching branches
     - Add team members with push access

### For `develop` branch:
1. Add rule for `develop`
2. Enable:
   - ✅ Require pull request reviews before merging
     - Required approving reviews: 1
   - ✅ Require status checks to pass before merging
   - ✅ Require conversation resolution before merging

### For `staging` branch:
1. Add rule for `staging`
2. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging

## GitLab Settings Configuration
[Similar configuration for GitLab if using]

## Command Line Setup (for reference)
```bash
# These are typically configured via UI, but documenting API calls:

# GitHub CLI example (requires appropriate permissions)
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["continuous-integration"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```


