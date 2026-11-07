# Security policy

Gemify holds personal financial data, so a flaw that exposes that data, corrupts it, or lets a crafted backup file change it without confirmation is treated as a security issue.

## Supported versions

Until 1.0, fixes are released only for the latest version and applied to the `master` branch.

## Reporting a vulnerability

Do **not** report vulnerabilities through public issues, pull requests or discussions.

Report them privately through GitHub: open the repository's [Security tab](https://github.com/azevedo1z/Gemify/security) and select **Report a vulnerability**.

Include as much of the following as possible:

- The affected area (database, backup import or export, share, a screen)
- The type of issue and its potential impact
- Steps to reproduce, or a proof of concept
- The app version or commit you tested against

Never include real financial data or a real backup file in a report; build a minimal one instead.

## What to expect

- An acknowledgement as soon as possible.
- An assessment and, when confirmed, a fix on `master` and a patch release.
