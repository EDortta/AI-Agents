# Unattended Run

How an agent works a queue with nobody watching — overnight, on a schedule — and,
above all, **when it must stop**. Global/common rules remain canonical in
`/AGENTS.md`.

`./delivery-loop.md` covers *what must be true about the work*. `./session-close.md`
covers *how to close a session a human is attending*. This file covers the case
where there is no human to attend it, which fails differently: the danger is not
bad work, it is work that never ends.

Load this file before arming anything that runs without supervision, and before
reviewing anything that already is.

If this file conflicts with `/AGENTS.md`, follow `/AGENTS.md`.

---

## 0. The one rule everything else serves

An autonomous run that cannot decide to stop is not autonomous. It is an
unsupervised consumer of budget.

Specify how it continues **and** how it gives up, with the same care. Every clause
below exists because its absence has already cost money — see the annex.

---

## 1. Before anything runs — operator consent

Do not arm anything until these are answered and stored. Refuse to start if the
effective configuration no longer matches what was consented.

- **Which repositories, and which paths inside them may change.** "The repo" is
  not an answer; a monorepo may allow git to operate on the whole tree while only
  two directories may be modified.
- **Which model for which phase**, by exact name. Labels like "advanced" or
  "cheap" identify nothing and change meaning between releases.
- **Every ceiling**: per call, per issue, per review round, per night, and for the
  campaign as a whole. A night limit multiplied by the nights nobody looks is not
  a limit.
- **Concurrency**, both of model calls and of local work. Builds and test suites
  have their own parallelism and are the real load.
- **The window**, checked against the host's maintenance calendar.
- **The notification channel**, and how delivery is confirmed.
- **What review is required before work reaches the integration branch**, and how
  often it runs (per issue, per epic, per batch of N — see §5).

Echo the stored block in the dry run and in the morning report. Any change needs
new consent.

---

## 2. When to stop

Each of these ends the work. Distinguish the two kinds:

**Suspend** — a known transient condition **with a deterministic resume rule
written next to it**. Without such a rule, the correct outcome is fault.

    window closed              resumes next window
    local resource pressure    resumes when pressure drops for N ticks
    night budget spent         resumes next night
    campaign budget spent      resumes only by operator act

**Fault** — confidence in the run's own state is gone. It never resumes on its
own, it survives restarts, and only the operator releases it.

    a boundary was crossed (wrote outside scope, published, reached a credential)
    integration left the target branch failing its own checks
    an external effect cannot be reconciled
    state is corrupt or impossible
    dirt of unknown origin in the working tree
    a fatal configuration error — bad credential, unknown model
    repeated infrastructure failure past its ceiling
    actual cost exceeded what was reserved for a call
    **no progress**: N consecutive issues consumed real work and closed none

**No progress is a fault, not a suspension.** Issues that consumed calls and
closed nothing are evidence that the work model is not working tonight. That needs
a human, not another night.

**Never continue automatically after a boundary violation** — not in another
issue, not in another repository.

### 2.1 Do not retry what did not converge

- **Cap the rounds.** Two review rounds per object. There is no third.
- **Detect the cycle, not just the repetition.** Compare a normalized signature of
  each round — findings by identity, plus the diff — against **every earlier round
  of that object**, not only the previous one. A→B→A is the common shape.
- **A round that produced no decision is not a round of progress.** Count it
  separately, with its own ceiling.
- **Stop the whole run, not the issue**, when the failure is environmental. If the
  environment is broken, the next issue breaks too.

---

## 3. Asking a human is a protocol, not a phrase

The agent declares it as data — `{"status": "needs_operator", "question": "..."}` —
never in prose the caller has to recognize. Searching output for "permission" or
"can you" produces false positives and false negatives.

When it happens:

- the asking subject stops — the issue for implementation, the review object for a
  review lens;
- the question is stored **verbatim**;
- the operator is notified **immediately**, with delivery confirmed. Saving it for
  the morning report is how a pipeline once paid for review rounds for twelve
  hours to receive the same question back;
- a queue of unanswered questions has its own ceiling, and reaching it is a fault.

An answered question must have a way back into the queue. A parked issue that the
operator resolved and that nothing can restart is the same defect wearing a
different hat.

---

## 4. Cost

**Every agent call is capped, including the implementation call.** In the incident
that produced this file, the expensive call was implementation, not review.

**Input dominates.** An agentic call re-sends its context every turn: one envelope
showed 7.1M cached input tokens against 68k of output. A ceiling on output and
turns bounds nothing. Cap the context, and truncate tool results that enter it.

**Cap by count as well as by money.** Some providers report no cost at all; when
money is unavailable, the count is the only ceiling that binds.

**Refuse before spending, not after.** A call that cannot be paid for is refused at
admission. Admitting an issue that can pay for its most expensive call and not for
the first fix converts its whole budget into waste.

**A call that started and produced no result still cost money.** Record it as
exposure, never as zero. Own ceiling; reaching it is a fault.

**A cancelled or failed call is not free.** Record what it used.

Report cost broken down by issue, by phase and by model. That is the number that
says whether a cheaper model on implementation is paying for itself, or whether it
is buying extra review rounds at the expensive model's price.

---

## 5. How often the review runs

Reviewing every issue is the most expensive option and has the smallest blast
radius. Reviewing a batch amortizes it and widens the damage of a rejection.

Whatever the choice, **nothing reaches the integration branch without a review
that passed over the diff that is entering**. If review is deferred, the work must
wait somewhere that is not the integration branch.

Sensible default: close the batch on whichever comes first — N issues, an epic
with nothing left to run, an accumulated diff too large to review in one pass, or
the latest start that still fits the window.

Two definitions that decide whether this works:

- **"Epic finished" must mean "nothing in it is runnable"**, not "all its issues
  succeeded". Otherwise one dead issue blocks the trigger forever.
- **Membership forms itself.** Collect issues as they finish; declare no member
  list in advance. A batch waiting for a member that will never arrive is a stall
  with no exit.

---

## 6. Time

**Find out when the machine stops.** Read the maintenance schedule, the update
policy, the provider's window, and the restart history. If any source cannot be
consulted, or a schedule points at a script whose stop command is inside it, or
the history shows a pattern nothing explains — **assume a stop is coming** and
shorten the horizon accordingly.

Absence of evidence is not an infinite horizon. One pipeline started a call fifteen
minutes before a daily reboot it could have looked up, on a ten-minute tick that
guaranteed hitting it.

**Do not start what will not finish.** Before every call: does its maximum
duration fit before the window closes and before the next known stop? Before a
phase: is there budget to finish the whole phase?

**Drain before the deadline, do not be killed at it.** Reserve enough time to
checkpoint. A stop signal gives seconds, not minutes.

**Measure durations on a monotonic clock**; use the wall clock only for the
calendar, and only after the clock is known to be synchronized.

---

## 7. What it never does

- `push`, deploy, or any publication — the boundary is the destination, not the
  subcommand, and pushing to a local path needs no credential;
- touch a repository or a path outside what was consented;
- **modify, clean, stash or commit dirt whose origin is not its own record.** An
  automatic stash hides human work. Unknown dirt is a fault;
- keep going after a boundary violation;
- run a third round on something two rounds could not close.

---

## 8. The morning report

Written on every run and on every stop, and durable enough to survive the crash
that produced it.

- **First line: if nothing closed, say so.** Do not make the operator discover it
  by reading logs.
- Why the run is in the state it is in.
- Per issue: the final state and **the sentence explaining why it stopped**.
- Cost by issue, by phase and by model, separating wasted infrastructure from
  useful work, with known cost and unresolved exposure as distinct numbers.
- What the discovered maintenance regime was, and the evidence for it.
- What is waiting on the operator, in the order to handle it.

**A stop nobody hears did not happen.** Notification failure escalates through a
channel independent of the one that failed, and a watchdog outside the pipeline
alerts on **lack of progress**, not merely on absence of runs — a run that wakes
up, does nothing and exits is invisible to a check that only asks whether runs
happen.

---

## 9. Before arming

Prove each brake by breaking it on purpose: the question that stops the work, the
signature that repeats, the ceiling that refuses a call, the horizon that is too
short, the boundary that is crossed, the budget that runs out both after a call
and before one.

Then kill the process at each boundary — after writing a file and before its
checkpoint, after a commit, mid-merge, after starting a call and before recording
its result — restart, and show that nothing is duplicated and nothing is lost.

**An untested brake does not exist.** State explicitly what was not exercised end
to end.

---

## Annex — what each rule cost

Incident of 13–14 Aug 2026, two pipelines, ~12 hours, zero issues closed.

| rule | what its absence did |
|---|---|
| §2.1 cap the rounds, detect the cycle | one issue repeated the same four-lens cycle round after round: ~100 rounds, zero closures |
| §3 ask as protocol, notify at once | the state file held "Can you grant write permission?" for twelve hours while the run paid for rounds to receive it again |
| §4 cap every call, cap the input | one implementation call: 77 turns, an error result, USD 6.86, 7.1M cached input tokens against 68k of output |
| §6 find out when the machine stops | that call started 15 minutes before a scheduled daily reboot, on a ten-minute tick that guaranteed hitting it |
| §1 cap concurrency | a concurrency ceiling existed in an earlier revision and vanished in a rewrite |
| §2 no progress is a fault | a hundred rounds and zero closures was observable in real time and nobody was observing |
| §7 unknown dirt is a fault | the second pipeline refused every ten minutes for hours — `0 unit(s) attempted` — blocked by a dead unit's leftovers, never stopping, never warning |
| §8 report and watchdog | both pipelines looked healthy from outside for twelve hours |
| §9 prove the brakes | nothing had ever been exercised end to end; the first real run was unattended |

---

## Provenance

Distilled from four adversarial council rounds against a full design specification
for such a pipeline. **The councils never disputed a single rule above**; what they
broke, repeatedly, was the mechanism proposed to implement them — which is why this
file states properties and decisions and leaves mechanism to whoever builds it.

Those design notes are kept outside the kit, as reference and not as instruction —
a record of how hard the implementation is, not a plan that was validated.

Review method for a document like this: `../agents/council.md`.
