import Foundation
import Testing

@testable import SpeechLanes

@Suite struct LaneArbiterTests {
  @Test func picksTheHighestConfidenceCandidateAboveTheFloor() {
    // given — the measured mismatch shape: garbage scores ~0.02, the right language ~0.84
    let english = scored(", , ,", confidence: 0.02)
    let russian = scored("Привет, это голосовое сообщение", confidence: 0.84, locale: "ru-RU")

    // when
    let winner = LaneArbiter.winner(among: [english, russian], floor: 0.3)

    // then
    #expect(winner == russian)
  }

  @Test func rejectsWhenEveryScoredCandidateIsBelowTheFloor() {
    // given — wrong-language output can look like plausible text, so low scores must lose
    let candidates = [
      scored(", , ,", confidence: 0.02),
      scored("Hello des Voice месседж", confidence: 0.21),
    ]

    // when
    let winner = LaneArbiter.winner(among: candidates, floor: 0.3)

    // then
    #expect(winner == nil)
  }

  @Test func fallsBackToTheFirstCandidateWhenNoConfidenceExists() {
    // given — an engine that emits no confidence data must not brick the feature
    let first = scored("first lane", confidence: nil)
    let second = scored("second lane", confidence: nil, locale: "ru-RU")

    // when
    let winner = LaneArbiter.winner(among: [first, second], floor: 0.3)

    // then
    #expect(winner == first)
  }

  @Test func unscoredCandidatesLoseToScoredOnes() {
    // given
    let unscored = scored("no data", confidence: nil)
    let confident = scored("confident", confidence: 0.9)

    // when
    let winner = LaneArbiter.winner(among: [unscored, confident], floor: 0.3)

    // then
    #expect(winner == confident)
  }

  @Test func unscoredCandidatesCannotRescueAScoredFieldBelowTheFloor() {
    // given — once any lane produced a measurable score, an unmeasurable lane must not win
    let unscored = scored("no data", confidence: nil)
    let garbage = scored(", , ,", confidence: 0.02)

    // when
    let winner = LaneArbiter.winner(among: [unscored, garbage], floor: 0.3)

    // then
    #expect(winner == nil)
  }

  @Test func emptyCandidateListHasNoWinner() {
    // given / when
    let winner = LaneArbiter.winner(among: [], floor: 0.3)

    // then
    #expect(winner == nil)
  }

  @Test func prefersTheEarlierCandidateOnEqualConfidence() {
    // given — candidate order is the configured locale priority
    let preferred = scored("preferred locale", confidence: 0.8)
    let secondary = scored("secondary locale", confidence: 0.8, locale: "ru-RU")

    // when
    let winner = LaneArbiter.winner(among: [preferred, secondary], floor: 0.3)

    // then
    #expect(winner == preferred)
  }

  @Test func averageConfidenceIsTheMeanOfTheRunValues() {
    // given / when
    let average = LaneArbiter.averageConfidence([0.5, 1.0])

    // then
    #expect(average == 0.75)
  }

  @Test func averageConfidenceIsNilWithoutRunValues() {
    // given / when
    let average = LaneArbiter.averageConfidence([])

    // then
    #expect(average == nil)
  }
}
