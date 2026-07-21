import Foundation
import Testing

@testable import SpeechLanes

/// The eviction policy of the reservation gate: only a locale this library reserved, and never one
/// the current request still needs, may be released to free a slot.
@Suite struct AssetReservationGateTests {
    @Test func evictsOurOwnReservationTheRequestNoLongerNeeds() {
        // given — de-DE was reserved by us earlier and is not in the current keep set
        let reserved = [Locale(identifier: "de-DE"), Locale(identifier: "en-US")]

        // when
        let evictable = AssetReservationGate.evictionCandidate(
            from: reserved,
            reservedByUs: ["de-de", "en-us"],
            keeping: ["en-us", "ru-ru"]
        )

        // then
        #expect(evictable == Locale(identifier: "de-DE"))
    }

    @Test func neverEvictsAReservationTheLibraryDidNotMake() {
        // given — the only occupied slot is held by the host app, not by us
        let reserved = [Locale(identifier: "fr-FR")]

        // when
        let evictable = AssetReservationGate.evictionCandidate(
            from: reserved,
            reservedByUs: [],
            keeping: ["en-us"]
        )

        // then
        #expect(evictable == nil)
    }

    @Test func neverEvictsALocaleTheCurrentRequestStillNeeds() {
        // given — every reservation we made is part of this request's keep set
        let reserved = [Locale(identifier: "en-US"), Locale(identifier: "ru-RU")]

        // when
        let evictable = AssetReservationGate.evictionCandidate(
            from: reserved,
            reservedByUs: ["en-us", "ru-ru"],
            keeping: ["en-us", "ru-ru"]
        )

        // then
        #expect(evictable == nil)
    }
}
