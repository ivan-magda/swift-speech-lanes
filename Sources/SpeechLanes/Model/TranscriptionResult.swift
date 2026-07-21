import Foundation

/// The transcript chosen from the configured locale lanes, with the provenance a caller needs to
/// decide how much to trust it.
public struct TranscriptionResult: Sendable, Equatable {
    /// The winning lane's transcribed text.
    public let text: String

    /// The locale of the lane that won.
    public let locale: Locale

    /// The mean per-word confidence of the winning lane, or `nil` when the engine reported none.
    ///
    /// A `nil` confidence means the engine emitted no confidence data, so the transcript is the
    /// first lane's output taken on faith rather than a scored winner.
    public let confidence: Double?

    /// Which engine produced the winning transcript.
    public let engine: TranscriberEngine

    public init(text: String, locale: Locale, confidence: Double?, engine: TranscriberEngine) {
        self.text = text
        self.locale = locale
        self.confidence = confidence
        self.engine = engine
    }
}

extension ScoredTranscript {
    /// Promotes a winning lane score into the public result.
    var result: TranscriptionResult {
        TranscriptionResult(text: text, locale: locale, confidence: confidence, engine: engine)
    }
}
