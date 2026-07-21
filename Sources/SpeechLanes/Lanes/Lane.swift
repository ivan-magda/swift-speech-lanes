import Foundation

/// One resolved transcription lane: a supported locale bound to the engine that will run it.
enum Lane: Equatable {
    case speech(Locale)
    case dictation(Locale)

    var locale: Locale {
        switch self {
        case .speech(let locale), .dictation(let locale):
            locale
        }
    }

    var engine: TranscriberEngine {
        switch self {
        case .speech:
            .speech
        case .dictation:
            .dictation
        }
    }
}
