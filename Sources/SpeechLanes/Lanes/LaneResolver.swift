import Foundation
import Speech

/// Resolves configured locales to runnable lanes: `SpeechTranscriber` where the locale has a model,
/// `DictationTranscriber` otherwise. Matching tries an exact BCP-47 tag first, then widens a partial
/// tag (`ru` -> `ru_RU`) through the engine's own equivalence, counting the result only when that
/// engine's supported list actually contains it.
enum LaneResolver {
  static func resolveLanes(for locales: [Locale]) async -> [Lane] {
    let speechLocales =
      SpeechTranscriber.isAvailable ? await SpeechTranscriber.supportedLocales : []
    let dictationLocales = await DictationTranscriber.supportedLocales

    return await lanes(
      for: locales,
      speechLocales: speechLocales,
      dictationLocales: dictationLocales,
      speechEquivalent: SpeechTranscriber.supportedLocale(equivalentTo:),
      dictationEquivalent: DictationTranscriber.supportedLocale(equivalentTo:)
    )
  }

  /// Pure lane assignment over injected supported-locale lists and equivalence functions, so the
  /// speech-vs-dictation fallback is testable without the speech stack. A locale a
  /// `SpeechTranscriber` model covers becomes a `.speech` lane; a locale only
  /// `DictationTranscriber` covers becomes a `.dictation` lane; a locale neither supports is
  /// dropped.
  static func lanes(
    for locales: [Locale],
    speechLocales: [Locale],
    dictationLocales: [Locale],
    speechEquivalent: (Locale) async -> Locale?,
    dictationEquivalent: (Locale) async -> Locale?
  ) async -> [Lane] {
    var lanes: [Lane] = []
    for requested in locales {
      if let locale = await resolve(requested, in: speechLocales, via: speechEquivalent) {
        lanes.append(.speech(locale))
      } else if let locale = await resolve(
        requested,
        in: dictationLocales,
        via: dictationEquivalent
      ) {
        lanes.append(.dictation(locale))
      }
    }

    return lanes
  }

  /// Pure resolution: an exact tag match wins outright; otherwise the engine's `equivalent` widens
  /// the request, and the result counts only when `supportedLocales` contains it — the equivalence
  /// call alone also returns locales the installed stack cannot transcribe.
  static func resolve(
    _ requested: Locale,
    in supportedLocales: [Locale],
    via equivalent: (Locale) async -> Locale?
  ) async -> Locale? {
    let requestedTag = requested.bcp47Tag
    if let exactMatch = supportedLocales.first(where: { $0.bcp47Tag == requestedTag }) {
      return exactMatch
    }

    guard let normalized = await equivalent(requested) else {
      return nil
    }

    return supportedLocales.first { $0.bcp47Tag == normalized.bcp47Tag }
  }
}
