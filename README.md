# Critter Covenant

Ein eigenständiges, luck-basiertes Tower-Defense-Spiel für Godot 4.7. Der aktuelle spielbare Build enthält zwölf illustrierte Hüter mit Seltenheiten und Elementfähigkeiten, vier Gegnertypen, drei Maps, Bossphasen, gewichtete Beschwörung, 3er-Merges und fünf Covenants.

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

Die Tierportraits und UI-Texturen stammen aus den CC0-Paketen **Kenney Animal Pack Remastered** und **Kenney UI Pack**. Herkunft und Lizenz sind in `ASSET_MANIFEST.json`, `ATTRIBUTION.md` und `LICENSES/third_party/` dokumentiert. Der reproduzierbare Downloader liegt unter `scripts/assets/fetch_assets.ps1`.

```powershell
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tools/simulate.gd
```
