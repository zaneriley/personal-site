# ADR 0006 — Time-first performance contract with byte ratchets

**Status:** accepted 2026-08-30, ratified by Z in session.
**Supersedes:** the budget values previously in `ci/contracts/routes.json`
(the enforcement mechanism and gate are unchanged and stay per ADR 0001).

## Context

The performance contract enforced per-category byte budgets that were written
as aspirations before the type system and design existed. By 2026-08-29 the
contract had three defects, all measured:

1. **It was unsatisfiable.** The whole-page budget (88,000 bytes) was smaller
   than the font budget alone (100,000), so no combination of passing
   sub-budgets could produce a passing page. A gate that cannot pass trains its
   owner to ignore it — the mechanism by which a 574 KB draft image went
   unnoticed in a 34-line failure dump.
2. **The timing numbers were fake.** The gate's "mobile-cold Pixel 5" profile
   set only a viewport and user agent. No network or CPU throttling existed
   anywhere in the gate, so `readable_content_ms` measured a desktop machine
   talking to itself over loopback (191–313 ms) and said nothing about a real
   visitor.
3. **The websocket budget was unactionable.** The gate sums decompressed frame
   payloads, so wire compression can never move the number; only sending less
   LiveView data can. It also measures mostly post-paint traffic, which is not
   part of the cold-load story.

Meanwhile the actual goal was never bytes. The goal is: **a first-time visitor
on a mid-range phone and a slow connection can read the page in under a
second.** Bytes were standing in for that goal — and standing in badly, because
the June font work (metric-override fallback faces, ADR 0004) deliberately
made readability independent of webfont delivery: text renders immediately in
a matched system font with zero layout shift, and the brand typeface swaps in
when it arrives. Font bytes delay the swap, not readability.

## Decision

**The primary enforced metric is time, measured honestly. Bytes remain as
never-worse-than-now ratchets.**

1. **The gate throttles.** The profile gains a network shape and CPU slowdown,
   applied per route via Chrome's devtools protocol: 9 Mbps down / 1.5 Mbps up
   / 100 ms latency, CPU at one quarter speed — the current 75th-percentile
   mobile baseline (Russell, *The Performance Inequality Gap, 2026*). The
   profile lives in the contract, not the gate code.
2. **The goal metric:** `readable_content_ms ≤ 1000` and `cls ≤ 0.1` on every
   public route, under that throttle. This is the sentence the site promises:
   readable in under a second, cold, without the layout jumping.
3. **Timing is sampled three times per route and the median sample is
   judged.** Throttled timings are noisy; single-sample timing gates flake and
   get ignored. Three navigations per route costs the gate roughly two extra
   minutes.
4. **Byte budgets become ratchets set just above today's worst measured route**
   (values in `routes.json`). They exist to catch regressions
   deterministically, which noisy timing cannot. The ratchet rule, unchanged
   from the backlog: **a ratchet may be tightened when a saving lands; it may
   never be raised to make a run green.** A deliberate, dated exception in the
   contract's `exceptions` list is the only sanctioned way to carry a known
   overrun.
5. **The websocket byte budget is deleted.** The gate keeps measuring and
   reporting the number in its artifact; it is no longer pass/fail.

## Consequences

- The gate is green today by construction, so the next red run means something
  actually regressed — either the one-second promise or a ratchet. This
  restores the gate's information value, which the unsatisfiable contract had
  destroyed.
- Timing budgets and throttled numbers are not comparable to any measurement
  taken before this ADR; `page-weight.md` records both eras.
- The fonts-versus-budget standoff dissolves into a polish question: 373 KB of
  fonts do not threaten the one-second promise, they delay the brand-typeface
  swap. Shrinking them (display-face subsetting, dropping Latin Extended-A)
  remains queued in the backlog as ratchet-tightening work, not as a launch
  blocker.
- CI still measures fonts as zero until font delivery lands (they are
  gitignored and 404 in CI). The ratchets are therefore only fully honest in
  local `ci:release` runs until that backlog item closes.

## Calibration note, 2026-08-30

The first honest CI run (fonts present for the first time) showed shared CI
runners are roughly 2× slower than the reference machine under the CPU
throttle: readable 1073–1805 ms in CI vs 636–847 ms locally, identical bytes.
The contract's timing ceilings were recalibrated to CI-hardware reality
(readable 2400, dcl 1000, load 1400, fcp 1400) and the contract text now names
the split explicitly: **the one-second goal is authoritative on the reference
profile via local `ci:release`; CI's timing ceilings catch gross regressions
on slower shared hardware.** Byte ratchets, which are hardware-independent,
carry the deterministic enforcement in both places. This is a measurement
calibration, not a goal change — the site still reads in under a second on
the profile the goal was written for.

## Rejected

- **Bytes as the primary metric (status quo):** enforces a proxy, not the
  goal, and the proxy contradicted itself.
- **Replacing the gate with Lighthouse CI:** dormant tooling (no commits in 14
  months, budget spec archived), known-flaky timing assertions, and it would
  discard the route contract.
- **Timing without throttling:** measures the development machine, not a
  visitor.
