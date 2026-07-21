import Foundation
import Testing

@testable import SpeechLanes

/// Pure locale resolution: exact-tag matching and equivalence widening, exercised with injected
/// supported-locale lists so the real speech stack is never touched.
@Suite struct LocaleResolutionTests {
    @Test func exactTagMatchWinsWithoutConsultingEquivalence() async {
        // given
        let supported = [Locale(identifier: "en-US"), Locale(identifier: "ru-RU")]

        // when
        let resolved = await LaneResolver.resolve(
            Locale(identifier: "ru-RU"),
            in: supported
        ) { _ in
            Issue.record("equivalence must not be consulted when an exact tag matches")
            return nil
        }

        // then
        #expect(resolved == Locale(identifier: "ru-RU"))
    }

    @Test func exactTagMatchIsCaseAndSeparatorInsensitive() async {
        // given — Locale identity compares on the folded BCP-47 tag, not the raw string
        let supported = [Locale(identifier: "en-US")]

        // when
        let resolved = await LaneResolver.resolve(Locale(identifier: "en_us"), in: supported) { _ in
            nil
        }

        // then
        #expect(resolved == Locale(identifier: "en-US"))
    }

    @Test func partialTagWidensThroughEquivalenceIntoTheSupportedList() async {
        // given — "ru" is valid BCP-47; the engine widens it to its regional model
        let supported = [Locale(identifier: "ru-RU")]

        // when
        let resolved = await LaneResolver.resolve(Locale(identifier: "ru"), in: supported) { _ in
            Locale(identifier: "ru-RU")
        }

        // then
        #expect(resolved == Locale(identifier: "ru-RU"))
    }

    @Test func equivalenceResultOutsideTheSupportedListIsRejected() async {
        // given — the equivalence call alone also returns locales the stack cannot transcribe
        let supported = [Locale(identifier: "en-US")]

        // when
        let resolved = await LaneResolver.resolve(Locale(identifier: "ar"), in: supported) { _ in
            Locale(identifier: "ar-SA")
        }

        // then
        #expect(resolved == nil)
    }

    @Test func noEquivalenceIsUnresolved() async {
        // given
        let supported = [Locale(identifier: "en-US")]

        // when
        let resolved = await LaneResolver.resolve(Locale(identifier: "xx"), in: supported) { _ in
            nil
        }

        // then
        #expect(resolved == nil)
    }
}
