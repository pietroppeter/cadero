import nimib, tema   # tema: stessi colori e caratteri degli artefatti
import std/[strformat, strutils]

nbInit(theme = useTema)
nb.title = "Parete con nicchia letto"

nbText: """
# Parete con nicchia letto

Questa pagina ridisegna da codice la tavola di riferimento: una parete attrezzata
larga 237 cm, alta 316 e profonda 80, con una nicchia letto rialzata, cassetti in
alto e ante, gradini e cassetti in basso. Tutte le misure sono in cm.

Il mobile è descritto da un oggetto di parametri e da una funzione che lo
trasforma in parti (scatole). Viste, quote, 3D e distinta vengono tutte da lì.
Per capire come funziona il codice, passo passo: [come funziona Caderò](come_funziona.html).
"""

nbCode:
  import cadero, parete    # libreria (src/) e modello del mobile (models/)

  let p = rilievo()        # i parametri letti dal disegno
  let m = parete(p)        # il modello: una lista di parti
  echo "parti: ", m.parts.len, ", altezza totale: ", fmtNum(p.altezza)

nbText: """
## La tavola

Prospetto frontale, vista laterale (sezione dentro la colonna destra guardando verso
sinistra, con la libreria tagliata e il cassetto centrale aperto) e pianta (sezione
all'altezza della nicchia, col materasso tratteggiato). In testa al letto la colonna
destra è aperta verso la nicchia: sotto c'è la testata con il gavone, sopra il piano
della testata, che fa da comodino, e la libreria con scaffali meno profondi.
Dietro a destra, tratteggiata, la risega del muro: la colonna si ferma contro di essa.
Le quote sono generate dai parametri: se cambia una misura, cambiano anche loro.
"""

nbCode:
  let svgTavola = tavola(p, m)
nbRawHtml: svgTavola

nbText: """
## Vista 3D

Per vederla a tutto schermo, con viste predefinite (anche da dentro la nicchia),
il cassetto aperto e il fronte nascosto: [visore 3D](visore3d.html).
"""
nbRawHtml: viewer3d(m)

nbText: """
## Cambiare le misure

Una variante: nicchia più bassa di 10 cm, quattro gradini invece di cinque e
cassetti in basso tutti chiusi. L'altezza totale si ricalcola da sola.
"""

nbCode:
  var p2 = rilievo()
  p2.nicchia = 112
  p2.nGradini = 4
  p2.cassettoAperto = -1
  let m2 = parete(p2)
  echo "altezza totale: ", fmtNum(p2.altezza)

  var foglio = initSheet()
  let fronte = View(kind: vFront)
  foglio.draw(fronte, m2)
  for q in quote(p2):
    if q.view == vFront: foglio.draw(fronte, q)
nbRawHtml: foglio.render()

nbText: """
## Cosa non torna

`controlli(p)` confronta le misure con le decisioni prese e segnala i conflitti.
Con i parametri attuali non trova niente; con il materasso da 80 delle prime note
invece sì:
"""

nbCode:
  echo "controlli: ", p.controlli.len
  var p80 = rilievo()
  p80.materasso[1] = 80
  for c in p80.controlli: echo "- ", c

nbText: """
## Distinta dei pezzi

Pezzi uguali sono contati insieme; misure dalla più grande alla più piccola.
"""

block:
  var t = "| pezzi | parte | tipo | misure (cm) |\n| ---: | --- | --- | --- |\n"
  for r in bom(m):
    t.add &"| {r.count} | {r.name} | {r.kind} | {fmtNum(r.dims[0])} × {fmtNum(r.dims[1])} × {fmtNum(r.dims[2])} |\n"
  nbText: t

nbText: """
## Ipotesi da verificare

Le misure scritte sulla tavola sono usate così come sono. Le altre le ho
rilevate in scala dal disegno o inventate; sono tutte parametri in
`models/parete.nim`.

- **Spessore pannelli** 1.8 cm (multistrato), ipotesi.
- **Posizioni orizzontali** di frontali e aperture, rilevate in scala: margini laterali
  12.5, nicchia da 16 a 181.5 con raggio 18, colonne in basso larghe 71, 29, 52 e 38.5.
- **Risega del muro**: pilastro dietro a destra per tutta l'altezza, sporge 7 e largo 38.
  La colonna destra è quindi profonda 73. Il rivestimento è a L, per tutta l'altezza:
  la faccia larga è coperta dallo schienale della colonna, il bordo sottile da un
  pannellino che si unisce allo schienale della nicchia e a quello della colonna.
- **Materasso** 76 × 190, spesso 17 (su misura: 80 non entra nei 76.4 cm tra fronte e
  schienale), appoggiato direttamente sul piano a 104.
- **Testata e libreria** (decisioni dopo il confronto con i nonni): piano della testata
  55 sopra il piano letto (17 di materasso + 38 di schienale), profondo 37.9 a filo della
  risega, fa da comodino. Sopra, fino al soffitto della nicchia (260), tre vani alti
  circa 32 con scaffali profondi 26 appoggiati al fianco destro. Il divisorio è aperto
  tra il comodino (159) e il soffitto; sotto fa da testata.
- **Gavone**: un vano chiuso dentro la colonna, tra il piano letto (104) e il comodino
  (159). Come si apre è da decidere.
- **Scatole dei gradini**: dietro ogni gradino una scatola aperta sul davanti, profonda
  30 (da definire), come un cassetto senza frontale.
- **Prese** (2 USB-C e 1 schuko) sulla faccia interna del fronte, 8 cm sopra il
  comodino: posizione indicativa.
- **Cassetti in basso** profondi 75, il centrale disegnato aperto di 23 cm.
- **Fori maniglia** di 4 cm; quelli delle ante a 10 cm dal bordo e 12 dall'alto.
- Le **linee tratteggiate** davanti al mobile nella laterale e nella pianta del disegno
  originale non sono riprodotte: non è chiaro cosa rappresentino.
- I **cassetti alti** hanno solo il frontale: la profondità non è indicata.
"""

nbSave
