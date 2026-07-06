#!/bin/bash

echo "╔══════════════════════════════╗"
echo "║       System Update          ║"
echo "╚══════════════════════════════╝"
echo ""

echo "▶ brew"
/home/linuxbrew/.linuxbrew/bin/brew upgrade 2>&1
echo ""

echo "▶ flatpak"
flatpak -y update 2>&1
echo ""

echo "▶ dnf"
nm-online -q --timeout=30 && sudo dnf upgrade --refresh -y 2>&1 || echo "⚠ Netzwerk nicht erreichbar, dnf übersprungen"
echo ""

echo "✓ Fertig. Schließt in 2 Sekunden..."
sleep 2
