import Foundation

/// Transcribes an audio file into text on-device.
///
/// The seam a consumer injects so app code can be tested against a fake without the speech stack.
public protocol SpeechTranscribing: Sendable {
  /// Transcribes the audio at `url`, returning the best transcript across the configured locales.
  ///
  /// - Parameter url: A file URL to any format `AVAudioFile` can open — Telegram-shaped Ogg/Opus,
  ///   MP3, M4A, CAF, WAV. Content is sniffed, so the file extension does not matter.
  /// - Returns: The winning lane's ``TranscriptionResult``.
  /// - Throws: ``TranscriptionError`` for every failure mode, including cancellation.
  func transcribe(audioFileAt url: URL) async throws(TranscriptionError) -> TranscriptionResult
}
