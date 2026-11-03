import nimib, tema   # tema: stessi colori e caratteri degli artefatti
import std/[strformat, strutils]

nbInit(theme = useTema)
nb.title = "Come funziona Caderò"

nbText: """
# Come funziona Caderò

Caderò è un mini CAD scritto in Nim. Questa pagina lo spiega dal basso: ogni
blocco di codice qui sotto è stato eseguito per generare la pagina, e quello che
vedi sotto ogni blocco (testo o disegno) è il suo risultato.

L'idea di fondo sta in una riga:

> **un mobile è una funzione dei suoi parametri.**

Scrivi i parametri (misure), una funzione li trasforma in una lista di **parti**,
e tutto il resto (disegni, quote, 3D, distinta) legge quella lista. Cambi un
numero, rigeneri, e tutto si aggiorna insieme.

```
parametri ──► funzione del mobile ──► parti ──┬─► viste 2D + quote (SVG)
                                              ├─► vista 3D (three.js)
                                              └─► distinta dei pezzi
```

Il codice è diviso così:

| file | cosa contiene |
| --- | --- |
| `src/cadero/model.nim` | le parti (scatole), il mobile, la distinta |
| `src/cadero/drawing.nim` | proiezioni 2D, quote, foglio SVG |
| `src/cadero/web.nim` | esportazione JSON e vista 3D con three.js |
| `src/cadero.nim` | importa ed esporta i tre moduli |
| `models/parete.nim` | la parete con nicchia letto: parametri, funzione, quote, tavola |
| `docsrc/*.nim` | i documenti nimib, come questo |
| `tests/test_parete.nim` | controlli automatici sulle misure |

## 1. Assi e parti

Tutto è in centimetri. Gli assi sono quelli di chi guarda il mobile di fronte:

- **x**: larghezza, da sinistra a destra
- **y**: profondità, da 0 sul fronte verso il muro
- **z**: altezza, da 0 sul pavimento

Una **parte** (`Part`) è una scatola allineata agli assi: un angolo (`pos`, quello
con x, y, z più piccoli) e le dimensioni (`size`). Ha un nome e un tipo (`Kind`), che
decide come viene disegnata: un pannello, un frontale, un cassetto, un materasso,
un foro maniglia o un accessorio.
"""

nbCode:
  import cadero

  let fianco = part("fianco sinistro", kPanel,
                    x = 0, y = 0, z = 0,       # angolo in basso a sinistra davanti
                    w = 1.8, d = 40, h = 70)   # spessore, profondità, altezza
  echo fianco.name, ": ", fianco.size.x, " × ", fianco.size.y, " × ", fianco.size.z
  echo "finisce a x = ", fianco.x1, ", y = ", fianco.y1, ", z = ", fianco.z1

nbText: """
Le scatole bastano per quasi tutto un mobile di pannelli. Le due cose in più sono:

- **angoli arrotondati** visti di fronte (`r`), per ante e frontali;
- **aperture** (`holes`) nel pannello frontale: rettangoli arrotondati vuoti, come la
  nicchia e i gradini della parete.

## 2. Un mobile piccolo, a mano

Un `Model` è solo un nome e una lista di parti. Costruiamo un comodino: due fianchi,
cielo, fondo, schienale, un pannello frontale con un'apertura e un cassetto.
"""

nbCode:
  var m: Model
  m.name = "comodino"
  let s = 1.8
  m.add part("fianco sx", kPanel, 0, s, 0, s, 40 - s, 55)
  m.add part("fianco dx", kPanel, 45 - s, s, 0, s, 40 - s, 55)
  m.add part("fondo", kPanel, s, s, 0, 45 - 2*s, 40 - s, s)
  m.add part("cielo", kPanel, s, s, 55 - s, 45 - 2*s, 40 - s, s)
  m.add part("schienale", kPanel, s, 40 - s, s, 45 - 2*s, s, 55 - 2*s)
  var fronte = part("fronte", kPanel, 0, 0, 0, 45, s, 55)
  fronte.holes.add rrect(x = 6, z = 32, w = 33, h = 17, r = 4)   # vano a giorno
  m.add fronte
  m.add part("cassetto", kBox, 6, 0, 6, 33, 35, 20, r = 3)
  m.add part("foro", kKnob, 22.5, 0, 16, 3, 0, 3)
  echo m.parts.len, " parti"

nbText: """
## 3. Dalle scatole al disegno: le proiezioni

Un disegno tecnico è una **proiezione**: si butta via una coordinata.

- nel **prospetto frontale** si tiene (x, z) e si scarta la profondità y;
- nella **vista laterale** si tiene (y, z), con il fronte a sinistra;
- nella **pianta** si tiene (x, y), con il fronte in basso.

Così ogni scatola diventa un rettangolo. Una `View` dice quale proiezione usare e
dove mettere la sua origine sul foglio (`ox`, `oy`, in cm). Uno `Sheet` raccoglie
linee, rettangoli e testi e alla fine produce l'SVG; il foglio lavora in cm e il
browser lo scala.
"""

nbCode:
  var foglio = initSheet()
  foglio.draw(View(kind: vFront, ox: 0, oy: 0), m)
  foglio.draw(View(kind: vSide, cut: 100, ox: 75, oy: 0), m)
  foglio.draw(View(kind: vPlan, cut: 40, ox: 0, oy: 75), m)
  let svg1 = foglio.render(pxPerCm = 3)
nbRawHtml: svg1

nbText: """
Ogni vista decide cosa mostrare con regole semplici, scritte in `drawing.nim`:

- **prospetto**: il pannello frontale con le sue aperture, i frontali, i cassetti,
  i fori; le parti nascoste (come il divisorio della parete) solo se marcate
  `hiddenFront`, tratteggiate;
- **laterale**: è una *sezione* al piano x = `cut`, guardando verso sinistra:
  si vedono le parti tagliate e quelle oltre il taglio (x < `cut`);
- **pianta**: sezione orizzontale al piano z = `cut`: si disegnano le parti che
  quel piano attraversa, e il pannello frontale viene spezzato dove c'è un'apertura.

Non c'è un vero calcolo delle linee nascoste: per mobili di pannelli queste regole
bastano, e restano facili da leggere.

## 4. Le quote

Una quota è un oggetto a sé, una **catena** (`DimChain`): una linea con una serie di
punti (`stops`). Ogni coppia di punti vicini diventa una misura scritta. `at` dice
dove passa la linea di quota, `ext` da dove partono le linee di richiamo (di solito
il bordo del mobile). Il tratto obliquo agli estremi è quello dei disegni di
architettura.
"""

nbCode:
  var foglio2 = initSheet()
  let fr = View(kind: vFront)
  foglio2.draw(fr, m)
  foglio2.draw(fr, DimChain(view: vFront, vertical: true, at: -10, ext: 0,
                            stops: @[0.0, 6, 26, 32, 49, 55]))
  foglio2.draw(fr, DimChain(view: vFront, vertical: false, at: -8, ext: 0,
                            stops: @[0.0, 45]))
  let svg2 = foglio2.render(pxPerCm = 3)
nbRawHtml: svg2

nbText: """
Qui i numeri delle quote li ho scritti a mano, ed è proprio il difetto da evitare:
se cambio l'altezza del comodino, la quota resta vecchia. Il passo successivo
risolve il problema.

## 5. Il mobile come funzione

Mettiamo le misure in un oggetto di parametri e scriviamo una funzione che
costruisce il mobile **e** le sue quote dagli stessi numeri. Nella parete vera è
esattamente così: `rilievo()` dà i parametri, `parete(p)` le parti, `quote(p)` le
quote.
"""

nbCode:
  type Comodino = object
    larghezza, profondita, altezza, spessore: float
    margine, vano, cassetto: float     # catena verticale del fronte

  proc comodino(c: Comodino): Model =
    let s = c.spessore
    let (L, P, H) = (c.larghezza, c.profondita, c.altezza)
    result.name = "comodino"
    result.add part("fianco sx", kPanel, 0, s, 0, s, P - s, H)
    result.add part("fianco dx", kPanel, L - s, s, 0, s, P - s, H)
    result.add part("fondo", kPanel, s, s, 0, L - 2*s, P - s, s)
    result.add part("cielo", kPanel, s, s, H - s, L - 2*s, P - s, s)
    let zCass = c.margine
    let zVano = H - c.margine - c.vano
    var f = part("fronte", kPanel, 0, 0, 0, L, s, H)
    f.holes.add rrect(c.margine, zVano, L - 2*c.margine, c.vano, 4)
    result.add f
    result.add part("cassetto", kBox, c.margine, 0, zCass, L - 2*c.margine, P - 5, c.cassetto, 3)
    result.add part("foro", kKnob, L/2, 0, zCass + c.cassetto/2, 3, 0, 3)

  proc quoteComodino(c: Comodino): seq[DimChain] =
    let H = c.altezza
    @[DimChain(view: vFront, vertical: true, at: -10, ext: 0,
               stops: @[0.0, c.margine, c.margine + c.cassetto,
                        H - c.margine - c.vano, H - c.margine, H]),
      DimChain(view: vFront, vertical: false, at: -8, ext: 0,
               stops: @[0.0, c.larghezza])]

  proc prospetto(m: Model; q: seq[DimChain]; ox = 0.0): Sheet =
    result = initSheet()
    let v = View(kind: vFront, ox: ox)
    result.draw(v, m)
    for d in q: result.draw(v, d)

  let basso = Comodino(larghezza: 45, profondita: 40, altezza: 55, spessore: 1.8,
                       margine: 6, vano: 17, cassetto: 20)
  var alto = basso
  alto.altezza = 75          # più alto
  alto.larghezza = 38        # e più stretto
  alto.cassetto = 30

nbText: "A sinistra il comodino di partenza, a destra la variante: stesse regole, numeri diversi, quote sempre giuste."

nbCode:
  var f3 = prospetto(comodino(basso), quoteComodino(basso))
  let v2 = View(kind: vFront, ox: 75)
  f3.draw(v2, comodino(alto))
  for d in quoteComodino(alto): f3.draw(v2, d)
  let svg3 = f3.render(pxPerCm = 3)
nbRawHtml: svg3

nbText: """
Due cose da notare, perché valgono anche per la parete:

- alcune misure sono **parametri** (larghezza, cassetto), altre sono **calcolate**
  (dove sta il vano, quanto è largo il cassetto). Nella parete l'altezza totale non
  è nemmeno un parametro: è la somma della catena 6 + 95 + 30 + 122 + 12 + 43 + 8.
- i **vincoli** sono semplicemente formule scritte in avanti (`zVano = H - margine - vano`).
  I CAD grandi usano un risolutore numerico; per un mobile le formule bastano e si
  leggono meglio.

## 6. La parete vera

`models/parete.nim` segue lo stesso schema, con più parti. Ecco i passaggi chiave.
"""

nbCode:
  import parete

  let p = rilievo()
  echo "catena del fronte: ", p.catenaFronte
  echo "altezza (calcolata): ", fmtNum(p.altezza)
  echo "inizio colonna destra: ", fmtNum(p.xColonna)
  echo "libreria: da ", fmtNum(p.baseLibreria), " a ", fmtNum(p.cimaLibreria)

nbText: """
Le posizioni che il disegno non scrive sono ricavate da poche regole. Per esempio i
cinque gradini dividono la zona bassa alta 95 in parti uguali, lasciando 5.5 cm tra
l'uno e l'altro:
"""

nbCode:
  let hGradino = (p.zonaBassa - p.passoGradini * float(p.nGradini - 1)) / float(p.nGradini)
  echo "altezza di un gradino: ", fmtNum(hGradino)
  let wAlto = (p.larghezza - 2 * p.margineLato - 2 * p.gapAlti) / 3
  echo "larghezza di una ribalta alta: ", fmtNum(wAlto)

nbText: """
La funzione `parete(p)` usa queste formule per aggiungere le parti in gruppi:
pannello frontale con le aperture, struttura (fianchi, cielo, fondo, schienali,
divisorio aperto all'altezza della libreria), nicchia (piano letto, soffitto,
materasso), colonna destra (gavone, ripiani, prese), ribalte in alto e zona bassa.
`quote(p)` restituisce le catene di quote, `tavola(p, m)` dispone le tre viste.
"""

nbCode:
  let pm = parete(p)
  var conta: array[Kind, int]
  for q in pm.parts: inc conta[q.kind]
  for k in Kind:
    if conta[k] > 0: echo k, ": ", conta[k]
  let tav = tavola(p, pm)
nbRawHtml: tav

nbText: """
## 7. La distinta

`bom(m)` scorre le parti e conta insieme quelle dello stesso tipo con le stesse
misure (ordinate dalla più grande). È la base per una lista di taglio.
"""

nbCode:
  for r in bom(comodino(basso)):
    echo r.count, " × ", r.name, ": ", fmtNum(r.dims[0]), " × ", fmtNum(r.dims[1]), " × ", fmtNum(r.dims[2])

nbText: """
## 8. Il 3D

`toJson(m)` trasforma le parti in JSON; `viewer3d(m)` produce un pezzo di HTML che
carica three.js e disegna:

- le scatole come parallelepipedi;
- il pannello frontale come un profilo **estruso**, con le aperture e le sagome dei
  frontali ritagliate;
- frontali e cassetti come rettangoli arrotondati estrusi.

Gli assi cambiano nome: in three.js l'alto è y e la profondità va verso −z, quindi
(x, y, z) del CAD diventano (x, z, −y). Qui sotto il comodino; trascina per ruotare.
"""

nbRawHtml: viewer3d(comodino(basso), id = "comodino3d", height = 380)

nbText: """
## 9. Come si lavora

1. Cambi un parametro in `rilievo()` (o in un documento, come la variante in `index.nim`).
2. `nimble test` controlla che le quote tornino con la tavola (per esempio che la
   catena del fronte sia 0, 6, 101, 131, 253, 265, 308, 316).
3. `nimble docs` rigenera i documenti in `docs/`; su GitHub lo fa la CI e li pubblica
   su Pages.

Per aggiungere un mobile nuovo basta un file in `models/` con il suo oggetto di
parametri, la funzione che crea le parti e le sue quote, come il comodino qui sopra.
"""

nbSave
