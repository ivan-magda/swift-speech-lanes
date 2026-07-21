import AVFAudio
import Foundation
import Testing

@testable import SpeechLanes

/// The library hands audio straight to `AVAudioFile` with no transcoder — and Telegram's Ogg/Opus
/// decode rests on an UNDOCUMENTED CoreAudio component ('Oggf', no public constant), so this fixture
/// decode is the tripwire for an OS update silently removing it. The fixture is synthetic (say ->
/// ffmpeg libopus -> Ogg, 48 kHz mono — the exact codec/container/params of a real voice note).
@Suite struct OggOpusDecodeTests {
    @Test func avAudioFileDecodesTelegramShapedOggOpusToPCM() throws {
        // given
        let fixtureURL = try fixture(named: "voice-note")

        // when
        let audioFile = try AVAudioFile(forReading: fixtureURL)
        let format = audioFile.processingFormat
        let buffer = try #require(
            AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))
        )
        try audioFile.read(into: buffer)

        // then — real PCM came out (audible samples, mono, Opus's native 48 kHz), not silence
        #expect(buffer.frameLength > 0)
        #expect(format.channelCount == 1)
        #expect(format.sampleRate == 48_000)
        let channel = try #require(buffer.floatChannelData)
        var peak: Float = 0
        for index in 0..<Int(buffer.frameLength) {
            peak = max(peak, abs(channel[0][index]))
        }
        #expect(peak > 0)
    }
}

/// The ground-truth duration guard is pure arithmetic on an opened file — testable with the fixture
/// (~7.8s of audio), no speech assets or network involved.
@Suite struct DurationGuardTests {
    @Test func fixtureWithinCapPassesAndOverCapThrowsAudioTooLong() throws {
        // given
        let audioFile = try AVAudioFile(forReading: fixture(named: "voice-note"))

        // when / then — nil and generous caps pass; a cap below the decoded length throws typed
        try DurationGuard.enforce(decodedDurationOf: audioFile, cap: nil)
        try DurationGuard.enforce(decodedDurationOf: audioFile, cap: .seconds(600))
        #expect(throws: TranscriptionError.audioTooLong(.seconds(7))) {
            try DurationGuard.enforce(decodedDurationOf: audioFile, cap: .seconds(5))
        }
    }

    @Test func fractionalSecondCapExercisesTheAttosecondsPath() throws {
        // given — a non-integer cap forces the attoseconds arithmetic that whole-second caps skip
        let audioFile = try AVAudioFile(forReading: fixture(named: "voice-note"))
        let decodedSeconds = Double(audioFile.length) / audioFile.processingFormat.sampleRate

        // when / then — a fractional cap just above the decoded length passes; just below throws
        let justOver = Duration.milliseconds(Int((decodedSeconds + 0.4) * 1000))
        let justUnder = Duration.milliseconds(Int((decodedSeconds - 0.4) * 1000))
        try DurationGuard.enforce(decodedDurationOf: audioFile, cap: justOver)
        #expect(throws: TranscriptionError.audioTooLong(.seconds(Int(decodedSeconds)))) {
            try DurationGuard.enforce(decodedDurationOf: audioFile, cap: justUnder)
        }
    }
}
