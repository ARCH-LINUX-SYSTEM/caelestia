pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string _extractThumbsScript: `
import os
import subprocess
import sys

cache = os.path.expanduser("~/.cache/caelestia/videothumbs")
os.makedirs(cache, exist_ok=True)


def djb2(s):
    h = 5381
    for ch in s:
        h = (h * 33 + ord(ch)) & 0xFFFFFFFF
    return str(h)


for path in sys.argv[1:]:
    out = os.path.join(cache, djb2(path) + ".jpg")
    if not os.path.exists(out):
        subprocess.run(
            [
                "ffmpeg", "-y", "-i", path,
                "-vframes", "1", "-ss", "00:00:01",
                "-vf", "scale=256:256:force_original_aspect_ratio=decrease,pad=256:256:(ow-iw)/2:(oh-ih)/2",
                out,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    if os.path.exists(out):
        print(path)
`
    property bool _refreshing: false
    property string actualCurrent
    readonly property var allWallpapers: staticWallpapers.entries.concat(animatedWallpapers.entries)
    property string cacheBuster: ""
    readonly property string current: showPreview ? previewPath : actualCurrent
    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")
    property var itemBusters: ({})
    property bool pendingPreviewClear
    property bool previewColourLock
    property string previewPath
    property bool restoreWallpaperMode: false
    property bool showPreview: false
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property list<string> validVideoExtensions: ["mp4", "webm", "mkv"]
    readonly property list<string> validWallpaperExtensions: Images.validImageExtensions.concat(validVideoExtensions)
    property string wallpaperMode: "static"

    function djb2_hash(s) {
        let h = 5381;
        for (let i = 0; i < s.length; i++) {
            h = (h * 33 + s.charCodeAt(i)) >>> 0;
        }
        return h.toString(10);
    }
    function fileExtension(path: string): string {
        const clean = localPath(path).toLowerCase();
        const index = clean.lastIndexOf(".");
        return index >= 0 ? clean.slice(index + 1) : "";
    }
    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }
    function getPreviewSource(path, buster) {
        if (isVideo(path))
            return getWallpaperThumb(path, buster);

        const source = localFileUrl(path);
        if (!source || !buster)
            return source;

        const separator = source.includes("?") ? "&" : "?";
        return `${source}${separator}v=${encodeURIComponent(buster)}`;
    }
    function getWallpaperThumb(path, buster) {
        const clean = localPath(path);
        let b = buster !== undefined ? buster : cacheBuster;
        return "file://" + Paths.cache + "/videothumbs/" + djb2_hash(clean) + ".jpg" + (b ? "?v=" + b : "");
    }
    function isGif(path: string): bool {
        return fileExtension(path) === "gif";
    }
    function isVideo(path: string): bool {
        return validVideoExtensions.includes(fileExtension(path));
    }
    function localFileUrl(path: string): string {
        const clean = localPath(path).trim();
        if (!clean)
            return "";
        if (clean[0] === "/")
            return "file://" + clean.split("/").map(segment => encodeURIComponent(segment)).join("/");
        if (clean.includes("://"))
            return clean;
        return Qt.resolvedUrl(clean);
    }
    function localPath(path: string): string {
        const value = String(path || "");
        if (value.indexOf("file://") !== 0)
            return value;

        const encodedPath = value.substring(7);
        try {
            return decodeURIComponent(encodedPath);
        } catch (error) {
            return encodedPath;
        }
    }
    function preview(path: string): void {
        const clean = localPath(path);
        previewPath = clean;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    // Removed invalid updateWallpapers function

    function refreshAnimatedThumbs() {
        if (_refreshing)
            return;
        itemBusters = {};
        _refreshing = true;
        _extractThumbsProc.command = ["python3", "-c", root._extractThumbsScript].concat(animatedWallpapers.entries.map(w => w.path));
        _extractThumbsProc.running = true;
    }
    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }
    function setWallpaper(path: string): void {
        const clean = localPath(path);
        if (isVideo(clean)) {
            previewColourLock = false;
            stopPreview();
        }
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", clean, ...smartArg]);
    }
    function setWallpaperMode(mode) {
        wallpaperMode = mode;
    }
    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })
    key: "relativePath"
    list: wallpaperMode === "animated" ? animatedWallpapers.entries : staticWallpapers.entries
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    Timer {
        interval: Math.max(60000, GlobalConfig.nexus.wallpaperChangeInterval * 60000)
        repeat: true
        running: GlobalConfig.nexus.wallpaperChangeInterval > 0 && root.allWallpapers.length > 1
        triggeredOnStart: false
        onTriggered: root.setRandom()
    }

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }
        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
        function set(path: string): void {
            root.setWallpaper(path);
        }

        target: "wallpaper"
    }
    FileView {
        path: root.currentNamePath
        printErrors: false
        watchChanges: true

        onFileChanged: reload()
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
            if (root.isVideo(root.actualCurrent)) {
                root.wallpaperMode = "animated";
                root.cacheBuster = Date.now().toString();
            } else {
                root.wallpaperMode = "static";
            }
        }
    }
    FileSystemModel {
        id: staticWallpapers

        filter: FileSystemModel.Files
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.tif", "*.tiff", "*.svg", "*.gif"]
        path: Paths.wallsdir
        recursive: true
        watchChanges: true
    }
    FileSystemModel {
        id: animatedWallpapers

        filter: FileSystemModel.Files
        nameFilters: ["*.mp4", "*.webm", "*.mkv"]
        path: Paths.wallsdir + "/Animated"
        recursive: true
        watchChanges: true
    }
    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]

        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
    Process {
        id: _extractThumbsProc

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                let newBusters = Object.assign({}, root.itemBusters);
                const now = Date.now().toString();
                for (let i = 0; i < lines.length; i++) {
                    const line = root.localPath(lines[i].trim());
                    if (line) {
                        newBusters[line] = now;
                        newBusters["file://" + line] = now;
                    }
                }
                root.itemBusters = newBusters;
                root._refreshing = false;
                root.cacheBuster = now;
                root.restoreWallpaperMode = true;
            }
        }
    }
}
