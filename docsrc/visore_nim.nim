## Come funziona il visore 3D e come è passato da JavaScript a Nim
## (-> docs/visore_nim.html).
import std/[os, strutils]
import nimib, tema
import nimib/highlight

nbInit(theme = useTema)
nb.title = "Come è fatto il visore 3D"

let radice = currentSourcePath().parentDir.parentDir

proc pezzo(file, inizio: string; fine = ""): string =
  ## Le righe di un file del repository dalla prima che contiene `inizio`
  ## fino alla prima riga vuota (o fino a quella che contiene `fine`, compresa).
  ## Così i pezzi di codice mostrati qui sono sempre quelli veri.
  var dentro = false
  for riga in lines(radice / file):
    if not dentro and inizio in riga: dentro = true
    if dentro:
      if fine == "" and riga.strip == "": break
      result.add riga & "\n"
      if fine != "" and fine in riga: break
  result = result.strip(leading = false)

proc mostra(file, inizio: string; fine = "") =
  ## Mostra un pezzo di codice colorato, con il nome del file sopra.
  let codice = pezzo(file, inizio, fine)
  nbRawHtml: "<p class=\"nb-small\"><code>" & file & "</code></p>\n" &
    "<pre><code class=\"nim hljs\">" & highlightNim(codice).strip(chars = {'\n'}) & "</code></pre>"

nbText: """
# Come è fatto il visore 3D

Il [visore 3D](visore3d.html) è la pagina dove la parete si gira, si apre e si
taglia (c'è anche quello della nostra idea, [Visore 3D - Idea](visore3d_idea.html),
stessa pagina con altri modelli). Fino a questa versione era una pagina HTML con circa 600 righe di
JavaScript scritte a mano; ora la logica è scritta in **Nim**, compilata in
JavaScript, e la pagina è un documento nimib con un solo blocco `nbJsFromCode`
(il blocco di nimib che compila Nim per il browser).

Questa pagina spiega come funziona il visore e come è avvenuto il passaggio.

## Perché

Prima il percorso dei dati era questo:

```
Nim (C)                      testo                     JavaScript
parete(p) ─► Model ─► toJson ─► 12 modelli JSON ─► visore3d.tpl.html (600 righe)
                              incollati nel template     campi rinominati: w, d, h,
                                                         holesTop.y = holesPiano.z ...
```

Il visore non vedeva il tipo `Part` di Caderò ma una sua copia in JSON, con
nomi diversi: `w`, `d`, `h` invece di `size.x`, `size.y`, `size.z`; nei fori
del piano `y` e `d` invece di `z` e `h`. Il pannello frontale riceveva come fori
anche le sagome dei frontali, ma solo nel JSON. Ogni nuova proprietà delle parti
(`apre`, `alzata`, `dentro`...) andava aggiunta in tre posti: il tipo in Nim, la
conversione in JSON, il JavaScript. E il JavaScript non aveva nessun controllo:
un nome sbagliato diventava `undefined` senza errori.

Ora:

```
Nim (JS, nel browser)
parete(p) ─► Model ─► avviaVisore ─► three.js
```

- **lo stesso codice Nim** che fa le tavole calcola i modelli anche nel browser:
  niente JSON, niente copie; ogni variante è una chiamata a `parete(...)`;
- il visore usa i tipi veri (`Part`, `Kind`, `RRect`) e il compilatore controlla
  nomi e tipi;
- i valori che prima erano scritti a mano nel JavaScript (viste, materiali, assi
  dei tagli) sono costanti e funzioni Nim con un nome e un commento;
- la pagina diventa un documento nimib come gli altri, generato da `nimble docs`.

## I pezzi

| file | cosa contiene |
| --- | --- |
| `src/cadero/js/three.nim` | i binding: le classi e i metodi di three.js che servono, visti da Nim |
| `src/cadero/js/pagina.nim` | le poche cose del browser che mancano in `std/dom` |
| `src/cadero/visore.nim` | il visore: dalla scena alle sezioni, in Nim |
| `docsrc/visore3d.nim`, `docsrc/visore3d_idea.nim` | le due pagine (falegnami e idea): modelli e testi, il blocco `nbJsFromCode` |
| `docsrc/pagina_visore.nim` | il renderer comune: template, carta da parati |
| `tools/visore3d.tpl.html` | stile, pulsanti, posti per la tavola e per lo script |
| `tools/visore3d.nim` | dalla pagina di Pages all'artefatto claude.ai |

## 1. Il blocco nbJsFromCode

Il cuore della pagina è questo blocco. Non gira quando si genera il documento:
nimib lo scrive in un file, lo compila con `nim js` e mette il JavaScript che
esce nella pagina, dentro un `<script>`. Le variabili tra parentesi (qui
`cartaSrc`, l'immagine della carta da parati) sono **catturate**: nimib le
trasforma in JSON durante la generazione e il blocco le ritrova nel browser.
"""

mostra("docsrc/visore3d_idea.nim", "nbJsFromCode(cartaSrc):", "quandoThreePronto")

nbText: """
Le varianti sono le stesse di prima (base o con tavolino, risega rivestita o
scoperta, antina, prese sul comodino: 12 combinazioni), ma ora si calcolano nel
browser invece di arrivare come 12 modelli JSON incollati nella pagina. Il file da
compilare nimib lo scrive nella cartella dei documenti (`docs/`): per questo gli
import cominciano con `../`.

## 2. three.js visto da Nim

three.js è una libreria JavaScript. Per usarla da Nim si scrivono dei
**binding**: dichiarazioni Nim che dicono al compilatore quale JavaScript
scrivere. Non serve un binding completo, solo le classi e i metodi che il visore
usa (circa 80). Due esempi dal file dei binding:
"""

mostra("src/cadero/js/three.nim", "  Vector3* = ref object of JsRoot")
mostra("src/cadero/js/three.nim", "proc newBox3*", "getSize")

nbText: """
- un tipo che eredita da `JsRoot` con il pragma `importc` è un oggetto JavaScript
  qualunque: i suoi campi (`x`, `position`, `visible`) si leggono e scrivono così
  come sono;
- un proc con `importjs` ha un **modello** di JavaScript: `#` è il prossimo
  argomento, `@` tutti i restanti. `newBox3()` diventa `new THREE.Box3()`,
  `b.getCenter(v)` resta `b.getCenter(v)`;
- i parametri "oggetto" di three.js (es. `{color: 0xe3c9a0, roughness: 0.8}`) si
  scrivono con `js{...}` di `std/jsffi`.

I binding hanno i nomi di three.js, così il codice del visore si legge con la
documentazione di three.js accanto.

### Come arriva three.js

three.js è copiato nel repository (`vendor/three/`, la versione 0.160.0) e la
generazione dei documenti lo mette in `docs/three/`, accanto alle pagine: nessuna
chiamata a un CDN. Si carica come modulo ES, con un importmap. Un modulo
parte *dopo* gli script normali, e quello generato da Nim è uno script normale.
Allora un piccolo modulo nella pagina mette three.js in `window.THREE` e manda un
evento; il codice Nim aspetta quell'evento con `quandoThreePronto`:
"""

mostra("tools/visore3d.tpl.html", "<script type=\"module\">", "</script>")
mostra("src/cadero/js/three.nim", "proc quandoThreePronto*")

nbText: """
## 3. Dalla parte alla scena

`costruisci(m)` scorre le parti del modello. Per ognuna sceglie la forma, la
mette nella scena con il suo materiale e i suoi spigoli e, se è apribile, la
aggancia al suo gruppo. Gli assi cambiano nome: in three.js l'alto è y e la
profondità va verso −z, quindi (x, y, z) del CAD diventano (x, z, −y).
"""

mostra("src/cadero/visore.nim", "proc geometria(p: Part)")

nbText: """
Per leggere il codice come prima, la parte ha anche i nomi brevi di una volta,
calcolati dai campi veri:
"""

mostra("src/cadero/visore.nim", "proc x(p: Part)")

nbText: """
Il pannello frontale nel 3D ha come fori anche le sagome di ante e cassetti, che
vanno a occuparli. Prima questo succedeva solo nella conversione in JSON; ora è
una funzione del modello, usata sia dal visore sia da `toJson`:
"""

mostra("src/cadero/model.nim", "proc foriVisti*")

nbText: """
## 4. Aprire e chiudere

Ogni gruppo apribile (`Unita`) ha due contenitori: `pivot`, che sta sullo spigolo
della cerniera e ruota o trasla, e `inner`, che riporta le parti al loro posto.
`k` va da 0 (chiuso) a 1 (aperto) e a ogni fotogramma insegue `target`; `posa`
dice dove sta il gruppo per un certo `k`, secondo il suo modo di aprirsi (`apre`):
"""

mostra("src/cadero/visore.nim", "proc posa(u: Unita)")

nbText: """
Il resto del visore segue la stessa forma del JavaScript di prima, con gli stessi
nomi dove possibile (`build` è diventato `costruisci`, `pose` è `posa`): le viste
(`vista(nome)`), il tocco che apre (`unitAt`), l'esploso, i piani di taglio e le
sezioni in SVG (`disegna`).

## 5. Come è stata fatta la migrazione

1. **Binding minimi.** Elenco di tutto quello che il JavaScript usava di three.js e
   del browser, e un binding per ognuno, con i nomi originali.
2. **Traduzione riga per riga** del JavaScript in `src/cadero/visore.nim`,
   tenendo la stessa struttura e gli stessi commenti, così il confronto è facile.
3. **I modelli nel browser.** Il codice di `models/parete.nim` compila anche con
   `nim js` senza modifiche: il blocco `nbJsFromCode` chiama `parete(...)` e
   passa i modelli al visore. La conversione JSON resta solo per la vista 3D
   piccola dentro i documenti (`viewer3d` in `web.nim`).
4. **La pagina come documento nimib**, con un renderer suo (copia di quello di
   nimib) che riempie il template del visore invece del tema dei documenti.
5. **Verifica.** Vecchio e nuovo visore aperti in Chromium headless con le stesse
   azioni (vista iniziale, apri tutto, chiudi tutto, due tocchi su ante e cassetti,
   tavolino, antina aperta, prese sul comodino, dentro con la risega scoperta,
   senza carta da parati, senza fronte, esploso, sezioni, sezione selezionata e
   cursore spostato), con le animazioni disattivate: le 15 immagini sono identiche
   al pixel e gli SVG delle tre sezioni identici carattere per carattere.

### Cose da sapere

- **Closure nei cicli.** In JavaScript `for (const name of ...)` dà a ogni giro la
  sua variabile; in Nim no: una closure creata in un ciclo vede l'ultima. Per
  questo i pulsanti creati in un ciclo usano `closureScope:` con una copia della
  variabile (il primo tentativo aveva proprio questo errore: "Base" riapriva il
  tavolino).
- **Stringhe.** In Nim JS una `string` non è una stringa JavaScript: per DOM e
  three.js si passa `cstring`.
- **Conversioni di tipo.** Un evento DOM non ha le informazioni di tipo di Nim:
  per passare da `Event` a un evento del puntatore si usa `cast`, non la
  conversione normale.
- **`importjs` vuole un modello.** Per leggere una costante come
  `THREE.RepeatWrapping` il modello va tra parentesi: `"(THREE.RepeatWrapping)"`.
- **Peso della pagina.** Il JavaScript generato (visore + modello + libreria
  standard di Nim) prende il posto dei 12 modelli JSON: la pagina passa da circa
  350 KB a circa 495 KB (la carta da parati ne pesa 60). Con più varianti la
  differenza cresce a favore di Nim: una variante in più è una chiamata, non un JSON.
- **Il blocco è ricopiato come testo.** nimib trasforma il blocco `nbJsFromCode`
  in testo e lo ricompila: un'espressione come `(if a: "x" else: "") & (if b: ...)`
  su più righe non sopravvive alla copia. Meglio istruzioni semplici, una per riga.
- **Compilazione.** `nimble docs` ora chiama anche `nim js` per il blocco del
  visore: qualche secondo in più.

## 6. Cosa diventa possibile

Visto che il modello si calcola nel browser, il prossimo passo naturale sono i
**cursori delle misure** nel visore: cambiare un parametro (per esempio l'altezza
della nicchia) e ricostruire la scena con `parete(p)` senza rigenerare la pagina.

## Comandi

```sh
nimble docs                    # tutti i documenti, visore compreso (anche nim js)
nim r docsrc/visore3d.nim      # solo il visore -> docs/visore3d.html
nim r tools/visore3d.nim       # dopo il visore: tools/parete-3d.html per l'artefatto
```
"""

nbSave
