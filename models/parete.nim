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
    # risega: il pilastro nel muro, dietro a destra, per tutta l'altezza.
    # La colonna destra è profonda solo profondita - sporgenza (73).
    risegaSporge*: float     ## quanto sporge dal muro verso la stanza (note di Pietro: 7)
    risegaLarga*: float      ## quanto è larga lungo la parete (note di Pietro: 38)
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
    profGradini*: float      ## profondità della scatola dietro ogni gradino (Pietro: 30 per ora)
    nCassettiBassi*: int     ## 3
    gapCassetti*: float      ## (rilevato: 4)
    # letto
    pianoLetto*: float       ## quota del piano letto: 104
    materasso*: array[3, float]   ## 190 x 78 x 17 su misura (80 non entra: tra fronte e muro ci sono 78.2)
    rete*: float             ## spazio tra piano e materasso (0: il materasso poggia sul piano)
    # nicchia
    sottoCassetti*: float    ## soffitto della nicchia sotto i cassetti alti (rilevato: 5)
    # testata e libreria-comodino: in testa al letto, dentro la colonna destra.
    # Decisioni (note di Pietro, dopo il confronto con i nonni):
    testata*: float          ## piano della testata (= comodino) sopra il piano letto: 55
                             ## (materasso 17 + 38 di schienale)
    profScaffali*: float     ## gli scaffali sopra il comodino sono meno profondi: 26
    nVani*: int              ## vani sopra il comodino, fino al soffitto della nicchia: 3
    altezzaLibri*: float     ## altezza utile minima di un vano per i libri (ipotesi: 25)
    # cassetti in basso
    profCassetti*: float     ## (rilevato: 75)
    cassettoAperto*: int     ## quale cassetto basso disegnare aperto (-1 nessuno)
    corsa*: float            ## di quanto esce (rilevato: 23)
    # variante: tavolino estraibile al posto dei primi gradini
    tavolino*: bool          ## false: mobile base
    gradiniTavolino*: int    ## quanti gradini, dal basso, stanno nel tavolino (Pietro: 3)
    profTavolino*: float     ## profondità del piano: chiuso, le gambe dietro arrivano
                             ## vicino al muro senza toccarlo (ipotesi: 76.8, 1.4 di gioco)
    corsaTavolino*: float    ## di quanto si estrae nel disegno: tutto (profTavolino + spessore);
                             ## davanti poggia sui fianchi, dietro sulle due gambe
    profCassettiTavolino*: float ## profondità dei cassetti-gradino del tavolino (ipotesi: 20,
                             ## meno delle scatole fisse, per lasciare spazio alle gambe)
    gambaTavolino*: float    ## larghezza delle gambe dietro, pannelli alti e sottili messi
                             ## di traverso, paralleli al frontale (ipotesi: 8)
    tavolinoAperto*: bool    ## disegnarlo estratto
    diamForo*: float         ## fori maniglia (ipotesi: 4)

proc rilievo*(): Parete =
  ## I parametri ricavati dal disegno di riferimento.
  Parete(
    larghezza: 237, profondita: 80, spessore: 1.8,
    margineBasso: 6, zonaBassa: 95, fascia: 30, nicchia: 122,
    stacco: 12, cassettiAlti: 43, margineAlto: 8,
    colonnaDx: 38.8, risegaSporge: 7, risegaLarga: 38,
    margineLato: 12.5, gapAlti: 3.75,
    nicchiaX: 16, nicchiaL: 165.5, raggioNicchia: 18, raggio: 3,
    colonneBasse: [71.0, 29, 52, 38.5], spaziBassi: [7.5, 5.5, 8.5],
    nGradini: 5, passoGradini: 5.5, profGradini: 30, nCassettiBassi: 3, gapCassetti: 4,
    pianoLetto: 104, materasso: [190.0, 78, 17], rete: 0,
    sottoCassetti: 5, testata: 55, profScaffali: 26, nVani: 3, altezzaLibri: 25,
    profCassetti: 75, cassettoAperto: 1, corsa: 23, diamForo: 4,
    tavolino: false, gradiniTavolino: 3, profTavolino: 76.8, corsaTavolino: 78.6,
    profCassettiTavolino: 20, gambaTavolino: 8, tavolinoAperto: false)

proc conTavolino*(p: Parete; aperto = true): Parete =
  ## La variante con il tavolino estraibile.
  result = p
  result.tavolino = true
  result.tavolinoAperto = aperto

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

proc profColonna*(p: Parete): float =
  ## 73: la colonna destra finisce contro la risega.
  p.profondita - p.risegaSporge

proc baseLibreria*(p: Parete): float =
  ## 159: il piano della testata, che fa da comodino.
  p.pianoLetto + p.testata

proc cimaLibreria*(p: Parete): float =
  ## 260: la libreria arriva fino al soffitto della nicchia.
  p.soffittoNicchia

proc profComodino*(p: Parete): float =
  ## 37.9: il piano della testata va dal piano del divisorio al fianco destro,
  ## quindi è a filo della risega.
  p.colonnaDx - p.spessore / 2

proc ripiani*(p: Parete): seq[float] =
  ## Quote dei ripiani (piano superiore) dalla base della libreria:
  ## nVani vani uguali tra il comodino e il cielo della libreria.
  let s = p.spessore
  let passo = (p.cimaLibreria - p.baseLibreria) / float(p.nVani)
  for i in 1 ..< p.nVani:
    result.add float(i) * passo + s / 2

proc vanoUtile*(p: Parete): float =
  ## Altezza libera di ciascun vano, tolti gli spessori.
  let s = p.spessore
  (p.cimaLibreria - p.baseLibreria - float(p.nVani) * s) / float(p.nVani)

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
  result.name = if p.tavolino: "Parete con nicchia letto e tavolino" else: "Parete con nicchia letto"

  # --- pannello frontale: un unico pannello con le aperture ---------------
  var fronte = part("fronte", kPanel, 0, 0, 0, L, s, H)
  fronte.holes.add rrect(p.nicchiaX, zNicchia, p.nicchiaL, p.nicchia, p.raggioNicchia)
  let cx = p.colonneX
  let hGradino = (p.zonaBassa - p.passoGradini * float(p.nGradini - 1)) / float(p.nGradini)
  let wG = p.colonneBasse[1]
  proc zGradino(i: int): float = zBasso + float(i) * (hGradino + p.passoGradini)
  # con la variante, i primi gradini stanno nel tavolino: il fronte ha
  # un'unica apertura che li contiene e arriva a terra, perché i fianchi del
  # tavolino scendono fino al pavimento
  let nT = if p.tavolino: p.gradiniTavolino else: 0
  let xT = cx[1] - s                       # il tavolino è largo quanto le scatole dei gradini
  let wT = wG + 2 * s
  let zT1 = zGradino(nT - 1) + hGradino + s   # il piano sta sopra l'ultimo gradino
  for i in nT ..< p.nGradini:
    fronte.holes.add rrect(cx[1], zGradino(i), wG, hGradino, p.raggio)
  if nT > 0:
    fronte.holes.add rrect(xT, 0, wT, zT1, 0)   # spigoli dritti: tondi solo i vani
  result.add fronte

  # dietro ogni gradino una scatola aperta sul davanti, come un cassetto senza
  # frontale: fondo (dove si appoggia il piede), cielo, due fianchi e schiena
  proc scatola(m: var Model; i: int; y, prof: float; gruppo = ""; fondo = true, cielo = true) =
    let z = zGradino(i)
    var parti: seq[Part]
    if fondo: parti.add part("fondo gradino", kPanel, cx[1] - s, y, z - s, wT, prof, s)
    if cielo: parti.add part("cielo gradino", kPanel, cx[1] - s, y, z + hGradino, wT, prof, s)
    parti.add part("fianco gradino", kPanel, cx[1] - s, y, z, s, prof, hGradino)
    parti.add part("fianco gradino", kPanel, cx[1] + wG, y, z, s, prof, hGradino)
    parti.add part("schiena gradino", kPanel, cx[1] - s, y + prof, z - s, wT, s, hGradino + 2 * s)
    for q in parti.mitems:
      q.gruppo = gruppo
      m.add q
  for i in nT ..< p.nGradini:
    result.scatola(i, s, p.profGradini)

  # --- variante: tavolino estraibile ---------------------------------------
  # Il frontale porta i primi gradini; dietro c'è il piano, nascosto dal frontale.
  # Davanti i gradini sono cassetti senza frontale: due fianchi da terra al
  # piano, un fondo in comune dietro e un pannello orizzontale sotto ogni
  # gradino. Dietro i cassetti non c'è altro: solo due gambe, pannelli alti e
  # sottili sotto il piano, così sotto la parte dietro c'è spazio per le gambe.
  if nT > 0:
    let y0 = if p.tavolinoAperto: -p.corsaTavolino else: 0.0
    let yB = y0 + s                          # dietro il frontale
    let pT = p.profTavolino
    let pC = p.profCassettiTavolino          # profondità dei cassetti-gradino
    let zP = zT1 - s                         # sotto il piano
    var t: seq[Part]
    var fr = part("frontale tavolino", kFront, xT, y0, 0, wT, s, zT1, 0)
    for i in 0 ..< nT:
      fr.holes.add rrect(cx[1], zGradino(i), wG, hGradino, p.raggio)
    t.add fr
    t.add part("piano tavolino", kPanel, xT, yB, zP, wT, pT, s)
    t.add part("fianco tavolino", kPanel, xT, yB, 0, s, pC + s, zP)
    t.add part("fianco tavolino", kPanel, xT + wT - s, yB, 0, s, pC + s, zP)
    t.add part("fondo cassetti", kPanel, xT + s, yB + pC, 0, wT - 2 * s, s, zP)
    for i in 0 ..< nT:
      t.add part("ripiano gradino", kPanel, xT + s, yB, zGradino(i) - s, wT - 2 * s, pC, s)
    # gambe di traverso agli angoli dietro: tengono il blocco anche di lato e
    # lasciano libero il fianco, da dove entrano le gambe di chi si siede
    for x in [xT, xT + wT - p.gambaTavolino]:
      t.add part("gamba tavolino", kPanel, x, yB + pT - s, 0, p.gambaTavolino, s, zP)
    for q in t.mitems:
      q.gruppo = "tavolino"
      result.add q

  # --- struttura -----------------------------------------------------------
  result.add part("fianco sx", kPanel, 0, s, 0, s, P - s, H)
  result.add part("fianco dx", kPanel, L - s, s, 0, s, p.profColonna - s, H)
  # il divisorio è aperto all'altezza della libreria: sotto fa da testata
  # il divisorio arriva fino al rivestimento della risega
  let pDiv = p.profColonna - 2 * s
  var divisorio = part("divisorio", kPanel, xCol - s / 2, s, 0, s, pDiv,
                       p.baseLibreria - s)
  divisorio.hiddenFront = true
  result.add divisorio
  var divisorioAlto = part("divisorio alto", kPanel, xCol - s / 2, s, p.cimaLibreria, s, pDiv,
                           H - s - p.cimaLibreria)
  divisorioAlto.hiddenFront = true
  result.add divisorioAlto
  result.add part("cielo", kPanel, s, s, H - s, L - 2 * s, P - s, s)
  # niente fondo sul pavimento e niente schienale: dietro c'è il muro con la
  # carta da parati, che nella nicchia si vede direttamente (Pietro)
  result.add part("muro (carta da parati)", kWall, 0, P, 0, L, 2, H)
  # la risega (muro, non è un pezzo da costruire) e il suo rivestimento a L,
  # per tutta l'altezza: la faccia larga è coperta dallo schienale della colonna,
  # che parte dal piano del divisorio; il bordo sottile (7 cm, verso la nicchia)
  # da un pannellino che si unisce allo schienale della colonna e arriva al muro
  result.add part("risega (muro)", kWall, L - p.risegaLarga, p.profColonna, 0,
                  p.risegaLarga, p.risegaSporge, H)
  result.add part("schienale colonna", kPanel, xCol - s / 2, p.profColonna - s, s,
                  p.colonnaDx - s / 2, s, H - 2 * s)
  result.add part("pannellino risega", kPanel, xCol - s / 2, p.profColonna, s,
                  s, p.risegaSporge, H - 2 * s)

  # --- nicchia letto -------------------------------------------------------
  let xInt = s                       # interno della campata sinistra
  let lInt = xCol - s / 2 - s
  # piano e soffitto della nicchia arrivano fino al muro
  result.add part("piano letto", kPanel, xInt, s, p.pianoLetto - s, lInt, P - s, s)
  result.add part("soffitto nicchia", kPanel, xInt, s, p.soffittoNicchia - s, lInt, P - s, s)
  let (mL, mP, mH) = (p.materasso[0], p.materasso[1], p.materasso[2])
  # contro il fronte; se è più largo dello spazio interno sporge dietro (vedi controlli)
  var mat = part("materasso", kSoft, xInt + (lInt - mL) / 2, s,
                 p.pianoLetto + p.rete, mL, mP, mH, r = 3)
  mat.hiddenFront = true
  result.add mat

  # --- colonna destra: gavone, comodino, libreria, prese --------------------
  let xc = xCol + s / 2                 # interno della colonna
  let lc = L - s - xc
  let pc = p.profColonna - 2 * s
  result.add part("fondo gavone", kPanel, xc, s, p.pianoLetto - s, lc, pc, s)
  # il piano della testata copre anche il divisorio: profondo 38 verso il letto
  let xCom = xCol - s / 2
  result.add part("piano testata (comodino)", kPanel, xCom, s, p.baseLibreria - s,
                  p.profComodino, pc, s)
  # scaffali meno profondi, appoggiati al fianco destro
  let xScaf = L - s - p.profScaffali
  for h in p.ripiani:
    result.add part("ripiano libreria", kPanel, xScaf, s, p.baseLibreria + h - s,
                    p.profScaffali, pc, s)
  result.add part("cielo libreria", kPanel, xCom, s, p.cimaLibreria - s, p.profComodino, pc, s)
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
    var cas = part("cassetto", kBox, cx[2], y, z, p.colonneBasse[2], p.profCassetti, hC, p.raggio)
    var foro = part("foro", kKnob, cx[2] + p.colonneBasse[2] / 2, y, z + hC / 2,
                    p.diamForo, 0, p.diamForo)
    if y < 0: (cas.gruppo = "cassetto"; foro.gruppo = "cassetto")
    result.add cas
    result.add foro
  result.add part("anta stretta", kFront, cx[3], 0, zBasso, p.colonneBasse[3], s, p.zonaBassa, p.raggio)
  result.add part("foro", kKnob, cx[3] + 10, 0, zTop - 12, p.diamForo, 0, p.diamForo)

proc controlli*(p: Parete): seq[string] =
  ## Le cose che non tornano: misure che non ci stanno o decisioni in conflitto.
  let s = p.spessore
  let interno = p.profondita - s               # tra fronte e muro (niente schienale)
  if p.materasso[1] > interno:
    result.add "materasso largo " & fmtNum(p.materasso[1]) & " ma tra fronte e muro ci sono " &
      fmtNum(interno) & " cm"
  let campata = p.xColonna - s / 2 - s
  if p.materasso[0] > campata:
    result.add "materasso lungo " & fmtNum(p.materasso[0]) & " ma la campata è " & fmtNum(campata)
  let schiena = p.testata - p.rete - p.materasso[2]
  if schiena < 38 or schiena > 40:
    result.add "la testata sporge " & fmtNum(schiena) & " cm sopra il materasso (deciso: 38-40)"
  if p.vanoUtile < p.altezzaLibri:
    result.add "i vani della libreria sono alti " & fmtNum(p.vanoUtile) &
      " cm: meno di " & fmtNum(p.altezzaLibri) & " per i libri"
  if abs(p.risegaLarga - p.profComodino) > 1:
    result.add "comodino profondo " & fmtNum(p.profComodino) & " ma la risega è larga " &
      fmtNum(p.risegaLarga) & ": non è a filo"
  if p.tavolino and s + p.profTavolino > p.profondita - 0.5:
    result.add "il tavolino chiuso arriva al muro"
  if p.tavolino and p.corsaTavolino > p.profTavolino + s + 0.01:
    result.add "il tavolino esce di " & fmtNum(p.corsaTavolino) & " ma è profondo solo " &
      fmtNum(p.profTavolino + s)
  if p.profScaffali >= p.profComodino:
    result.add "gli scaffali non sono meno profondi del comodino"

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
