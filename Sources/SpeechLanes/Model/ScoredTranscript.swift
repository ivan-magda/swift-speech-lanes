import Foundation

/// One lane's transcript paired with the locale and engine that produced it and the averaged
/// per-word confidence the engine reported. ``LaneArbiter`` ranks these to pick a winner.
///
/// Fields are declared in the same order as ``TranscriptionResult`` so the two initializers line up.
public struct ScoredTranscript: Sendable, Equatable {
    /// The transcribed text this lane produced.
    public let text: String

    /// The locale of the lane that produced ``text``.
    public let locale: Locale

    /// The mean of the engine's per-word confidence scores, or `nil` when the engine reported none.
    public let confidence: Double?

    /// The engine that produced ``text``.
    public let engine: TranscriberEngine

    public init(text: String, locale: Locale, confidence: Double?, engine: TranscriberEngine) {
        self.text = text
        self.locale = locale
        self.confidence = confidence
        self.engine = engine
    }
}
