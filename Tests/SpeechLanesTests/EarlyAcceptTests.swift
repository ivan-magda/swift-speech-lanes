import Foundation
import Testing

@testable import SpeechLanes

/// The early-accept decision: the first lane clearing `acceptConfidence` ends the race before any
/// lower-priority lane runs.
@Suite struct EarlyAcceptTests {
  @Test func unscoredLaneNeverEarlyAccepts() {
    // given — an engine that reports no confidence must not short-circuit the race
    let lane = scored("no confidence", confidence: nil)

    // when / then
    #expect(!SpeechLaneTranscriber.clearsEarlyAccept(lane, threshold: 0.6))
  }

  @Test func exactlyAtThresholdAccepts() {
    // given — the comparison is inclusive
    let lane = scored("boundary", confidence: 0.6)

    // when / then
    #expect(SpeechLaneTranscriber.clearsEarlyAccept(lane, threshold: 0.6))
  }

  @Test func justBelowThresholdDefersToTheArbiter() {
    // given
    let lane = scored("almost", confidence: 0.59)

    // when / then
    #expect(!SpeechLaneTranscriber.clearsEarlyAccept(lane, threshold: 0.6))
  }

  @Test func aClearMatchAccepts() {
    // given
    let lane = scored("clear match", confidence: 0.9)

    // when / then
    #expect(SpeechLaneTranscriber.clearsEarlyAccept(lane, threshold: 0.6))
  }
}
