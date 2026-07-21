import Foundation
import Speech

/// Serializes reservation of on-device speech models process-wide and confines eviction to the
/// locales this library reserved.
///
/// `AssetInventory` is a global, per-process reservation set with a limited slot budget and a
/// check-then-act shape, and a Swift actor does not serialize across `await` — so each reservation
/// is chained onto the previous one to keep concurrent transcriptions from interleaving their
/// bookkeeping. When the budget is full, only a locale SpeechLanes itself reserved (and that the
/// current request no longer needs) is evicted; a host app's own reservations are never dropped.
actor AssetReservationGate {
  static let shared = AssetReservationGate()

  private var tail: Task<Void, Never>?
  private var reservedTags: Set<String> = []

  func reserve(
    _ locale: Locale,
    keeping keepingTags: Set<String>
  ) async throws(TranscriptionError) {
    let predecessor = tail
    let work = Task {
      await predecessor?.value
      return await self.performReserve(locale, keeping: keepingTags)
    }
    tail = Task { _ = await work.value }

    switch await work.value {
    case .success:
      return
    case .failure(let error):
      throw error
    }
  }

  private func performReserve(
    _ locale: Locale,
    keeping keepingTags: Set<String>
  ) async -> Result<Void, TranscriptionError> {
    let tag = locale.bcp47Tag
    let reserved = await AssetInventory.reservedLocales

    if reserved.contains(where: { $0.bcp47Tag == tag }) {
      reservedTags.insert(tag)
      return .success(())
    }

    if let failure = await attemptReserve(locale) {
      let evictable = Self.evictionCandidate(
        from: reserved,
        reservedByUs: reservedTags,
        keeping: keepingTags
      )
      guard let evictable else {
        return .failure(failure)
      }

      await AssetInventory.release(reservedLocale: evictable)
      reservedTags.remove(evictable.bcp47Tag)

      if let retryFailure = await attemptReserve(locale) {
        return .failure(retryFailure)
      }
    }

    reservedTags.insert(tag)
    return .success(())
  }

  private func attemptReserve(_ locale: Locale) async -> TranscriptionError? {
    do {
      try await AssetInventory.reserve(locale: locale)
      return nil
    } catch is CancellationError {
      return .cancelled
    } catch {
      return .assetsUnavailable("\(error)")
    }
  }

  static func evictionCandidate(
    from reserved: [Locale],
    reservedByUs: Set<String>,
    keeping keepingTags: Set<String>
  ) -> Locale? {
    reserved.first { candidate in
      let candidateTag = candidate.bcp47Tag
      return reservedByUs.contains(candidateTag) && !keepingTags.contains(candidateTag)
    }
  }
}
