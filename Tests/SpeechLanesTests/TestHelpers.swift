import Foundation
import Testing

@testable import SpeechLanes

/// Builds a `ScoredTranscript` with sensible defaults so scoring tests read as the numbers under
/// test, not locale/engine boilerplate.
func scored(
    _ text: String,
    confidence: Double?,
    locale: String = "en-US",
    engine: TranscriberEngine = .speech
) -> ScoredTranscript {
    ScoredTranscript(
        text: text,
        locale: Locale(identifier: locale),
        confidence: confidence,
        engine: engine
    )
}

/// Resolves a bundled audio fixture by name, failing the test if the resource is missing.
func fixture(named name: String) throws -> URL {
    try #require(
        Bundle.module.url(forResource: name, withExtension: "oga", subdirectory: "Fixtures")
    )
}
