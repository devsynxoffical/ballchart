# Voice / microphone — detailed plan (Tactical Lab + future ASR)

## Current architecture

- **Client:** `speech_to_text` (on-device STT where the OS supports it).
- **Flow:** Mic → OS speech engine → `onResult` → text field → `parseCoachCommand` → animation.
- **Optional later:** Cloud ASR (Whisper, Google STT) for higher accuracy or unsupported platforms.

---

## Phase A — Make the mic reliable (in-app)

| Step | Action | Owner |
|------|--------|--------|
| A1 | **Runtime permission** — `permission_handler` + `RECORD_AUDIO` (Android) / mic usage strings (iOS). If `MissingPluginException` appears, code **falls back** to `speech_to_text` only; do a **full rebuild** (`flutter run` from cold start, not hot reload) so native plugins register. | Done in code |
| A2 | **`initialize` callbacks** — `onError`, `onStatus` so UI matches real listening state (not a stuck icon). | Done in code |
| A3 | **`SpeechListenOptions`** — non-deprecated options; `cancelOnError`, `partialResults`, `listenMode`. | Done in code |
| A4 | **Dispose** — `stop()` / `cancel()` in `dispose()` so sessions don’t leak. | Done in code |
| A5 | **Platform messaging** — Web: mic unsupported (use keyboard). Desktop: best-effort; recommend phone for voice. | Done in code |
| A6 | **UX** — SnackBars for permission denied, permanent errors, and “open settings”. | Done in code |

---

## Phase B — QA matrix (manual)

| Platform | Expectation |
|----------|-------------|
| **Android (physical)** | Grant mic → speak short command → text updates → tap Run or enable auto-run on final result. |
| **iOS** | Same; ensure Siri & Dictation allowed in Settings if recognition fails. |
| **Windows (desktop)** | `speech_to_text` may work on Win11 with offline recognition; if `initialize` fails, use keyboard. |
| **Web** | Not supported by plugin; keyboard only. |
| **Emulator** | Often no mic or broken audio; test on real device. |

---

## Phase C — Product improvements (next)

| Item | Description |
|------|-------------|
| **Auto-run on final utterance** | When `SpeechRecognitionResult.finalResult == true`, call `_runCommand` automatically (optional toggle in UI). |
| **Locale** | Let user pick `localeId` (en-US vs en-GB) for accent. |
| **Noise / timeout** | Tune `listenFor` / `pauseFor`; show “Listening…” with timer. |
| **Offline-first coaching** | Keep parser local; no network required for demo. |

---

## Phase D — Optional cloud ASR (later)

Use when on-device STT is insufficient:

1. Record short PCM/WAV or stream to backend.
2. Backend calls Whisper / Google Speech-to-Text.
3. Return text into the same `parseCoachCommand` pipeline.

**Pros:** Consistent across platforms, better noisy gyms. **Cons:** Latency, cost, privacy review.

---

## Phase E — Telemetry

- Log `initialize` success/failure by platform.
- Log permission denial vs user cancel.
- Track time from mic stop → command run (targets in `TACTICAL_IMPLEMENTATION_PLAN.md`).

---

## References

- `speech_to_text`: initialization, `listen`, status strings (`listening`, `notListening`, `done`).
- Android: [RECORD_AUDIO runtime](https://developer.android.com/training/permissions/requesting).
- iOS: `NSSpeechRecognitionUsageDescription` + `NSMicrophoneUsageDescription` (already in `Info.plist`).
