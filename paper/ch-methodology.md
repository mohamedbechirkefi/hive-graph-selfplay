# Chapter 8 — Working methodology: gated human–AI research (booklet, 2026-10-09)

*Condensed from `docs/methodology.md` (workspace, v1.0) and the
append-only methodology log; this chapter is also the report's AI-use
declaration in expanded form.*

## Division of labour

This study was executed under **goal-level delegation with mechanical
human authority**. The human author is the principal investigator: he
owns the research questions, every scientific commitment, every
expenditure, everything public, and the final word on every claim — a
responsibility that is not delegable. The AI assistant (Claude,
Anthropic — operating as Claude Code sessions) is the runtime: given
the research plan, it routes itself, builds, measures, journals, and
drafts toward the plan's end-state without per-task instruction.

The boundary is enforced by six **gates** enumerating decisions only
the human makes: freezing any protocol, split or test set (G-FREEZE);
spending or long compute (G-SPEND); anything leaving the machine
(G-PUBLIC); reuse of material with unsettled rights (G-RIGHTS);
institutional contact (G-ADMIN); destruction of data or results
(G-DESTRUCTIVE). Every gate crossing in this study is recorded in the
decision log with the human's approval quoted verbatim — the protocol
freeze, the opponent-population freeze with its budget sub-choice, the
openings freeze, four compute approvals with explicit sizing, and the
seed-extension pre-commitments.

## Why the state lives in files

Sessions are stateless by design: a session reads the routing file,
executes the active phase's pipeline document (ordered tasks, each with
an acceptance check, closed by exit criteria), journals everything
measured, and updates the state files last. Research quality is thereby
a property of **process artifacts** — journals, the decision log,
frozen documents with hashes, the claims register — not of any
session's memory or competence. Everything in this booklet traces to
those artifacts.

## What the discipline caught

The methodology log records every incident where the discipline changed
an outcome. During this study it caught, among others: a protocol-
deadlock in the pipeline documents before any work ran; an engine-vs-
corpus disagreement resolved *against* the hand-written corpus (the
engine was right, and the record of being wrong was kept); an
evaluation harness defect detected because three "different" opponents
produced identical results; a silent record-loss path in the match
runner found by the rule that every selected failure position must be
*reproduced and verified* before publication; and an ablation that had
silently diverged to NaN for ten generations, caught by the same
identical-results alarm and converted into the study's clearest
ablation finding. The pattern is the methodology's core claim: **at
small scale, harness error is a larger threat than statistical noise,
and only mechanical verification catches it.**

## What the AI did not do

The AI chose no hypothesis, froze nothing, spent nothing, published
nothing, and decided no claim. Where its drafts contained errors, the
process — translation passes, mechanical consistency checks,
adversarial re-reads — surfaced several (stale seed counts, stale
claim limits) before this version; the final-control record lists the
checks. The human author has personally verified the conclusions he
signs.
