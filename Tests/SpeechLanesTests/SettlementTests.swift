import Foundation
import Testing

@testable import SpeechLanes

/// The pure end-of-race policy: which transcript (or which typed error) leaves the engine after
/// every lane ran, collected as candidates or as a remembered first failure.
@Suite struct SettlementTests {
    @Test func theWinningCandidateSettlesAsItself() {
        // given
        let winner = scored("привет мир", confidence: 0.84, locale: "ru-RU", engine: .dictation)
        let garbage = scored(", , ,", confidence: 0.02)

        // when
        let outcome = SpeechLaneTranscriber.settle(
            candidates: [garbage, winner],
            firstFailure: nil,
            floor: 0.3
        )

        // then
        #expect(outcome == .success(winner))
    }

    @Test func aLaneFailureOutranksLowConfidenceWhenNoCandidateWins() {
        // given — a lane that never ran may be the one that would have matched; saying
        // "couldn't make out the language" would hide the real, actionable fault
        let garbage = scored(", , ,", confidence: 0.02)

        // when
        let outcome = SpeechLaneTranscriber.settle(
            candidates: [garbage],
            firstFailure: .assetsUnavailable("reservation slots exhausted"),
            floor: 0.3
        )

        // then
        #expect(outcome == .failure(.assetsUnavailable("reservation slots exhausted")))
    }

    @Test func allLanesGarbageWithoutFailuresIsLowConfidence() {
        // given
        let candidates = [
            scored(", , ,", confidence: 0.02),
            scored("Hello des Voice месседж", confidence: 0.21)
        ]

        // when
        let outcome = SpeechLaneTranscriber.settle(
            candidates: candidates,
            firstFailure: nil,
            floor: 0.3
        )

        // then
        #expect(outcome == .failure(.lowConfidence))
    }

    @Test func everyLaneFailingSettlesAsTheFirstFailure() {
        // given / when
        let outcome = SpeechLaneTranscriber.settle(
            candidates: [],
            firstFailure: .assetsUnavailable("download failed"),
            floor: 0.3
        )

        // then
        #expect(outcome == .failure(.assetsUnavailable("download failed")))
    }

    @Test func aWinnerStillBeatsAFailureFromAnotherLane() {
        // given — one broken locale must not take down a language that worked
        let winner = scored("quick brown fox", confidence: 0.96)

        // when
        let outcome = SpeechLaneTranscriber.settle(
            candidates: [winner],
            firstFailure: .assetsUnavailable("ru-RU download failed"),
            floor: 0.3
        )

        // then
        #expect(outcome == .success(winner))
    }

    @Test func noCandidatesAndNoFailureIsTranscriptionFailed() {
        // given / when — the defensive branch: resolution produced lanes but none actually ran
        let outcome = SpeechLaneTranscriber.settle(candidates: [], firstFailure: nil, floor: 0.3)

        // then
        #expect(outcome == .failure(.transcriptionFailed("no lane ran")))
    }
}
