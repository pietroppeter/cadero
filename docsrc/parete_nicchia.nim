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
## Variante: tavolino estraibile

I primi tre gradini stanno nel frontale di un blocco che si estrae del tutto. Il
frontale ha gli spigoli dritti (tondi sono solo i vani) e nasconde il piano, che fa
da tavolino. Davanti i gradini sono cassetti senza frontale: due fianchi da terra al
piano, un fondo in comune dietro e un ripiano sotto ogni gradino. Dietro i cassetti
non c'è altro, solo due gambe a pannello alte e sottili sotto il piano, messe di
traverso agli angoli: tengono il blocco anche di lato e lasciano libero il fianco,
da dove entrano le gambe di chi si siede. Da chiuso le gambe arrivano vicino al muro, senza
toccarlo, ed è di nuovo una scaletta.
"""

nbCode:
  let pt = rilievo().conTavolino
  let mt = parete(pt)
  let piano = mt.find("piano tavolino")
  let fondo = mt.find("fondo cassetti")
  let gamba = mt.find("gamba tavolino")
  echo "piano: ", fmtNum(piano.size.x), " × ", fmtNum(piano.size.y), " cm, alto ",
       fmtNum(piano.z1), " da terra"
  echo "spazio per le gambe, seduti di lato: largo ", fmtNum(gamba.pos.y - fondo.y1),
       ", sotto il piano ", fmtNum(piano.size.x), ", alto ", fmtNum(piano.pos.z), " cm"

  var foglioT = initSheet()
  let fronteT = View(kind: vFront)
  foglioT.draw(fronteT, parete(rilievo().conTavolino(aperto = false)))
nbRawHtml: foglioT.render()
nbRawHtml: viewer3d(mt, id = "tavolino3d", height = 420)

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
  pannellino che si unisce allo schienale della colonna e arriva al muro.
- **Niente fondo e niente schienale** (Pietro): il mobile poggia sul pavimento con fianchi
  e divisori, dietro c'è il muro con la carta da parati, che nella nicchia si vede.
- **Materasso** 78 × 190, spesso 17 (su misura: 80 non entra nei 78.2 cm tra fronte e
  muro), appoggiato direttamente sul piano a 104.
- **Testata e libreria** (decisioni dopo il confronto con i nonni): piano della testata
  55 sopra il piano letto (17 di materasso + 38 di schienale), profondo 37.9 a filo della
  risega, fa da comodino. Sopra, fino al soffitto della nicchia (260), tre vani alti
  circa 32 con scaffali profondi 26 appoggiati al fianco destro. Il divisorio è aperto
  tra il comodino (159) e il soffitto; sotto fa da testata.
- **Gavone**: un vano chiuso dentro la colonna, tra il piano letto (104) e il comodino
  (159). Come si apre è da decidere.
- **Scatole dei gradini**: dietro ogni gradino una scatola aperta sul davanti, profonda
  30 (da definire), come un cassetto senza frontale.
- **Tavolino** (variante): largo quanto le scatole dei gradini (32.6), piano profondo 76.8
  (1.4 di gioco dal muro) a 62.6 da terra, sopra il terzo gradino. Cassetti-gradino
  profondi 20 (le scatole fisse 30); gambe dietro di traverso, larghe 8. Esce di tutta la sua profondità;
  i fianchi e le gambe scorrono sul pavimento (pattini o feltrini da scegliere).
- **Prese** (2 USB-C e 1 schuko) sulla faccia interna del fronte, 8 cm sopra il
  comodino: posizione indicativa.
- **Cassetti in basso** profondi 75, con cassa (fondo, fianchi, schiena) 1 cm più stretta
  del frontale per lato; escono di 60, il centrale è disegnato aperto.
- **Ante in basso**: dietro ognuna una scatola con i fianchi da terra al piano letto,
  che fa da cielo, fondo e schiena. Nell'anta a sinistra un ripiano a metà altezza;
  nell'anta stretta un bastone appendiabiti dal davanti al dietro, 7 cm sotto il cielo.
- **Vani alti**: un piano sotto, una schiena e due divisori tra le ribalte, profondi
  quanto la colonna (69.4).
- **Fori maniglia** di 4 cm; quelli delle ante a 10 cm dal bordo e 12 dall'alto.
- Le **linee tratteggiate** davanti al mobile nella laterale e nella pianta del disegno
  originale non sono riprodotte: non è chiaro cosa rappresentino.
- In alto ci sono tre vani con **ribalte** che si alzano (nel disegno sembravano cassetti).
- **Carta da parati** Vårklockor (Josef Frank, Svenskt Tenn): le misure non sono note.
  Dalla foto il motivo è a mezza caduta; ho assunto rotolo da 53 cm e rapporto di 53.
"""

nbSave
