import QtQuick
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property string mantra: "功德 +1"
  property color primaryColor: Commons.Color.accent
  property color foregroundColor: Commons.Color.foreground
  property bool autoKnocking: false

  signal struck(string text)

  implicitWidth: Style.space(220)
  implicitHeight: Style.space(170)

  // Trigger strike animation
  function strike(text) {
    var floatText = text || root.mantra || "功德 +1"
    
    // Trigger bounce animation
    bounceAnim.restart()
    malletAnim.restart()
    rippleAnim.restart()

    // Spawn floating karma text
    spawnFloatingText(floatText)

    root.struck(floatText)
  }

  // Floating texts list model
  ListModel {
    id: karmaModel
  }

  function spawnFloatingText(txt) {
    var randX = (Math.random() - 0.5) * Style.space(40)
    karmaModel.append({
      "text": txt,
      "startX": (fishContainer.x + fishContainer.width / 2 - Style.space(30)) + randX,
      "startY": fishContainer.y + Style.space(10)
    })
  }

  // Ripple shockwave ring
  Rectangle {
    id: ripple
    anchors.centerIn: fishContainer
    width: Style.space(80)
    height: Style.space(80)
    radius: width / 2
    color: "transparent"
    border.color: root.primaryColor
    border.width: Style.space(2)
    opacity: 0
    scale: 0.6

    ParallelAnimation {
      id: rippleAnim
      NumberAnimation { target: ripple; property: "scale"; from: 0.8; to: 2.1; duration: 420; easing.type: Easing.OutCubic }
      NumberAnimation { target: ripple; property: "opacity"; from: 0.8; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
    }
  }

  // Container holding the Wooden Fish canvas
  Item {
    id: fishContainer
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: -Style.space(12)
    width: Style.space(130)
    height: Style.space(105)
    transformOrigin: Item.Center

    // Canvas drawing of authentic, polished wooden fish
    Canvas {
      id: fishCanvas
      anchors.fill: parent
      antialiasing: true

      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var w = width
        var h = height

        // Fish Body gradient
        var grad = ctx.createRadialGradient(w * 0.45, h * 0.4, w * 0.1, w * 0.5, h * 0.5, w * 0.55)
        grad.addColorStop(0, "#D97706") // warm amber highlight
        grad.addColorStop(0.65, "#92400E") // rich wood tone
        grad.addColorStop(1, "#451A03") // deep shadow

        ctx.save()

        // 1. Base Drop Shadow
        ctx.beginPath()
        ctx.ellipse(w * 0.5, h * 0.86, w * 0.38, h * 0.12)
        ctx.fillStyle = "rgba(0, 0, 0, 0.25)"
        ctx.fill()

        // 2. Main Wooden Fish Body (classic curved bulbous shape)
        ctx.beginPath()
        ctx.moveTo(w * 0.22, h * 0.72)
        // bottom belly
        ctx.bezierCurveTo(w * 0.38, h * 0.90, w * 0.68, h * 0.90, w * 0.84, h * 0.70)
        // back curve towards top handle
        ctx.bezierCurveTo(w * 0.95, h * 0.52, w * 0.90, h * 0.28, w * 0.74, h * 0.18)
        // top crest curve
        ctx.bezierCurveTo(w * 0.60, h * 0.10, w * 0.40, h * 0.10, w * 0.26, h * 0.22)
        // front head curve
        ctx.bezierCurveTo(w * 0.10, h * 0.36, w * 0.08, h * 0.58, w * 0.22, h * 0.72)
        ctx.closePath()

        ctx.fillStyle = grad
        ctx.fill()

        // Outer rim subtle highlight
        ctx.lineWidth = Style.space(2)
        ctx.strokeStyle = "rgba(255, 255, 255, 0.25)"
        ctx.stroke()

        // 3. Hollow Mouth Slit (Characteristic feature of Chinese Muyu)
        ctx.beginPath()
        ctx.moveTo(w * 0.14, h * 0.54)
        ctx.bezierCurveTo(w * 0.28, h * 0.62, w * 0.50, h * 0.60, w * 0.66, h * 0.52)
        ctx.bezierCurveTo(w * 0.52, h * 0.46, w * 0.30, h * 0.48, w * 0.14, h * 0.54)
        ctx.fillStyle = "#1E0B02" // deep dark cavity inside
        ctx.fill()

        // Slit edge accent line
        ctx.beginPath()
        ctx.moveTo(w * 0.16, h * 0.56)
        ctx.bezierCurveTo(w * 0.30, h * 0.63, w * 0.50, h * 0.61, w * 0.64, h * 0.53)
        ctx.lineWidth = Style.space(1.5)
        ctx.strokeStyle = "rgba(245, 158, 11, 0.4)"
        ctx.stroke()

        // 4. Carved Dragon Scale / Zen Wave patterns on body
        ctx.beginPath()
        ctx.arc(w * 0.48, h * 0.34, w * 0.08, 0, Math.PI, false)
        ctx.arc(w * 0.62, h * 0.36, w * 0.07, 0, Math.PI, false)
        ctx.lineWidth = Style.space(1.5)
        ctx.strokeStyle = "rgba(251, 191, 36, 0.35)"
        ctx.stroke()

        // 5. Wooden Fish "Eye" Carving (Double-circle eye)
        ctx.beginPath()
        ctx.arc(w * 0.26, h * 0.36, w * 0.055, 0, 2 * Math.PI)
        ctx.fillStyle = "#2D1305"
        ctx.fill()
        ctx.lineWidth = Style.space(1.5)
        ctx.strokeStyle = "rgba(251, 191, 36, 0.45)"
        ctx.stroke()

        // Eye center pupil
        ctx.beginPath()
        ctx.arc(w * 0.26, h * 0.36, w * 0.02, 0, 2 * Math.PI)
        ctx.fillStyle = "#FDE68A"
        ctx.fill()

        // 6. Top handle ring hole (traditional loop)
        ctx.beginPath()
        ctx.arc(w * 0.74, h * 0.28, w * 0.05, 0, 2 * Math.PI)
        ctx.fillStyle = "#280F03"
        ctx.fill()
        ctx.lineWidth = Style.space(1.5)
        ctx.strokeStyle = "rgba(251, 191, 36, 0.3)"
        ctx.stroke()

        ctx.restore()
      }
    }

    // Elastic Squash & Stretch Bounce Animation
    SequentialAnimation {
      id: bounceAnim
      ParallelAnimation {
        NumberAnimation { target: fishContainer; property: "scale"; to: 0.91; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: fishContainer; property: "rotation"; to: -2; duration: 50; easing.type: Easing.OutQuad }
      }
      ParallelAnimation {
        NumberAnimation { target: fishContainer; property: "scale"; to: 1.06; duration: 110; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
        NumberAnimation { target: fishContainer; property: "rotation"; to: 1.5; duration: 110 }
      }
      ParallelAnimation {
        NumberAnimation { target: fishContainer; property: "scale"; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: fishContainer; property: "rotation"; to: 0; duration: 160 }
      }
    }

    // Click handler directly on the fish
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onPressed: root.strike()
    }
  }

  // Wooden Mallet (木槌) - positioned to strike down upon the fish
  Item {
    id: mallet
    x: fishContainer.x + fishContainer.width - Style.space(12)
    y: fishContainer.y - Style.space(24)
    width: Style.space(60)
    height: Style.space(70)
    transformOrigin: Item.BottomRight
    rotation: 18

    // Mallet Stick & Head Canvas
    Canvas {
      id: malletCanvas
      anchors.fill: parent
      antialiasing: true

      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var w = width
        var h = height

        ctx.save()

        // Mallet Head (round bulb at tip)
        var headGrad = ctx.createRadialGradient(w * 0.25, h * 0.70, w * 0.04, w * 0.28, h * 0.75, w * 0.22)
        headGrad.addColorStop(0, "#F59E0B")
        headGrad.addColorStop(0.7, "#92400E")
        headGrad.addColorStop(1, "#451A03")

        ctx.beginPath()
        ctx.arc(w * 0.26, h * 0.74, w * 0.16, 0, 2 * Math.PI)
        ctx.fillStyle = headGrad
        ctx.fill()
        ctx.lineWidth = Style.space(1)
        ctx.strokeStyle = "rgba(255, 255, 255, 0.25)"
        ctx.stroke()

        // Mallet Stick (handle extending to top-right)
        ctx.beginPath()
        ctx.moveTo(w * 0.34, h * 0.68)
        ctx.lineTo(w * 0.88, h * 0.14)
        ctx.lineWidth = Style.space(5)
        ctx.lineCap = "round"
        ctx.strokeStyle = "#78350F"
        ctx.stroke()

        // Handle grip wrapping
        ctx.beginPath()
        ctx.moveTo(w * 0.65, h * 0.36)
        ctx.lineTo(w * 0.90, h * 0.12)
        ctx.lineWidth = Style.space(6)
        ctx.strokeStyle = "#B45309"
        ctx.stroke()

        ctx.restore()
      }
    }

    // Mallet striking swing animation
    SequentialAnimation {
      id: malletAnim
      // Swing down fast to strike
      NumberAnimation { target: mallet; property: "rotation"; to: -22; duration: 55; easing.type: Easing.InQuad }
      // Recoil bounce back up
      NumberAnimation { target: mallet; property: "rotation"; to: 24; duration: 120; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
      // Rest back to default position
      NumberAnimation { target: mallet; property: "rotation"; to: 18; duration: 150; easing.type: Easing.OutQuad }
    }
  }

  // Floating Karma Texts (e.g., "+1 功德", "Bug -1")
  Repeater {
    model: karmaModel
    delegate: Text {
      id: karmaText
      x: model.startX
      y: model.startY
      text: model.text
      color: root.primaryColor
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.bold: true
      opacity: 1

      // Auto-float and self-destruct animation
      ParallelAnimation {
        running: true
        NumberAnimation {
          target: karmaText
          property: "y"
          to: model.startY - Style.space(65)
          duration: 750
          easing.type: Easing.OutCubic
        }
        NumberAnimation {
          target: karmaText
          property: "opacity"
          from: 1.0
          to: 0.0
          duration: 750
          easing.type: Easing.InQuad
        }
        NumberAnimation {
          target: karmaText
          property: "scale"
          from: 0.8
          to: 1.25
          duration: 750
          easing.type: Easing.OutCubic
        }
        onFinished: {
          for (var i = 0; i < karmaModel.count; i++) {
            if (karmaModel.get(i).text === model.text && karmaModel.get(i).startX === model.startX) {
              karmaModel.remove(i)
              break
            }
          }
        }
      }
    }
  }
}
