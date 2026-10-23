import QtQuick
import QtQuick.Window
import ".."

Window {
  id: window
  width: 960
  height: 500
  visible: true
  color: "#111827"
  title: "Cyber Muyu · QtQuick regression evidence"

  MeritState { id: meritModel }
  ProcessResultGate {
    id: processGate
    onBatchCompleted: function(count, output, exitCode, requestRevision, generation) {
      window.completedBatches += 1
      window.lastCompletedCount = count
      window.lastCompletedOutput = output
      window.lastCompletedExitCode = exitCode
      window.lastCompletedRevision = requestRevision
      window.lastCompletedGeneration = generation
    }
  }
  property string outcome: "Running isolated counter regression…"
  property string details: ""
  property string failureDetails: ""
  property int failures: 0
  property int completedBatches: 0
  property int lastCompletedCount: 0
  property int lastCompletedExitCode: -1
  property int lastCompletedRevision: 0
  property int lastCompletedGeneration: 0
  property string lastCompletedOutput: ""
  readonly property color lowTint: Qt.tint("#111827", Qt.rgba(0.976, 0.980, 0.988, 0.04))
  readonly property color trackTint: Qt.tint("#111827", Qt.rgba(0.976, 0.980, 0.988, 0.12))

  function check(condition, message) {
    if (!condition) {
      console.error("FAIL: " + message)
      failures += 1
      failureDetails += (failureDetails.length ? "; " : "") + message
    } else {
      console.log("PASS: " + message)
    }
  }

  Component.onCompleted: {
    meritModel.applySnapshot('{"todayDate":"2026-10-23","todayMerits":0,"totalMerits":0}', 0)
    meritModel.noteKnock()
    var requestAfterTap = meritModel.knockRevision
    var snapshotAcceptedWhilePending = meritModel.applySnapshot('{"todayDate":"2026-10-23","todayMerits":0,"totalMerits":0}', requestAfterTap)
    check(!snapshotAcceptedWhilePending && meritModel.todayMerits === 1 && meritModel.totalMerits === 1,
          "snapshot started during a pending tap cannot double-count it")

    meritModel.applyKnock('{"todayDate":"2026-10-23","todayMerits":1,"totalMerits":1}', 1)
    var staleAfterAckAccepted = meritModel.applySnapshot('{"todayDate":"2026-10-23","todayMerits":0,"totalMerits":0}', requestAfterTap)
    check(!staleAfterAckAccepted && meritModel.todayMerits === 1 && meritModel.totalMerits === 1,
          "pre-ack snapshot is rejected after a successful knock reply advances the epoch")

    var rapidTapSnapshotRevision = meritModel.knockRevision
    meritModel.noteKnock()
    meritModel.noteKnock()
    var rapidStaleAccepted = meritModel.applySnapshot('{"todayDate":"2026-10-23","todayMerits":1,"totalMerits":1}', rapidTapSnapshotRevision)
    check(!rapidStaleAccepted && meritModel.todayMerits === 3 && meritModel.totalMerits === 3,
          "late snapshot cannot erase two rapid optimistic taps")
    meritModel.applyKnock('{"todayDate":"2026-10-23","todayMerits":2,"totalMerits":2}', 1)
    check(meritModel.pendingKnocks === 1 && meritModel.todayMerits === 3 && meritModel.totalMerits === 3,
          "first serialized reply preserves the remaining optimistic tap")
    meritModel.applyKnock('{"todayDate":"2026-10-23","todayMerits":3,"totalMerits":3}', 1)
    check(meritModel.pendingKnocks === 0 && meritModel.todayMerits === 3 && meritModel.totalMerits === 3,
          "second reply confirms both persisted increments without a jump")

    meritModel.applySnapshot('{"todayDate":"2026-10-24","todayMerits":0,"totalMerits":3}', meritModel.knockRevision)
    check(meritModel.todayMerits === 0 && meritModel.totalMerits === 3,
          "next-day summary rolls today's count to zero")

    meritModel.applySnapshot('{"todayDate":"2026-10-24","todayMerits":3,"totalMerits":45}', meritModel.knockRevision)
    check(meritModel.todayMerits === 3 && meritModel.totalMerits === 45,
          "refresh shows merits added by another client")
    var requestBeforeFailedKnock = meritModel.knockRevision
    meritModel.noteKnock()
    var malformedAccepted = meritModel.applyKnock("not-json", 1)
    var staleAfterFailureAccepted = meritModel.applySnapshot('{"todayDate":"2026-10-24","todayMerits":3,"totalMerits":45}', requestBeforeFailedKnock)
    check(!malformedAccepted && meritModel.pendingKnocks === 0 && meritModel.todayMerits === 3 && !staleAfterFailureAccepted,
          "malformed knock response rolls back optimism and invalidates earlier snapshots")
    check(trackTint.r > lowTint.r && lowTint.r > 0.06,
          "Qt.tint composites explicit 4% and 12% foreground alpha overlays")

    processGate.begin(1, 101)
    processGate.finishProcess(0)
    var secondBatchStartedEarly = processGate.begin(2, 102)
    check(processGate.active && !secondBatchStartedEarly && window.completedBatches === 0,
          "process-exit-first leaves the old batch active while a mid-gap tap queues")
    processGate.finishOutput("exit-first summary")
    check(!processGate.active && window.completedBatches === 1 && window.lastCompletedCount === 1
          && window.lastCompletedOutput === "exit-first summary" && window.lastCompletedRevision === 101,
          "exit-first batch settles once stdout finishes, with its original metadata")

    processGate.begin(2, 202)
    processGate.finishOutput("output-first summary")
    var thirdBatchStartedEarly = processGate.begin(1, 303)
    check(processGate.active && !thirdBatchStartedEarly && window.completedBatches === 1,
          "stdout-first also blocks a mid-gap tap from replacing the active batch")
    processGate.finishProcess(7)
    check(!processGate.active && window.completedBatches === 2 && window.lastCompletedCount === 2
          && window.lastCompletedOutput === "output-first summary" && window.lastCompletedExitCode === 7
          && window.lastCompletedRevision === 202,
          "stdout-first batch settles once process exit arrives")

    processGate.begin(1, 404)
    processGate.failToStart()
    check(!processGate.active && window.completedBatches === 3 && window.lastCompletedCount === 1
          && window.lastCompletedOutput === "" && window.lastCompletedExitCode === -1
          && window.lastCompletedRevision === 404,
          "failed-to-start settles once without waiting for an exited event")

    if (Qt.application.arguments.indexOf("--force-failure") !== -1)
      check(false, "negative control intentionally fails an assertion")
    outcome = failures === 0 ? "PASS · all 14 regression assertions" : "FAIL · " + failures + " regression assertion(s)"
    details = failures === 0 ? "Real MeritState.qml · QtQuick offscreen · no plugin instance or user data" : failureDetails
    captureTimer.start()
  }

  Timer {
    id: captureTimer
    interval: 250
    onTriggered: evidence.grabToImage(function(result) {
      var path = ".github/pr-evidence/release-readiness/merit-state-regression.png"
      var saved = result.saveToFile(path)
      if (!saved) {
        window.failures += 1
        window.outcome = "FAIL · could not save regression image"
        console.error("Could not save " + path)
      }
      else console.log("Saved " + path)
      Qt.exit(window.failures === 0 && saved ? 0 : 1)
    })
  }

  Item {
    id: evidence
    anchors.fill: parent

  Rectangle {
    anchors.fill: parent
    anchors.margins: 28
    radius: 18
    color: "#1f2937"
    border.color: "#374151"
    border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 30
      spacing: 20

      Text {
        text: "Cyber Muyu counter regression"
        color: "#f9fafb"
        font.pixelSize: 27
        font.weight: Font.DemiBold
      }
      Text {
        text: "Isolated QtQuick fixture · production MeritState.qml"
        color: "#9ca3af"
        font.pixelSize: 15
      }
      Row {
        spacing: 36
        Rectangle {
          width: 250; height: 118; radius: 12; color: "#111827"
          Column {
            anchors.centerIn: parent; spacing: 8
            Text { text: "TODAY'S MERITS"; color: "#9ca3af"; font.pixelSize: 13 }
            Text { text: meritModel.todayMerits; color: "#a7f3d0"; font.pixelSize: 38; font.weight: Font.Bold }
          }
        }
        Rectangle {
          width: 250; height: 118; radius: 12; color: "#111827"
          Column {
            anchors.centerIn: parent; spacing: 8
            Text { text: "TOTAL MERITS"; color: "#9ca3af"; font.pixelSize: 13 }
            Text { text: meritModel.totalMerits; color: "#a7f3d0"; font.pixelSize: 38; font.weight: Font.Bold }
          }
        }
      }
      Text { text: window.outcome; color: "#86efac"; font.pixelSize: 19; font.weight: Font.DemiBold }
      Text { text: window.details; color: "#9ca3af"; font.pixelSize: 13 }
      Row {
        spacing: 12
        Rectangle { width: 160; height: 32; radius: 6; color: window.lowTint; border.color: "#4b5563"; Text { anchors.centerIn: parent; text: "4% panel fill"; color: "#f9fafb"; font.pixelSize: 12 } }
        Rectangle { width: 160; height: 32; radius: 6; color: window.trackTint; border.color: "#4b5563"; Text { anchors.centerIn: parent; text: "12% progress track"; color: "#f9fafb"; font.pixelSize: 12 } }
      }
    }
  }
  }
}
