# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the package
swift build

# Run the deterministic test suite (Apple's Testing framework, not XCTest)
swift test

# Run the opt-in end-to-end engine tests (real transcription, may download model assets)
SPEECHLANES_LIVE_TESTS=1 swift test

# Run SwiftLint (strict mode, as CI does)
swiftlint --strict

# Build in release mode
swift build -c release
```

## Architecture

SpeechLanes turns an audio file plus an ordered list of locales into the best on-device transcript, running one transcription lane per locale on Apple's `SpeechAnalyzer` stack and picking the winner by engine confidence. It is scoped to the transcription engine only — download, staging, redaction, timeouts, and trust decisions belong to the consuming app.

### Core Components

- **SpeechLaneTranscriber** (`actor`, conforms to `SpeechTranscribing`): the public entry point. Resolves lanes, applies the duration guard, runs lanes in priority order with early-accept, and `settle`s the winner. `settle` is a pure static so it is unit-tested without the speech stack.
- **Configuration**: locales (ordered), `acceptConfidence` (0.6), `floorConfidence` (0.3), and an optional `maximumAudioDuration`.
- **TranscriptionResult / ScoredTranscript / TranscriberEngine / TranscriptionError**: the public value types — the winning transcript with its locale/confidence/engine, one lane's scored output, the `.speech`/`.dictation` marker, and the typed failure set.
- **LaneResolver**: locale → lane. `resolve(_:in:via:)` is a pure function over injected supported-locale lists (exact BCP-47 match, then equivalence widening), so it is CI-testable; `resolveLanes(for:)` wires in the real engine lists.
- **LaneExecutor**: runs a lane through `SpeechAnalyzer`, accumulating the transcript and per-word confidence.
- **LaneArbiter**: pure, public confidence math — `winner(among:floor:)` and `averageConfidence(_:)`.
- **AssetProvisioner**: idempotent model reserve / stale-eviction / download-and-install.
- **DurationGuard**: the ground-truth decoded-duration cap (arithmetic on an opened `AVAudioFile`).

Sources are grouped under `Transcriber/`, `Model/`, `Lanes/`, and `Extensions/`.

### Platform Requirements

- iOS 26.0+, macOS 26.0+, visionOS 26.0+ (no watchOS/tvOS: `DictationTranscriber` is unavailable on tvOS, and `SpeechAnalyzer` on neither)
- Swift 6.2+ (strict concurrency), Xcode 26+
- No third-party dependencies (`swift-docc-plugin` is a build-tool plugin for docs only)

### Testing

Tests use Apple's `Testing` framework in two tiers:

- **Deterministic (default):** `LaneArbiterTests`, `SettlementTests`, `ConfigurationTests`, `LocaleResolutionTests`, and the `AVAudioFile` decode + `DurationGuard` fixture tests. These run anywhere the package builds and never touch the live speech engine or the network.
- **Live (opt-in via `SPEECHLANES_LIVE_TESTS=1`):** `LiveTranscriptionTests` — real `SpeechAnalyzer` transcription of the bundled English/Russian fixtures, racing the wrong language first.

Shared test helpers live in `TestHelpers.swift`.

## Code Style

SwiftLint enforced with `--strict` (no swift-format). Key rules:

- 4-space indentation; line length 120 warning / 150 error
- Opt-in rules include `force_unwrapping`, `implicit_return`, `conditional_returns_on_newline`, `trailing_closure` — no trailing commas in collection literals
- Tests follow Given-When-Then (`// given` / `// when` / `// then`)
