import Foundation

/// A typed failure from ``SpeechLaneTranscriber/transcribe(audioFileAt:)``.
public enum TranscriptionError: Error, Sendable, Equatable {
  /// No speech engine can run on this host (ineligible hardware, or no models at all).
  case unavailable

  /// None of the configured locales is supported by the installed speech stack.
  case localeUnsupported([Locale])

  /// The on-device model assets could not be reserved, downloaded, or installed.
  case assetsUnavailable(String)

  /// The audio file could not be opened or decoded.
  case undecodableAudio(String)

  /// The decoded audio runs longer than ``Configuration/maximumAudioDuration`` — the ground-truth
  /// check behind the cheap declared-metadata guard a caller may apply first.
  case audioTooLong(Duration)

  /// The engine accepted the audio but failed while producing the transcript.
  case transcriptionFailed(String)

  /// Every configured locale produced only low-confidence output — the audio most likely is not
  /// in any configured language, so no transcript is trustworthy enough to return.
  case lowConfidence

  /// The surrounding task was cancelled (for example a caller-imposed deadline or shutdown),
  /// not an engine fault.
  case cancelled
}
