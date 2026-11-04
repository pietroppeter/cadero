## La parete come l'hanno disegnata i falegnami (7 tavole SketchUp, 3 novembre 2026).
##
## Stessa stanza e stesse idee della nostra parete (`models/parete.nim`), ma
## divisa nei mobili che loro costruiscono, ognuno con le sue misure:
##
## - il fronte: quattro pannelli 112.5 × 156.8, una fascia in alto, due spalle ai lati
## - tre vani alti, scatole aperte con la ribalta (quella di sinistra tagliata a 15:
##   si apre solo la parte destra, per il condizionatore)
## - il cassone del letto, la libreria in testa al letto con il gavone sotto
## - quattro mobili bassi: A con ripiani, B con i gradini (e il pannellino che esce
##   dalla fessura), C con tre cassetti, D con l'appenderia
##
## Le misure sono in cm, come nel resto di Caderò (le loro sono in mm). Quelle
## scritte sulle tavole sono segnate "disegno"; quelle misurate in scala
## "rilevato"; le altre "ipotesi". Le scatole grigie dei disegni le leggo come
## melaminico da 19 mm (si vede dalle misure: 500 fuori, 462 dentro); le parti a
## vista color legno come multistrato da 18 (libreria: 635 fuori, 599 dentro).
##
## Assi come sempre: x da sinistra, y dal fronte verso il muro, z da terra.
## In profondità: ante e ribalte stanno davanti al pannello frontale (lo coprono
## di 2 cm per lato), il pannello frontale dietro di loro, i mobili dietro il fronte.

import std/strutils
import ../src/cadero
import parete   # i vincoli del muro e il materasso sono gli stessi

type
  Falegnami* = object
    muro*: VincoliMuro
    materasso*: Materasso
    sMulti*: float           ## multistrato a vista: fronte, ante, cassone, libreria, gradini (18 mm)
    sMel*: float             ## melaminico delle scatole grigie (19 mm)
    sSchiena*: float         ## la schiena sottile dei vani alti e dei mobili bassi: 0.8 (ipotesi:
                             ## non è sulle tavole, Pietro la vuole; grigia, color legno nei gradini)
    # --- il fronte
    spalla*: float           ## le due spalle ai lati, da cima a fondo: 5.9 (disegno: 59)
    pannelloL*, pannelloH*: float   ## i quattro pannelli: 112.5 × 156.8 (disegno)
    fascia*: float           ## la fascia in alto, sopra i pannelli: 6 (disegno: 60)
    spazio*: float           ## tra due frontali vicini: 4 (rilevato; torna con tutte le larghezze)
    sormonto*: float         ## quanto ante e ribalte coprono l'apertura, per lato: 2
                             ## (disegno: ante 755, aperture 715)
    sormontoCassetti*: float ## sopra e sotto i cassetti: 1 (frontali 290, aperture 270)
    raggioAperture*, raggioFrontali*, raggioNicchia*: float   ## rilevati: 3, 2, 5
    diamForo*: float         ## fori maniglia: 3 (rilevato)
    # --- la nicchia nel fronte
    nicchiaZ*: float         ## il bordo in basso dell'apertura, da terra: 135.3, dedotto
                             ## perché il bordo alto sia a filo del cielo del cassone
                             ## (in scala sul prospetto si legge circa 137)
    nicchiaL*, nicchiaH*: float     ## 156.7 × 121.9 (disegno)
    # --- la zona bassa del fronte
    zBassi*: float           ## fondo di ante, cassetti e gradini, da terra: 12 (disegno: 120)
    altezzaAnte*: float      ## 95 (disegno)
    antaA*, cassetti*, antaD*: float   ## larghezze dei frontali: 75.5, 50.2, 50.2 (disegno)
    hCassetto*: float        ## 29 (disegno); lo spazio tra i cassetti si calcola
    nCassetti*: int          ## 3
    gradini*: seq[float]     ## le altezze delle aperture dei gradini, dal basso:
                             ## 15.8, 15.8, 14.3, 14.3, 15.8 (disegno)
    spazioGradini*: float    ## tra un gradino e l'altro: 4 (rilevato)
    pannello*: bool          ## il pannellino che esce dalla fessura tra il 3° e il 4° gradino
    fessura*: float          ## l'altezza della fessura: 3 (rilevato); sopra e sotto c'è `spazioGradini` / 2
    lungPannello*: float     ## 67 (disegno)
    # --- la zona alta del fronte
    zRibalte*: float         ## fondo delle ribalte, da terra: 263.3, dedotto perché la
                             ## cima della ribalta sia a filo della cima delle scatole
                             ## (Pietro); in scala sul prospetto si legge circa 270
    ribaltaL*, ribaltaH*: float   ## 68.3 × 36.6 (disegno)
    parteFissa*: float       ## la ribalta di sinistra è tagliata: 15 fissi a sinistra (disegno)
    # --- i mobili
    hBassi*: float           ## i quattro mobili bassi: alti 109 (disegno)
    zoccolo*: float          ## sotto il fondo dei mobili bassi: 11.8 (rilevato: 118)
    mobileA*, mobileB*, mobileC*, mobileD*: float   ## larghezze: 75.3, 28.6, 50, 50 (disegno)
    profGradini*: float      ## il mobile B dei gradini è profondo solo 30 (disegno: 300, confermato
                             ## da Pietro): dietro resta spazio libero sotto il cassone
    prof*: float             ## profondità dei mobili: 77.5 (disegno: 775)
    profRisega*: float       ## quelli davanti alla risega: 62.2 (disegno: 622)
    interno*: float          ## il cassone del letto dentro: 193 (disegno: 1930)
    hNicchia*: float         ## il cassone fuori, dal sotto del piano letto alla cima del
                             ## cielo: 150, come la libreria accanto (Pietro: alte uguali)
    profLibreria*, hLibreria*: float   ## 63.5 × 150 (disegno)
    gavone*: float           ## il frontale del gavone, verso il letto: 32 (disegno)
    comodino*: float         ## profondità del piano sopra il gavone: 38 (disegno)
    scaffali*: float         ## profondità degli scaffali: 27 (disegno)
    nScaffali*: int          ## 3
    vanoL*, vanoH*: float    ## i tre vani alti: 68.1 × 40.9 (disegno)

proc falegnami*(): Falegnami =
  ## Le misure delle tavole dei falegnami.
  let r = rilievo()
  var mat = r.materasso
  mat.larghezza = 77   # Pietro: nel cassone da 77.5
  Falegnami(muro: r.muro, materasso: mat, sMulti: 1.8, sMel: 1.9, sSchiena: 0.8,
    spalla: 5.9, pannelloL: 112.5, pannelloH: 156.8, fascia: 6, spazio: 4,
    sormonto: 2, sormontoCassetti: 1, raggioAperture: 3, raggioFrontali: 2, raggioNicchia: 5,
    diamForo: 3,
    nicchiaZ: 135.3, nicchiaL: 156.7, nicchiaH: 121.9,
    zBassi: 12, altezzaAnte: 95, antaA: 75.5, cassetti: 50.2, antaD: 50.2,
    hCassetto: 29, nCassetti: 3, gradini: @[15.8, 15.8, 14.3, 14.3, 15.8], spazioGradini: 4,
    pannello: true, fessura: 3, lungPannello: 67,
    zRibalte: 263.3, ribaltaL: 68.3, ribaltaH: 36.6, parteFissa: 15,
    hBassi: 109, zoccolo: 11.8, mobileA: 75.3, mobileB: 28.6, mobileC: 50, mobileD: 50,
    profGradini: 30,
    prof: 77.5, profRisega: 62.2, interno: 193, hNicchia: 150,
    profLibreria: 63.5, hLibreria: 150, gavone: 32, comodino: 38, scaffali: 27, nScaffali: 3,
    vanoL: 68.1, vanoH: 40.9)

proc senzaPannello*(f: Falegnami): Falegnami =
  ## La variante senza il pannellino: niente fessura, i gradini si ridistribuiscono.
  result = f
  result.pannello = false

# --- misure derivate --------------------------------------------------------------
proc larghezza*(f: Falegnami): float = 2 * f.spalla + 2 * f.pannelloL
  ## 236.8: spalle e pannelli
proc altezza*(f: Falegnami): float = 2 * f.pannelloH + f.fascia
  ## 319.6: due pannelli e la fascia
proc yFronte*(f: Falegnami): float = f.sMulti
  ## 1.8: il pannello frontale sta dietro ante e ribalte
proc yMobili*(f: Falegnami): float = 2 * f.sMulti
  ## 3.6: i mobili cominciano dietro il pannello frontale
proc profondita*(f: Falegnami): float = f.yMobili + f.prof
  ## 81.1: dal davanti delle ante al dietro dei mobili
proc xFronte*(f: Falegnami): float = f.spalla
proc aperturaGradini*(f: Falegnami): float = f.mobileB - 2 * f.sMulti
  ## 25: le aperture dei gradini sono larghe quanto il mobile B dentro
proc margine*(f: Falegnami): float =
  ## 6.05: ai lati dei frontali in basso (e in alto), quello che resta
  (2 * f.pannelloL - f.antaA - f.aperturaGradini - f.cassetti - f.antaD - 3 * f.spazio) / 2
proc margineAlto*(f: Falegnami): float = (2 * f.pannelloL - 3 * f.ribaltaL - 2 * f.spazio) / 2
  ## 6.05: ai lati delle ribalte
proc spazioCassetti*(f: Falegnami): float =
  ## 4: tra i cassetti, quello che resta nell'altezza delle ante
  (f.altezzaAnte - float(f.nCassetti) * f.hCassetto) / float(f.nCassetti - 1)
proc colonne*(f: Falegnami): array[4, float] =
  ## dove cominciano i frontali in basso, da sinistra: anta A, gradini, cassetti, anta D
  result[0] = f.xFronte + f.margine
  result[1] = result[0] + f.antaA + f.spazio
  result[2] = result[1] + f.aperturaGradini + f.spazio
  result[3] = result[2] + f.cassetti + f.spazio
proc pianoLetto*(f: Falegnami): float = f.hBassi + f.sMulti
  ## 110.8: il cassone appoggia sui mobili bassi
proc cieloNicchia*(f: Falegnami): float = f.hBassi + f.hNicchia - f.sMulti
  ## 257.2: il sotto del cielo del cassone; la cima (259) è a filo della libreria
proc fondoVani*(f: Falegnami): float = f.cieloNicchia + f.sMulti
  ## 262.6: i vani alti sono scatole appoggiate sul cielo del cassone (Pietro)
proc scalinoVani*(f: Falegnami): float = f.zRibalte + f.sormonto - f.fondoVani - f.sMel
  ## 7.5: di quanto il dentro dei vani alti sta sotto il bordo dell'apertura
proc pianoComodino*(f: Falegnami): float = f.hBassi + f.gavone + f.sMulti
  ## 142.8: la cima del piano sopra il gavone
proc bordo*(f: Falegnami): float = f.nicchiaZ - f.pianoLetto - f.materasso.altezza
  ## 9.2: il fronte sopra il materasso
proc schienale*(f: Falegnami): float = f.pianoComodino - f.pianoLetto - f.materasso.altezza
  ## 15: la testata (il gavone) sopra il materasso
proc xLibreria*(f: Falegnami): float = f.larghezza - f.sMulti - f.comodino - 0.2
  ## 196.8: la libreria arriva al muro di destra, dietro ha la sua schiena
proc xRisega*(f: Falegnami): float = f.muro.larghezza - f.muro.risegaLarga
proc yRisega*(f: Falegnami): float = f.muro.profondita - f.muro.risegaProf

proc zGradini*(f: Falegnami): seq[float] =
  ## il fondo di ogni apertura dei gradini. Con il pannellino, tra il 3° e il 4°
  ## c'è la fessura (con mezzo spazio sopra e sotto); senza, lo spazio tra i
  ## gradini si calcola perché arrivino in cima alle ante
  let n = f.gradini.len
  var tot = 0.0
  for h in f.gradini: tot += h
  let g = if f.pannello: f.spazioGradini
          else: (f.altezzaAnte - tot) / float(n - 1)
  var z = f.zBassi
  for i, h in f.gradini:
    result.add z
    z += h + g
    if f.pannello and i == 2: z += f.fessura   # la fessura, con mezzo spazio sopra e sotto
proc zFessura*(f: Falegnami): float =
  ## il fondo della fessura del pannellino: sopra il 3° gradino, a mezzo spazio
  let z = f.zGradini
  z[2] + f.gradini[2] + f.spazioGradini / 2

proc catenaFronte*(f: Falegnami): seq[float] =
  ## le quote verticali del prospetto
  @[0.0, f.zBassi, f.zBassi + f.altezzaAnte, f.nicchiaZ, f.nicchiaZ + f.nicchiaH, f.zRibalte,
    f.zRibalte + f.ribaltaH, 2 * f.pannelloH, f.altezza]

proc zScaffali*(f: Falegnami): seq[float] =
  ## il sotto di ogni scaffale della libreria: passo uguale tra il piano del
  ## comodino e il cielo della libreria
  let sm = f.sMulti
  let top = f.hBassi + f.hLibreria - sm
  let passo = (top - f.pianoComodino - float(f.nScaffali) * sm) / float(f.nScaffali + 1)
  for k in 1 .. f.nScaffali:
    result.add f.pianoComodino + float(k) * passo + float(k - 1) * sm

proc xRibalte*(f: Falegnami): seq[float] =
  ## dove comincia ogni ribalta dei vani alti, da sinistra
  for i in 0..2:
    result.add f.xFronte + f.margineAlto + float(i) * (f.ribaltaL + f.spazio)

proc xSezione*(f: Falegnami): float =
  ## dove taglia la sezione laterale della tavola: nella libreria, a metà degli scaffali
  f.larghezza - f.sMulti - f.scaffali / 2

proc pannelloRisega*(f: Falegnami): float = f.profondita - (f.yMobili + f.profLibreria - f.sMulti)
  ## 15.8: il pannello che copre la risega, dal fianco dietro della libreria al dietro del mobile
proc yMuro*(f: Falegnami): float = max(f.muro.profondita, f.profondita)
  ## dove si disegna il muro: i mobili arrivano a 81.1, oltre gli 80 della stanza

# --- le modifiche che vorremmo (Pietro, 4 novembre 2026) --------------------------
const larghezzaPannelloRisega* = 10.0
  ## il pannello che copre la risega, nel modello rivisto: 10 invece di 15.8
const rimaVani* = 3.0
  ## nella proposta per i vani alti: il fronte che resta sopra l'apertura, sotto la fascia

proc rivisto*(f: Falegnami): Falegnami =
  ## Il modello rivisto: senza il pannellino estraibile (non lo vogliamo), la
  ## testata della libreria alta 58 dal piano letto (gavone 58 invece di 32) con
  ## uno scaffale in meno, e il pannello della risega largo 10: la libreria si fa
  ## più profonda (69.3 invece di 63.5) e arriva quasi alla risega.
  result = f
  result.pannello = false
  result.gavone = 58
  result.nScaffali = 2
  # il pannello va dal fianco dietro della libreria (y0 + pl - sm) al dietro del
  # mobile (profondità): perché sia largo 10, pl = profondità - 10 - y0 + sm
  result.profLibreria = f.profondita - larghezzaPannelloRisega - f.yMobili + f.sMulti

proc vaniAlti*(f: Falegnami): Falegnami =
  ## La proposta per aprire di più i vani alti: il fronte alto quanto la stanza
  ## (2 pannelli da 155 + la fascia da 6 = 316, invece di 2 × 156.8 + 6 = 319.6),
  ## le scatole alte fino alla fascia (51 invece di 40.9), le ribalte che partono
  ## da dove partono oggi e arrivano a 1 cm dalla fascia: apertura 41.7 invece di 32.6.
  result = f
  result.pannelloH = (f.muro.altezza - f.fascia) / 2
  let cima = 2 * result.pannelloH                 # 310: sotto la fascia
  result.vanoH = cima - f.fondoVani               # 51
  result.ribaltaH = cima - rimaVani + f.sormonto - f.zRibalte   # 45.7

# --- le aperture del fronte -----------------------------------------------------------
proc aperture*(f: Falegnami): seq[RRect] =
  ## Tutte le aperture del pannello frontale, prima di dividerlo nei quattro pezzi.
  let (so, sc, ra) = (f.sormonto, f.sormontoCassetti, f.raggioAperture)
  let c = f.colonne
  let zA = f.zBassi + so
  let hA = f.altezzaAnte - 2 * so
  # la nicchia, allineata a sinistra con l'anta A e la prima ribalta
  result.add rrect(c[0], f.nicchiaZ, f.nicchiaL, f.nicchiaH, f.raggioNicchia)
  # in basso: anta A, i gradini (e la fessura), i cassetti, l'anta D
  result.add rrect(c[0] + so, zA, f.antaA - 2 * so, hA, ra)
  for i, z in f.zGradini:
    result.add rrect(c[1], z, f.aperturaGradini, f.gradini[i], ra)
  if f.pannello:
    result.add rrect(c[1], f.zFessura, f.aperturaGradini, f.fessura, 0)
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    result.add rrect(c[2] + so, z + sc, f.cassetti - 2 * so, f.hCassetto - 2 * sc, ra)
  result.add rrect(c[3] + so, zA, f.antaD - 2 * so, hA, ra)
  # in alto: i tre vani
  for i in 0..2:
    let x = f.xFronte + f.margineAlto + float(i) * (f.ribaltaL + f.spazio)
    result.add rrect(x + so, f.zRibalte + so, f.ribaltaL - 2 * so, f.ribaltaH - 2 * so, ra)

# --- il modello ---------------------------------------------------------------------
proc modello*(f: Falegnami): Model =
  let (sm, sl) = (f.sMulti, f.sMel)
  let L = f.larghezza
  let H = f.altezza
  let y0 = f.yMobili
  let c = f.colonne
  result.name = "Parete dei falegnami" & (if f.pannello: "" else: " (senza pannellino)")
  proc aggiungi(m: var Model; parti: var seq[Part]; blocco: string; mel = false) =
    ## le parti di un mobile: nell'esploso restano insieme
    for q in parti.mitems:
      q.blocco = blocco
      if mel: q.materiale = "melaminico"
      m.add q

  # --- il fronte: quattro pannelli, la fascia, le spalle -----------------------
  # la nicchia e il vano alto di mezzo passano da un pannello all'altro: nei
  # pezzi diventano tacche del contorno (vedi `pannelloForato`)
  let fori = f.aperture
  for (nome, i, j) in [("basso sx", 0, 0), ("basso dx", 1, 0), ("alto sx", 0, 1), ("alto dx", 1, 1)]:
    result.add pannelloForato("fronte " & nome, f.xFronte + float(i) * f.pannelloL, f.yFronte,
                              float(j) * f.pannelloH, f.pannelloL, sm, f.pannelloH, fori)
  for q in [part("fronte fascia", kPanel, f.xFronte, f.yFronte, 2 * f.pannelloH, 2 * f.pannelloL, sm, f.fascia),
            part("fronte spalla sx", kPanel, 0, f.yFronte, 0, f.spalla, sm, H),
            part("fronte spalla dx", kPanel, L - f.spalla, f.yFronte, 0, f.spalla, sm, H)]:
    var q = q
    q.contorno = @[(q.pos.x, q.pos.z), (q.x1, q.pos.z), (q.x1, q.z1), (q.pos.x, q.z1)]   # per le viste
    result.add q

  # --- frontali: ante, cassetti, ribalte --------------------------------------
  let d = f.diamForo
  proc frontale(m: var Model; nome, gruppo, apre: string; x, z, w, h, fx, fz: float; corsa = 0.0) =
    var a = part(nome, kFront, x, 0, z, w, sm, h, f.raggioFrontali)
    var foro = part("foro", kKnob, fx, 0, fz, d, 0, d)
    a.apribile(gruppo, apre, corsa)
    foro.apribile(gruppo, apre, corsa)
    m.add a
    m.add foro
  let zTop = f.zBassi + f.altezzaAnte
  result.frontale("anta A", "anta A", "sx", c[0], f.zBassi, f.antaA, f.altezzaAnte,
                  c[0] + f.antaA - 6, zTop - 6)
  result.frontale("anta D", "anta D", "dx", c[3], f.zBassi, f.antaD, f.altezzaAnte, c[3] + 6, zTop - 6)
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    result.frontale("frontale cassetto", "cassetto " & $(f.nCassetti - i), "tira", c[2], z, f.cassetti,
                    f.hCassetto, c[2] + f.cassetti / 2, z + f.hCassetto - 6, 60)
  for i in 0..2:
    let x = f.xFronte + f.margineAlto + float(i) * (f.ribaltaL + f.spazio)
    if i == 0:
      # tagliata per il condizionatore: a sinistra un pezzo fisso, si apre il resto
      var fisso = part("ribalta, parte fissa", kFront, x, 0, f.zRibalte, f.parteFissa, sm, f.ribaltaH,
                       f.raggioFrontali)
      result.add fisso
      let xa = x + f.parteFissa + 0.3
      let wa = f.ribaltaL - f.parteFissa - 0.3
      result.frontale("ribalta", "ribalta 1", "su", xa, f.zRibalte, wa, f.ribaltaH,
                      xa + wa / 2, f.zRibalte + 6)
    else:
      result.frontale("ribalta", "ribalta " & $(i + 1), "su", x, f.zRibalte, f.ribaltaL, f.ribaltaH,
                      x + f.ribaltaL / 2, f.zRibalte + 6)

  # --- i mobili bassi -------------------------------------------------------------
  # scatole senza schiena (dietro c'è il muro), centrate dietro il loro frontale;
  # i fianchi arrivano a terra, il fondo sta sopra lo zoccolo
  # dietro, tra i fianchi, una schiena sottile dal fondo al cielo; fondo e cielo
  # arrivano davanti alla schiena
  let ss = f.sSchiena
  proc scatola(nome: string; x, w, h, p, s, zFondo: float; z0 = 0.0): seq[Part] =
    for xf in [x, x + w - s]:
      var fi = part("fianco " & nome, kPanel, xf, y0, z0, s, p, h)
      fi.hiddenFront = true
      result.add fi
    result.add part("fondo " & nome, kPanel, x + s, y0, zFondo, w - 2 * s, p - ss, s)
    result.add part("cielo " & nome, kPanel, x + s, y0, z0 + h - s, w - 2 * s, p - ss, s)
    var sc = part("schiena " & nome, kPanel, x + s, y0 + p - ss, zFondo, w - 2 * s, ss, z0 + h - zFondo)
    sc.hiddenFront = true
    result.add sc
  let xA = c[0] + (f.antaA - f.mobileA) / 2
  var a = scatola("mobile A", xA, f.mobileA, f.hBassi, f.prof, sl, f.zoccolo)
  let zIn = f.zoccolo + sl
  let passoA = (f.hBassi - sl - zIn - 2 * sl) / 3
  for k in 1..2:   # due ripiani mobili, a passo uguale
    a.add part("ripiano mobile A", kPanel, xA + sl, y0, zIn + float(k) * passoA + float(k - 1) * sl,
               f.mobileA - 2 * sl, f.prof - ss - 2, sl)
  result.aggiungi(a, "mobile A", mel = true)

  # B: i gradini, in multistrato a vista. Sotto ogni apertura un piano, dove si
  # appoggia il piede; con il pannellino, la fessura ha un piano sotto
  let xB = c[1] - sm
  var b = scatola("mobile B", xB, f.mobileB, f.hBassi, f.profGradini, sm, f.zBassi - sm)
  b.delete(2)   # il fondo: è il piano del primo gradino, sotto
  if f.pannello:
    # la schiena dei gradini si apre all'altezza della fessura: il pannellino
    # chiuso passa dietro, nello spazio libero
    let sc = b.pop()
    let (zs0, zs1) = (f.zFessura, f.zFessura + f.fessura)
    var sotto = sc
    sotto.size.z = zs0 - sc.pos.z
    var sopra = sc
    sopra.pos.z = zs1
    sopra.size.z = sc.z1 - zs1
    b.add sotto
    b.add sopra
  let zg = f.zGradini
  for i, z in zg:
    b.add part("piano gradino", kPanel, xB + sm, y0, z - sm, f.aperturaGradini, f.profGradini - ss, sm)
  if f.pannello:
    b.add part("piano sotto la fessura", kPanel, xB + sm, y0, f.zFessura - sm, f.aperturaGradini, f.profGradini - ss, sm)
  result.aggiungi(b, "mobile B")
  if f.pannello:
    # il pannellino, dentro la fessura: esce verso chi guarda. È più lungo del mobile
    # B (67 contro 30): chiuso rientra nello spazio libero dietro, sotto il cassone
    var pa = part("pannellino estraibile", kFront, c[1] + 0.2, 0, f.zFessura + (f.fessura - sm) / 2,
                  f.aperturaGradini - 0.4, f.lungPannello, sm)
    pa.apribile("pannellino", "tira", f.lungPannello - 12)
    result.add pa

  # C: tre cassetti veri tra i fianchi del mobile
  let xC = c[2] + (f.cassetti - f.mobileC) / 2
  var cc = scatola("mobile C", xC, f.mobileC, f.hBassi, f.prof, sl, f.zoccolo)
  result.aggiungi(cc, "mobile C", mel = true)
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    let (xi, wi, hi, di) = (xC + sl + 1.3, f.mobileC - 2 * sl - 2.6, f.hCassetto - 2 * f.sormontoCassetti - 4, 70.0)
    var parti = @[
      part("fondo cassetto", kPanel, xi + sm, sm, z + f.sormontoCassetti + 1, wi - 2 * sm, di - sm, sm),
      part("fianco cassetto", kPanel, xi, sm, z + f.sormontoCassetti + 1, sm, di, hi),
      part("fianco cassetto", kPanel, xi + wi - sm, sm, z + f.sormontoCassetti + 1, sm, di, hi),
      part("schiena cassetto", kPanel, xi + sm, sm + di - sm, z + f.sormontoCassetti + 1, wi - 2 * sm, sm, hi)]
    for q in parti.mitems:
      q.hiddenFront = true
      q.materiale = "melaminico"
      q.apribile("cassetto " & $(f.nCassetti - i), "tira", 60)
      result.add q

  # D: l'appenderia, meno profondo per stare davanti alla risega
  let xD = c[3] + (f.antaD - f.mobileD) / 2
  var dd = scatola("mobile D", xD, f.mobileD, f.hBassi, f.profRisega, sl, f.zoccolo)
  dd.add part("bastone appendiabiti", kAccessory, xD + sl, y0 + f.profRisega / 2 - 1.25,
              f.hBassi - sl - 7, f.mobileD - 2 * sl, 2.5, 2.5)
  result.aggiungi(dd, "mobile D", mel = true)

  # --- il cassone del letto -----------------------------------------------------
  # piano e cielo solo sopra la nicchia (non passano sotto e sopra la libreria,
  # che è un mobile a sé); un fianco a sinistra, niente schiena: c'è il muro
  let wC = f.interno + sm
  var cas = @[
    part("piano letto", kPanel, 0, y0, f.hBassi, wC, f.prof, sm),
    part("cielo cassone", kPanel, 0, y0, f.cieloNicchia, wC, f.prof, sm),
    part("fianco cassone", kPanel, 0, y0, f.pianoLetto, sm, f.prof, f.cieloNicchia - f.pianoLetto)]
  cas[2].hiddenFront = true
  result.aggiungi(cas, "cassone letto")
  var mat = part("materasso", kSoft, sm + (f.interno - f.materasso.lunghezza) / 2,
                 y0 + (f.prof - f.materasso.larghezza) / 2, f.pianoLetto,
                 f.materasso.lunghezza, f.materasso.larghezza, f.materasso.altezza, r = 3)
  mat.hiddenFront = true
  mat.apribile("materasso", "esce", f.profondita + 20)
  mat.alzata = f.nicchiaZ - f.pianoLetto + 1
  result.add mat

  # --- la libreria in testa al letto ------------------------------------------------
  # aperta verso il letto: due fianchi (davanti e dietro), la schiena contro il
  # muro di destra, il gavone sotto con il suo frontale verso il letto, il piano
  # del comodino con l'apertura e i due coperchi, tre scaffali più corti
  let xl = f.xLibreria
  let wl = L - sm - xl                 # 38.2: dentro, dal bordo verso il letto alla schiena
  let pl = f.profLibreria
  let zl = f.hBassi
  let zc = f.pianoComodino
  var lib = @[
    part("fianco libreria", kPanel, xl, y0, zl, wl, sm, f.hLibreria),
    part("fianco libreria", kPanel, xl, y0 + pl - sm, zl, wl, sm, f.hLibreria),
    part("schiena libreria", kPanel, L - sm, y0, zl, sm, pl, f.hLibreria),
    part("fondo gavone", kPanel, xl + sm, y0 + sm, zl, wl - sm, pl - 2 * sm, sm),
    part("frontale gavone", kPanel, xl, y0 + sm, zl, sm, pl - 2 * sm, f.gavone),
    part("cielo libreria", kPanel, xl, y0 + sm, zl + f.hLibreria - sm, wl, pl - 2 * sm, sm)]
  # il pannello che copre la risega, a sinistra della libreria guardandola dal
  # letto: in piano con l'apertura della libreria, dal suo fianco dietro fino al
  # muro (largo quanto serve: profondità del mobile meno fianco e libreria)
  lib.add part("pannello risega", kPanel, xl - sm, y0 + pl - sm, zl,
               sm, f.profondita - (y0 + pl - sm), f.hLibreria)
  var com = part("piano comodino", kPanel, xl, y0 + sm, zc - sm, wl, pl - 2 * sm, sm)
  let (xG, yG, wG, dG) = (xl + 4, y0 + sm + 6, wl - 8, pl - 2 * sm - 12)
  com.holesPiano.add rrect(xG, yG, wG, dG, 4)
  lib.add com
  for z in f.zScaffali:
    lib.add part("scaffale", kPanel, L - sm - f.scaffali, y0 + sm, z, f.scaffali, pl - 2 * sm, sm)
  for q in lib.mitems:
    if q.name.startsWith("fianco"): q.hiddenFront = true
  result.aggiungi(lib, "libreria")
  for k in 0..1:
    var cop = part("coperchio gavone", kPanel, xG + 0.2, yG + 0.2 + float(k) * dG / 2,
                   zc - 1, wG - 0.4, dG / 2 - 0.4, 1, r = 4)
    cop.hiddenFront = true
    cop.apribile("coperchio " & $(k + 1), "alza", 14)
    result.add cop

  # --- i tre vani alti ------------------------------------------------------------
  # scatole aperte davanti, appoggiate sul cielo del cassone (solo scatole, come
  # nella tavola 6); quella sopra la risega è meno profonda
  for i in 0..2:
    let x = f.xFronte + f.margineAlto + float(i) * (f.ribaltaL + f.spazio) + (f.ribaltaL - f.vanoL) / 2
    let p = if x + f.vanoL > f.xRisega: f.profRisega else: f.prof
    var v = scatola("vano alto " & $(i + 1), x, f.vanoL, f.vanoH, p, sl, f.fondoVani, f.fondoVani)
    result.aggiungi(v, "vano alto " & $(i + 1), mel = true)

  # --- il muro ------------------------------------------------------------------------
  # i mobili dei falegnami arrivano a 81.1, oltre gli 80 del muro (vedi `controlli`):
  # il muro si disegna dietro di loro, altrimenti coprirebbe le schiene
  let yMuro = f.yMuro
  result.add part("muro (carta da parati)", kWall, 0, yMuro, 0, L, 2, H)
  result.add part("risega (muro, carta da parati)", kWall, f.xRisega, yMuro - f.muro.risegaProf, 0,
                  f.muro.risegaLarga, f.muro.risegaProf, H)

# --- i controlli ------------------------------------------------------------------
proc controlli*(f: Falegnami; m: Model): seq[string] =
  ## Le cose che non tornano con la stanza o con le nostre decisioni.
  let mu = f.muro
  if f.altezza > mu.altezza + 0.01:
    result.add "il fronte è alto " & fmtNum(f.altezza) & " (2 × " & fmtNum(f.pannelloH) & " + " &
      fmtNum(f.fascia) & "): la stanza è alta " & fmtNum(mu.altezza)
  if abs(f.larghezza - mu.larghezza) > 0.5:
    result.add "il fronte è largo " & fmtNum(f.larghezza) & ", la parete " & fmtNum(mu.larghezza)
  if f.profondita > mu.profondita + 0.01:
    result.add "ante, fronte e mobili profondi " & fmtNum(f.prof) & " fanno " & fmtNum(f.profondita) &
      " cm: oltre gli " & fmtNum(mu.profondita) & " della stanza (a 80 c'è la cornice della porta)"
  if f.materasso.larghezza > f.prof + 0.01:
    result.add "il materasso è largo " & fmtNum(f.materasso.larghezza) & " ma il cassone è profondo " & fmtNum(f.prof)
  if f.materasso.lunghezza > f.interno + 0.01:
    result.add "il materasso è lungo " & fmtNum(f.materasso.lunghezza) & " ma il cassone dentro è " & fmtNum(f.interno)
  if f.bordo < 16:
    result.add "il fronte sopra il materasso è alto " & fmtNum(f.bordo) & " cm: meno di 16 (il nostro bordo)"
  if f.schienale < 40:
    result.add "la testata (il gavone) sporge " & fmtNum(f.schienale) &
      " cm sopra il materasso: meno di 40 (noi avevamo deciso testata 58, cioè 41 sopra il materasso)"
  if f.nicchiaZ + f.nicchiaH > f.cieloNicchia + 0.01:
    result.add "l'apertura della nicchia sale oltre il cielo del cassone"
  if f.scaffali < f.comodino:
    result.add "gli scaffali (" & fmtNum(f.scaffali) & ") sono più corti del piano del comodino (" &
      fmtNum(f.comodino) & "), come scritto; nel disegno sembrano uguali"
  let xD = f.colonne[3] + (f.antaD - f.mobileD) / 2
  if xD + f.mobileD < f.larghezza - 0.5:
    result.add "la libreria appoggia sul mobile D, che finisce a " & fmtNum(xD + f.mobileD) &
      ": per gli ultimi " & fmtNum(f.larghezza - xD - f.mobileD) & " cm sotto non c'è niente"
  # tra il cassone e la libreria c'è il pannello che copre la risega
  let avanzo = f.xLibreria - 2 * f.sMulti - f.interno
  if avanzo > 0.5:
    result.add "tra il cassone (dentro " & fmtNum(f.interno) & "), il pannello della risega e la libreria (comodino " &
      fmtNum(f.comodino) & ") avanzano " & fmtNum(avanzo) & " cm di larghezza"
  let dietroLib = f.yMobili + f.profLibreria
  if dietroLib > f.yMuro - f.muro.risegaProf + 0.01:
    result.add "la libreria (profonda " & fmtNum(f.profLibreria) & ") entra nella risega di " &
      fmtNum(dietroLib - (f.yMuro - f.muro.risegaProf)) & " cm"
  if f.pannello and f.lungPannello > f.profGradini:
    result.add "il pannellino (" & fmtNum(f.lungPannello) & ") è più lungo del mobile dei gradini (" &
      fmtNum(f.profGradini) & "): chiuso sporge dietro di " & fmtNum(f.lungPannello - f.profGradini) &
      " cm, nello spazio libero; lì serve una guida che lo regga"
  if f.margine < 0:
    result.add "i frontali in basso non ci stanno nei pannelli"
  if f.scalinoVani > 0.5:
    result.add "il fondo dei vani alti sta " & fmtNum(f.scalinoVani) &
      " cm sotto il bordo dell'apertura delle ribalte: dentro c'è uno scalino"
  let sopra = f.zRibalte + f.ribaltaH - f.sormonto - (f.fondoVani + f.vanoH)
  if sopra > 0.5:
    result.add "il cielo dei vani alti sta " & fmtNum(sopra) &
      " cm sotto il bordo alto dell'apertura delle ribalte: dall'apertura si vede sopra la scatola"
  for r in fuoriLastra(m):
    result.add r

proc quote*(f: Falegnami): seq[DimChain] =
  let H = f.altezza
  let L = f.larghezza
  let c = f.colonne
  # in alto: le ribalte dei vani alti (con la parte fissa della prima) e la nicchia
  var alto = @[0.0]
  for i, x in f.xRibalte:
    alto.add x
    if i == 0: alto.add x + f.parteFissa
    alto.add x + f.ribaltaL
  alto.add L
  # in basso: anta A, gradini, cassetti, anta D
  var basso = @[0.0]
  for (x, w) in [(c[0], f.antaA), (c[1], f.aperturaGradini), (c[2], f.cassetti), (c[3], f.antaD)]:
    basso.add x
    basso.add x + w
  basso.add L
  # la libreria nella sezione laterale: comodino e scaffali (il loro piano)
  var libreria = @[f.hBassi, f.pianoComodino]
  for z in f.zScaffali: libreria.add z + f.sMulti
  libreria.add f.hBassi + f.hLibreria
  @[
    DimChain(view: vFront, vertical: true, at: -22, ext: 0, stops: f.catenaFronte),
    DimChain(view: vFront, vertical: true, at: -52, ext: -22, stops: @[0.0, f.pannelloH, 2 * f.pannelloH, H]),
    DimChain(view: vFront, vertical: false, at: H + 12, ext: H, stops: alto),
    DimChain(view: vFront, vertical: false, at: H + 28, ext: H,
             stops: @[0.0, c[0], c[0] + f.nicchiaL, L]),
    DimChain(view: vFront, vertical: false, at: -12, ext: 0, stops: basso),
    DimChain(view: vFront, vertical: false, at: -28, ext: -12,
             stops: @[0.0, f.spalla, f.spalla + f.pannelloL, L - f.spalla, L]),
    DimChain(view: vSide, vertical: true, at: -26, ext: 0,
             stops: @[0.0, f.hBassi, f.pianoLetto, f.cieloNicchia, f.cieloNicchia + f.sMulti,
                      f.fondoVani, f.fondoVani + f.vanoH, H]),
    DimChain(view: vSide, vertical: true, at: f.profondita + 14, ext: f.profondita, stops: libreria),
    DimChain(view: vSide, vertical: false, at: -18, ext: 0,
             stops: @[0.0, f.yMobili, f.profondita]),
    DimChain(view: vPlan, vertical: false, at: f.profondita + 18, ext: f.profondita,
             stops: @[0.0, f.sMulti, f.sMulti + f.interno, f.xLibreria, L]),
    DimChain(view: vPlan, vertical: true, at: -14, ext: 0, stops: @[0.0, f.yMobili, f.profondita]),
  ]

proc tavola*(f: Falegnami; m: Model): string =
  ## Prospetto, sezione laterale nella libreria (si vedono gli scaffali),
  ## pianta sopra il piano letto.
  let views = [
    View(kind: vFront, ox: 0, oy: 0),
    View(kind: vSide, cut: f.xSezione, ox: f.larghezza + 110, oy: 0),
    View(kind: vPlan, cut: 130, ox: 0, oy: 60 + f.profondita),
  ]
  var s = initSheet()
  for v in views:
    s.draw(v, m)
    for d in f.quote:
      if d.view == v.kind: s.draw(v, d)
  s.render()
