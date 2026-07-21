import Foundation
import Speech

/// Idempotently makes a locale's on-device model present before a lane runs: reserve the locale
/// (serialized through ``AssetReservationGate``), then download and install its assets. Every
/// failure surfaces as a typed ``TranscriptionError``.
enum AssetProvisioner {
  static func ensureAssets(
    for module: some SpeechModule,
    locale: Locale,
    configuredTags: Set<String>
  ) async throws(TranscriptionError) {
    try await AssetReservationGate.shared.reserve(locale, keeping: configuredTags)

    do {
      let request = try await AssetInventory.assetInstallationRequest(supporting: [module])
      guard let request else {
        return
      }

      try await request.downloadAndInstall()
    } catch is CancellationError {
      throw TranscriptionError.cancelled
    } catch {
      throw TranscriptionError.assetsUnavailable("\(error)")
    }
  }
}
