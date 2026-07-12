# Critter Covenant

Ein eigenständiges, luck-basiertes Tower-Defense-Spiel für Godot 4.7. Der aktuelle Vertical Slice enthält sechs prozedural dargestellte Hüter, vier Gegnervarianten, Bosswellen, zufällige Beschwörung, 3er-Merges und zwei spielverändernde Covenants.

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

Alle Grafiken sind prozedurale Primitive, daher existieren derzeit keine Drittanbieter-Assetabhängigkeiten.

