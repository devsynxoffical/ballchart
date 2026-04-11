# Tactical: Strategy + Battle + AI Voice-to-Animation

This document maps your seven phases to **concrete code locations**, **API contracts**, and **implementation status**. A full enterprise rollout of every bullet (analytics, cloud ASR, LLM assist at scale, telemetry) is staged; the repo now contains a **working vertical slice** (client-side engine + lab UI + server metadata + socket relay) you can extend without rework.

---

## Phase 1 — Foundation (Data + Architecture)

| Deliverable | Location | Status |
|-------------|----------|--------|
| Canonical enums (revision, session phase, step kinds) | `lib/core/models/tactical/tactical_schema.dart` | Done |
| Entities: `PlayStep`, `Formation`, `BattleSession`, `BattleEvent`, `TimelineAction` | `lib/core/tactical/tactical_entities.dart` | Done |
| Court grid + slots + ball state | `lib/core/tactical/court_geometry.dart` | Done |
| Strategy revision (`draft` / `published` / `archived`) | `metadata.revisionState` on strategy (API + Dart) | Done (API field) |
| Role permissions helper | `lib/core/tactical/tactical_permissions.dart` | Done |

**Backend contracts:** `metadata` (Mixed) on Strategy and Battle; `revisionState`, `formation`, `playSteps`, `timeline` JSON shapes documented in entity Dart file.

---

## Phase 2 — Strategy (Planning Studio)

| Deliverable | Location | Status |
|-------------|----------|--------|
| Formation + sequential steps in models | `TacticalPlaybook`, `PlayStep` in `tactical_entities.dart` | Done |
| Validation (duplicate slot, ball owner, bounds) | `lib/core/tactical/tactical_validation.dart` | Done |
| Library filters (team, opponent, success, recency) | Enhanced strategy UI + query params | Partial — extend `StrategyRepository` queryParams when API supports filters |

---

## Phase 3 — Battle (Execution + Tracking)

| Deliverable | Location | Status |
|-------------|----------|--------|
| Lifecycle UI | `lib/features/battle/view/battle_screen.dart` + `BattleModel.sessionPhase` | Partial |
| Load strategy to timeline | `TacticalPlaybackController` + lab | Done (client) |
| Log events | `POST /api/battles/:id/events` | Done |
| Post-battle analytics | — | Future (needs aggregated metrics + charts) |

---

## Phase 4 — AI Voice-to-Command

| Deliverable | Location | Status |
|-------------|----------|--------|
| Text command parser (intents + entities + confidence + alternatives) | `lib/core/tactical/voice_command_parser.dart` | Done |
| Microphone ASR | `speech_to_text` + runtime mic permission + `SpeechListenOptions` in `TacticalLabScreen` | Done — see **[`VOICE_MICROPHONE_PLAN.md`](VOICE_MICROPHONE_PLAN.md)** for platform matrix & QA |
| Safety / “Did you mean?” chips | Parsed `alternatives` in lab UI | Done |

---

## Phase 5 — Court Animation Engine

| Deliverable | Location | Status |
|-------------|----------|--------|
| State machine + interpolated moves | `lib/core/tactical/tactical_animation_engine.dart` | Done |
| Timeline renderer (nodes from commands/steps) | `TacticalPlaybackController` + `TacticalCourtCanvas` | Done |
| Real-time sync | Socket `TACTICAL_ANIMATION_FRAME` + `join_tactical_room` | Done (server relay in `src/server.js`) |

---

## Phase 6 — AI Assistive Layer

| Deliverable | Location | Status |
|-------------|----------|--------|
| Heuristic next-action suggestions | `lib/core/tactical/tactical_ai_suggestions.dart` | Done (non-LLM) |
| Prompt → mini-strategy (LLM) | — | Future (requires API key + endpoint) |
| Explainable cards | — | Future |

---

## Phase 7 — Quality & Release

| Deliverable | Status |
|-------------|--------|
| Parser + validation unit tests | `test/tactical/` |
| Perf budgets (<150ms ack, <500ms anim) | Instrument in lab + future CI |
| Rollout / telemetry | Future |

---

## Suggested build order (matches repo)

1. Shared models + validation (`tactical_entities`, `tactical_validation`) — **done**
2. Animation engine + court canvas — **done**
3. Voice parser (text) + mic — **done**
4. Connect parser → engine + socket — **done**
5. Enrich strategy/battle APIs + analytics + LLM assist — **incremental**

---

## Key entry points

- **Tactical lab (demo / coach tool):** `lib/features/tactics/view/tactical_lab_screen.dart`
- **Open from:** Strategy (`EnhancedStrategyScreen`) and Battle (`BattleScreen`) header actions
- **Socket events:** `join_tactical_room`, `TACTICAL_ANIMATION_FRAME`
