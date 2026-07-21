import Foundation
import Testing

@testable import SpeechLanes

private func noEquivalent(_ locale: Locale) async -> Locale? { nil }
private func ruEquivalent(_ locale: Locale) async -> Locale? { Locale(identifier: "ru-RU") }

/// Lane assignment over injected engine-support lists: speech where a model exists, dictation as the
/// fallback, priority to speech, and dropped when neither engine supports the locale.
@Suite struct LaneAssignmentTests {
  @Test func speechSupportedLocaleBecomesASpeechLane() async {
    // given / when
    let lanes = await LaneResolver.lanes(
      for: [Locale(identifier: "en-US")],
      speechLocales: [Locale(identifier: "en-US")],
      dictationLocales: [],
      speechEquivalent: noEquivalent,
      dictationEquivalent: noEquivalent
    )

    // then
    #expect(lanes == [.speech(Locale(identifier: "en-US"))])
  }

  @Test func speechUnsupportedButDictationSupportedFallsBackToDictation() async {
    // given — ru-RU has no SpeechTranscriber model; this is the headline fallback path
    // when
    let lanes = await LaneResolver.lanes(
      for: [Locale(identifier: "ru-RU")],
      speechLocales: [Locale(identifier: "en-US")],
      dictationLocales: [Locale(identifier: "ru-RU")],
      speechEquivalent: noEquivalent,
      dictationEquivalent: noEquivalent
    )

    // then
    #expect(lanes == [.dictation(Locale(identifier: "ru-RU"))])
  }

  @Test func speechWinsWhenBothEnginesSupportTheLocale() async {
    // given / when
    let lanes = await LaneResolver.lanes(
      for: [Locale(identifier: "en-US")],
      speechLocales: [Locale(identifier: "en-US")],
      dictationLocales: [Locale(identifier: "en-US")],
      speechEquivalent: noEquivalent,
      dictationEquivalent: noEquivalent
    )

    // then
    #expect(lanes == [.speech(Locale(identifier: "en-US"))])
  }

  @Test func localeUnsupportedByBothEnginesIsDropped() async {
    // given / when
    let lanes = await LaneResolver.lanes(
      for: [Locale(identifier: "xx")],
      speechLocales: [Locale(identifier: "en-US")],
      dictationLocales: [Locale(identifier: "ru-RU")],
      speechEquivalent: noEquivalent,
      dictationEquivalent: noEquivalent
    )

    // then
    #expect(lanes.isEmpty)
  }

  @Test func partialTagWidensIntoADictationLane() async {
    // given — "ru" widens to ru-RU via the dictation engine's equivalence
    // when
    let lanes = await LaneResolver.lanes(
      for: [Locale(identifier: "ru")],
      speechLocales: [Locale(identifier: "en-US")],
      dictationLocales: [Locale(identifier: "ru-RU")],
      speechEquivalent: noEquivalent,
      dictationEquivalent: ruEquivalent
    )

    // then
    #expect(lanes == [.dictation(Locale(identifier: "ru-RU"))])
  }
}
