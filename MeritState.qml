import QtQuick

// Keeps backend values and unconfirmed taps separate so optimistic UI updates
// never replace the bindings to the backend summary.
QtObject {
  id: root

  property var summary: ({})
  property int pendingKnocks: 0
  property int knockRevision: 0

  readonly property int todayMerits: Number(summary.todayMerits || 0) + pendingKnocks
  readonly property int totalMerits: Number(summary.totalMerits || 0) + pendingKnocks

  function noteKnock() {
    pendingKnocks += 1
    knockRevision += 1
  }

  // Refresh and settings responses can have been read before a recent tap.
  // Ignore those snapshots; the serialized knock response will reconcile them.
  function applySnapshot(raw, requestRevision) {
    var parsed = parseSummary(raw)
    if (!parsed || pendingKnocks > 0 || requestRevision !== knockRevision) return false
    summary = parsed
    return true
  }

  function applyKnock(raw, batchCount) {
    var parsed = parseSummary(raw)
    if (!parsed) {
      rejectKnock(batchCount)
      return false
    }
    summary = parsed
    settleKnockBatch(batchCount)
    return true
  }

  function rejectKnock(batchCount) {
    settleKnockBatch(batchCount)
  }

  function settleKnockBatch(batchCount) {
    pendingKnocks = Math.max(0, pendingKnocks - batchCount)
    // Invalidate snapshots that started before this acknowledgement or error.
    knockRevision += 1
  }

  function parseSummary(raw) {
    try {
      const parsed = JSON.parse(String(raw || ""))
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null
      if (!isFinite(Number(parsed.todayMerits)) || !isFinite(Number(parsed.totalMerits))) return null
      return parsed
    } catch (e) {
      console.warn("cyber-muyu: failed parsing summary: " + e)
      return null
    }
  }
}
