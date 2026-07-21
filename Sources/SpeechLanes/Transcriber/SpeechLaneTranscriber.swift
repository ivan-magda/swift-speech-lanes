import AVFAudio
import Foundation
import Speech

/// On-device, multi-locale speech-to-text built on the `SpeechAnalyzer` stack.
///
/// Apple's speech framework has no audio language detection and binds each transcriber to a single
/// locale, so `SpeechLaneTranscriber` runs the audio through one *lane* per configured locale — a
/// `SpeechTranscriber` where the locale ships a model, a `DictationTranscriber` (the
/// system-dictation model, for example for `ru-RU`) otherwise — and lets ``LaneArbiter`` pick the
/// winner by the engine's own per-word confidence. Lanes run in the configured priority order; a
/// lane clearing ``Configuration/acceptConfidence`` wins immediately, and one lane's engine failure
/// never takes down a language that still works.
///
/// ```swift
/// let transcriber = SpeechLaneTranscriber(
///     configuration: Configuration(localeIdentifiers: ["en-US", "ru-RU"])
/// )
/// let result = try await transcriber.transcribe(audioFileAt: fileURL)
/// print(result.text, result.locale.identifier, result.confidence ?? -1)
/// ```
///
/// The engine honors task cancellation: cancelling the surrounding task abandons a wedged analyzer
/// and throws ``TranscriptionError/cancelled``. Wrap the call in a timeout task to bound it.
public actor SpeechLaneTranscriber: SpeechTranscribing {
    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func transcribe(
        audioFileAt url: URL
    ) async throws(TranscriptionError) -> TranscriptionResult {
        if Task.isCancelled {
            throw TranscriptionError.cancelled
        }

        let lanes = await LaneResolver.resolveLanes(for: configuration.locales)

        if lanes.isEmpty {
            throw await Self.emptyLaneFailure(configuredLocales: configuration.locales)
        }

        let probeFile: AVAudioFile
        do {
            probeFile = try AVAudioFile(forReading: url)
        } catch {
            throw TranscriptionError.undecodableAudio("\(error)")
        }
        try DurationGuard.enforce(
            decodedDurationOf: probeFile,
            cap: configuration.maximumAudioDuration
        )

        // Lanes run in configured priority order; a clear early match skips the remaining lanes,
        // and one lane's engine failure must not take down a language that still works.
        let configuredTags = Set(lanes.map { $0.locale.bcp47Tag })
        var candidates: [ScoredTranscript] = []
        var firstFailure: TranscriptionError?

        for lane in lanes {
            let scored: ScoredTranscript
            do {
                scored = try await LaneExecutor.run(lane, configuredTags: configuredTags, url: url)
            } catch {
                if case .cancelled = error {
                    throw TranscriptionError.cancelled
                }
                firstFailure = firstFailure ?? error
                continue
            }

            if Self.clearsEarlyAccept(scored, threshold: configuration.acceptConfidence) {
                return scored.result
            }

            candidates.append(scored)
        }

        switch Self.settle(
            candidates: candidates,
            firstFailure: firstFailure,
            floor: configuration.floorConfidence
        ) {
        case .success(let scored):
            return scored.result
        case .failure(let failure):
            throw failure
        }
    }

    /// Whether a lane's score clears the early-accept threshold, ending the race before lower
    /// priority lanes run. An unscored lane (nil confidence) never clears it; the comparison is
    /// inclusive so a lane exactly at the threshold accepts.
    static func clearsEarlyAccept(_ scored: ScoredTranscript, threshold: Double) -> Bool {
        (scored.confidence ?? 0) >= threshold
    }

    /// The pure end-of-race policy: a winner among the collected candidates settles as itself; else
    /// a remembered lane failure outranks ``TranscriptionError/lowConfidence`` (a lane that never
    /// produced output may be the one that would have matched, so surfacing its real fault beats a
    /// misleading "couldn't make out the language"); with candidates but no failure, every lane
    /// scored below the floor — which is ``TranscriptionError/lowConfidence``.
    static func settle(
        candidates: [ScoredTranscript],
        firstFailure: TranscriptionError?,
        floor: Double
    ) -> Result<ScoredTranscript, TranscriptionError> {
        if let winner = LaneArbiter.winner(among: candidates, floor: floor) {
            return .success(winner)
        }

        if let firstFailure {
            return .failure(firstFailure)
        }

        guard !candidates.isEmpty else {
            return .failure(.transcriptionFailed("no lane ran"))
        }

        return .failure(.lowConfidence)
    }

    /// Distinguishes "no engine on this host" from "engines exist but none supports the configured
    /// locales" when lane resolution comes back empty.
    private static func emptyLaneFailure(configuredLocales: [Locale]) async -> TranscriptionError {
        let dictationLocales = await DictationTranscriber.supportedLocales

        guard SpeechTranscriber.isAvailable || !dictationLocales.isEmpty else {
            return .unavailable
        }

        return .localeUnsupported(configuredLocales)
    }
}
