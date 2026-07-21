import AVFAudio
import Foundation

/// The ground-truth duration check: pure arithmetic on an opened audio file, independent of the
/// speech stack. A caller may guard on a container's *declared* duration first, but that can be
/// forged; this reads the decoded length the engine will actually process.
enum DurationGuard {
    static func enforce(
        decodedDurationOf audioFile: AVAudioFile,
        cap: Duration?
    ) throws(TranscriptionError) {
        guard let cap else {
            return
        }

        let decodedSeconds = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        let capSeconds = Double(cap.components.seconds)
            + Double(cap.components.attoseconds) / 1e18

        guard decodedSeconds <= capSeconds else {
            throw TranscriptionError.audioTooLong(.seconds(Int(decodedSeconds)))
        }
    }
}
