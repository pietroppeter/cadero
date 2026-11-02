## Parete attrezzata con nicchia letto rialzata.
##
## Le misure vengono dal disegno di riferimento (scala 1:25). Quelle che il
## disegno non scrive le ho rilevate in scala e sono segnate "rilevato";
## quelle inventate sono segnate "ipotesi".

import ../src/cadero

type
  Parete* = object
    # ingombro
    larghezza*: float        ## 237
    profondita*: float       ## 80
    spessore*: float         ## pannelli in multistrato (ipotesi: 1.8)
    # catena verticale del fronte, dal basso: la somma è l'altezza totale
    margineBasso*: float     ## 6
    zonaBassa*: float        ## 95, ante, gradini e cassetti
    fascia*: float           ## 30, fascia davanti al materasso
    nicchia*: float          ## 122, apertura della nicchia
    stacco*: float           ## 12
    cassettiAlti*: float     ## 43
    margineAlto*: float      ## 8
    # divisione orizzontale
    colonnaDx*: float        ## 38.8, colonna a destra
    profColonna*: float      ## profondità della colonna destra (rilevato in pianta: 73)
    margineLato*: float      ## distanza dei frontali dai bordi (rilevato: 12.5)
    gapAlti*: float          ## spazio tra i cassetti alti (rilevato: 3.75)
    nicchiaX*: float         ## inizio della nicchia da sinistra (rilevato: 16)
    nicchiaL*: float         ## larghezza della nicchia (rilevato: 165.5)
    raggioNicchia*: float    ## (rilevato: 18)
    raggio*: float           ## raggio degli altri frontali (rilevato: 3)
    # zona bassa: quattro colonne, larghezze e spazi tra di loro (rilevati)
    colonneBasse*: array[4, float]   ## anta, gradini, cassetti, anta stretta
    spaziBassi*: array[3, float]
    nGradini*: int           ## 5
    passoGradini*: float     ## spazio verticale tra i gradini (rilevato: 5.5)
    nCassettiBassi*: int     ## 3
    gapCassetti*: float      ## (rilevato: 4)
    # letto
    pianoLetto*: float       ## quota del piano letto: 104
    materasso*: array[3, float]   ## 190 x 78 x 18 (spessore rilevato dal tratteggio)
    rete*: float             ## spazio tra piano e materasso (ipotesi: 2)
    # nicchia
    sottoCassetti*: float    ## soffitto della nicchia sotto i cassetti alti (rilevato: 5)
    # testata e libreria: in testa al letto, dentro la colonna destra (schizzo)
    testata*: float          ## altezza della testata sopra il piano letto: 32
    ripiani*: seq[float]     ## altezze dei ripiani dalla base della libreria (rilevati: 41, 85, 107)
    # cassetti in basso
    profCassetti*: float     ## (rilevato: 75)
    cassettoAperto*: int     ## quale cassetto basso disegnare aperto (-1 nessuno)
    corsa*: float            ## di quanto esce (rilevato: 23)
    diamForo*: float         ## fori maniglia (ipotesi: 4)

proc rilievo*(): Parete =
  ## I parametri ricavati dal disegno di riferimento.
  Parete(
    larghezza: 237, profondita: 80, spessore: 1.8,
    margineBasso: 6, zonaBassa: 95, fascia: 30, nicchia: 122,
    stacco: 12, cassettiAlti: 43, margineAlto: 8,
    colonnaDx: 38.8, profColonna: 73,
    margineLato: 12.5, gapAlti: 3.75,
    nicchiaX: 16, nicchiaL: 165.5, raggioNicchia: 18, raggio: 3,
    colonneBasse: [71.0, 29, 52, 38.5], spaziBassi: [7.5, 5.5, 8.5],
    nGradini: 5, passoGradini: 5.5, nCassettiBassi: 3, gapCassetti: 4,
    pianoLetto: 104, materasso: [190.0, 78, 18], rete: 2,
    sottoCassetti: 5, testata: 32, ripiani: @[41.0, 85, 107],
    profCassetti: 75, cassettoAperto: 1, corsa: 23, diamForo: 4)

proc altezza*(p: Parete): float =
  ## L'altezza non è un parametro: è la somma della catena del fronte.
  p.margineBasso + p.zonaBassa + p.fascia + p.nicchia + p.stacco +
    p.cassettiAlti + p.margineAlto

proc catenaFronte*(p: Parete): seq[float] =
  ## Le quote verticali del prospetto: 0, 6, 101, 131, 253, 265, 308, 316.
  result = @[0.0]
  for v in [p.margineBasso, p.zonaBassa, p.fascia, p.nicchia, p.stacco,
            p.cassettiAlti, p.margineAlto]:
    result.add result[^1] + v

proc soffittoNicchia*(p: Parete): float =
  ## 260 nella vista laterale: poco sotto i cassetti alti.
  p.catenaFronte[5] - p.sottoCassetti

proc baseLibreria*(p: Parete): float =
  ## 136: la libreria parte sopra la testata.
  p.pianoLetto + p.testata

proc cimaLibreria*(p: Parete): float =
  ## 264: la libreria arriva fin sotto i cassetti alti (128 cm nello schizzo).
  p.catenaFronte[5] - 1

proc xColonna*(p: Parete): float = p.larghezza - p.colonnaDx

proc colonneX*(p: Parete): array[4, float] =
  ## Dove inizia ciascuna colonna della zona bassa.
  var x = p.margineLato
  for i in 0..3:
    result[i] = x
    if i < 3: x += p.colonneBasse[i] + p.spaziBassi[i]

proc parete*(p: Parete): Model =
  let s = p.spessore
  let H = p.altezza
  let L = p.larghezza
  let P = p.profondita
  let c = p.catenaFronte
  let zBasso = c[1]                 # 6: fondo dei frontali in basso
  let zNicchia = c[3]               # 131: base dell'apertura
  let zAlti = c[5]                  # 265: fondo dei cassetti alti
  let xCol = p.xColonna             # 198.2
  result.name = "Parete con nicchia letto"

  # --- pannello frontale: un unico pannello con le aperture ---------------
  var fronte = part("fronte", kPanel, 0, 0, 0, L, s, H)
  fronte.holes.add rrect(p.nicchiaX, zNicchia, p.nicchiaL, p.nicchia, p.raggioNicchia)
  let cx = p.colonneX
  let hGradino = (p.zonaBassa - p.passoGradini * float(p.nGradini - 1)) / float(p.nGradini)
  for i in 0 ..< p.nGradini:
    let z = zBasso + float(i) * (hGradino + p.passoGradini)
    fronte.holes.add rrect(cx[1], z, p.colonneBasse[1], hGradino, p.raggio)
  result.add fronte

  # --- struttura -----------------------------------------------------------
  result.add part("fianco sx", kPanel, 0, s, 0, s, P - s, H)
  result.add part("fianco dx", kPanel, L - s, s, 0, s, p.profColonna - s, H)
  # il divisorio è aperto all'altezza della libreria: sotto fa da testata
  var divisorio = part("divisorio", kPanel, xCol - s / 2, s, s, s, P - s, p.baseLibreria - s)
  divisorio.hiddenFront = true
  result.add divisorio
  var divisorioAlto = part("divisorio alto", kPanel, xCol - s / 2, s, p.cimaLibreria, s, P - s,
                           H - s - p.cimaLibreria)
  divisorioAlto.hiddenFront = true
  result.add divisorioAlto
  result.add part("cielo", kPanel, s, s, H - s, L - 2 * s, P - s, s)
  result.add part("fondo", kPanel, s, s, 0, L - 2 * s, P - s, s)
  result.add part("schienale", kPanel, s, P - s, s, xCol - 1.5 * s, s, H - 2 * s)
  result.add part("schienale colonna", kPanel, xCol + s / 2, p.profColonna - s, s,
                  p.colonnaDx - 1.5 * s, s, H - 2 * s)

  # --- nicchia letto -------------------------------------------------------
  let xInt = s                       # interno della campata sinistra
  let lInt = xCol - s / 2 - s
  result.add part("piano letto", kPanel, xInt, s, p.pianoLetto - s, lInt, P - 2 * s, s)
  result.add part("soffitto nicchia", kPanel, xInt, s, p.soffittoNicchia - s, lInt, P - 2 * s, s)
  let (mL, mP, mH) = (p.materasso[0], p.materasso[1], p.materasso[2])
  var mat = part("materasso", kSoft, xInt + (lInt - mL) / 2, (P - mP) / 2,
                 p.pianoLetto + p.rete, mL, mP, mH, r = 3)
  mat.hiddenFront = true
  result.add mat

  # --- colonna destra: gavone, libreria, prese -----------------------------
  let xc = xCol + s / 2                 # interno della colonna
  let lc = L - s - xc
  let pc = p.profColonna - 2 * s
  result.add part("fondo gavone", kPanel, xc, s, p.pianoLetto - s, lc, pc, s)
  result.add part("coperchio gavone", kPanel, xc, s, p.baseLibreria - s, lc, pc, s)
  for h in p.ripiani:
    result.add part("ripiano libreria", kPanel, xc, s, p.baseLibreria + h - s, lc, pc, s)
  result.add part("cielo libreria", kPanel, xc, s, p.cimaLibreria, lc, pc, s)
  result.add part("prese (2 USB-C, 1 schuko)", kAccessory, xc + lc - 14, s, p.baseLibreria + 8,
                  12, 0.6, 7)

  # --- cassetti alti -------------------------------------------------------
  let wAlto = (L - 2 * p.margineLato - 2 * p.gapAlti) / 3
  for i in 0..2:
    let x = p.margineLato + float(i) * (wAlto + p.gapAlti)
    result.add part("frontale cassetto alto", kFront, x, 0, zAlti, wAlto, s, p.cassettiAlti, p.raggio)
    result.add part("foro", kKnob, x + wAlto / 2, 0, zAlti + p.cassettiAlti / 2,
                    p.diamForo, 0, p.diamForo)

  # --- zona bassa ----------------------------------------------------------
  let zTop = zBasso + p.zonaBassa
  result.add part("anta", kFront, cx[0], 0, zBasso, p.colonneBasse[0], s, p.zonaBassa, p.raggio)
  result.add part("foro", kKnob, cx[0] + p.colonneBasse[0] - 10, 0, zTop - 12,
                  p.diamForo, 0, p.diamForo)
  let hC = (p.zonaBassa - p.gapCassetti * float(p.nCassettiBassi - 1)) / float(p.nCassettiBassi)
  for i in 0 ..< p.nCassettiBassi:
    let z = zTop - hC - float(i) * (hC + p.gapCassetti)
    let y = if i == p.cassettoAperto: -p.corsa else: 0.0
    result.add part("cassetto", kBox, cx[2], y, z, p.colonneBasse[2], p.profCassetti, hC, p.raggio)
    result.add part("foro", kKnob, cx[2] + p.colonneBasse[2] / 2, y, z + hC / 2,
                    p.diamForo, 0, p.diamForo)
  result.add part("anta stretta", kFront, cx[3], 0, zBasso, p.colonneBasse[3], s, p.zonaBassa, p.raggio)
  result.add part("foro", kKnob, cx[3] + 10, 0, zTop - 12, p.diamForo, 0, p.diamForo)

proc quote*(p: Parete): seq[DimChain] =
  ## Le stesse quote della tavola di riferimento, ricavate dai parametri.
  let H = p.altezza
  let m = p.materasso
  @[
    # prospetto frontale
    DimChain(view: vFront, vertical: true, at: -22, ext: 0, stops: p.catenaFronte),
    DimChain(view: vFront, vertical: true, at: -52, ext: -22, stops: @[0.0, H]),
    DimChain(view: vFront, vertical: false, at: -12, ext: 0, stops: @[0.0, p.larghezza]),
    # vista laterale
    DimChain(view: vSide, vertical: true, at: -26, ext: 0,
             stops: @[0.0, p.pianoLetto, p.baseLibreria, p.cimaLibreria, H]),
    DimChain(view: vSide, vertical: true, at: p.profondita + 40, ext: p.profondita,
             stops: @[0.0, p.pianoLetto, p.margineBasso + p.zonaBassa + p.fascia]),
    DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, p.profondita]),
    # pianta
    DimChain(view: vPlan, vertical: false, at: p.profondita + 18, ext: p.profondita,
             stops: @[0.0, p.xColonna, p.larghezza]),
    DimChain(view: vPlan, vertical: false, at: p.profondita / 2 - 14, ext: p.profondita / 2 - 14,
             stops: @[(p.xColonna - m[0]) / 2, (p.xColonna + m[0]) / 2]),
    DimChain(view: vPlan, vertical: true, at: 60, ext: 60, stops: @[0.0, p.profondita]),
  ]

proc tavola*(p: Parete; m: Model): string =
  ## Il foglio con le tre viste disposte come nel disegno di riferimento.
  let views = [
    View(kind: vFront, ox: 0, oy: 0),
    View(kind: vSide, cut: 230, ox: p.larghezza + 110, oy: 0),
    View(kind: vPlan, cut: 200, ox: 0, oy: 40 + p.profondita),
  ]
  var s = initSheet()
  for v in views:
    s.draw(v, m)
    for d in p.quote:
      if d.view == v.kind: s.draw(v, d)
  let last = views[2]
  s.label(last, p.larghezza + p.profondita + 160, -10, "SCALA 1 : 25 @ A4")
  s.render()
