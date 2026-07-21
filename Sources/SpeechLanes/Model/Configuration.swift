import Foundation

/// How a ``SpeechLaneTranscriber`` transcribes: the locales to try and the confidence thresholds
/// that decide which lane wins.
public struct Configuration: Sendable, Equatable {
    /// The locales to transcribe, in priority order. Each becomes one lane; the first lane whose
    /// average confidence reaches ``acceptConfidence`` wins immediately without running the rest.
    public var locales: [Locale]

    /// A lane whose average confidence is at least this value is accepted without running any
    /// lower-priority lane. Defaults to `0.6`, inside the measured separation between a matching
    /// language (>= 0.84 average) and a mismatched one (<= 0.21).
    public var acceptConfidence: Double

    /// The lowest average confidence a lane may have and still be returned. Below it a lane is
    /// discarded, so audio matching no configured language fails with
    /// ``TranscriptionError/lowConfidence`` instead of returning plausible-looking garbage.
    /// Defaults to `0.3`.
    public var floorConfidence: Double

    /// An optional cap on the decoded audio duration. When set, audio longer than this fails with
    /// ``TranscriptionError/audioTooLong(_:)`` before the engine runs. `nil` (the default) imposes
    /// no limit.
    public var maximumAudioDuration: Duration?

    public init(
        locales: [Locale],
        acceptConfidence: Double = 0.6,
        floorConfidence: Double = 0.3,
        maximumAudioDuration: Duration? = nil
    ) {
        self.locales = locales
        self.acceptConfidence = acceptConfidence
        self.floorConfidence = floorConfidence
        self.maximumAudioDuration = maximumAudioDuration
    }

    /// Builds a configuration from BCP-47 locale identifiers (for example `["en-US", "ru-RU"]`), a
    /// convenience for callers that hold language tags as strings.
    public init(
        localeIdentifiers: [String],
        acceptConfidence: Double = 0.6,
        floorConfidence: Double = 0.3,
        maximumAudioDuration: Duration? = nil
    ) {
        self.init(
            locales: localeIdentifiers.map { Locale(identifier: $0) },
            acceptConfidence: acceptConfidence,
            floorConfidence: floorConfidence,
            maximumAudioDuration: maximumAudioDuration
        )
    }
}
