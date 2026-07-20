---
name: DuoShield CI auth
description: Which GitHub PAT works for which operations in this project
---

## Token situation
- `GIT_PAT` (Replit secret): works for `git push`, GitHub Actions API (workflow runs, jobs, logs, dispatch)
- `GITHUB_PAT` (Replit secret): returns 401 for GitHub API calls — likely expired or wrong scope

**How to apply:** Always use `$GIT_PAT` for any GitHub API curl calls or git push commands.
If `GITHUB_PAT` needs to work, user must regenerate it with `repo` scope at github.com/settings/tokens.

## GitHub Actions secrets required for signing
- `KEY_STORE_PASSWORD` — JKS keystore password
- `KEY_ALIAS` — key alias (lowercased in Gradle via `.toLowerCase()`)
- `KEY_PASSWORD` — key password
- `KEYSTORE_BASE64` — base64-encoded `duoshield-release.keystore`
- `GOOGLE_SERVICES_JSON` — full raw content of `google-services.json`

## Workflow dispatch
Pushes to `main` auto-trigger the workflow. Manual dispatch also works via API with `GIT_PAT`.
