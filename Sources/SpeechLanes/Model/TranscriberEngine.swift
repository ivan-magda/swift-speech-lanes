/// Which on-device model produced a transcript.
public enum TranscriberEngine: Sendable, Equatable {
    /// The current `SpeechTranscriber` model — used for every locale that ships one.
    case speech
    /// The system-dictation `DictationTranscriber` model — the fallback lane for locales
    /// (for example `ru-RU`) that have no `SpeechTranscriber` model.
    case dictation
}
