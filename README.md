# Critter Covenant

Ein eigenständiges, luck-basiertes Tower-Defense-Spiel für Godot 4.7. Der aktuelle spielbare Build enthält zwölf illustrierte Hüter mit Seltenheiten und Elementfähigkeiten, vier Gegnertypen, drei Maps, Bossphasen, gewichtete Beschwörung, 3er-Merges und fünf Covenants.

Ein vollständiges Match umfasst 30 Wellen. Elite-Wellen erscheinen alle vier Wellen, Bosse alle fünf Wellen. Der HUD unterstützt Pause, 1×–3× Tempo und eine einmalige Covenant-Blüte als Notfallfähigkeit. Ergebnisbelohnungen, Siege und Achievements werden lokal versioniert gespeichert.

Das Hauptmenü enthält eine vollständige Hüter-Sammlung mit Detailkarten, einen Covenant-Codex sowie Profil-, Quest- und Achievement-Fortschritt. Neben der Standardbeschwörung gibt es eine teurere Focus-Beschwörung nach Element. Nach sieben Ziehungen ohne Rare oder Legendary erhöht der Pity-Schutz deren Gewicht deutlich.

## Lokal starten

```powershell
godot --editor project.godot
```

Oder direkt: `godot --path .`

## Web-Build und Vercel

Godot Export Templates 4.7 installieren, dann:

```powershell
godot --headless --path . --export-release Web public/index.html
npx vercel
```

In Vercel sind kein Framework und `public` als Output Directory vorgesehen. `vercel.json` liefert WebAssembly- und Cross-Origin-Header mit aus.

## Bedienung

Mit **Beschwören** zufällige Hüter kaufen, Hüter antippen/anklicken und drei identische derselben Stufe über **Merge** verbinden. **Nächste Welle** startet den Angriff. Zwei Nature-Hüter oder Fire + Storm aktivieren Covenants.

## Assets und Tests

Die Tierportraits, UI-Texturen und die isometrische 3D-Welt stammen aus den CC0-Paketen **Kenney Animal Pack Remastered**, **Kenney UI Pack** und **Kenney Tower Defense Kit**. Herkunft und Lizenz sind in `ASSET_MANIFEST.json`, `ATTRIBUTION.md` und `LICENSES/third_party/` dokumentiert. Der reproduzierbare Downloader liegt unter `scripts/assets/fetch_assets.ps1`.

Hüter stehen auf zwölf taktischen Slots direkt am Gegnerpfad. Wähle einen Hüter und tippe einen freien Slot an oder ziehe ihn per Maus/Touch auf den Zielslot, um ihn während des Matches neu zu positionieren.

```powershell
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tools/simulate.gd
```
