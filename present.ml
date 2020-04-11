let display_profile = "28553808-bdf4-4c4d-b77c-cf1e84dc787e"
let basedir = "/home/hars/.tmux-present"
let name = ref "demo"

let workdir = ref (basedir ^ "/" ^ !name)
let here = Sys.getcwd()

exception CmdError of int * string

let command s =
  match Sys.command s with
  | 0 -> ()
  | err -> raise (CmdError(err, s))

let red = "setaf 1"
let green = "setaf 6"
let white = "setaf 7"
let normal = "sgr0"

let tput s =
  command ("tput " ^ s)

let wait () =
  tput green;
  print_string "> ";
  flush_all ();
  tput normal;
  ignore (read_line())

let tmux s =
  command ("tmux " ^ s)

let cr () =
  tmux "send-keys C-M"

let write s =
  let l = String.length s in
  for i = 0 to l - 1 do
    let c = match s.[i] with
      | '\'' -> "\"'\""
      | ';' -> "';;'"
      | ci -> "'" ^ (String.make 1 s.[i]) ^ "'"
    in
    tmux ("send-keys " ^ c);
    Unix.sleepf (0.02 +. Random.float 0.1)
  done

let cmd  ?(wt=false) s =
  tput red;
  tput "bold";
  print_string "$ ";
  flush_all ();
  tput white;
  print_string s;
  flush_all ();
  tput normal;
  wait ();
  write s;
  if wt then
    wait ()
  else
      Unix.sleepf (0.15 +. Random.float 0.3);
  cr()

let note s =
  Format.set_margin 65;
  Format.open_box 2;
  Format.print_string "  ";
  List.iter (function w ->
               Format.print_string w;
               Format.print_space ())
    (String.split_on_char ' ' s);
  Format.print_newline ();
  Format.close_box ()

let send s =
  let l = String.length s
  and out = ref "'" in
  (* Yeah, this is quadratic, sue me *)
  for i = 0 to l - 1 do
    let c = match s.[i] with
      | '\'' -> "'\"'\"'"
      | ci -> String.make 1 s.[i]
    in
    out := !out ^ c
  done;
  command ("tmux send-keys " ^ !out ^ "'")

let select ?(args="") pane_nr =
  command ("tmux select-pane -t =" ^ !name ^ ":" ^ pane_nr ^ " " ^ args )

let split dir pane size cmd =
  command ("tmux split-window -t =" ^ !name ^ ":" ^ pane ^ " " ^ dir ^ " -l " ^ (string_of_int size) ^ " " ^ cmd)

let split_v ?(cmd="bash") pane_nr lines =
  split "-v" pane_nr lines cmd

let split_h ?(cmd="bash") pane_nr lines =
  split "-h" pane_nr lines cmd

let clear () =
  send "clear";
  cr()

let setup nm title =
  name := nm;
  workdir := basedir ^ "/" ^ !name;
  command ("rm -rf " ^ !workdir);
  command ("mkdir -p " ^ !workdir);
  Sys.chdir (!workdir);
  command ("tmux kill-session -t =" ^ !name ^ " 2>/dev/null || true");
  command ("tmux new-session -s " ^ !name ^ " -d bash");
  select "0.0" ~args:("-T '" ^ title ^ "'");
  send ("export PS1='\\W$ '");
  cr();
  send ("clear; echo '" ^ title ^ "' | recode utf8..latin1 | figlet -c -W; echo -e '\\n'; figlet -c -W -f small 'Florian Hars'; date +%Y-%m-%d | figlet -c -W -f small; echo -e '\\n\\n\\n'");
  cr();
  command("gnome-terminal --profile=" ^ display_profile ^ " --geometry=+650+400 -- " ^ here ^ "/start-display " ^ !name ^ ">/dev/null");
  note ("execute 'tmux attach-session -t =" ^ !name ^ "' in all terminals");
  wait()

let copy () =
  tmux "copy-mode"

let paste () =
  tmux "paste-buffer"

let copy_word_before s =
  copy ();
  tmux ("send -X search-backward " ^ s);
  tmux "send-keys -X begin-selection";
  tmux "send-keys -X previous-word";
  wait ();
  tmux "send-keys -X copy-selection-and-cancel"

let copy_word_after s =
  copy ();
  tmux ("send -X search-backward " ^ s);
  tmux "send-keys -X next-word-end";
  tmux ("send-keys -X cursor-right");
  tmux "send-keys -X begin-selection";
  tmux "send-keys -X next-word-end";
  wait ();
  tmux "send-keys -X copy-selection-and-cancel"

let copy_prev_line () =
  copy ();
  tmux "send-keys C-P C-A C-K"

let retitle s =
  print_string ("\027]0;" ^ s ^ "\007")

let () =
  Random.init 1;
  retitle "CONTROL-FULL";
  setup "git" "Ein Blick in .git/";
  retitle "CONTROL-SBS";
  note "In der täglichen Arbeit mit git reichen meist eine Hand voll einfacher Kommandos. Aber manchmal fällt einem git in den Rücken und gibt nur eine seltsame Fehlermeldung aus, oder Dinge funktionieren nicht so, wie man es sich wünscht. Dann kann es hilfreich sein, wenn man versteht, was git im Hintergrund eigentlich tut.";
  wait ();
  retitle "CONTROL-SLIDE";
  note "Um zu sehen, was git so tut, benötigen wir als erstes ein leeres Verzeichnis";
  cmd "mkdir repo; cd repo; ls -lA";
  note "Darin legen wir dann ein Repository an";
  cmd "git init";
  note "Auch, wenn git sagt, dass das Repo noch leer ist, hat es ein verstecktes Verzeichnis mit ein paar Dingen darin angelegt";
  cmd "tree -F .git/";
  note "Ein Teil davon sind Beispieldateien, die wir nicht brauchen, also weg damit:";
  cmd "find .git -name *.sample | xargs rm";
  cmd "clear; tree -F .git/";
  note "Ein paar davon sind aber interessant: Wir haben eine Konfigurationsdatei mit grundsätzlichen Einstellungen, die und heute aber nicht wirklich interessiert:";
  cmd "cat .git/config";
  note "eine Beschreibung, die Tools wie gitlab anzeigen können:";
  cmd "cat .git/description";
  note "und als drittes die HEAD Datei, die eine Dateinamen enthält, der den aktuellen Branch beschreibt.";
  cmd "cat .git/HEAD";
  note "Das Verzeichnis refs/heads, in dem diese Datei liegen sollte, können wir oben sehen, die Datei gibt es aber noch nicht, das Verzeichnis ist noch leer, genauso wie fast alle anderen Verzeichnisse, die git init für uns angelegt hat.";
  note "Ein paar von diesen Verzeichnissen werden wir für den Rest des Vortrags im Auge behalten";
  wait ();
  split_h "0.0" 30;
  send "cd repo; while true; do clear;  tree -C -A -F -I 'logs|hooks|info' .git/ | cut -c 1-36; sleep 2; done";
  cr ();
  select "0.0";
  retitle "CONTROL-SBS";
  note "Was git mit den Dateien in diesem Verzeichnis macht ist, über das normale Dateisystem, in dem Dateien über ihren Namen identifiziert werden, ein virtuelles inhaltsadressiertes Dateisystem legt, in dem Dateien über ihren Inhalt identiziziert werden.";
  wait ();
  note "Der Unterschied ist, dass du bei einem normalen Dateisystem einen Namen hast und du das Dateisystem bittest 'gibt mit eine Datei mit diesem Namen', zu Beispiel 'divoc-background.png' um den Hintergrund hier um mich herum zu sehen, und dann gibt dir das Dateisystem eine Datei mit dem Namen, wie auch immer sie aussieht.";
  wait ();
  note "Bei einem inhaltsadressierten Dateisystem kennst du dagegen den Inhalt der Datei, die Häschen und Karotten, und du bittest das Dateisystem 'gib mir eine Datei mit diesem Inhalt' und das Dateisystem macht genau das.";
  wait ();
  note "Das klingt erst mal doof, ich meine, warum soll ich die Datei von Dateisystem anfordern, wenn ich den Ihnalt schon kenne, dann habe ich ihn doch schon?";
  note "Der Trick ist, dass git für die Identifizierung einer Datei nicht den kompletten Inhalt benutzt, sondern einen eindeutigen Hashwert.";
  wait ();
  retitle "CONTROL-SLIDE";
  clear ();
  note "Ein Beispiel, wir schicken die Zeichenkette 'Foo' an 'git hash-object' und bekommen einen Hashwert zurück:";
  cmd "echo Foo | git hash-object --stdin";
  note "Dieser Hash bc56c4... identifiziert eindeutig die Datei mit dem Inhalt 'Foo'. Wir können den Hash zu Beispiel mit ein paar Schlüsselwötern, die ein git-repository indentifizieren, an eine Suchmaschine unseres Vertrauens verfüttern:";
  wait ();
  write "w3m https://duckduckgo.com/html?q=heads%20master%20";
  copy_prev_line ();
  wait ();
  paste();
  note "Wenn wir die Anfrage abschicken, sehen wir (hoffentlich, gestern ging es noch), dass genau dieser Hash auf einer Seite im Soucecode-Explorer von Chromium vorkommt:";
  wait ();
  cr ();
  note "Wir können zu dem Link gehen";
  wait();
  tmux "send-keys C-N C-N C-N C-N C-N";
  note "und ihn öffnen";
  wait ();
  cr ();
  tmux "send-keys Tab";
  cr ();
  note "und wir sehen, dass dieses Datei bar tatsächlich den Inhalt 'Foo' hat.";
  wait ();
  tmux "send-keys qy";
  retitle "CONTROL-PIP";
  note "Wenn google so eine Datei hat, dann muss das was cooles sein, und wir wollen jetzt auch so eine Datei haben";
  cmd "echo Foo > foo.txt";
  note "und machen sie dann auch gleich git mit dem Befehl \"git add\" bekannt:";
  cmd "git add foo.txt";
  note "Diese Aktion heißt auch, die Datei dem Index hinzufügen, und wenn ihr euch jemals gefragt hat, wo das her kommt, könnt ihr in die Liste rechts gucken: da ist jetzt eine neue Datei mit dem Namen \"index\" hinzugekommen.";
  note "In dieser Datei verwaltet git Informationen über den Zustand der ihm bekannten Dateien im Arbeitsverzeichnis.";
  note "index ist eine Binärdatei mit der man normalerweise nichts direkt zu tun hat, aber wenn man mal hineinguckt finden wir ein paar bekannte Informationen wieder:";
  cmd "od -t x1 -c .git/index | egrep -10 'bc.*48|f   o   o   .   t   x' ";
  note "Wir können sowohl unseren Hash sehen als auch den Namen der Datei rechts unten Ende der Zeile.";
  wait ();
  note "Die andere neue Datei ist in dem objects Verzeichnis aufgetaucht. Ihr Name ist offennsichtlich von dem Hash von foo.txt abgeleitet";
  wait();
  retitle "CONTROL-SLIDE";
  note "Wenn man git schon mal benutzt hat, sieht Hash dieser Datei  erst mal nicht anders aus als der Hash irgendeines Commits, und tatsächlich kann man sich mit git show eine Datei ebenso gut anzeigen lassen wie einen Commit:";
  wait ();
  write "git show --pretty=full ";
  paste ();
  note "Wenn das der Hash eines Commits wäre, würde man jetzt das Datum und die Namen der Committerin erwarten, zusammen mit einer Beschreibung und einem Diff. Dies ist aber der Hash einer Datei, und wenn wir den Befehl ausführen sehen wir...";
  wait ();
  cr();
  note "... den Inhalt der Datei.";
  wait ();
  note "Wenn wir unser neue Datei jetzt committen, passiert einiges mehr in dem .git Verzeichnis";
  cmd "git commit -m 'import foo.txt'";
  note "Wir sehen zwei neue Objekte";
  wait();
  note "Eins davon scheint unser Commit-Objekt zu sein, da der Dateiname zu der Commit-Id passt:";
  copy_word_before "]";
  note "Und wir sehen jetzt endlich die refs/heads/master-Datei, die schon die ganze Zeit in HEAD referenziert wird, und der Inhalt ist offensichtlich auch der Hash des neuen Commit-Objekts.";
  cmd "cat .git/refs/heads/master";
  note "Wenn wir uns den Commit mit git show ansehen finden wir tatsächlich, was wir in dem Commit erwarten:";
  wait ();
  write "git show --pretty=raw ";
  paste ();
  wait ();
  cr ();
  note "Der Commit ist von mir, hat die Message, die ich ihm gerade gegeben habe, und enthält die Datei foo.txt, die jetzt den Hash bc56c4 hat.";
  wait ();
  note "Der Commit verweist aber mit dem Label tree noch auf einen weiteren Hash, der gerade zu dem letzten neuen Objekt passt.";
  note "Dieses Objekt enthält eine Liste, unter welchen Namen welche Inhalte in diesem Commit zu finden sind.";
  copy_word_after "tree ";
  note "Wir können es uns mit git show ansehen:";
  write "git show ";
  paste ();
  wait ();
  cr ();
  note "Das zeigt aber nur die Namen der Dateien, mehr Informationen bekommen wir mit git ls-tree";
  wait ();
  write "git ls-tree ";
  paste ();
  wait ();
  cr ();
  note "In diesen Commit gibt es genau eine einzige Datei mit dem Namen foo.txt und dem erwarteten Hash des Inhalts.";
  wait ();
  note "Fügen wir noch eine Datei hinzu";
  cmd "echo Foo > bar.txt";
  cmd "git add bar.txt";
  note "Bis jetzt hat sich in dem .git-Verzeichnis nicht viel geändert außer dem Inhalt der index-Datei, da die neue Datei natürlich dem gleichen Objekt entspricht wie die alte.";
  note "Mit dem Commit passiert dann mehr:";
  cmd ~wt:true "git commit -m 'add bar.txt'";
  note "Jetzt haben wir wieder zwei neue Objekte";
  wait();
  note "Das eine ist wieder das Commit-Objekt:";
  copy_word_before "]";
  write "git show --pretty=raw ";
  paste ();
  cr ();
  note "Das andere ist wieder das tree-Objekt";
  wait ();
  copy_word_after "tree ";
  write "git ls-tree ";
  paste ();
  cr ();
  note "das dieses mal zwei gleiche Dateien enthält.";
  wait ();
  note "Was gegenüber dem ersten Commit neu ist, ist das Parent-Feld, das den Hash des vorigen Commits enthält:";
  copy_word_after "parent ";
  note "Diese Verweise auf parent-Commits sind alles, was aus dem inhaltsadressierten Dateisystem git ein Versionsverwaltungssystem macht.";
  wait ();
  note "Commits ";
  send "clear; git show --pretty=raw";
  cr ();
  wait();
  note  "verweisen in git immer auf einen momentanen Stand des Repositories (das tree-Objekt des Commits),";
  copy_word_after "tree ";
  note "und die parent-Hashes";
  copy_word_after "parent ";
  note "machen aus der Menge von Versionsständen einen gerichteten Graphen:";
  cmd ~wt:true "git log --graph --pretty=short --all";

  retitle "CONTROL-SBS";
  note "Das ist im Grundsatz das ganze Datenmodell von git. Es gibt Commits, Tree-Objekte und die eigentlichen Daten in Blobs, und alles wird gleichermaßen über Hashes identifiziert.";
  note "Zusätzlich gibt dann noch Branches, was aber nur einfache Dateien sind, die den Hash eines Commits enthalten. Das ist anders als bei vielen anderen Versionsverwaltungssystemen, worauf ich gleich noch genauer eingehen werden.";
    note "NEUER ABSCHNITT";
  wait ();
  send "clear; figlet -c -W -f small 'Keine Angst vor Fehlern'; echo -e '\\n\\n\\n'";
  cr();
  note "Eine angenehme Eigenschaft von git ist, dass es unter normalen Umständen alle diese Objekte eine ganze Zeit lang aufbewahrt (typischerweise zwei Wochen), auch, wenn eigentlich nichts mehr auf ein Objekt verweiset.";
  note "Das macht es oft möglich, nach einem Merge- oder Rebase-Unfall verloren geglaubte Daten wieder herzustellen, wenn man weiß, wo man suchen muss.";
  wait();
  retitle "CONTROL-SLIDE";
  note "Nehmen wir zum Beispiel an, dass wir unseren letzten Commit durch ein falsches Kommando verloren haben:";
  cmd "git reset --hard HEAD^";
  note "Jetzt is unsere neue Datei weg:";
  cmd "ls";
  note "Und auch in dem Graphen aller Versionen taucht er nicht mehr auf:";
  cmd ~wt:true "git log --graph --pretty=short --all";
  note "Aber in dem .git-Verzeichnis ist alles noch da, und wir sehen eine neue Datei ORIG_HEAD, die den Hash des gerade verlorenen Commits enthält:";
  cmd "cat .git/ORIG_HEAD";
  note "Darüber können wir den Commit wieder finden, wenn uns der Fehler rechtzeitig auffällt.";
  note "Eine andere Möglichkeit, auch ältere Commits wieder zu finden, ist das reflog, das Informationen darüber enthält, welche Commits schon mal ausgecheckt waren:";
  cmd "git reflog";
  note "Der zweite Commit in dieser Liste ist der, den wir haben wollen:";
  wait ();
  copy_word_before "HEAD@{1}";
  write "git reset --hard ";
  paste ();
  note "und wir können den aktuellen Branch zum Beispiel hart auf diesen Commit zurück setzen";
  wait ();
  cr ();
  note "Und wir sind wieder da, wo wir waren:";
  cmd "git log --graph --pretty=short --all";

  note "Eine andere Situation, in der man sich manchmal befindet, insbesondere, wenn man alte Versionen im Reflog untersucht, ist die, dass man einen Commit ausgecheckt hat, sich aber auf keinem Branch befindet.";
  cmd "git checkout HEAD^";
  note "In dieser Situation zeigt HEAD nicht auf einen Branchnamen, sondern direkt auf einen Commit:";
  cmd "git log --graph --pretty=short --all";
  cmd "cat .git/HEAD";
  note "Das ist erst mal kein Problem und man kann in dieser Situation fast normal weiter arbeiten. Allerdings findet man Dinge, die man in dieser Situation ändert, nicht so leicht wieder: wenn man jetzt etwas commitet muss man den Commit meist im reflog suchen, wenn man ihn später noch mal braucht.";
  note "Daher beglückt git einen in dieser Situation regelmäßig mit ziemlich langen Meldungen, die man meistens nicht wirklich liest, die aber eine Weg aus dieser Situation erklären: man kann einfach einen neuen Branch starten, der auf den aktuellen Commit zeigt:";
  cmd "git checkout -b \"more-foo\"";
  note "Jetzt zeigt HEAD wieder auf einen Branch:";
  cmd "cat .git/HEAD";
  note "Und der Branch zeigt auf den aktuellen Commit:";
  cmd "cat .git/refs/heads/more-foo";
  note "Wir können und das auch noch mal in der Graphenansicht angucken:";
  cmd "git log --graph --pretty=short --all";

  note "Mit diesem Branch können wir jetzt ganz normal arbeiten, als wenn nichts gewesen wäre.";
  note "Wir können eine Datei ändern, zum Beispiel eine Zeile hinzufügen";
  cmd "echo FooFooFoo >> foo.txt";
  cmd "git diff";
  cmd "git add foo.txt";
  note "Wenn wir die jetzte commiten kriegen wir wieder ein paar neue Objekte im objects-Verzeichnis";
  cmd "git commit -m 'add more Foo'";
  note "HEAD zeigt weiter auf underen Branch in dem refs/heads-Verzeichnis:";
  cmd "cat .git/HEAD";
  note "Und der Branch zeigt auf den neuen Commit:";
  cmd "cat .git/refs/heads/more-foo";
  note "Unser Graph hat jetzt eine Verzweigung:";
  cmd "git log --graph --pretty=short --all";

  note "Jetzt können wir den Branch in den master mergen.";
  note "Dazu wechseln wir erst ein mal wieder auf den master-Branch";
  cmd  "git checkout master";
  note "Wie erwartet, hat sich HEAD jetzt geändert:";
  cmd "cat .git/HEAD";
  note "Und wir mergen den Branch";
  cmd "git merge -m \"Merge branch 'more-foo'\" more-foo";
  note "und können ihn schließlich löschen.";
  cmd "git branch -d more-foo";
  note "Wenn wir uns jetzt den letzen Commit auf dem master sehen, sehen wir, dass er zwei parents hat:";
  cmd "git show --pretty=raw";
  note "Das ist der einzige Unterschied zwischen einem Merge-Commit und einem normalen Commit: ein Merge-Commit hat zwei oder mehr Parents, ein normaler Commit höchstens einen.";
  cmd "git log --graph --pretty=short --all";

  note "NEUER ABSCHNITT";
  retitle "CONTROL-SBS";
  wait ();
  send "clear; figlet -c -W -f small 'Was ist ein Branch?'; echo -e '\\n\\n\\n'";
  cr();
  note "Jetzt haben wir mit zwei Branches gearbeitet, zwischen ihnen gewechselt und Dinge gemergt. Das ist ein guter Punkt, darauf einzugehen, has ein Branch in git eigentlich ist.";
  wait ();
  note "In vielen Versionsverwaltungen sind Branches schwerwiegende, aufwändig zu verwaltende Dinge. Insbesondere in Subversion muss man für einen Branch fast das ganze Repository kopieren, und Code zwischen verschiedenen Branches zusammen zu führen ist nicht einfach und muss wohlüberlegt sein.";
  note "Verglichen damit gibt es in git eigentlich fast gar keine Branches. Ein Branch ist nur ein Name, der auf einen Commit verweist und es so einfacher macht, diesen Commit wieder zu finden. Es gibt nur noch eine zusätzliche Konvention: wenn HEAD auf einen Branch zeigt und man einen neuen Commit erzeugt, wird der Branch so aktualisiert, dass er auf diesen Commit zeigt.";
  wait();
  retitle "CONTROL-PIP";
  note "Gucken wir uns noch mal den merge-Commit von eben an:";
  cmd "git show --pretty=raw";
  note "Branches und Branchnamen werden nur in den an zukünftige Benutzer gerichteten Freitextfeld der Commitmessage erwähnt.";
  note "Für git und die History, die git verwaltet, sind nur die Verweise auf die parent-Commits (und transitiv deren History) relevant. Ob diese Commits jemals auf einem Branch waren oder ob alles mit losgelösten HEADs passiert ist, ist git völlig egal.";
  note "Das Gleiche auch in der Graphenansicht:";
  cmd "git log --graph --pretty=short --all";
  note "Die Linien haben nichts mit irgendwelchen Branches zu tun. Die einzige Stelle, wo hier ein Branch auftaucht, ist in der ersten Zeile, HEAD verweist auf den gerade ausgecheckten master-Branch, der gerade auf den Mergecommit von eben verweist.";
  wait ();
  retitle "CONTROL-FULL";
  note "Das Branches in git im wesentlichen nur Namen, nur Schall und Rauch sind, ist etwas, womit viele Leute, die von anderen Systemen kommen, Probleme haben. Das kann dann dazu führen, dass sie völlig kontraproduktive Regelwerke für das Branchmanagement aufstellen.";
  note "Das abschreckende Beispiel ist das vor ein paar Jahren aufgekommene 'git flow'.";
  note "git flow ist um die fehlgeleitete Idee strukturiert, dass es besondere, langlebige Branches gibt und dass die Zugehörigkeit eines Commits zu einem Branch eine wesentliche Eigenschaft dieses Commits ist. Wenn jemand die Illustrationen zu git flow kennt, das drückt sich dann in den durchgehenden geraden Linien aus, die lauter Commits einer Farbe verbinden, Commits auf master sind alle blau, auf develop gelb und so weiter.";
  wait();
  retitle "CONTROL-SBS";
  note "Das arbeitet genau gegen die grundlegenden Konzepte von git (ebenso wie das merkwürdige Schema für die Branchnamen, das alle Defaults von git über den Haufen wirft), und führt nur zu bürokratischem Overhead und jeder Menge an nutzlosen Mergecommits.";
  send "clear; echo 'Sagt \"Nein!\" zu git flow' | recode utf8..latin1 | figlet -c -W -f small; echo -e '\\n\\n\\n'";
  cr ();
  note "NEUER ABSCHNITT";
  note "Das Datenmodell, wie ich es beschrieben habe, legt viele, viele Dateien in .git an, die es dort lange liegen lässt. Da kann man sich fragen: Wird das nicht auf die Dauer ineffizient?";
  wait ();
  retitle "CONTROL-PIP";
  send "clear; echo 'Die Müllabfuhr' | recode utf8..latin1 | figlet -c -W -f small; echo -e '\\n\\n\\n'";
  cr();
  note "Die Antwort darauf ist ja, aber git weiß das zu vermeiden, indem es regelmäßig oder auf Verlangen aufräumt.";
  cmd ~wt:true "git gc";
  note "Jetzt sind alle die einzelnen Dateien verschwunden, und die übriggebliebenen Daten sind in gepackte Objekte gewandert.";
  note "Da sind sie aber immer noch:";
  cmd "git log --graph --pretty=short --all";
  note "Dieses Aufräumen ist übrigens eine der wenigen Situationen, in denen git Daten wegwirft: nicht mehr referenzierte Objekte, die ein gewisses Alter übersteigen (normalerweise zwei Wochen) werden dabei gelöscht.";
  note "LETZTE FOLIE";
  wait ();
  retitle "CONTROL-SBS";
  send "clear; figlet -c -W 'Danke!'; echo -e '\\n'; figlet -c -W 'Fragen?'; echo -e '\\n\\n\\n'";
  cr();
  wait ();
  retitle "CONTROL0";
  ()
