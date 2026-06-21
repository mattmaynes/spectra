# 0006 — Persona enable/disable vs. update: decouple the file from its state

From the 📐 architect review of PR #10.

## Symptom
The first design made a persona active iff its file was present, and `/spectra-disable` removed
the file. To keep a disable sticky, `spectra-update` then had to stop copying the full set and
"refresh only present" files — which silently dropped update's **distribution** role: a
newly-shipped or accidentally-removed persona could no longer arrive via update.

## Root cause
One signal (file present/absent) was overloaded to mean two independent things: *"is this persona
installed?"* and *"has the developer enabled it?"*. Any operation touching persona files then had
to satisfy both meanings at once, and they conflicted — update wants to deliver every file, while
disable wants a file to stay gone.

## Fix
Split the two concerns. **Files** are Spectra-owned and always shipped/copied (update is a plain
additive `cp "$SRC/personas/"*.md`). The **enabled set** is a separate developer-owned allowlist,
`docs/spectra/personas.config`, seeded-if-absent by install and never overwritten by update.
Activation = slug in the config, not file presence. Update can now distribute and repair every
persona file *and* a `/spectra-disable` still persists, because they act on different things.

## Learning
When one piece of state is forced to answer two independent questions, the operations that read it
will eventually pull in opposite directions. Give each question its own representation — here,
"installed" (the file) vs. "enabled" (the config line) — and the operations stop fighting.
