# 0006 — File-presence toggling makes `spectra-update` non-additive

From the 📐 architect review of PR #10.

## Symptom
Switching `spectra-update` from "copy all shipped personas" to "refresh only personas already
present" silently dropped update's **distribution** role: an existing install can no longer
receive a newly-shipped core persona, nor have a lost one repaired. The regression was invisible
— nothing said update had stopped being additive.

## Root cause
The "active = file present" model overloads **absence**: a missing persona now means *either*
"never installed" *or* "the developer ran `/spectra-disable`". Once absence can mean "disabled",
any operation that previously treated absence as "needs filling" (update re-adding the full set)
becomes unsafe — re-adding would silently undo a deliberate disable.

## Fix
Keep update non-additive, but make it **explicit and intentional**: state in
`spectra-update/SKILL.md` that update refreshes present personas only and never adds/restores
one, and route additions (including newly-shipped or to-be-restored personas) through
`/spectra-enable`. Documented the contract change in `overview/architecture.md`.

## Learning
When a piece of state gains a second meaning (here: absent = *disabled*, not just *missing*),
audit every operation that acted on the old meaning. They don't automatically stay correct —
each must be re-decided against the new meaning and the choice made explicit, not left implicit.
