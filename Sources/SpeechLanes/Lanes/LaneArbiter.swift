import Foundation

/// Picks the winning transcript when the same audio ran through several candidate locales, and
/// exposes the confidence math the lanes use. Pure and deterministic — it never touches the speech
/// stack.
public enum LaneArbiter {
    /// Returns the highest-confidence candidate, provided that candidate clears `floor`.
    ///
    /// When no candidate carries a confidence score the first is returned on faith (an engine that
    /// emits no confidence data must not brick transcription). Once any candidate is scored, an
    /// unscored one can no longer win, and a scored best below `floor` yields `nil` — wrong-language
    /// output can read as plausible text, so a low score must lose rather than be forwarded.
    public static func winner(
        among candidates: [ScoredTranscript],
        floor: Double
    ) -> ScoredTranscript? {
        let scored = candidates.filter { $0.confidence != nil }

        guard let best = scored.max(by: { ($0.confidence ?? 0) < ($1.confidence ?? 0) }) else {
            return candidates.first
        }

        guard let confidence = best.confidence, confidence >= floor else {
            return nil
        }

        return best
    }

    /// The mean of a lane's per-word confidence scores, or `nil` for an empty set.
    public static func averageConfidence(_ values: [Double]) -> Double? {
        if values.isEmpty {
            return nil
        }
        return values.reduce(0, +) / Double(values.count)
    }
}
