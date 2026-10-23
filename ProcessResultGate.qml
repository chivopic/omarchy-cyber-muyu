import QtQuick

// A Process run is not reusable until its exit signal and stdout stream end
// have both arrived. It also captures the request metadata for that run.
QtObject {
  id: root

  property bool active: false
  property int generation: 0
  property int batchCount: 0
  property int requestRevision: 0
  property string output: ""
  property int exitCode: -1
  property bool outputFinished: false
  property bool processExited: false

  signal batchCompleted(int count, string output, int exitCode, int requestRevision, int generation)

  function begin(count, revision) {
    if (active) return false
    active = true
    generation += 1
    batchCount = count
    requestRevision = revision
    output = ""
    exitCode = -1
    outputFinished = false
    processExited = false
    return true
  }

  function finishOutput(text) {
    if (!active || outputFinished) return false
    output = text
    outputFinished = true
    finishIfReady()
    return true
  }

  function finishProcess(code) {
    if (!active || processExited) return false
    exitCode = code
    processExited = true
    finishIfReady()
    return true
  }

  // FailedToStart has no later exited signal. Runtime errors such as Crashed
  // must go through finishOutput + finishProcess to avoid early reuse.
  function failToStart() {
    if (!active) return false
    output = ""
    exitCode = -1
    outputFinished = true
    processExited = true
    finishIfReady()
    return true
  }

  function finishIfReady() {
    if (!active || !outputFinished || !processExited) return false
    var completedCount = batchCount
    var completedOutput = output
    var completedExitCode = exitCode
    var completedRevision = requestRevision
    var completedGeneration = generation

    active = false
    batchCount = 0
    requestRevision = 0
    output = ""
    exitCode = -1
    outputFinished = false
    processExited = false
    batchCompleted(completedCount, completedOutput, completedExitCode, completedRevision, completedGeneration)
    return true
  }
}
