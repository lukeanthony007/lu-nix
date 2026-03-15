import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property string currentPage: "setup"
    property real progress: 0.0
    property string statusText: "Starting..."
    property bool showCloudPicker: false
    property int selectedWallpaperIndex: -1
    property string selectedWallpaperName: ""
    property var wallpaperPaths: []
    property string home: Quickshell.env("HOME") || "/home/luke"

    property var tasks: [
        { name: "Wallpapers", description: "Downloading latest collection", state: "pending" },
        { name: "Editor", description: "Installing NvChad configuration", state: "pending" },
        { name: "Cloud Storage", description: "Configuring cloud sync", state: "pending" }
    ]

    function setTaskState(index, newState, desc) {
        var t = tasks.slice();
        t[index] = { name: t[index].name, description: desc, state: newState };
        tasks = t;
    }

    // -- Fullscreen overlay --
    PanelWindow {
        id: bootstrapWindow
        visible: true
        color: "#0a0a0a"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "bootstrap"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Loader {
            anchors.fill: parent
            active: root.currentPage === "setup"
            sourceComponent: SetupPage {}
        }

        Loader {
            anchors.fill: parent
            active: root.currentPage === "wallpaper"
            sourceComponent: WallpaperPage {}
        }
    }

    // -- Poll status file by reading it fresh each cycle --
    Process {
        id: statusReader
        running: false
        command: ["cat", root.home + "/.local/state/bootstrap-status.json"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.parseStatus(data)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: statusReader.running = true
    }

    function parseStatus(txt) {
        if (!txt || txt.length === 0) return;
        try {
            var s = JSON.parse(txt);

            if (s.task0state) setTaskState(0, s.task0state, s.task0desc || "");
            if (s.task1state) setTaskState(1, s.task1state, s.task1desc || "");

            if (s.task2state === "cloud") {
                setTaskState(2, "running", s.task2desc || "Choose a provider");
                showCloudPicker = true;
                statusText = "Choose a cloud provider or skip";
            } else if (s.task2state) {
                setTaskState(2, s.task2state, s.task2desc || "");
            }

            if (s.progress !== undefined) progress = s.progress;
            if (s.status && s.status !== "done" && s.status !== "cloud") statusText = s.status;

            if (s.wallpapers && s.wallpapers.length > 0) {
                wallpaperPaths = s.wallpapers;
            }

            // All done — transition to wallpaper picker
            if (s.status === "done") {
                progress = 1.0;
                statusText = wallpaperPaths.length > 0 ? "Choose a wallpaper" : "Get started";
                currentPage = "wallpaper";
            }
        } catch (e) {
            // JSON not ready yet
        }
    }

    // -- Cloud provider selection --
    function selectProvider(provider) {
        showCloudPicker = false;
        setTaskState(2, "done", "Provider: " + provider + " — run cloud-sync-setup");
        progress = 1.0;

        saveProc.command = ["sh", "-c",
            "mkdir -p " + root.home + "/.local/state && echo '{\"provider\":\"" + provider + "\"}' > " + root.home + "/.local/state/bootstrap-state.json"
        ];
        saveProc.running = true;

        statusText = wallpaperPaths.length > 0 ? "Choose a wallpaper" : "Get started";
        currentPage = "wallpaper";
    }

    function skipCloud() {
        showCloudPicker = false;
        setTaskState(2, "done", "Skipped — configure later");
        progress = 1.0;

        statusText = wallpaperPaths.length > 0 ? "Choose a wallpaper" : "Get started";
        currentPage = "wallpaper";
    }

    // -- Wallpaper selection and finish --
    function getStarted() {
        if (selectedWallpaperIndex >= 0 && selectedWallpaperIndex < wallpaperPaths.length) {
            var wp = wallpaperPaths[selectedWallpaperIndex];
            writeWpProc.command = ["sh", "-c",
                "mkdir -p " + root.home + "/.local/state/DankMaterialShell && " +
                "echo '{\"wallpaperPath\":\"" + wp + "\",\"wallpaperPathDark\":\"" + wp + "\",\"wallpaperPathLight\":\"" + wp + "\"}' > " + root.home + "/.local/state/DankMaterialShell/session.json"
            ];
            writeWpProc.running = true;
        }
        finishBootstrap();
    }

    function finishBootstrap() {
        markerProc.running = true;
    }

    Process { id: saveProc; running: false }
    Process { id: writeWpProc; running: false }
    Process {
        id: markerProc
        running: false
        command: ["sh", "-c", "mkdir -p " + root.home + "/.local/state && echo done > " + root.home + "/.local/state/bootstrap-done"]
        onExited: Qt.quit()
    }
}
