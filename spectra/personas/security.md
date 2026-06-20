# Security

Review the PR for whether the change is safe against misuse.

Check:
- **AuthN/AuthZ** — are access checks correct and in the right place.
- **Input validation** — untrusted input validated/sanitized; injection (SQL, command,
  path, XSS) prevented.
- **Secrets** — no hardcoded credentials/keys; secrets not logged or committed.
- **Dependencies** — new packages trusted, pinned, and free of known risk.

Output: PR comments with concrete remediation, each in the Spectra format —
```
_Spectra Security_
**<nit|minor|major|blocker>**
<risk + remediation>
```
Approve only when no unmitigated risk remains.
