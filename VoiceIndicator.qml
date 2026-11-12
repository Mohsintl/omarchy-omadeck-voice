import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Reads the state file the OmaDeck daemon writes on every transition, so the
// bar reflects what the assistant is doing without polling a process.
//
// The widget is a companion to OmaDeck (github.com/Mohsintl/omadeck). It never
// talks to a model itself: it reads one local JSON file and runs the local
// `omarchy-voice` command. With OmaDeck absent the file is missing, and the
// widget says so instead of pretending to be a dead microphone.
BarWidget {
  id: root
  moduleName: "io.github.mohsintl.omadeck-voice"

  readonly property string setupUrl: "https://github.com/Mohsintl/omadeck"

  property string status: "unconfigured"
  property string label: ""

  readonly property bool unconfigured: status === "unconfigured"

  readonly property var icons: ({
    "stopped":      "󰍭",
    "idle":         "󰍬",
    "listening":    "󰍬",
    "thinking":     "󱚟",
    "acting":       "󱐋",
    "confirm":      "󰀦",
    "error":        "󰍭",
    // No state file yet: OmaDeck is not installed, or its service is not running.
    "unconfigured": "󰒓"
  })

  FileView {
    id: state
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/omarchy-voice/state.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const parsed = JSON.parse(state.text())
        root.status = parsed.status || "idle"
        root.label = parsed.text || ""
      } catch (e) {
        root.status = "error"
        root.label = ""
      }
    }
    onLoadFailed: {
      root.status = "unconfigured"
      root.label = ""
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icons[root.status] || root.icons["idle"]
    active: root.status === "listening" || root.status === "thinking"
             || root.status === "acting" || root.status === "confirm"
    tooltipText: root.unconfigured
                 ? "OmaDeck is not installed or not running — click for setup"
                 : root.label !== ""
                   ? root.status + " — " + root.label
                   : "Voice control: " + root.status
    onPressed: function(b) {
      if (root.unconfigured) {
        Qt.openUrlExternally(root.setupUrl)
        return
      }
      if (!root.bar)
        return
      if (root.status === "confirm")
        root.bar.run("omarchy-voice listen confirm")
      else
        root.bar.run("omarchy-voice listen toggle")
    }
  }
}
