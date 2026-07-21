import Foundation
import Testing

@testable import SpeechLanes

@Suite struct ConfigurationTests {
  @Test func defaultsMatchTheMeasuredThresholdsWithNoDurationCap() {
    // given / when
    let config = Configuration(locales: [Locale(identifier: "en-US")])

    // then
    #expect(config.acceptConfidence == 0.6)
    #expect(config.floorConfidence == 0.3)
    #expect(config.maximumAudioDuration == nil)
  }

  @Test func defaultThresholdsSitInsideTheMeasuredSeparation() {
    // given / then — measured lanes: right language >= 0.84 average, wrong language <= 0.21;
    // the floor must sit between them and the early-accept must only fire on a clear match
    let config = Configuration(locales: [Locale(identifier: "en-US")])
    #expect(config.floorConfidence > 0.21)
    #expect(config.floorConfidence < 0.84)
    #expect(config.acceptConfidence > config.floorConfidence)
    #expect(config.acceptConfidence < 0.84)
  }

  @Test func localeIdentifierInitMapsTagsInOrder() {
    // given / when
    let config = Configuration(localeIdentifiers: ["en-US", "ru-RU"])

    // then
    #expect(config.locales == [Locale(identifier: "en-US"), Locale(identifier: "ru-RU")])
  }

  @Test func customValuesArePreserved() {
    // given / when
    let config = Configuration(
      locales: [Locale(identifier: "de-DE")],
      acceptConfidence: 0.75,
      floorConfidence: 0.4,
      maximumAudioDuration: .seconds(600)
    )

    // then
    #expect(config.acceptConfidence == 0.75)
    #expect(config.floorConfidence == 0.4)
    #expect(config.maximumAudioDuration == .seconds(600))
  }
}
