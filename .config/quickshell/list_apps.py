import configparser, glob, os

dirs = [
    d
    for d in [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications",
    ]
    if os.path.isdir(d)
]

icon_roots = [
    r
    for r in [
        "/usr/share",
        os.path.expanduser("~/.local/share"),
    ]
    if os.path.isdir(r)
]

_icon_cache = {}


def resolve_icon(icon):
    if not icon:
        return ""
    if icon.startswith("/"):
        return icon if os.path.isfile(icon) else ""
    if icon in _icon_cache:
        return _icon_cache[icon]

    candidates = []
    for root in icon_roots:
        for ext in ("svg", "png"):
            candidates += glob.glob(f"{root}/icons/*/*/apps/{icon}.{ext}")
            candidates += glob.glob(f"{root}/icons/*/*/apps/*/{icon}.{ext}")
            candidates += glob.glob(f"{root}/icons/*/apps/*/{icon}.{ext}")
        candidates += glob.glob(f"{root}/pixmaps/{icon}.*")

    def score(path):
        s = 1000 if path.endswith(".svg") else 0
        for sz in ("256", "128", "96", "64", "48"):
            if f"/{sz}" in path or f"{sz}x{sz}" in path:
                s += int(sz)
        return s

    candidates.sort(key=score, reverse=True)
    result = candidates[0] if candidates else ""
    _icon_cache[icon] = result
    return result


seen_ids = set()
seen_names = set()
entries = []
for d in dirs:
    for path in glob.glob(os.path.join(d, "*.desktop")):
        desktop_id = os.path.basename(path).lower()
        if desktop_id in seen_ids:
            continue
        seen_ids.add(desktop_id)
        cp = configparser.ConfigParser(interpolation=None, strict=False)
        try:
            cp.read(path, encoding="utf-8")
        except Exception:
            continue
        if "Desktop Entry" not in cp:
            continue
        e = cp["Desktop Entry"]
        if e.get("Type", "Application") != "Application":
            continue
        if e.get("NoDisplay", "false").lower() == "true":
            continue
        if e.get("Hidden", "false").lower() == "true":
            continue
        name = e.get("Name", "")
        exec_ = e.get("Exec", "")
        icon = e.get("Icon", "")
        if not name or not exec_:
            continue
        key = name.lower()
        if key in seen_names:
            continue
        seen_names.add(key)
        for code in ("%f", "%F", "%u", "%U", "%i", "%c", "%k"):
            exec_ = exec_.replace(code, "")
        exec_ = exec_.replace("%%", "%").strip()
        entries.append((name, exec_, resolve_icon(icon)))

entries.sort(key=lambda x: x[0].lower())
for name, exec_, icon in entries:
    print(f"{name}|||{exec_}|||{icon}")
