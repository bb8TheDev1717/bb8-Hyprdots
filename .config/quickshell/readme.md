 Bar.qml - top bar (workspaces, clock, netzwerk, öffnet die popups)

 Calender.qml - kalender, wird als eine der popup-pages in der Bar eingebunden

 colors.js - farben, werden von allen qml-dateien mit `import "colors.js" as C` genutzt

 ControlPopup.qml - popup-page mit power-menu (sperren/neustart/aus) + wallpaper-hero

 Notification.qml - eigener notification-daemon (NotificationServer + popup-cards)

 Overlay.qml - app-launcher (Mod+Space), läuft als eigenes Fullscreen-PanelWindow

 PlayerCtl.qml - media-controls popup-page (playerctl + cava-visualizer)

 VolumeOSD.qml - volume-osd, pollt wpctl/pactl und blendet sich kurz ein

 shell.qml - Einstiegspunkt (ShellRoot), lädt Bar/Overlay/Notification/VolumeOSD - so eine Datei ist laut Quickshell-Docs nötig

 pinnedApps.js - liste der im Launcher immer oben angezeigten Apps

 list_apps.py - liest .desktop-Dateien für den Launcher aus (Name/Exec/Icon)

 cava/ - config für den audio-visualizer in PlayerCtl.qml

 shaders/ - blob-shader (vert/frag + kompilierte .qsb) für den Bar-Hintergrund

 CalPopup.qml, ControlCenter.qml - leer, werden nirgends importiert (alte Reste)
