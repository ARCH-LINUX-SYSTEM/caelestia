#!/usr/bin/env python3
"""Audit end4-pC settings against Caelestia's typed configuration.

The parser is intentionally small and source-oriented:

* end4-pC leaves are read from ``modules/common/Config.qml``.
* Caelestia leaves are derived from ``CONFIG_*_PROPERTY`` and
  ``CONFIG_SUBOBJECT`` declarations rooted at ``GlobalConfig``.
* Every end4 leaf is mapped explicitly or by a narrow, documented rule.

Run without arguments to print a summary. Use ``--emit-tsv`` to generate the
machine-readable per-setting map used by the port documentation.
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import re
import sys
from collections import Counter
from functools import lru_cache


DEFAULT_END4 = pathlib.Path.home() / ".config/quickshell/end4-pC"


@dataclasses.dataclass(frozen=True)
class Mapping:
    classification: str
    targets: tuple[str, ...]
    adapter: str = "identity"
    note: str = ""


def parse_end4_leaves(config_file: pathlib.Path) -> list[str]:
    """Extract leaf paths from end4's indentation-stable JsonAdapter."""

    lines = config_file.read_text(encoding="utf-8").splitlines()
    adapter_line = next(
        (
            index
            for index, line in enumerate(lines)
            if re.search(r"\bJsonAdapter\s*\{", line)
            and any("configOptionsJsonAdapter" in item for item in lines[index : index + 5])
        ),
        None,
    )
    if adapter_line is None:
        raise ValueError(f"cannot find configOptionsJsonAdapter in {config_file}")

    object_stack: list[tuple[int, str]] = []
    leaves: list[str] = []
    property_re = re.compile(
        r"^(?P<indent>\s*)property\s+(?P<type>JsonObject|(?:list<[^>]+>)|\w+)"
        r"\s+(?P<name>\w+)\s*:"
    )

    for line in lines[adapter_line + 1 :]:
        match = property_re.match(line)
        if not match:
            continue

        indent = len(match.group("indent").expandtabs(4))
        while object_stack and indent <= object_stack[-1][0]:
            object_stack.pop()

        name = match.group("name")
        if match.group("type") == "JsonObject":
            object_stack.append((indent, name))
        else:
            leaves.append(".".join([entry[1] for entry in object_stack] + [name]))

    if len(leaves) != len(set(leaves)):
        duplicates = [path for path, count in Counter(leaves).items() if count > 1]
        raise ValueError(f"duplicate end4 leaves: {duplicates}")
    return leaves


def parse_caelestia_schema(config_dir: pathlib.Path) -> set[str]:
    """Derive persisted leaves by walking ConfigObject classes."""

    classes: dict[str, tuple[str | None, tuple[str, ...], tuple[tuple[str, str], ...]]] = {}
    class_re = re.compile(r"^class\s+(\w+)\s*(?::\s*public\s+(\w+))?\s*\{")
    property_re = re.compile(
        r"CONFIG_(?:(?:GLOBAL|PER_MONITOR)_)?PROPERTY\s*\(\s*[^,]+,\s*(\w+)",
        re.DOTALL,
    )
    subobject_re = re.compile(
        r"CONFIG_SUBOBJECT\s*\(\s*(\w+)\s*,\s*(\w+)", re.DOTALL
    )

    for header in sorted(config_dir.glob("*.hpp")):
        lines = header.read_text(encoding="utf-8").splitlines()
        index = 0
        while index < len(lines):
            class_match = class_re.match(lines[index])
            if not class_match:
                index += 1
                continue

            name, base = class_match.groups()
            end = index + 1
            while end < len(lines) and not re.match(r"^};\s*$", lines[end]):
                end += 1
            if end >= len(lines):
                raise ValueError(f"unterminated class {name} in {header}")

            body = "\n".join(lines[index + 1 : end])
            properties = tuple(match.group(1) for match in property_re.finditer(body))
            subobjects = tuple(
                (match.group(2), match.group(1)) for match in subobject_re.finditer(body)
            )
            classes[name] = (base, properties, subobjects)
            index = end + 1

    @lru_cache(maxsize=None)
    def members(class_name: str) -> tuple[tuple[str, ...], tuple[tuple[str, str], ...]]:
        if class_name not in classes:
            return (), ()
        base, properties, subobjects = classes[class_name]
        base_properties, base_subobjects = members(base) if base else ((), ())
        return base_properties + properties, base_subobjects + subobjects

    leaves: set[str] = set()

    def walk(class_name: str, prefix: str = "", ancestors: tuple[str, ...] = ()) -> None:
        if class_name in ancestors:
            raise ValueError(f"ConfigObject cycle: {' -> '.join(ancestors + (class_name,))}")
        properties, subobjects = members(class_name)
        leaves.update(prefix + property_name for property_name in properties)
        for object_name, object_type in subobjects:
            walk(object_type, prefix + object_name + ".", ancestors + (class_name,))

    walk("GlobalConfig")
    return leaves


def replace_enable(path: str) -> str:
    if path.endswith(".enable"):
        return path[: -len(".enable")] + ".enabled"
    return path


def classify(path: str) -> str:
    group = path.split(".", 1)[0]
    if path == "panelFamily":
        return "NOT_APPLICABLE"

    schema_only_groups = {
        "policies",
        "ai",
        "conflictKiller",
        "crosshair",
        "dock",
        "light",
        "osk",
        "overlay",
        "musicRecognition",
        "sounds",
        "updates",
        "hacks",
        "workSafety",
        "windows",
    }
    if group in schema_only_groups:
        return "SCHEMA_ONLY"

    if group == "background" and (
        path == "background.widgetsLocked"
        or (
            path.startswith("background.widgets.")
            and not path.startswith("background.widgets.clock.")
            and not path.startswith("background.widgets.visualizer.")
        )
        or path.startswith("background.parallax.")
    ):
        return "SCHEMA_ONLY"

    if group == "language" and path != "language.ui":
        return "SCHEMA_ONLY"

    if group == "search" and not (
        path in {
            "search.sloppy",
            "search.prefix.showDefaultActionsWithoutPrefix",
            "search.prefix.action",
            "search.prefix.app",
        }
    ):
        return "SCHEMA_ONLY"

    if group == "sidebar" and (
        path.startswith("sidebar.translator.")
        or path.startswith("sidebar.ai.")
        or path.startswith("sidebar.booru.")
        or path.startswith("sidebar.quickSliders.")
        or path in {"sidebar.banner", "sidebar.bannerImage"}
    ):
        return "SCHEMA_ONLY"

    existing_groups = {
        "audio",
        "battery",
        "calendar",
        "launcher",
        "media",
        "networking",
        "notifications",
        "osd",
        "resources",
        "tray",
        "custom",
        "screenRecord",
        "screenSnip",
    }
    if group in existing_groups:
        return "EXISTING"

    direct_groups = {"profile", "apps", "time", "wallpaperSelector"}
    if group in direct_groups:
        return "DIRECT"

    return "REWRITE"


def map_setting(path: str) -> Mapping:
    classification = classify(path)

    if path == "panelFamily":
        return Mapping(
            classification,
            (),
            "fixed-caelestia-platform",
            "Caelestia remains the only panel family",
        )

    if path.startswith("appearance.fonts."):
        name = path.rsplit(".", 1)[1]
        targets = {
            "main": ("appearance.font.body.family", "appearance.font.label.family"),
            "numbers": ("appearance.font.numbers",),
            "title": ("appearance.font.title.family", "appearance.font.headline.family"),
            "iconNerd": ("appearance.font.workspaces",),
            "monospace": ("appearance.font.mono.family",),
            "reading": ("appearance.font.reading",),
            "expressive": ("appearance.font.expressive",),
        }[name]
        return Mapping(classification, targets, "font-role-merge")

    appearance_aliases = {
        "appearance.transparency.enable": ("appearance.transparency.enabled", "rename"),
        "appearance.transparency.backgroundTransparency": (
            "appearance.transparency.base",
            "opacity=1-transparency",
        ),
        "appearance.transparency.contentTransparency": (
            "appearance.transparency.layers",
            "opacity=1-transparency",
        ),
    }
    if path in appearance_aliases:
        target, adapter = appearance_aliases[path]
        return Mapping(classification, (target,), adapter)

    audio_aliases = {
        "audio.protection.enable": ("services.audioProtection.enabled", "rename"),
        "audio.protection.maxAllowedIncrease": (
            "services.audioProtection.maxIncrease",
            "percent-to-ratio",
        ),
        "audio.protection.maxAllowed": ("services.maxVolume", "percent-to-ratio"),
    }
    if path in audio_aliases:
        target, adapter = audio_aliases[path]
        return Mapping(classification, (target,), adapter)

    if path.startswith("hyprland."):
        return Mapping(classification, (replace_enable(path),), "enable-to-enabled")

    if path.startswith("apps."):
        name = path.split(".", 1)[1]
        target_name = "audio" if name == "volumeMixer" else name
        return Mapping(classification, (f"general.apps.{target_name}",), "command-to-argv")

    if path.startswith("background.widgets.clock."):
        suffix = path[len("background.widgets.clock.") :]
        target = replace_enable("background.desktopClock." + suffix)
        return Mapping(classification, (target,), "clock-adapter")

    if path.startswith("background.widgets.visualizer."):
        suffix = path[len("background.widgets.visualizer.") :]
        target = replace_enable("background.visualiser." + suffix)
        return Mapping(classification, (target,), "visualiser-adapter")

    if path.startswith("background.widgets."):
        return Mapping(classification, (replace_enable(path),), "enable-to-enabled")

    battery_aliases = {
        "battery.low": ("general.battery.warnLevels", "warning-list-low"),
        "battery.critical": ("general.battery.warnLevels", "warning-list-critical"),
        "battery.full": ("general.battery.fullLevel", "rename"),
        "battery.automaticSuspend": ("general.battery.autoHibernate", "rename"),
        "battery.suspend": ("general.battery.criticalLevel", "rename"),
    }
    if path in battery_aliases:
        target, adapter = battery_aliases[path]
        return Mapping(classification, (target,), adapter)

    service_aliases = {
        "calendar.locale": "services.calendarLocale",
        "media.filterDuplicatePlayers": "services.filterDuplicatePlayers",
        "networking.userAgent": "services.networkUserAgent",
        "notifications.timeout": "notifs.defaultExpireTimeout",
        "resources.updateInterval": "dashboard.resourceUpdateInterval",
        "resources.historyLength": "dashboard.resourceHistoryLength",
    }
    if path in service_aliases:
        return Mapping(classification, (service_aliases[path],), "merge-existing-service")

    if path == "osd.timeout":
        return Mapping(classification, ("osd.hideDelay",), "rename")

    if path == "launcher.pinnedApps":
        return Mapping(classification, ("launcher.favouriteApps",), "rename")

    if path == "tray.monochromeIcons":
        return Mapping(classification, ("bar.tray.recolour",), "rename")
    if path.startswith("tray."):
        return Mapping(classification, ("bar." + path,), "merge-bar-tray")

    if path == "search.prefix.action":
        return Mapping(classification, ("launcher.actionPrefix",), "merge-launcher-prefix")
    if path == "search.prefix.app":
        return Mapping(classification, ("launcher.appPrefix",), "merge-launcher-prefix")

    sidebar_aliases = {
        "sidebar.quickToggles.style": ("utilities.quickToggleStyle", "merge-utilities"),
        "sidebar.quickToggles.android.columns": (
            "utilities.quickToggleColumns",
            "merge-utilities",
        ),
        "sidebar.quickToggles.android.toggles": (
            "utilities.quickToggles",
            "type-size-to-id-enabled",
        ),
    }
    if path in sidebar_aliases:
        target, adapter = sidebar_aliases[path]
        return Mapping(classification, (target,), adapter)

    custom_aliases = {
        "custom.distroIcon": "general.logo",
        "custom.colorizeIcon": "lock.recolourLogo",
        "screenRecord.savePath": "paths.screenRecordDir",
        "screenSnip.savePath": "paths.screenSnipDir",
    }
    if path in custom_aliases:
        return Mapping(classification, (custom_aliases[path],), "merge-existing")

    wallpaper_aliases = {
        "wallpaperSelector.useSystemFileDialog": "nexus.useSystemFileDialog",
        "wallpaperSelector.showBlurBackground": "nexus.showWallpaperBlurBackground",
        "wallpaperSelector.showHomePath": "nexus.showWallpaperHomePath",
        "wallpaperSelector.userPath": "nexus.wallpaperUserPath",
        "wallpaperSelector.showSearchbar": "nexus.showWallpaperSearch",
        "wallpaperSelector.columns": "nexus.wallpapersPerRow",
        "wallpaperSelector.closeAfterSelection": "nexus.closeAfterWallpaperSelection",
        "wallpaperSelector.changeInterval": "nexus.wallpaperChangeInterval",
    }
    if path in wallpaper_aliases:
        adapter = (
            "milliseconds-to-minutes"
            if path == "wallpaperSelector.changeInterval"
            else "merge-nexus"
        )
        return Mapping(classification, (wallpaper_aliases[path],), adapter)

    if path.endswith(".enable") and (
        path.startswith("dock.")
        or path.startswith("light.antiFlashbang.")
        or path.startswith("overview.")
        or path.startswith("interactions.deadPixelWorkaround.")
    ):
        return Mapping(classification, (replace_enable(path),), "enable-to-enabled")

    return Mapping(classification, (path,))


def load_reference_sources(repo: pathlib.Path) -> list[tuple[pathlib.Path, str]]:
    source_suffixes = {".qml", ".js", ".cpp", ".hpp"}
    ignored_parts = {".git", "build", "docs", "tools", "plugin"}
    sources = []

    for source in repo.rglob("*"):
        if not source.is_file() or source.suffix not in source_suffixes:
            continue
        relative = source.relative_to(repo)
        if any(part in ignored_parts for part in relative.parts):
            continue
        sources.append(
            (relative, source.read_text(encoding="utf-8", errors="ignore"))
        )
    return sources


def reference_counts(
    sources: list[tuple[pathlib.Path, str]], targets: tuple[str, ...]
) -> tuple[int, int]:
    if not targets:
        return 0, 0

    runtime_count = 0
    nexus_count = 0

    for relative, text in sources:
        count = 0
        for target in targets:
            count += text.count(f"GlobalConfig.{target}")
            count += text.count(f"Config.{target}")
        runtime_count += count
        if relative.parts[:2] == ("modules", "nexus"):
            nexus_count += count

    return runtime_count, nexus_count


def build_rows(
    repo: pathlib.Path, end4: pathlib.Path
) -> tuple[list[tuple[str, Mapping, bool, int, int]], set[str]]:
    end4_leaves = parse_end4_leaves(end4 / "modules/common/Config.qml")
    schema_leaves = parse_caelestia_schema(repo / "plugin/src/Caelestia/Config")
    sources = load_reference_sources(repo)
    rows = []
    missing_targets: set[str] = set()

    for path in end4_leaves:
        mapping = map_setting(path)
        schema_ok = bool(mapping.targets) and all(
            target in schema_leaves for target in mapping.targets
        )
        if mapping.classification == "NOT_APPLICABLE":
            schema_ok = True
        if not schema_ok:
            missing_targets.update(
                target for target in mapping.targets if target not in schema_leaves
            )
        runtime_count, nexus_count = reference_counts(sources, mapping.targets)
        rows.append((path, mapping, schema_ok, runtime_count, nexus_count))

    return rows, missing_targets


def emit_tsv(rows: list[tuple[str, Mapping, bool, int, int]]) -> None:
    print(
        "\t".join(
            [
                "end4_path",
                "classification",
                "caelestia_path",
                "adapter",
                "schema_verified",
                "runtime_refs",
                "nexus_refs",
                "note",
            ]
        )
    )
    for path, mapping, schema_ok, runtime_count, nexus_count in rows:
        values = [
            path,
            mapping.classification,
            ";".join(mapping.targets) if mapping.targets else "-",
            mapping.adapter,
            "yes" if schema_ok else "no",
            str(runtime_count),
            str(nexus_count),
            mapping.note,
        ]
        print("\t".join(value.replace("\t", " ").replace("\n", " ") for value in values))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[1]
    )
    parser.add_argument("--end4", type=pathlib.Path, default=DEFAULT_END4)
    parser.add_argument("--emit-tsv", action="store_true")
    parser.add_argument(
        "--strict-runtime",
        action="store_true",
        help="also fail rewritten/direct/existing rows with no textual runtime reference",
    )
    args = parser.parse_args()

    rows, missing_targets = build_rows(args.repo.resolve(), args.end4.resolve())
    if args.emit_tsv:
        emit_tsv(rows)
    else:
        classifications = Counter(mapping.classification for _, mapping, _, _, _ in rows)
        no_runtime = [
            path
            for path, mapping, _, runtime_count, _ in rows
            if mapping.classification in {"EXISTING", "DIRECT", "REWRITE"}
            and runtime_count == 0
        ]
        print(f"end4 leaves: {len(rows)}")
        print(
            "classifications: "
            + ", ".join(
                f"{name}={classifications[name]}" for name in sorted(classifications)
            )
        )
        print(f"missing schema targets: {len(missing_targets)}")
        print(f"applicable leaves without textual runtime refs: {len(no_runtime)}")
        if no_runtime:
            print("\n".join(f"  {path}" for path in no_runtime))

    if len(rows) != 386:
        print(f"error: expected 386 end4 leaves, found {len(rows)}", file=sys.stderr)
        return 1
    if missing_targets:
        print(
            "error: missing Caelestia schema targets: "
            + ", ".join(sorted(missing_targets)),
            file=sys.stderr,
        )
        return 1
    if args.strict_runtime:
        missing_runtime = [
            path
            for path, mapping, _, runtime_count, _ in rows
            if mapping.classification in {"EXISTING", "DIRECT", "REWRITE"}
            and runtime_count == 0
        ]
        if missing_runtime:
            print(
                f"error: {len(missing_runtime)} applicable leaves have no textual runtime reference",
                file=sys.stderr,
            )
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
