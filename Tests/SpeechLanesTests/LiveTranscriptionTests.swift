import Foundation
import Testing

@testable import SpeechLanes

/// End-to-end engine tests: real `SpeechAnalyzer` transcription of the fixtures. Opt-in only
/// (`SPEECHLANES_LIVE_TESTS=1`): first use may download model assets over the network, which the
/// deterministic suite must never depend on.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SPEECHLANES_LIVE_TESTS"] == "1"))
struct LiveTranscriptionTests {
    @Test func transcribesTheEnglishFixtureVerbatim() async throws {
        // given
        let transcriber = SpeechLaneTranscriber(
            configuration: Configuration(localeIdentifiers: ["en-US"])
        )

        // when
        let result = try await transcriber.transcribe(audioFileAt: fixture(named: "voice-note"))

        // then — the fixture's known ground truth, tolerant of inverse-text-normalization drift
        #expect(result.text.lowercased().contains("quick brown fox"))
        #expect(result.engine == .speech)
    }

    /// Both fixtures run with the WRONG language configured first, so passing requires the full
    /// race: the mismatched lane must score below early-accept and the matching lane must win. The
    /// Russian lane also exercises the `DictationTranscriber` fallback — `ru-RU` has no
    /// `SpeechTranscriber` model.
    @Test(arguments: [
        LiveCase(
            fixture: "voice-note",
            expected: "quick brown fox",
            locales: ["ru-RU", "en-US"],
            engine: .speech
        ),
        LiveCase(
            fixture: "voice-note-ru",
            expected: "французских",
            locales: ["en-US", "ru-RU"],
            engine: .dictation
        ),
        // Language-only tags are valid BCP-47 and must resolve to each engine's regional model.
        LiveCase(
            fixture: "voice-note-ru",
            expected: "французских",
            locales: ["en", "ru"],
            engine: .dictation
        )
    ])
    func multiLocaleRacePicksTheLaneMatchingTheAudio(_ testCase: LiveCase) async throws {
        // given
        let transcriber = SpeechLaneTranscriber(
            configuration: Configuration(localeIdentifiers: testCase.locales)
        )

        // when
        let result = try await transcriber.transcribe(audioFileAt: fixture(named: testCase.fixture))

        // then
        #expect(result.text.lowercased().contains(testCase.expected))
        #expect(result.engine == testCase.engine)
    }

    @Test func aCancelledTaskThrowsCancelled() async throws {
        // given
        let transcriber = SpeechLaneTranscriber(
            configuration: Configuration(localeIdentifiers: ["en-US"])
        )
        let fixtureURL = try fixture(named: "voice-note")

        // when — a task cancelled before the engine runs must surface the typed cancellation
        let task = Task {
            try await transcriber.transcribe(audioFileAt: fixtureURL)
        }
        task.cancel()

        // then
        await #expect(throws: TranscriptionError.cancelled) {
            try await task.value
        }
    }
}

/// A single parameterized live-transcription scenario.
struct LiveCase: Sendable {
    let fixture: String
    let expected: String
    let locales: [String]
    let engine: TranscriberEngine
}
