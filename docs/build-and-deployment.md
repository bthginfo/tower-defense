# Build and Deployment

1. Godot 4.7 Export Templates über den Editor installieren.
2. `godot --headless --path . --export-release Web public/index.html` ausführen.
3. `npx vercel` starten, Projekt verknüpfen und deployen.
4. Für Produktion `npx vercel --prod` verwenden.

Vercel liest `vercel.json`; der statische Output liegt unter `public/`. Der Ordner bleibt absichtlich außerhalb von Git, CI erzeugt ihn reproduzierbar.
