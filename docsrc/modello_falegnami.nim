## Il modello dei falegnami (-> docs/modello_falegnami.html): le loro tavole
## ridisegnate da codice, il confronto con la nostra parete, i calcoli della
## nicchia, i mobili uno per uno e le cose da chiedere.
import nimib, tema
import std/[strutils]

nbInit(theme = useTema)
nb.title = "Il modello dei falegnami"

nbText: """
# Il modello dei falegnami

I falegnami hanno mandato sette tavole SketchUp della parete. È la stessa stanza
e la stessa idea della [nostra parete](parete_nicchia.html), ma divisa nei mobili
che costruiranno davvero, con molto dettaglio in più. Qui è ridisegnata da codice
in `models/falegnami.nim`, accanto alla nostra, che resta com'è. Nel
[visore 3D](visore3d.html) si sceglie con il pulsante **Falegnami**; il pulsante
**Pannello estraibile** toglie il pannellino tra i gradini (senza, i gradini si
ridistribuiscono).

Le loro misure sono in mm, qui in cm. Quelle scritte sulle tavole sono riportate
così come sono; quelle che mancano le ho misurate in scala sul prospetto
(rilevate) o ipotizzate: sono elencate in fondo.
"""

nbCode:
  import cadero, parete, falegnami
  let f = falegnami()
  let m = modello(f)
  let p = rilievo()
  echo m.parts.len, " parti, ", fmtNum(f.larghezza), " × ", fmtNum(f.altezza), " × ", fmtNum(f.profondita), " cm"

nbText: """
## Come è diviso

- **Il fronte**: quattro pannelli da 112.5 × 156.8, una fascia alta 6 in cima e due
  spalle larghe 5.9 contro i muri. La nicchia e il vano alto di mezzo passano da
  un pannello all'altro: nei pezzi diventano tacche del bordo, non fori.
- **Tre vani alti** 68.1 × 40.9, scatole aperte davanti con la ribalta. Quella di
  sinistra è tagliata a 15 cm: il pezzo a sinistra resta fisso, si apre solo la
  parte destra, così la ribalta non sbatte contro il condizionatore.
- **Il cassone del letto**: piano, cielo e un fianco a sinistra, dentro 193 × 150,
  profondo 77.5. Piano e cielo non passano sotto e sopra la libreria (non è
  chiaro dalle tavole: l'ho assunto).
- **La libreria** in testa al letto, un mobile a sé: 63.5 di profondità, alta 150,
  aperta verso il letto, con il gavone sotto (frontale 32), il piano del comodino
  profondo 38 con l'apertura e i due coperchi, tre scaffali profondi 27.
- **Quattro mobili bassi** alti 109: A con due ripiani mobili (75.3), B con i
  gradini in multistrato (28.6), C con tre cassetti (50), D con l'appenderia (50,
  profondo solo 62.2 per stare davanti alla risega).

Le scatole grigie dei disegni le leggo come melaminico da 19 mm (500 fuori, 462
dentro), le parti color legno come multistrato da 18 (la libreria: 635 fuori,
599 dentro). Nel visore il melaminico è grigio.
"""

nbText: "## La tavola"
nbCode:
  let svgTavola = tavola(f, m)
nbRawHtml: svgTavola

nbText: """
Prospetto, sezione laterale a x = 150 (dentro la nicchia, si vedono i cassetti di
C) e pianta a 130 cm da terra, sopra il piano letto. Senza il pannellino il
prospetto dei gradini cambia così: niente fessura, lo spazio tra i gradini diventa
4.75 invece di 4.
"""

nbCode:
  let senza = falegnami().senzaPannello
  var foglio = initSheet()
  let fronte = View(kind: vFront)
  foglio.draw(fronte, modello(senza))
  for q in quote(senza):
    if q.view == vFront: foglio.draw(fronte, q)
nbRawHtml: foglio.render()

nbText: """
## L'altezza della nicchia, dalla base del letto

Sulle tavole non c'è una quota della nicchia misurata dal letto: va calcolata
sommando le altezze dei mobili. I mobili bassi sono alti 109, il piano del
cassone (18 mm) ci sta sopra, dentro il cassone ci sono 150 cm, poi il cielo.
"""

nbCode:
  let righe = @[
    ("cima dei mobili bassi", f.hBassi),
    ("piano letto (cima del piano del cassone)", f.pianoLetto),
    ("cima del materasso (" & fmtNum(f.materasso.altezza) & ")", f.pianoLetto + f.materasso.altezza),
    ("piano del comodino (gavone 32 + 1.8)", f.pianoComodino),
    ("bordo basso dell'apertura (rilevato)", f.nicchiaZ),
    ("bordo alto dell'apertura (+ 121.9)", f.nicchiaZ + f.nicchiaH),
    ("sotto del cielo del cassone (+ 150)", f.cieloNicchia),
    ("fondo dei vani alti (rialzo " & fmtNum(f.rialzo) & ")", f.fondoVani),
    ("cima del fronte (2 × 156.8 + 6)", f.altezza)]
  for (nome, z) in righe:
    echo fmtNum(z).align(6), "  ", nome
  echo ""
  echo "dal piano letto: apertura da ", fmtNum(f.nicchiaZ - f.pianoLetto), " a ",
    fmtNum(f.nicchiaZ + f.nicchiaH - f.pianoLetto), ", cielo a ", fmtNum(f.hNicchia)
  echo "sopra il materasso: fronte ", fmtNum(f.bordo), ", testata ", fmtNum(f.schienale)

nbText: """
## Confronto con la nostra parete

Le stesse misure nei due modelli (la nostra con i parametri di oggi).
"""

nbCode:
  let confronto = @[
    ("altezza del mobile", p.altezza, f.altezza),
    ("profondità (ante comprese)", p.profondita, f.profondita),
    ("piano letto da terra", p.pianoLetto, f.pianoLetto),
    ("nicchia dentro, dal piano letto", p.altezze.nicchia, f.hNicchia),
    ("apertura: bordo basso da terra", p.nicchiaZ, f.nicchiaZ),
    ("apertura: altezza", p.nicchiaH, f.nicchiaH),
    ("apertura: larghezza", p.nicchiaL, f.nicchiaL),
    ("fronte sopra il materasso (bordo)", p.bordo, f.bordo),
    ("testata sopra il piano letto", p.altezze.testata, f.pianoComodino - f.pianoLetto),
    ("testata sopra il materasso", p.schienale, f.schienale),
    ("profondità del comodino", p.profComodino, f.comodino),
    ("profondità degli scaffali", p.libreria.profScaffali, f.scaffali),
    ("ribalte: altezza", p.alta.altezzaRibalta, f.ribaltaH),
    ("ribalte: larghezza", p.alta.larghezzaRibalta, f.ribaltaL),
    ("ante in basso: da terra", p.bassa.zoccolo, f.zBassi),
    ("ante in basso: altezza", p.bassa.altezzaAnte, f.altezzaAnte),
    ("anta grande (A)", p.bassa.antaGrande, f.antaA),
    ("gradini: larghezza", p.bassa.gradini, f.aperturaGradini),
    ("cassetti: larghezza", p.bassa.cassetti, f.cassetti),
    ("anta stretta (D)", p.bassa.antaStretta, f.antaD)]
  echo "misura".alignLeft(36), "nostra".align(8), "loro".align(8)
  for (nome, a, b) in confronto:
    let segno = if abs(a - b) > 0.5: "  ←" else: ""
    echo nome.alignLeft(36), fmtNum(a).align(8), fmtNum(b).align(8), segno

nbText: """
Le differenze grandi: la testata (loro 32 sopra il piano letto, noi avevamo
deciso 58), il fronte più alto della stanza, le ribalte più basse e le ante in
basso più larghe e su uno zoccolo più alto. La nicchia dentro è più bassa (150
contro 159), ma l'apertura è quasi uguale.

## Cose che non tornano

Dai controlli del modello:
"""

nbCode:
  for c in controlli(f, m): echo "- ", c

nbText: """
## Letture e ipotesi da verificare

- **Altezza**: 60 + 1568 + 1568 fa 319.6, la stanza è 316. Forse hanno rimisurato;
  da chiedere.
- **Profondità**: con le ante davanti al fronte (le ante 755 coprono aperture da 715)
  e i mobili da 775 dietro, si arriva a 81.1. Se invece le ante stanno a filo nel
  fronte, si arriva a 79.3 e torna con gli 80: da chiedere.
- **622**: lo leggo come la profondità dei mobili davanti alla risega (il vano alto
  di destra e il mobile D); 775 per gli altri.
- **300** sul mobile dei gradini: non so a cosa si riferisca. L'ho fatto profondo
  come gli altri (77.5), così il pannellino lungo 67 ci sta dentro.
- **Pannellino**: Pietro lo chiama ribaltabile; dal disegno non capisco come si
  ribalta, nel visore esce dalla fessura verso chi guarda.
- **Il triangolo** fuori dalla libreria, a 277 da uno scaffale, e il taglio per il
  passaggio dei cavi: non li ho disegnati. La scatola delle prese non c'è nelle tavole.
- **Vani alti**: perché dentro siano a filo delle aperture del fronte devono
  stare 7.5 sopra il cassone; ho messo due listelli di rialzo (ipotesi).
- **Libreria**: appoggia sui mobili bassi; a destra del mobile D restano 12 cm
  senza niente sotto.
- **Rilevate in scala**: bordo basso della nicchia (137), fondo delle ribalte
  (270), spazio tra i frontali (4, torna con tutte le larghezze), zoccolo dei
  mobili (11.8), raggi (nicchia 5, aperture 3, frontali 2), fori maniglia (3) a 6
  cm dagli spigoli.

## Distinta
"""

nbCode:
  for r in bom(m):
    if r.kind in {kPanel, kFront, kBox}:
      echo $r.count & " × " & fmtNum(r.dims[0]) & " × " & fmtNum(r.dims[1]) & " × " &
        fmtNum(r.dims[2]) & "  " & r.name

nbSave
