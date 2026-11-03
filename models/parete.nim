## Parete attrezzata con nicchia letto rialzata.
##
## I parametri sono divisi in gruppi, un oggetto per gruppo (revisione di
## Pietro, 3 novembre 2026). Si parte dai vincoli del muro, che non si
## scelgono ma si misurano nella stanza; tutto il resto si misura da un
## riferimento (il muro, la base del letto, il soffitto della nicchia) e le
## misure che ne vengono fuori si calcolano, non si scrivono due volte.
## Le misure non scritte sul disegno di riferimento sono segnate "rilevato"
## (misurate in scala) o "ipotesi" (inventate, da verificare).

import std/math
import ../src/cadero

type
  VincoliMuro* = object
    ## Le misure della stanza: fisse, cambiano solo se rimisurando si trova
    ## altro. Sono misure massime: il mobile non ne esce.
    altezza*: float          ## altezza della stanza: 316
    larghezza*: float        ## larghezza della parete: 237
    profondita*: float       ## profondità massima: 80 (lì c'è la cornice della porta)
    risegaProf*: float       ## quanto sporge la risega dal muro: 7
    risegaLarga*: float      ## larghezza della risega: 38.8 (= la colonna destra del disegno)
    # manca il condizionatore: sul muro di sinistra sopra la porta, impedisce
    # alla ribalta in alto a sinistra di aprirsi del tutto (soluzione da definire)

  VincoliCostruzione* = object
    spessore*: float         ## pannelli in multistrato (ipotesi: 1.8)
    gioco*: float            ## gioco di montaggio verso muri e soffitto, per lato (ipotesi: 0)
    spazioMinimo*: float     ## spazio minimo tra due frontali vicini (Pietro: 4)

  AltezzeChiave* = object
    baseLetto*: float        ## dal pavimento alla cima del pannello su cui sta il materasso: 104
    nicchia*: float          ## dalla base letto al sotto del soffitto della nicchia: 159.2
    testata*: float          ## dalla base letto alla cima del piano della testata (comodino): 58

  Materasso* = object
    ## Centrato nella nicchia su tutti e due gli assi: il gioco si calcola.
    lunghezza*: float        ## quello che ci sta: 190 (Pietro: circa 180)
    larghezza*: float        ## non più di profondità − spessore: 78
    altezza*: float          ## 17

  Libreria* = object
    ## In testa al letto, nella colonna destra, sopra il comodino.
    scaffali*: int           ## n scaffali, n + 1 vani: 2 (fino a 3)
    vani*: seq[float]        ## altezze libere dei vani dal basso; 0 (o mancante) = libera.
                             ## Se ne fissano al massimo n: le libere si dividono il resto
    profScaffali*: float     ## profondità degli scaffali, uguale per tutti: 26.5
    vanoMinimo*: float       ## controllo: altezza minima di un vano per i libri (ipotesi: 25)
    risegaRivestita*: bool   ## rivestita da pannelli su faccia e bordo; no: tappezzata

  CorniceNicchia* = object
    ## L'apertura della nicchia nel pannello frontale, misurata dai riferimenti.
    sinistra*: float         ## dal muro di sinistra: 16
    destra*: float           ## dalla risega (o dal muro, vedi `destraDalMuro`): 16.7
    destraDalMuro*: bool     ## false: `destra` si misura dalla risega
    bassa*: float            ## dalla base letto: 27 (il bordo sopra il materasso si calcola)
    alta*: float             ## dal sotto del soffitto della nicchia: 10.2
    raggio*: float           ## (rilevato: 18)

  ZonaBassa* = object
    zoccolo*: float          ## 6
    altezzaAnte*: float      ## 95: ante, gradini e cassetti
    margineLato*: float      ## margine ai lati, lo stesso della zona alta (rilevato: 12.5)
    antaGrande*: float       ## larghezze dei frontali, da sinistra (rilevate)
    gradini*: float          ## 29
    cassetti*: float         ## 52
    antaStretta*: float      ## 38.5
    spazioGradini*: float    ## lo spazio a sinistra e a destra dei gradini: 6.5
                             ## (lo spazio tra cassetti e anta stretta si calcola)
    nGradini*: int           ## 5
    passoGradini*: float     ## spazio verticale tra i gradini (rilevato: 5.5)
    profGradini*: float      ## profondità della scatola dei gradini (Pietro: 30 per ora)
    nCassetti*: int          ## 3
    gapCassetti*: float      ## (rilevato: 4)
    profCassetti*: float     ## profondità dei cassetti e della scatola dell'anta grande (rilevato: 75)
    corsa*: float            ## di quanto escono i cassetti (ipotesi: 60)

  ZonaAlta* = object
    margineAlto*: float      ## dal soffitto della stanza alle ribalte: 8
    altezzaRibalta*: float   ## 43
    larghezzaRibalta*: float ## le tre ribalte sono uguali: 68 (lo spazio tra loro si calcola)

  Frontali* = object
    raggio*: float           ## raggio degli angoli dei frontali (rilevato: 3)
    diamForo*: float         ## fori maniglia (ipotesi: 4)

  Prese* = object
    ## La scatola con una schuko, due USB-C e l'interruttore della luce, contro il
    ## fianco destro vicino al fronte. Il cavo arriva dal muro a destra.
    sulComodino*: bool       ## false: appesa sotto il primo scaffale
    sporgenza*, lunghezza*, altezza*: float   ## ipotesi: 6 x 16 x 9 (placca a 4 moduli)

  Tavolino* = object
    ## Variante: un tavolino che si estrae al posto dei primi gradini.
    attivo*: bool
    gradini*: int            ## quanti gradini, dal basso, stanno nel tavolino (Pietro: 3)
    prof*: float             ## profondità del piano (ipotesi: 76.8, 1.4 di gioco dal muro)
    profCassetti*: float     ## dei cassetti-gradino (ipotesi: 20, lasciano spazio alle gambe)
    gamba*: float            ## larghezza delle due gambe dietro (ipotesi: 8)
    antina*: bool            ## un'antina sotto il piano che si ribalta a destra

  Disegno* = object
    ## Non è il mobile: cosa la tavola disegna aperto.
    cassettoAperto*: int     ## quale cassetto basso (-1 nessuno)
    tavolinoAperto*: bool
    antinaAperta*: bool      ## solo con il tavolino aperto

  Parete* = object
    muro*: VincoliMuro
    costruzione*: VincoliCostruzione
    altezze*: AltezzeChiave
    materasso*: Materasso
    libreria*: Libreria
    cornice*: CorniceNicchia
    bassa*: ZonaBassa
    alta*: ZonaAlta
    frontali*: Frontali
    prese*: Prese
    tavolino*: Tavolino
    disegno*: Disegno

proc rilievo*(): Parete =
  ## I parametri ricavati dal disegno di riferimento e dalle decisioni di Pietro.
  Parete(
    muro: VincoliMuro(altezza: 316, larghezza: 237, profondita: 80, risegaProf: 7, risegaLarga: 38.8),
    costruzione: VincoliCostruzione(spessore: 1.8, gioco: 0, spazioMinimo: 4),
    altezze: AltezzeChiave(baseLetto: 104, nicchia: 159.2, testata: 58),
    materasso: Materasso(lunghezza: 190, larghezza: 78, altezza: 17),
    libreria: Libreria(scaffali: 2, profScaffali: 26.5, vanoMinimo: 25, risegaRivestita: true),
    cornice: CorniceNicchia(sinistra: 16, destra: 16.7, bassa: 27, alta: 10.2, raggio: 18),
    bassa: ZonaBassa(zoccolo: 6, altezzaAnte: 95, margineLato: 12.5,
      antaGrande: 71, gradini: 29, cassetti: 52, antaStretta: 38.5, spazioGradini: 6.5,
      nGradini: 5, passoGradini: 5.5, profGradini: 30, nCassetti: 3, gapCassetti: 4,
      profCassetti: 75, corsa: 60),
    alta: ZonaAlta(margineAlto: 8, altezzaRibalta: 43, larghezzaRibalta: 68),
    frontali: Frontali(raggio: 3, diamForo: 4),
    prese: Prese(sulComodino: false, sporgenza: 6, lunghezza: 16, altezza: 9),
    tavolino: Tavolino(attivo: false, gradini: 3, prof: 76.8, profCassetti: 20, gamba: 8),
    disegno: Disegno(cassettoAperto: 1))

proc conTavolino*(p: Parete; aperto = true): Parete =
  ## La variante con il tavolino estraibile.
  result = p
  result.tavolino.attivo = true
  result.disegno.tavolinoAperto = aperto

# --- misure derivate ----------------------------------------------------------------
# Tutte calcolate dai parametri. Il mobile ha l'origine nel suo angolo in basso a
# sinistra sul fronte; i muri stanno a `gioco` di distanza.

proc spessore*(p: Parete): float = p.costruzione.spessore
proc larghezza*(p: Parete): float = p.muro.larghezza - 2 * p.costruzione.gioco
  ## 237: da muro a muro, meno il gioco
proc altezza*(p: Parete): float = p.muro.altezza - p.costruzione.gioco
  ## 316: da terra al soffitto, meno il gioco
proc profondita*(p: Parete): float = p.muro.profondita - p.costruzione.gioco
  ## 80: tutta la profondità possibile

proc pianoLetto*(p: Parete): float = p.altezze.baseLetto
proc sottoSoffitto*(p: Parete): float = p.altezze.baseLetto + p.altezze.nicchia
  ## 263.2: il sotto del soffitto della nicchia
proc soffittoNicchia*(p: Parete): float = p.sottoSoffitto + p.spessore
  ## 265: la cima del soffitto della nicchia, che fa da fondo ai vani alti
proc baseLibreria*(p: Parete): float = p.altezze.baseLetto + p.altezze.testata
  ## 162: la cima del piano della testata (il comodino)
proc cimaLibreria*(p: Parete): float = p.sottoSoffitto
  ## 263.2: la libreria arriva al soffitto della nicchia
proc sopraMaterasso*(p: Parete): float = p.altezze.baseLetto + p.materasso.altezza
proc schienale*(p: Parete): float = p.altezze.testata - p.materasso.altezza
  ## 41: quanto la testata sporge sopra il materasso

proc xRisega*(p: Parete): float = p.muro.larghezza - p.costruzione.gioco - p.muro.risegaLarga
  ## 198.2: dove comincia la risega, in coordinate del mobile
proc xDivisorio*(p: Parete): float = p.xRisega - p.spessore
  ## 196.4: il divisorio tra nicchia e colonna è a filo della risega (e del suo rivestimento)
proc colonnaDx*(p: Parete): float = p.larghezza - p.xDivisorio
  ## 40.6: dal divisorio al bordo destro; dentro, la colonna è larga quanto la risega
proc profColonna*(p: Parete): float = p.profondita - p.muro.risegaProf
  ## 73: la colonna destra finisce contro la risega
proc profComodino*(p: Parete): float = p.larghezza - p.spessore - p.xDivisorio
  ## 38.8: il piano della testata va dal divisorio al fianco destro, come la risega
proc campata*(p: Parete): float = p.xDivisorio - p.spessore
  ## 194.6: la nicchia dentro, dal fianco sinistro al divisorio
proc interno*(p: Parete): float = p.profondita - p.spessore
  ## 78.2: tra il pannello frontale e il muro (niente schienale)
proc giocoMaterasso*(p: Parete): (float, float) =
  ## Il gioco per lato del materasso centrato: in lunghezza e in larghezza.
  ((p.campata - p.materasso.lunghezza) / 2, (p.interno - p.materasso.larghezza) / 2)

# la nicchia
proc nicchiaX*(p: Parete): float = p.cornice.sinistra - p.costruzione.gioco
proc nicchiaFine*(p: Parete): float =
  ## 181.5: il bordo destro dell'apertura
  if p.cornice.destraDalMuro: p.larghezza + p.costruzione.gioco - p.cornice.destra
  else: p.xRisega - p.cornice.destra
proc nicchiaL*(p: Parete): float = p.nicchiaFine - p.nicchiaX
proc nicchiaZ*(p: Parete): float = p.altezze.baseLetto + p.cornice.bassa
  ## 131: il bordo in basso dell'apertura
proc nicchiaH*(p: Parete): float = p.altezze.nicchia - p.cornice.bassa - p.cornice.alta
  ## 122: l'altezza dell'apertura
proc bordo*(p: Parete): float = p.nicchiaZ - p.sopraMaterasso
  ## 10: il bordo davanti al materasso

# zona bassa e zona alta
proc fineBassa*(p: Parete): float = p.bassa.zoccolo + p.bassa.altezzaAnte
  ## 101: la cima dei frontali in basso
proc sottoLetto*(p: Parete): float = p.pianoLetto - p.spessore - p.fineBassa
  ## 1.2: aria tra i frontali in basso e il pannello del letto
proc ribaltaZ*(p: Parete): float = p.altezza - p.alta.margineAlto - p.alta.altezzaRibalta
  ## 265: il fondo delle ribalte
proc gapAlti*(p: Parete): float =
  ## 4: lo spazio tra le ribalte (il margine ai lati è quello della zona bassa)
  (p.larghezza - 2 * p.bassa.margineLato - 3 * p.alta.larghezzaRibalta) / 2
proc spazioCassetti*(p: Parete): float =
  ## 8.5: lo spazio tra cassetti e anta stretta, quello che resta
  let b = p.bassa
  p.larghezza - 2 * b.margineLato - b.antaGrande - b.gradini - b.cassetti - b.antaStretta -
    2 * b.spazioGradini
proc hGradino*(p: Parete): float =
  (p.bassa.altezzaAnte - p.bassa.passoGradini * float(p.bassa.nGradini - 1)) / float(p.bassa.nGradini)
proc hCassetto*(p: Parete): float =
  (p.bassa.altezzaAnte - p.bassa.gapCassetti * float(p.bassa.nCassetti - 1)) / float(p.bassa.nCassetti)
proc corsaTavolino*(p: Parete): float = p.tavolino.prof + p.spessore
  ## 78.6: il tavolino si estrae del tutto

proc catenaFronte*(p: Parete): seq[float] =
  ## Le quote verticali del prospetto: 0, 6, 101, 131, 253, 265, 308, 316.
  @[0.0, p.bassa.zoccolo, p.fineBassa, p.nicchiaZ, p.nicchiaZ + p.nicchiaH, p.ribaltaZ,
    p.ribaltaZ + p.alta.altezzaRibalta, p.altezza]

proc colonneX*(p: Parete): array[4, float] =
  ## Dove inizia ciascuna colonna della zona bassa: anta grande, gradini, cassetti, anta stretta.
  let b = p.bassa
  result[0] = b.margineLato
  result[1] = result[0] + b.antaGrande + b.spazioGradini
  result[2] = result[1] + b.gradini + b.spazioGradini
  result[3] = result[2] + b.cassetti + p.spazioCassetti

proc larghezzeBasse*(p: Parete): array[4, float] =
  [p.bassa.antaGrande, p.bassa.gradini, p.bassa.cassetti, p.bassa.antaStretta]

# la libreria
proc vaniFissati*(p: Parete): int =
  for v in p.libreria.vani:
    if v > 0: inc result

proc vani*(p: Parete): seq[float] =
  ## Le altezze libere degli n + 1 vani, dal basso. Quelle fissate restano (al
  ## massimo n: le altre in più non contano), le libere si dividono il resto.
  let n = max(p.libreria.scaffali, 0)
  let resto0 = p.cimaLibreria - p.baseLibreria - float(n) * p.spessore
  var fissi = newSeq[float](n + 1)
  var usati = 0
  for i in 0 .. n:
    if i < p.libreria.vani.len and p.libreria.vani[i] > 0 and usati < n:
      fissi[i] = p.libreria.vani[i]; inc usati
  var resto = resto0
  for v in fissi: resto -= v
  let libere = n + 1 - usati
  for i in 0 .. n:
    result.add(if fissi[i] > 0: fissi[i] else: resto / float(libere))

proc ripiani*(p: Parete): seq[float] =
  ## Quote dei ripiani (piano superiore) dalla base della libreria.
  var z = 0.0
  let v = p.vani
  for i in 0 ..< v.high:
    z += v[i] + p.spessore
    result.add z

proc vanoUtile*(p: Parete): float =
  ## Il vano più basso della libreria.
  result = Inf
  for v in p.vani: result = min(result, v)

proc parete*(p: Parete): Model =
  let s = p.spessore
  let H = p.altezza
  let L = p.larghezza
  let P = p.profondita
  let c = p.catenaFronte
  let zBasso = c[1]                 # 6: fondo dei frontali in basso
  let zNicchia = c[3]               # 131: base dell'apertura
  let zAlti = c[5]                  # 265: fondo delle ribalte
  let xDiv = p.xDivisorio           # 196.4: il divisorio, a filo della risega
  let g = p.costruzione.gioco
  result.name = if p.tavolino.attivo: "Parete con nicchia letto e tavolino" else: "Parete con nicchia letto"

  # --- pannello frontale: un unico pannello con le aperture ---------------
  var fronte = part("fronte", kPanel, 0, 0, 0, L, s, H)
  fronte.holes.add rrect(p.nicchiaX, zNicchia, p.nicchiaL, p.nicchiaH, p.cornice.raggio)
  let cx = p.colonneX
  let hGradino = p.hGradino
  let wG = p.bassa.gradini
  proc zGradino(i: int): float = zBasso + float(i) * (hGradino + p.bassa.passoGradini)
  # con la variante, i primi gradini stanno nel tavolino: il fronte ha
  # un'unica apertura che li contiene e arriva a terra, perché i fianchi del
  # tavolino scendono fino al pavimento
  let nT = if p.tavolino.attivo: p.tavolino.gradini else: 0
  let xT = cx[1] - s                       # il tavolino è largo quanto le scatole dei gradini
  let wT = wG + 2 * s
  let zT1 = zGradino(nT - 1) + hGradino + s   # il piano sta sopra l'ultimo gradino
  for i in nT ..< p.bassa.nGradini:
    fronte.holes.add rrect(cx[1], zGradino(i), wG, hGradino, p.frontali.raggio)
  if nT > 0:
    fronte.holes.add rrect(xT, 0, wT, zT1, 0)   # spigoli dritti: tondi solo i vani
  result.add fronte

  # dietro i gradini una scatola sola, che non sta sospesa: due fianchi da
  # terra (o da sopra il tavolino) al piano letto, un fondo dietro e un ripiano
  # sotto ogni gradino, dove si appoggia il piede; sopra l'ultimo gradino fa
  # da cielo il piano letto
  let zL = p.pianoLetto - s                # sotto il piano letto
  if nT < p.bassa.nGradini:
    let zB = if nT > 0: zGradino(nT) - s else: 0.0
    var sc: seq[Part]
    for xf in [cx[1] - s, cx[1] + wG]:
      sc.add part("fianco gradini", kPanel, xf, s, zB, s, p.bassa.profGradini + s, zL - zB)
    sc.add part("fondo gradini", kPanel, cx[1], s + p.bassa.profGradini, zB, wG, s, zL - zB)
    for i in nT ..< p.bassa.nGradini:
      sc.add part("ripiano gradino", kPanel, cx[1], s, zGradino(i) - s, wG, p.bassa.profGradini, s)
    for q in sc.mitems:
      q.gruppo = "scatola gradini"
      if q.name != "ripiano gradino": q.hiddenFront = true
      result.add q

  # --- variante: tavolino estraibile ---------------------------------------
  # Il frontale porta i primi gradini; dietro c'è il piano, nascosto dal frontale.
  # Davanti i gradini sono cassetti senza frontale: due fianchi da terra al
  # piano, un fondo in comune dietro e un pannello orizzontale sotto ogni
  # gradino. Dietro i cassetti non c'è altro: solo due gambe, pannelli alti e
  # sottili sotto il piano, così sotto la parte dietro c'è spazio per le gambe.
  if nT > 0:
    let y0 = if p.disegno.tavolinoAperto: -p.corsaTavolino else: 0.0
    let yB = y0 + s                          # dietro il frontale
    let pT = p.tavolino.prof
    let pC = p.tavolino.profCassetti          # profondità dei cassetti-gradino
    let zP = zT1 - s                         # sotto il piano
    var t: seq[Part]
    var fr = part("frontale tavolino", kFront, xT, y0, 0, wT, s, zT1, 0)
    for i in 0 ..< nT:
      fr.holes.add rrect(cx[1], zGradino(i), wG, hGradino, p.frontali.raggio)
    t.add fr
    t.add part("piano tavolino", kPanel, xT, yB, zP, wT, pT, s)
    t.add part("fianco tavolino", kPanel, xT, yB, 0, s, pC + s, zP)
    t.add part("fianco tavolino", kPanel, xT + wT - s, yB, 0, s, pC + s, zP)
    t.add part("fondo cassetti", kPanel, xT + s, yB + pC, 0, wT - 2 * s, s, zP)
    for i in 0 ..< nT:
      t.add part("ripiano gradino", kPanel, xT + s, yB, zGradino(i) - s, wT - 2 * s, pC, s)
    # gambe di traverso agli angoli dietro: tengono il blocco anche di lato e
    # lasciano libero il fianco, da dove entrano le gambe di chi si siede
    for x in [xT, xT + wT - p.tavolino.gamba]:
      t.add part("gamba tavolino", kPanel, x, yB + pT - s, 0, p.tavolino.gamba, s, zP)
    for q in t.mitems:
      q.apribile("tavolino", "tira", p.corsaTavolino)
      result.add q
    # variante: l'antina ribaltabile. Chiusa sta sotto il piano, solo dietro i
    # cassetti-gradino (tra il loro fondo e le gambe); è incernierata sullo
    # spigolo destro del piano e, con il tavolino estratto, si ribalta a destra
    # e si affianca al piano, alla stessa quota. Il fermo non è disegnato.
    if p.tavolino.antina:
      let ya = yB + pC + s + 0.5                # dietro il fondo dei cassetti
      let da = pT - pC - 2 * s - 1              # fino davanti alle gambe
      var a = if p.disegno.antinaAperta and p.disegno.tavolinoAperto:
          part("antina tavolino", kPanel, xT + wT, ya, zP, wT, da, s)
        else: part("antina tavolino", kPanel, xT, ya, zP - s, wT, da, s)
      a.apribile("antina tavolino", "ribalta dx")
      a.dentro = "tavolino"
      a.blocco = "tavolino"
      result.add a

  # --- struttura -----------------------------------------------------------
  # Dietro, ai lati, sopra e sotto c'è il muro: niente schienale, niente cielo,
  # niente fondo. Due soli pannelli lunghi orizzontali, da un fianco all'altro:
  # il piano letto, che sotto la testata fa da fondo al gavone, e il soffitto
  # della nicchia, che sopra fa da fondo ai vani alti. I fianchi sono spezzati
  # da questi due pannelli: tre per lato. Dietro a destra i pannelli lunghi
  # girano intorno alla risega con una tacca.
  let zA = zAlti - s                         # sotto il soffitto della nicchia
  # la risega è rivestita (pannello sulla faccia larga e pannellino lungo sul
  # bordo, spezzati anche loro dai pannelli lunghi) oppure scoperta e tappezzata.
  # yCol è dove finisce la colonna destra: la faccia della risega o il rivestimento
  let yCol = if not p.libreria.risegaRivestita: p.profColonna else: p.profColonna - s
  let xTacca = if not p.libreria.risegaRivestita: p.xRisega else: xDiv
  let tacca = rrect(xTacca, yCol, L - xTacca, P - yCol, 0)
  var pianoLetto = part("piano letto", kPanel, 0, s, zL, L, P - s, s)
  var soffitto = part("soffitto nicchia", kPanel, 0, s, zA, L, P - s, s)
  pianoLetto.taccheP.add tacca
  soffitto.taccheP.add tacca
  result.add pianoLetto
  result.add soffitto
  for (nome, z0, z1) in [("basso", 0.0, zL), ("medio", p.pianoLetto, zA), ("alto", zAlti, H)]:
    result.add part("fianco sx " & nome, kPanel, 0, s, z0, s, P - s, z1 - z0)
    result.add part("fianco dx " & nome, kPanel, L - s, s, z0, s, yCol - s, z1 - z0)
    if not not p.libreria.risegaRivestita:
      var sc = part("schienale colonna " & nome, kPanel, xTacca, yCol, z0, L - xTacca, s, z1 - z0)
      var pan = part("pannellino risega " & nome, kPanel, xTacca, yCol + s, z0, s, P - yCol - s, z1 - z0)
      sc.hiddenFront = true
      pan.hiddenFront = true
      result.add sc
      result.add pan
  # il divisorio tra nicchia e colonna: poggia sul piano letto, arriva alla
  # risega e porta il piano della testata
  var divisorio = part("divisorio", kPanel, xDiv, s, p.pianoLetto, s, yCol - s,
                       p.baseLibreria - s - p.pianoLetto)
  divisorio.hiddenFront = true
  result.add divisorio
  # il muro con la carta da parati, che nella nicchia si vede direttamente;
  # la risega (il pilastro nel muro), se scoperta, è tappezzata con cura anche lei
  result.add part("muro (carta da parati)", kWall, -g, P + g, 0, L + 2 * g, 2, H + g)
  result.add part(if not p.libreria.risegaRivestita: "risega (muro, carta da parati)" else: "risega (muro)", kWall, p.xRisega, p.profColonna, 0,
                  p.muro.risegaLarga, p.muro.risegaProf, H + g)

  # --- nicchia letto -------------------------------------------------------
  let xInt = s                       # interno della campata sinistra
  let lInt = p.campata
  let (mL, mP, mH) = (p.materasso.lunghezza, p.materasso.larghezza, p.materasso.altezza)
  # centrato su tutti e due gli assi: il gioco si calcola (vedi giocoMaterasso)
  var mat = part("materasso", kSoft, xInt + (lInt - mL) / 2, s + (p.interno - mP) / 2,
                 p.pianoLetto, mL, mP, mH, r = 3)
  mat.hiddenFront = true
  # nel visore il materasso esce dalla nicchia: sale sopra la fascia e poi
  # viene avanti fin fuori dal mobile, così da dentro la nicchia si vede tutto
  mat.apribile("materasso", "esce", P + 20)
  mat.alzata = c[3] - p.pianoLetto + 1
  result.add mat

  # --- colonna destra: gavone, comodino, libreria, prese --------------------
  let xc = xDiv + s                     # interno della colonna
  let lc = L - s - xc
  let pc = yCol - s                     # fino alla risega o al suo rivestimento
  # il piano della testata copre anche il divisorio: profondo 38 verso il letto
  let xCom = xDiv
  # il gavone: lo spazio chiuso sotto il comodino, con il fondo nel piano letto.
  # Ci si accede dall'alto: il piano del comodino ha un'apertura stondata in
  # cui appoggiano due coperchi leggeri, ognuno metà apertura, che si alzano.
  var com = part("piano testata (comodino)", kPanel, xCom, s, p.baseLibreria - s,
                 p.profComodino, pc, s)
  # la scatola delle prese, contro il fianco destro vicino al fronte, rivolta
  # verso il letto
  let (sp, lp, hp) = (p.prese.sporgenza, p.prese.lunghezza, p.prese.altezza)
  let xP = L - s - sp
  let yP = s + 2
  # se la scatola sta sul comodino, l'apertura del gavone si ferma 2 cm prima
  let fineG = if p.prese.sulComodino: xP - 2 else: xc + lc - 4
  let (xG, yG, dG) = (xc + 4, s + 6, pc - 12)   # l'apertura del gavone
  let wG2 = fineG - xG
  com.holesPiano.add rrect(xG, yG, wG2, dG, 4)
  result.add com
  for k in 0..1:
    var cop = part("coperchio gavone", kPanel, xG + 0.2, yG + 0.2 + float(k) * dG / 2,
                   p.baseLibreria - 1, wG2 - 0.4, dG / 2 - 0.4, 1, r = 4)
    cop.hiddenFront = true
    cop.apribile("coperchio " & $(k + 1), "alza", 14)
    result.add cop
  # scaffali meno profondi, appoggiati al fianco destro; il cielo della
  # libreria è il soffitto della nicchia
  let xScaf = L - s - p.libreria.profScaffali
  for h in p.ripiani:
    result.add part("ripiano libreria", kPanel, xScaf, s, p.baseLibreria + h - s,
                    p.libreria.profScaffali, pc, s)
  let zP = if p.prese.sulComodino: p.baseLibreria
           elif p.ripiani.len > 0: p.baseLibreria + p.ripiani[0] - s - hp
           else: p.sottoSoffitto - hp      # appesa sotto il primo scaffale
  result.add part("scatola prese (schuko, 2 USB-C, interruttore luce)", kAccessory,
                  xP, yP, zP, sp, lp, hp)

  # --- in alto: tre vani con ribalte che si alzano --------------------------
  # sotto il soffitto della nicchia, dietro e sopra il muro, ai lati i fianchi
  # alti, in mezzo due divisori dal soffitto della nicchia al muro
  let wAlto = p.alta.larghezzaRibalta
  let zS = p.soffittoNicchia               # i vani alti stanno sopra il soffitto della nicchia
  for i in 0..2:
    let x = p.bassa.margineLato + float(i) * (wAlto + p.gapAlti)
    if i > 0:
      var d = part("divisorio vani alti", kPanel, x - p.gapAlti / 2 - s / 2, s, zS, s, P - s, H - zS)
      d.hiddenFront = true
      result.add d
    var rib = part("ribalta alta", kFront, x, 0, zAlti, wAlto, s, p.alta.altezzaRibalta, p.frontali.raggio)
    var foro = part("foro", kKnob, x + wAlto / 2, 0, zAlti + p.alta.altezzaRibalta / 2,
                    p.frontali.diamForo, 0, p.frontali.diamForo)
    rib.apribile("ribalta " & $(i + 1), "su")
    foro.apribile("ribalta " & $(i + 1), "su")
    result.add rib
    result.add foro

  # --- zona bassa ----------------------------------------------------------
  let zTop = zBasso + p.bassa.altezzaAnte
  # dietro ogni anta una scatola aperta sul davanti: fianchi da terra fino al
  # piano letto (che fa da cielo), fondo sotto l'anta, schiena dietro
  # (le parti della scatola hanno lo stesso gruppo: nell'esploso restano insieme)
  proc scatolaAnta(m: var Model; nome: string; x, w, prof: float) =
    let zCielo = p.pianoLetto - s
    for xf in [x - s, x + w]:
      var f = part("fianco " & nome, kPanel, xf, s, 0, s, prof + s, zCielo)
      f.hiddenFront = true
      f.gruppo = "scatola " & nome
      m.add f
    var fo = part("fondo " & nome, kPanel, x, s, zBasso - s, w, prof, s)
    fo.gruppo = "scatola " & nome
    m.add fo
    var sc = part("schiena " & nome, kPanel, x, s + prof, zBasso, w, s, zCielo - zBasso)
    sc.hiddenFront = true
    sc.gruppo = "scatola " & nome
    m.add sc
  # anta a sinistra: si apre verso sinistra, dentro un ripiano a metà
  let wA = p.bassa.antaGrande
  result.scatolaAnta("anta", cx[0], wA, p.bassa.profCassetti)
  for k in 1..2:   # due ripiani, a un terzo e due terzi dell'altezza
    var rip = part("ripiano anta", kPanel, cx[0], s, zBasso + p.bassa.altezzaAnte * float(k) / 3 - s / 2,
                   wA, p.bassa.profCassetti - 2, s)
    rip.hiddenFront = true
    rip.gruppo = "scatola anta"
    result.add rip
  var anta = part("anta", kFront, cx[0], 0, zBasso, wA, s, p.bassa.altezzaAnte, p.frontali.raggio)
  var foroAnta = part("foro", kKnob, cx[0] + wA - 10, 0, zTop - 12, p.frontali.diamForo, 0, p.frontali.diamForo)
  anta.apribile("anta", "sx")
  foroAnta.apribile("anta", "sx")
  result.add anta
  result.add foroAnta
  # cassetti veri: frontale e, dietro, una cassa con fondo, fianchi e schiena.
  # Scorrono tra due fianchi fissi da terra al piano letto (le guide stanno
  # nel centimetro tra cassa e fianco, non le disegno)
  let hC = p.hCassetto
  let wC = p.bassa.cassetti
  for xf in [cx[2] - s, cx[2] + wC]:
    var f = part("fianco cassetti", kPanel, xf, s, 0, s, p.bassa.profCassetti, zL)
    f.hiddenFront = true
    f.gruppo = "fianchi cassetti"
    f.blocco = "cassetti"             # nell'esploso i cassetti restano tra i loro fianchi
    result.add f
  for i in 0 ..< p.bassa.nCassetti:
    let z = zTop - hC - float(i) * (hC + p.bassa.gapCassetti)
    let y = if i == p.disegno.cassettoAperto: -p.bassa.corsa else: 0.0
    let (xi, wi, hi, di) = (cx[2] + 1, wC - 2, hC - 3, p.bassa.profCassetti - s)   # la cassa, dietro il frontale
    var parti = @[
      part("frontale cassetto", kFront, cx[2], y, z, wC, s, hC, p.frontali.raggio),
      part("foro", kKnob, cx[2] + wC / 2, y, z + hC / 2, p.frontali.diamForo, 0, p.frontali.diamForo),
      part("fondo cassetto", kPanel, xi + s, y + s, z + 1, wi - 2 * s, di - s, s),
      part("fianco cassetto", kPanel, xi, y + s, z + 1, s, di, hi),
      part("fianco cassetto", kPanel, xi + wi - s, y + s, z + 1, s, di, hi),
      part("schiena cassetto", kPanel, xi + s, y + s + di - s, z + 1 + s, wi - 2 * s, s, hi - s)]
    for q in parti.mitems:
      if q.kind == kPanel: q.hiddenFront = true
      q.apribile("cassetto " & $(i + 1), "tira", p.bassa.corsa)
      q.blocco = "cassetti"
      result.add q
  # anta stretta sotto la colonna destra: si apre verso destra, dentro un
  # bastone appendiabiti da un fianco all'altro, a metà profondità
  let wD = p.bassa.antaStretta
  let profD = yCol - 2 * s               # la schiena davanti alla risega o al rivestimento
  result.scatolaAnta("anta stretta", cx[3], wD, profD)
  var bastone = part("bastone appendiabiti", kAccessory, cx[3], s + profD / 2 - 1.25,
                     p.pianoLetto - s - 7, wD, 2.5, 2.5)
  bastone.gruppo = "scatola anta stretta"
  result.add bastone
  var antaDx = part("anta stretta", kFront, cx[3], 0, zBasso, wD, s, p.bassa.altezzaAnte, p.frontali.raggio)
  var foroDx = part("foro", kKnob, cx[3] + 10, 0, zTop - 12, p.frontali.diamForo, 0, p.frontali.diamForo)
  antaDx.apribile("anta stretta", "dx")
  foroDx.apribile("anta stretta", "dx")
  result.add antaDx
  result.add foroDx

proc controlli*(p: Parete): seq[string] =
  ## Le cose che non tornano: misure che non ci stanno, decisioni in conflitto e
  ## i vincoli soft (schienale, bordo, vani, spazi tra i frontali).
  let s = p.spessore
  let (gL, gP) = p.giocoMaterasso
  if gP < 0:
    result.add "materasso largo " & fmtNum(p.materasso.larghezza) & " ma tra fronte e muro ci sono " &
      fmtNum(p.interno) & " cm"
  if gL < 0:
    result.add "materasso lungo " & fmtNum(p.materasso.lunghezza) & " ma la campata è " & fmtNum(p.campata)
  if p.schienale < 40:
    result.add "lo schienale sporge " & fmtNum(p.schienale) & " cm sopra il materasso: meno di 40"
  if p.bordo < 16:
    result.add "il bordo davanti al materasso è alto " & fmtNum(p.bordo) & " cm: meno di 16"
  if p.sottoLetto < 0:
    result.add "i frontali in basso entrano di " & fmtNum(-p.sottoLetto) & " cm nel piano letto"
  if p.vaniFissati > p.libreria.scaffali:
    result.add "fissate " & $p.vaniFissati & " altezze di vano su " & $(p.libreria.scaffali + 1) &
      ": al massimo " & $p.libreria.scaffali & " (le altre non contano)"
  if p.vanoUtile < p.libreria.vanoMinimo:
    result.add "un vano della libreria è alto " & fmtNum(p.vanoUtile) & " cm: meno di " &
      fmtNum(p.libreria.vanoMinimo) & " per i libri"
  let sm = p.costruzione.spazioMinimo
  if p.gapAlti < sm:
    result.add "tra le ribalte restano " & fmtNum(p.gapAlti) & " cm: meno di " & fmtNum(sm)
  if p.spazioCassetti < sm:
    result.add "tra cassetti e anta stretta restano " & fmtNum(p.spazioCassetti) & " cm: meno di " & fmtNum(sm)
  if p.nicchiaX < s or p.nicchiaFine > p.xDivisorio:
    result.add "l'apertura della nicchia (da " & fmtNum(p.nicchiaX) & " a " & fmtNum(p.nicchiaFine) &
      ") esce dalla campata (da " & fmtNum(s) & " a " & fmtNum(p.xDivisorio) & ")"
  if p.nicchiaH <= 0:
    result.add "la nicchia non ha apertura: cornice bassa + alta supera l'altezza della nicchia"
  if p.ribaltaZ < p.soffittoNicchia - 0.05:
    result.add "le ribalte scendono di " & fmtNum(p.soffittoNicchia - p.ribaltaZ) &
      " cm sotto la cima del soffitto della nicchia"
  if p.ribaltaZ < p.nicchiaZ + p.nicchiaH:
    result.add "le ribalte scendono sull'apertura della nicchia"
  if p.tavolino.attivo:
    if s + p.tavolino.prof > p.profondita - 0.5:
      result.add "il tavolino chiuso arriva al muro"
    if p.tavolino.gradini >= p.bassa.nGradini:
      result.add "il tavolino ha tutti i gradini: ne serve almeno uno fisso sopra"
  if p.libreria.profScaffali >= p.profComodino:
    result.add "gli scaffali non sono meno profondi del comodino"

proc fuoriMuro*(p: Parete; m: Model): seq[string] =
  ## Le parti del mobile chiuso che escono dai vincoli del muro (non dovrebbe
  ## succedere: le misure partono dal muro).
  for q in m.parts:
    if q.kind in {kWall, kSoft} or (q.gruppo != "" and q.pos.y < 0): continue   # il materasso: controlli
    if q.pos.x < -0.01 or q.x1 > p.larghezza + 0.01 or q.pos.z < -0.01 or
       q.z1 > p.altezza + 0.01 or q.y1 > p.profondita + 0.01:
      result.add q.name & " esce dal muro"
    elif q.taccheP.len == 0 and q.x1 > p.xRisega + 0.01 and q.y1 > p.profColonna + 0.01:
      result.add q.name & " entra nella risega"

proc fuoriLastra*(m: Model; lastra = [300.0, 150.0]): seq[string] =
  ## I pezzi che non si ricavano da una lastra di multistrato (ipotesi: 300 x 150,
  ## il formato grande più comune; c'è anche 250 x 125): vanno divisi.
  for r in bom(m):
    if r.kind notin {kPanel, kFront}: continue
    if r.dims[0] > lastra[0] + 0.01 or r.dims[1] > lastra[1] + 0.01:
      result.add r.name & " " & fmtNum(r.dims[0]) & " x " & fmtNum(r.dims[1]) &
        ": non sta in una lastra " & fmtNum(lastra[0]) & " x " & fmtNum(lastra[1])

proc quote*(p: Parete): seq[DimChain] =
  ## Le stesse quote della tavola di riferimento, ricavate dai parametri,
  ## più quelle della libreria (ripiani e profondità degli scaffali).
  let H = p.altezza
  let xMat = p.spessore + p.giocoMaterasso[0]
  var libreria = @[p.baseLibreria]
  for h in p.ripiani: libreria.add p.baseLibreria + h
  libreria.add p.soffittoNicchia
  @[
    # prospetto frontale
    DimChain(view: vFront, vertical: true, at: -22, ext: 0, stops: p.catenaFronte),
    DimChain(view: vFront, vertical: true, at: -52, ext: -22, stops: @[0.0, H]),
    DimChain(view: vFront, vertical: false, at: -12, ext: 0, stops: @[0.0, p.larghezza]),
    # vista laterale
    DimChain(view: vSide, vertical: true, at: -26, ext: 0,
             stops: @[0.0, p.pianoLetto, p.baseLibreria, p.soffittoNicchia, H]),
    DimChain(view: vSide, vertical: true, at: p.profondita + 40, ext: p.profondita,
             stops: @[0.0, p.pianoLetto, p.nicchiaZ]),
    # i ripiani della libreria: dal piano del comodino al piano di ogni
    # ripiano e a quello del soffitto della nicchia, un passo uguale
    DimChain(view: vSide, vertical: true, at: p.profondita + 40, ext: p.profColonna,
             stops: libreria),
    DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, p.profondita]),
    # pianta
    DimChain(view: vPlan, vertical: false, at: p.profondita + 18, ext: p.profondita,
             stops: @[0.0, p.xRisega, p.larghezza]),
    DimChain(view: vPlan, vertical: false, at: p.profondita / 2 - 14, ext: p.profondita / 2 - 14,
             stops: @[xMat, xMat + p.materasso.lunghezza]),
    DimChain(view: vPlan, vertical: true, at: 60, ext: 60, stops: @[0.0, p.profondita]),
    # la profondità degli scaffali della libreria, misurata verso il letto
    DimChain(view: vPlan, vertical: false, at: -10, ext: 0,
             stops: @[p.larghezza - p.spessore - p.libreria.profScaffali, p.larghezza - p.spessore]),
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
