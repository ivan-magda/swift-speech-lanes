import AVFAudio
import Foundation
import Speech

/// Runs one resolved lane end to end: provision its model, analyze the audio file, and fold the
/// engine's per-word confidence into a single averaged score.
enum LaneExecutor {
    static func run(
        _ lane: Lane,
        configuredTags: Set<String>,
        url: URL
    ) async throws(TranscriptionError) -> ScoredTranscript {
        switch lane {
        case .speech(let locale):
            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: [],
                attributeOptions: [.transcriptionConfidence]
            )
            try await AssetProvisioner.ensureAssets(
                for: transcriber,
                locale: locale,
                configuredTags: configuredTags
            )
            return try await analyze(
                module: transcriber,
                results: transcriber.results,
                locale: locale,
                engine: .speech,
                url: url
            )
        case .dictation(let locale):
            let transcriber = DictationTranscriber(
                locale: locale,
                contentHints: [],
                transcriptionOptions: [],
                reportingOptions: [],
                attributeOptions: [.transcriptionConfidence]
            )
            try await AssetProvisioner.ensureAssets(
                for: transcriber,
                locale: locale,
                configuredTags: configuredTags
            )
            return try await analyze(
                module: transcriber,
                results: transcriber.results,
                locale: locale,
                engine: .dictation,
                url: url
            )
        }
    }

    private static func analyze<Result: SpeechModuleResult>(
        module: some SpeechModule,
        results: some AsyncSequence<Result, any Error>,
        locale: Locale,
        engine: TranscriberEngine,
        url: URL
    ) async throws(TranscriptionError) -> ScoredTranscript {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let analyzer = SpeechAnalyzer(
                modules: [module],
                options: SpeechAnalyzer.Options(
                    priority: .userInitiated,
                    modelRetention: .lingering
                )
            )

            // The analyzer runs autonomously after start(), so consumer-task cancellation only
            // reliably tears it down (and unblocks a wedged result stream) if we cancel it directly.
            return try await withTaskCancellationHandler {
                try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)

                var transcript = ""
                var confidences: [Double] = []

                for try await result in results {
                    try Task.checkCancellation()
                    guard let text = finalText(of: result) else {
                        continue
                    }

                    transcript += String(text.characters)

                    for textRun in text.runs {
                        let value = textRun[AttributeScopes.SpeechAttributes.ConfidenceAttribute.self]
                        if let value {
                            confidences.append(value)
                        }
                    }
                }

                return ScoredTranscript(
                    text: transcript,
                    locale: locale,
                    confidence: LaneArbiter.averageConfidence(confidences),
                    engine: engine
                )
            } onCancel: {
                Task { await analyzer.cancelAndFinishNow() }
            }
        } catch is CancellationError {
            throw TranscriptionError.cancelled
        } catch {
            throw TranscriptionError.transcriptionFailed("\(error)")
        }
    }

    private static func finalText(of result: some SpeechModuleResult) -> AttributedString? {
        if let speech = result as? SpeechTranscriber.Result {
            return speech.isFinal ? speech.text : nil
        }

        if let dictation = result as? DictationTranscriber.Result {
            return dictation.isFinal ? dictation.text : nil
        }

        return nil
    }
}
