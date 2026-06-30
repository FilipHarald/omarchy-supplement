import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "local.current-screen-workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceMonitorName(workspace) {
    if (!workspace) return ""
    if (workspace.monitor && workspace.monitor.name) return String(workspace.monitor.name)
    if (workspace.monitor) return String(workspace.monitor)
    return ""
  }

  function barScreenName() {
    var window = root.QsWindow ? root.QsWindow.window : null
    if (window && window.screen && window.screen.name) return String(window.screen.name)
    if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) return String(Hyprland.focusedMonitor.name)
    return ""
  }

  function workspaceIds() {
    var screenName = root.barScreenName()
    var ids = []
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      var id = workspace.id
      if (id <= 0 || id > 10) continue
      if (screenName && root.workspaceMonitorName(workspace) !== screenName) continue
      if (ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: workspaceButton

        required property int modelData


        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property int barSize: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

        implicitWidth: root.vertical ? barSize : Style.space(20)
        implicitHeight: barSize
        opacity: occupied || focused ? 1 : 0.5

        Text {
          anchors.centerIn: parent
          text: workspaceButton.modelData === 10 ? "0" : String(workspaceButton.modelData)
          color: workspaceButton.focused ? (root.bar ? root.bar.urgent : Color.urgent) : (root.bar ? root.bar.barForeground : Color.foreground)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: workspaceButton.focused ? Style.font.subtitle : Style.font.body
          font.weight: workspaceButton.focused ? Font.DemiBold : Font.Normal
          renderType: Text.NativeRendering
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(workspaceButton.modelData)
        }
      }
    }
  }
}
