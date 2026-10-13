# Security Policy

## Supported versions

Only the latest commit on `main` receives fixes.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report privately through GitHub's
[private vulnerability reporting](https://github.com/mylesagnew/cloudflare-backup/security/advisories/new).
Include steps to reproduce and the impact you observed. You can expect an
acknowledgement within 5 business days.

## Scope

In scope: token handling (logging, argv exposure, file permissions), unsafe
handling of API responses, and anything that could make the script write
outside `./domains`.

Out of scope: Cloudflare API behaviour itself and compromise of the host
running the script.

## Token guidance

Use a custom API token limited to **Zone → Zone → Read** and
**Zone → DNS → Read**. Never use the Global API Key. Keep `.env` at
`chmod 600`. If a token is ever committed or exposed, revoke it in the
Cloudflare dashboard immediately.
