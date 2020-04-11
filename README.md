Ein kurzer Blick in .git/
=========================

Dieses Repository enthält das Script für meinen Vortrag auf dem DiVOC
https://di.c3voc.de/fahrplan:florian-hars

Es benötigt tmux und ocaml.

Um es auszuführen muss man es mit

```
ocaml unix.cma present.ml
```

direkt in einem Terminalfenster starten, in dem kein tmux läuft. Es
startet dann eine tmux-Session, die es fernsteuert, und ein
gnome-terminal, das diese Session anzeigt.

Der Pfad und die gnome-terminal Session-Id (für die default Fonts
etc.) am Anfang des Skripts müssen vermutlich angepasst werden.
