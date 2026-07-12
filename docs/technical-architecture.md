# Technical Architecture

Der Vertical Slice trennt Definitionen (`UNIT_DEFS`) von Runtime-Instanzen. Die deterministisch seedbare Simulation aktualisiert Units, Gegner und Projektile getrennt. Darstellung und Eingabe liegen vorerst in einer schlanken Control-Scene; Content-Expansion soll Definitionen in typisierte Resources überführen.

Webexporte werden statisch nach `public/` geschrieben. Savegames nutzen `user://`, das im Webexport auf browserseitigen persistenten Speicher abgebildet wird.

