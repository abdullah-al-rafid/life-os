# Security Policy

LIFE OS is an active prototype and is not approved for production use. Do not use real personal or sensitive data to evaluate it.

## Reporting a vulnerability

If GitHub's **Private vulnerability reporting** feature is enabled for this repository, use the repository's **Security** tab and select **Report a vulnerability**. This creates a private report for maintainers. This project has not verified whether the feature is enabled, so do not assume that route is available.

If private reporting is unavailable, do not post exploit details, credentials, personal data, or a proof of concept in a public issue or discussion. Use a private contact route supplied by the repository owner or organization administrator. If no private route is available, ask the owner or administrator through an already-established private channel to provide one; share only a brief request for a secure reporting route, without vulnerability details.

When a private route is available, include the affected version or commit, the impact, reproduction steps, and any mitigations. Use synthetic accounts and data. Allow maintainers reasonable time to investigate and coordinate a fix before public disclosure.

## Scope and limitations

The presence of Firestore Rules and emulator tests does not establish that production rules or trusted memberships are configured. Shared tasks are experimental and disabled by default. Do not test against production services or accounts without explicit authorization.
