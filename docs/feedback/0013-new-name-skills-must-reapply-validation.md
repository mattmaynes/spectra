# 0013 - New/generalized name-acting skills must re-apply the slug-validation contract

From the 🔒 security and 🔧 engineer reviews of PR #19 (multiple User/ICP personas).

## Symptom
Two `major` findings, same shape:
- `spectra-add-user` introduced a brand-new write-by-slug path (`docs/spectra/personas/user-<slug>.md`)
  that said only "derive a kebab-case `<slug>`" - **no input contract**. A slug like `../security`
  resolves to `docs/spectra/security.md`, escaping the personas dir and clobbering a shipped
  persona. The "if the file already exists, stop" guard is a probe of an already-interpolated
  path - exactly what `feedback/0007` ruled insufficient.
- `spectra-persona-enable`'s **explicit-argument** path validated only `^[a-z][a-z0-9-]*$` + an
  existing persona file, so `/spectra-persona-enable user-smb` would add an ICP slug to
  `personas.config` - contradicting the same skill's header (which this PR edited to say ICP
  `user*.md` personas live *outside* the config). The no-arg candidate path excluded `user*`; the
  arg path did not.

## Root cause
`feedback/0007` fixed slug validation in the two persona skills that existed then. This PR (a) added
new sibling skills that act on a name and (b) generalized the ICP family from `user` to `user*` -
but the existing validation discipline was only partially carried over: a new skill shipped without
it, and an *alternate code path* (the arg path) in an edited skill kept a now-incomplete exclusion.
The lesson was treated as "those files are fixed" rather than "this pattern always needs the
contract." Compare `feedback/0010` (a logged lesson doesn't auto-apply to new code).

## Fix
- `spectra-add-user`: mandate the derived slug match `^[a-z][a-z0-9-]*$` (no `/`, `..`, leading `/`,
  or extension) **before** forming any path; ask again if it can't reduce to that; reject slugs
  colliding with a shipped persona. Only then write the file.
- `spectra-remove-user`: state the `rm` target MUST be one of the exact paths enumerated when
  listing - never a path built by interpolating a typed name.
- `spectra-persona-enable` / `spectra-persona-disable`: reject the whole `user`/`user-*` family on
  the explicit-argument path, matching the candidate-list exclusion.

## Learning
When you **add a new skill that acts on a name**, or **generalize the set a name can range over**,
re-apply the input-validation contract (`feedback/0007`) to *every* path - new siblings and
alternate branches (explicit-arg vs. menu), not just the file the lesson was first written in.
A validated no-arg path and an unvalidated arg path in the same skill is still a hole.
