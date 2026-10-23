import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.chivopic.cyber-muyu"

  readonly property string scriptPath: String(Qt.resolvedUrl("backend.py")).replace(/^file:\/\//, "")
  readonly property bool showCount: setting("showCount", true) === true
  readonly property string defaultSound: setting("sound", "muyu")
  readonly property int defaultVolume: setting("volume", 80)
  readonly property string defaultMantra: setting("mantra", "功德 +1")
  readonly property int defaultAutoBpm: setting("autoBpm", 60)
  readonly property int defaultDailyGoal: setting("dailyGoal", 108)

  // Live state from backend
  MeritState { id: meritState }
  ProcessResultGate {
    id: knockBatch
    onBatchCompleted: function(count, output, exitCode) {
      root.finishKnockBatch(count, output, exitCode)
    }
  }
  ProcessResultGate {
    id: statusRequest
    onBatchCompleted: function(count, output, exitCode, requestRevision) {
      root.finishStatusRefresh(output, exitCode, requestRevision)
    }
  }
  readonly property var summary: meritState.summary
  readonly property int todayMerits: meritState.todayMerits
  readonly property int totalMerits: meritState.totalMerits
  property int streak: Number(summary.streak || 1)
  property int dailyGoal: Number(summary.dailyGoal || defaultDailyGoal)
  property real goalProgress: Number(summary.goalProgress || 0)
  property bool goalCompleted: summary.goalCompleted === true
  property string activeMantra: summary.mantra || defaultMantra
  property string currentSound: summary.sound || defaultSound
  property int soundVolume: Number(summary.volume !== undefined ? summary.volume : defaultVolume)
  property bool soundMuted: soundVolume <= 0
  property int autoBpm: Number(summary.autoBpm || defaultAutoBpm)
  property string rankName: summary.rank || "扫地码农"
  property string rankEn: summary.rankEn || "Novice Monk"
  property string rankQuote: summary.quote || "身如菩提树，心如明镜台"
  property int rankLevel: Number(summary.rankLevel || 1)
  property int nextRankAt: Number(summary.nextRankAt || 100)
  property real rankProgress: Number(summary.rankProgress || 0)
  property var last7Days: summary.last7Days || []

  // UI state
  property bool popupOpen: false
  property bool autoKnocking: false
  property var pendingKnocks: []
  property var pendingSettings: ({})
  property bool refreshQueued: false
  property string barGlyph: "🪷"
  property string buttonText: showCount ? barGlyph + " " + todayMerits : barGlyph
  property string tooltipText: "赛博木鱼 · 今日功德: " + todayMerits + " · 累计: " + totalMerits + " · 境界: " + rankName + "\n左键敲击积德 · 右键修行面板 · 中键自动挂机"

  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }
  function toggleAuto() {
    autoKnocking = !autoKnocking
    var msg = autoKnocking ? "开启自动挂机积德 (" + autoBpm + " BPM)" : "已暂停自动挂机"
    Quickshell.execDetached([
      "omarchy", "notification", "send",
      "-g", barGlyph, "-u", "low", "-t", "2000",
      "赛博木鱼", msg
    ])
  }

  function soundPath(soundName) {
    return String(Qt.resolvedUrl("sounds/" + (soundName || currentSound) + ".wav")).replace(/^file:\/\//, "")
  }

  function playSound() {
    if (soundMuted || soundVolume <= 0) return
    try {
      soundPlayer.volume = Math.max(0.0, Math.min(1.0, soundVolume / 100.0))
      soundPlayer.stop()
      soundPlayer.play()
    } catch (e) {
      Quickshell.execDetached(["pw-play", soundPath(currentSound)])
    }
  }

  // Knock the wooden fish
  function knock(customMantra) {
    var txt = customMantra || activeMantra || "功德 +1"
    
    // Keep optimistic taps separate from backend-derived counters.
    meritState.noteKnock()
    
    // Visual feedback on bar
    barBounceAnim.restart()
    barFloatingText.spawn(txt)

    // Stage feedback if popup is open
    if (popupOpen && woodenFishStage) {
      woodenFishStage.animateStrike(txt)
    }

    // Audio feedback
    playSound()

    // Keep every tap until the backend has persisted it.
    var queued = pendingKnocks.slice()
    queued.push(txt)
    pendingKnocks = queued
    flushKnocks()
  }

  function flushKnocks() {
    if (knockProc.running || knockBatch.active) return
    if (pendingKnocks.length === 0) {
      if (refreshQueued && meritState.pendingKnocks === 0) refresh()
      return
    }

    var mantra = String(pendingKnocks[0] || defaultMantra)
    var count = 1
    while (count < pendingKnocks.length && pendingKnocks[count] === mantra) count += 1
    if (!knockBatch.begin(count, 0)) return
    pendingKnocks = pendingKnocks.slice(count)
    knockProc.command = ["/usr/bin/python3", "-I", root.scriptPath, "knock", String(count), mantra]
    knockProc.running = true
  }

  function applySnapshot(raw, requestRevision) {
    meritState.applySnapshot(raw, requestRevision)
  }

  function finishKnockBatch(count, output, exitCode) {
    if (exitCode === 0) {
      if (!meritState.applyKnock(output, count)) {
        console.warn("cyber-muyu: knock returned an invalid summary; refreshing state")
        refreshQueued = true
      }
    } else {
      meritState.rejectKnock(count)
      console.warn("cyber-muyu: knock process failed with exit code " + exitCode)
      refreshQueued = true
    }
    // Run after the Process signal returns so its running property has settled.
    Qt.callLater(function() { root.flushKnocks() })
  }

  function refresh() {
    refreshQueued = true
    startQueuedRefresh()
  }

  function startQueuedRefresh() {
    if (!refreshQueued || statusProc.running || statusRequest.active || knockProc.running || knockBatch.active || meritState.pendingKnocks > 0) return
    refreshQueued = false
    if (!statusRequest.begin(0, meritState.knockRevision)) return
    statusProc.running = true
  }

  function finishStatusRefresh(output, exitCode, requestRevision) {
    if (exitCode === 0) applySnapshot(output, requestRevision)
    // Let Process.running settle before reusing the Process object.
    Qt.callLater(function() { root.startQueuedRefresh() })
  }

  function updateSetting(key, val) {
    var queued = {}
    for (var queuedKey in pendingSettings) queued[queuedKey] = pendingSettings[queuedKey]
    queued[key] = val
    pendingSettings = queued
    flushSettings()
  }

  function flushSettings() {
    if (settingProc.running) return

    var keys = Object.keys(pendingSettings)
    if (keys.length === 0) return

    var key = keys[0]
    var value = pendingSettings[key]
    var queued = {}
    for (var queuedKey in pendingSettings) {
      if (queuedKey !== key) queued[queuedKey] = pendingSettings[queuedKey]
    }
    pendingSettings = queued
    settingProc.command = ["/usr/bin/python3", "-I", root.scriptPath, "set-setting", key, String(value)]
    settingProc.requestRevision = meritState.knockRevision
    settingProc.running = true
  }

  Component.onCompleted: refresh()

  // Periodic date rollover check
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // Auto-knock timer
  Timer {
    id: autoKnockTimer
    interval: Math.max(250, Math.round(60000 / Math.max(20, Math.min(240, root.autoBpm))))
    running: root.autoKnocking
    repeat: true
    onTriggered: root.knock(root.activeMantra)
  }

  // Audio Player
  SoundEffect {
    id: soundPlayer
    source: Qt.resolvedUrl("sounds/" + root.currentSound + ".wav")
    volume: root.soundMuted ? 0 : (root.soundVolume / 100.0)
  }

  // Shell IPC Interface for keybindings
  IpcHandler {
    target: "io.github.chivopic.cyber-muyu"

    function knock(): void { root.knock() }
    function open(): void { root.popupOpen = true }
    function close(): void { root.popupOpen = false }
    function toggle(): void { root.popupOpen = !root.popupOpen }
    function toggleAuto(): void { root.toggleAuto() }
    function refresh(): void { root.refresh() }
  }

  // Backend Process Handlers
  // quickshell-io.qmltypes orders ExitStatus as NormalExit=0, CrashExit=1;
  // a crash has no usable exit code and is normalized to failure.
  Process {
    id: statusProc
    command: ["/usr/bin/python3", "-I", root.scriptPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: statusRequest.finishOutput(text)
    }
    onExited: function(exitCode, exitStatus) {
      statusRequest.finishProcess(exitStatus === 0 ? exitCode : -1)
    }
    // In quickshell-io.qmltypes, QProcess::ProcessError.FailedToStart is 0;
    // Crashed is 1 and continues through the normal exited + stream-finished gate.
    onErrorOccurred: function(error) { if (error === 0) statusRequest.failToStart() }
  }

  Process {
    id: knockProc
    command: ["/usr/bin/python3", "-I", root.scriptPath, "knock", "1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: knockBatch.finishOutput(text)
    }
    onExited: function(exitCode, exitStatus) {
      knockBatch.finishProcess(exitStatus === 0 ? exitCode : -1)
    }
    // FailedToStart has no exited signal; runtime Crashed errors use the gate above.
    onErrorOccurred: function(error) { if (error === 0) knockBatch.failToStart() }
  }

  Process {
    id: settingProc
    property int requestRevision: 0
    command: ["/usr/bin/python3", "-I", root.scriptPath, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySnapshot(text, settingProc.requestRevision)
    }
    onExited: root.flushSettings()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The Bar Button
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.buttonText
    tooltipText: root.tooltipText
    horizontalMargin: 8.75

    // Visual pulse when knocked directly on bar
    SequentialAnimation {
      id: barBounceAnim
      NumberAnimation { target: button; property: "scale"; to: 1.15; duration: 60; easing.type: Easing.OutQuad }
      NumberAnimation { target: button; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) {
        root.knock()
      } else if (mouseButton === Qt.RightButton) {
        root.toggle()
      } else if (mouseButton === Qt.MiddleButton) {
        root.toggleAuto()
      }
    }
  }

  // Floating text that pops directly out of the bar button!
  Item {
    id: barFloatingText
    anchors.horizontalCenter: button.horizontalCenter
    y: (root.bar && root.bar.position === "bottom") ? button.y - Style.space(25) : button.y + button.height + Style.space(5)
    width: 1
    height: 1

    property var floatPool: []

    function spawn(txt) {
      floatingLabel.text = txt
      barFloatAnim.restart()
    }

    Text {
      id: floatingLabel
      anchors.centerIn: parent
      text: "+1 功德"
      color: Commons.Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.small
      font.bold: true
      opacity: 0

      ParallelAnimation {
        id: barFloatAnim
        NumberAnimation {
          target: floatingLabel
          property: "opacity"
          from: 1.0
          to: 0.0
          duration: 650
          easing.type: Easing.InQuad
        }
        NumberAnimation {
          target: floatingLabel
          property: "y"
          from: 0
          to: (root.bar && root.bar.position === "bottom") ? -Style.space(25) : Style.space(25)
          duration: 650
          easing.type: Easing.OutCubic
        }
      }
    }
  }

  // Reference property for stage communication
  property var woodenFishStage: null

  // Zen Sanctuary Popup Card
  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(contentCol.implicitHeight)

    Column {
      id: contentCol
      anchors.fill: parent
      spacing: Style.space(12)

      // 1. Header with Zen Rank Badge
      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "🪷"
          font.family: Style.font.family
          font.pixelSize: Style.font.display
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Row {
            spacing: Style.space(8)
            Text {
              text: "赛博木鱼"
              color: Commons.Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              height: Style.space(18)
              width: rankBadgeText.implicitWidth + Style.space(10)
              radius: height / 2
              color: Style.selectedFillFor(Commons.Color.foreground, Commons.Color.accent)
              border.color: Commons.Color.accent
              border.width: 1

              Text {
                id: rankBadgeText
                anchors.centerIn: parent
                text: root.rankName
                color: Commons.Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }
          }

          Text {
            text: root.rankQuote
            color: Commons.Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Commons.Color.popups.border
      }

      // 2. Interactive Wooden Fish Stage
      Item {
        width: parent.width
        height: Style.space(165)

        WoodenFish {
          id: fishItem
          anchors.centerIn: parent
          mantra: root.activeMantra
          primaryColor: Commons.Color.accent
          foregroundColor: Commons.Color.foreground
          autoKnocking: root.autoKnocking

          Component.onCompleted: {
            root.woodenFishStage = fishItem
          }

          onStruck: function(txt) {
            root.knock(txt)
          }
        }
      }

      // 3. Auto-Knock Controls & BPM
      Rectangle {
        width: parent.width
        height: Style.space(40)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 6
        color: Qt.tint(Commons.Color.popups.background, Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.04))
        border.color: Commons.Color.popups.border
        border.width: 1

        Item {
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.autoKnocking ? "⚡ 自动修禅中 (" + root.autoBpm + " BPM)" : "💤 自动挂机 (点击开启)"
            color: root.autoKnocking ? Commons.Color.accent : Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: root.autoKnocking
          }

          ToggleSwitch {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.autoKnocking
            onToggled: root.toggleAuto()
          }
        }
      }

      // BPM Slider (visible when auto-knocking is active or toggled)
      Row {
        width: parent.width
        spacing: Style.space(8)
        visible: root.autoKnocking

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "敲击节奏:"
          color: Commons.Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        PanelSlider {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(180)
          minimum: 30
          maximum: 180
          step: 5
          value: root.autoBpm
          onMoved: function(val) {
            root.autoBpm = Math.round(val)
          }
          onReleased: function(val) {
            root.autoBpm = Math.round(val)
            root.updateSetting("autoBpm", root.autoBpm)
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.autoBpm + " BPM"
          color: Commons.Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

      // 4. Mantra Preset Selection Chips
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "功德箴言 (敲击飘字):"
          color: Commons.Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Grid {
          width: parent.width
          columns: 3
          spacing: Style.space(6)

          Repeater {
            model: ["功德 +1", "Bug -1", "头发 +1", "薪水 +1", "编译通过", "顺利下班"]
            delegate: Button {
              width: (contentCol.width - Style.space(12)) / 3
              height: Style.space(26)
              text: modelData
              selected: root.activeMantra === modelData
              bordered: true
              fontSize: Style.font.small
              onClicked: {
                root.activeMantra = modelData
                root.updateSetting("mantra", modelData)
              }
            }
          }
        }

        // Custom mantra input
        TextField {
          width: parent.width
          placeholderText: "自定义箴言（如：需求不改、GPU充足...）"
          text: root.activeMantra
          verticalPadding: Style.space(4)
          onAccepted: {
            if (text.trim() !== "") {
              root.activeMantra = text.trim()
              root.updateSetting("mantra", root.activeMantra)
            }
          }
        }
      }

      // 5. Sound Presets & Volume
      Column {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "梵音音色:"
          color: Commons.Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: [
              { "id": "muyu", "label": "🪵 木鱼" },
              { "id": "bowl", "label": "🔔 铜磬" },
              { "id": "bubble", "label": "🫧 气泡" },
              { "id": "click", "label": "⌨️ 青轴" }
            ]
            delegate: Button {
              width: (contentCol.width - Style.space(18)) / 4
              height: Style.space(26)
              text: modelData.label
              selected: root.currentSound === modelData.id
              bordered: true
              fontSize: Style.font.small
              onClicked: {
                root.currentSound = modelData.id
                root.playSound()
                root.updateSetting("sound", modelData.id)
              }
            }
          }
        }

        // Volume row
        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(26)
            height: Style.space(26)
            iconText: root.soundMuted ? "󰝟" : "󰕾"
            selected: !root.soundMuted
            bordered: true
            onClicked: {
              if (root.soundMuted) {
                root.soundVolume = 80
              } else {
                root.soundVolume = 0
              }
              root.updateSetting("volume", root.soundVolume)
            }
          }

          PanelSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(220)
            minimum: 0
            maximum: 100
            step: 5
            value: root.soundVolume
            onMoved: function(val) {
              root.soundVolume = Math.round(val)
            }
            onReleased: function(val) {
              root.soundVolume = Math.round(val)
              root.playSound()
              root.updateSetting("volume", root.soundVolume)
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.soundMuted ? "静音" : root.soundVolume + "%"
            color: Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }
        }
      }

      // 6. Karma Stats & Daily Goal
      Rectangle {
        width: parent.width
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : 6
        color: Qt.tint(Commons.Color.popups.background, Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.04))
        border.color: Commons.Color.popups.border
        border.width: 1
        implicitHeight: statsCol.implicitHeight + Style.space(16)

        Column {
          id: statsCol
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(8)

          // Goal Row
          Item {
            width: parent.width
            height: goalTxtRow.implicitHeight

            Row {
              id: goalTxtRow
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(6)

              Text {
                text: "今日功德目标:"
                color: Commons.Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                text: root.todayMerits + " / " + root.dailyGoal + (root.goalCompleted ? " 🌟 圆满达成" : "")
                color: root.goalCompleted ? Commons.Color.accent : Commons.Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            Text {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: "连续 " + root.streak + " 天"
              color: Commons.Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          // Progress Bar
          Rectangle {
            width: parent.width
            height: Style.space(6)
            radius: 3
            color: Qt.tint(Commons.Color.popups.background, Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.12))

            Rectangle {
              width: parent.width * Math.min(1.0, root.goalProgress)
              height: parent.height
              radius: 3
              color: Commons.Color.accent

              Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
              }
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "每日功德目标"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            TextField {
              width: Style.space(88)
              height: Style.space(28)
              text: String(root.dailyGoal)
              validator: IntValidator { bottom: 1; top: 99999 }
              onAccepted: {
                var goal = Number(text)
                if (isFinite(goal) && goal >= 1 && goal <= 99999) {
                  root.dailyGoal = Math.round(goal)
                  root.updateSetting("dailyGoal", root.dailyGoal)
                }
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "次"
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          // Total merits & next rank
          Row {
            width: parent.width
            spacing: Style.space(12)

            Text {
              text: "总功德: " + root.totalMerits
              color: Commons.Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              text: "升级至下一重境还需: " + Math.max(0, root.nextRankAt - root.totalMerits)
              color: Commons.Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
