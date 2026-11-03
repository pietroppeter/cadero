## I parametri della parete descritti per una pagina: gruppi, etichette,
## intervalli dei cursori, da dove viene ogni valore. Più le misure derivate
## (con la formula) e uno schema delle due catene verticali.
##
## Compila con entrambi i backend: in C per il documento (le tabelle), in
## JavaScript per i cursori che cambiano il modello nel browser.

import std/[strutils, math]
import ../src/cadero/[model, drawing]
import parete

type
  Origine* = enum
    oDisegno = "disegno"        ## scritto sulla tavola di riferimento
    oRilevato = "rilevato"      ## misurato in scala sul disegno
    oPietro = "deciso"          ## deciso da Pietro
    oIpotesi = "ipotesi"        ## inventato, da verificare
    oVariante = "variante"      ## un'opzione sì/no
    oDoppione = "doppione"      ## scritto a mano ma si potrebbe calcolare

  Param* = object
    campo*: string      ## nome del campo in `Parete` ("materasso.1" per gli array)
    etichetta*: string
    min*, max*, passo*: float
    origine*: Origine
    nota*: string       ## da cosa dipende, cosa muove

  Gruppo* = object
    nome*, spiega*: string
    params*: seq[Param]

  Derivata* = object
    nome*, formula*: string
    valore*: float
    allarme*: bool      ## vale qualcosa che non torna

proc pr(campo, etichetta: string; mn, mx, ps: float; o: Origine; nota = ""): Param =
  Param(campo: campo, etichetta: etichetta, min: mn, max: mx, passo: ps, origine: o, nota: nota)

proc gruppi*(): seq[Gruppo] =
  ## I parametri raggruppati come li pensa chi disegna il mobile.
  @[
    Gruppo(nome: "Ingombro", spiega: "Le tre misure del vano tra i muri. Oggi l'altezza non c'è: è la somma della catena del fronte.",
      params: @[
        pr("larghezza", "Larghezza", 200, 280, 0.5, oDisegno, "muove solo il fianco destro e la colonna: le colonne basse e la nicchia restano dove sono"),
        pr("profondita", "Profondità", 60, 90, 0.5, oDisegno, "fianchi e pannelli lunghi; le scatole basse hanno profondità proprie"),
        pr("spessore", "Spessore pannelli", 1.2, 2.5, 0.1, oIpotesi, "entra in quasi tutte le formule")]),
    Gruppo(nome: "Catena del fronte", spiega: "Sette fasce dal basso: la loro somma è l'altezza. Decidono dove stanno i frontali, non i pannelli interni.",
      params: @[
        pr("margineBasso", "Zoccolo", 0, 20, 0.5, oDisegno),
        pr("zonaBassa", "Zona bassa (ante, gradini, cassetti)", 60, 130, 0.5, oDisegno, "non sposta il piano letto"),
        pr("fascia", "Fascia davanti al materasso", 10, 50, 0.5, oDisegno, "decide il bordo della nicchia, non il piano letto"),
        pr("nicchia", "Apertura della nicchia", 80, 150, 0.5, oDisegno),
        pr("stacco", "Stacco sopra la nicchia", 0, 30, 0.5, oDisegno, "il soffitto della nicchia sta in cima allo stacco"),
        pr("cassettiAlti", "Ribalte alte", 20, 70, 0.5, oDisegno),
        pr("margineAlto", "Margine in alto", 0, 20, 0.5, oDisegno)]),
    Gruppo(nome: "Letto", spiega: "Il piano letto è un numero a sé: non segue la catena del fronte.",
      params: @[
        pr("pianoLetto", "Quota del piano letto", 80, 140, 0.5, oDisegno, "sposta piano letto, fianchi, scatole basse, divisorio, comodino e libreria"),
        pr("materasso.0", "Materasso: lunghezza", 160, 200, 1, oPietro),
        pr("materasso.1", "Materasso: larghezza", 60, 90, 1, oPietro, "deve stare nei 78.2 tra fronte e muro"),
        pr("materasso.2", "Materasso: spessore", 8, 30, 0.5, oPietro, "la testata non lo segue: lo schienale cambia"),
        pr("rete", "Spazio sotto il materasso", 0, 15, 0.5, oIpotesi)]),
    Gruppo(nome: "Colonna destra e risega", spiega: "La colonna in testa al letto, con la risega del muro dietro.",
      params: @[
        pr("colonnaDx", "Larghezza della colonna", 30, 60, 0.1, oDisegno, "il comodino è profondo colonnaDx − s/2: a filo della risega solo se ≈ risegaLarga"),
        pr("risegaSporge", "Risega: sporgenza", 0, 20, 0.5, oPietro, "profondità della colonna = profondità − sporgenza"),
        pr("risegaLarga", "Risega: larghezza", 0, 60, 0.5, oPietro, "non muove la colonna: c'è solo un controllo"),
        pr("risegaScoperta", "Risega scoperta (tappezzata)", 0, 1, 1, oVariante)]),
    Gruppo(nome: "Testata e libreria", spiega: "Il comodino sta a pianoLetto + testata; i vani dividono in parti uguali lo spazio fino al soffitto della nicchia.",
      params: @[
        pr("testata", "Testata sopra il piano letto", 30, 80, 0.5, oPietro, "la decisione vera era 41 sopra il materasso: qui è 58 = 17 + 41 a mano"),
        pr("nVani", "Vani della libreria", 2, 6, 1, oPietro),
        pr("profScaffali", "Profondità scaffali", 15, 37, 0.5, oPietro),
        pr("altezzaLibri", "Altezza minima di un vano", 15, 40, 0.5, oIpotesi, "serve solo al controllo"),
        pr("preseSulComodino", "Prese sul comodino", 0, 1, 1, oVariante),
        pr("scatolaPrese.0", "Scatola prese: sporgenza", 3, 12, 0.5, oIpotesi),
        pr("scatolaPrese.1", "Scatola prese: lunghezza", 8, 30, 0.5, oIpotesi),
        pr("scatolaPrese.2", "Scatola prese: altezza", 5, 15, 0.5, oIpotesi)]),
    Gruppo(nome: "Frontali: margini e raggi", spiega: "Dove stanno le aperture nel pannello frontale. Numeri rilevati in scala, indipendenti tra loro.",
      params: @[
        pr("margineLato", "Margine ai lati", 0, 30, 0.5, oRilevato, "primo e ultimo frontale; le ribalte alte si dividono il resto"),
        pr("gapAlti", "Spazio tra le ribalte", 0, 10, 0.25, oRilevato),
        pr("nicchiaX", "Nicchia: inizio da sinistra", 0, 40, 0.5, oRilevato, "non è legata a margineLato né alla colonna"),
        pr("nicchiaL", "Nicchia: larghezza", 100, 198, 0.5, oRilevato),
        pr("raggioNicchia", "Nicchia: raggio", 0, 40, 0.5, oRilevato),
        pr("raggio", "Raggio degli altri frontali", 0, 8, 0.5, oRilevato),
        pr("diamForo", "Fori maniglia: diametro", 2, 6, 0.5, oIpotesi)]),
    Gruppo(nome: "Zona bassa: colonne", spiega: "Quattro larghezze e tre spazi, da sinistra dopo il margine. Nessuno si adatta: la somma deve tornare da sola.",
      params: @[
        pr("colonneBasse.0", "Anta sinistra", 30, 100, 0.5, oRilevato),
        pr("spaziBassi.0", "Spazio", 0, 20, 0.5, oRilevato),
        pr("colonneBasse.1", "Gradini", 20, 50, 0.5, oRilevato),
        pr("spaziBassi.1", "Spazio", 0, 20, 0.5, oRilevato),
        pr("colonneBasse.2", "Cassetti", 30, 80, 0.5, oRilevato),
        pr("spaziBassi.2", "Spazio", 0, 20, 0.5, oRilevato),
        pr("colonneBasse.3", "Anta stretta", 20, 60, 0.5, oRilevato, "non è allineata alla colonna destra di sopra")]),
    Gruppo(nome: "Gradini, cassetti, ante", spiega: "Le altezze dei gradini e dei cassetti si calcolano dalla zona bassa.",
      params: @[
        pr("nGradini", "Gradini", 3, 8, 1, oDisegno),
        pr("passoGradini", "Spazio tra i gradini", 2, 15, 0.5, oRilevato, "il passo vero (da un piede all'altro) è derivato"),
        pr("profGradini", "Profondità dei gradini", 15, 60, 0.5, oPietro),
        pr("nCassettiBassi", "Cassetti", 1, 5, 1, oDisegno),
        pr("gapCassetti", "Spazio tra i cassetti", 0, 10, 0.5, oRilevato),
        pr("profCassetti", "Profondità cassetti (e anta sinistra)", 30, 78, 0.5, oRilevato, "lo stesso numero vale anche per la scatola dell'anta"),
        pr("corsa", "Corsa dei cassetti", 20, 75, 0.5, oIpotesi, "non segue la profondità")]),
    Gruppo(nome: "Tavolino", spiega: "La variante con il tavolino che si estrae al posto dei primi gradini.",
      params: @[
        pr("tavolino", "Con tavolino", 0, 1, 1, oVariante),
        pr("gradiniTavolino", "Gradini nel tavolino", 1, 4, 1, oPietro),
        pr("profTavolino", "Profondità del piano", 40, 78, 0.1, oIpotesi, "= profondità − spessore − 1.4 di gioco, ma scritto a mano"),
        pr("corsaTavolino", "Corsa del tavolino", 30, 80, 0.1, oDoppione, "dovrebbe essere profTavolino + spessore"),
        pr("profCassettiTavolino", "Profondità cassetti-gradino", 10, 40, 0.5, oIpotesi),
        pr("gambaTavolino", "Larghezza delle gambe", 4, 15, 0.5, oIpotesi),
        pr("antinaTavolino", "Antina che si ribalta", 0, 1, 1, oVariante)]),
  ]

proc statoDisegno*(): seq[(string, string)] =
  ## Campi di `Parete` che non descrivono il mobile ma come disegnarlo.
  @[("cassettoAperto", "quale cassetto la tavola disegna aperto"),
    ("tavolinoAperto", "disegnare il tavolino estratto"),
    ("antinaAperta", "disegnare l'antina aperta")]

# --- leggere e scrivere un campo per nome --------------------------------------
proc valore*(p: Parete; campo: string): float =
  for nome, v in p.fieldPairs:
    when v is float:
      if nome == campo: return v
    elif v is int:
      if nome == campo: return float(v)
    elif v is bool:
      if nome == campo: return (if v: 1.0 else: 0.0)
    elif v is array:
      for i in 0 ..< v.len:
        if nome & "." & $i == campo: return v[i]
  NaN

proc imposta*(p: var Parete; campo: string; x: float) =
  for nome, v in p.fieldPairs:
    when v is float:
      if nome == campo: v = x
    elif v is int:
      if nome == campo: v = int(round(x))
    elif v is bool:
      if nome == campo: v = x > 0.5
    elif v is array:
      for i in 0 ..< v.len:
        if nome & "." & $i == campo: v[i] = x

proc sicuro*(p: Parete): Parete =
  ## I valori che farebbero cadere `parete(p)` (oggi non controllati), tenuti
  ## dentro i limiti: almeno 2 vani, gradini del tavolino meno dei gradini.
  result = p
  result.nVani = max(result.nVani, 2)
  result.gradiniTavolino = clamp(result.gradiniTavolino, 1, result.nGradini - 1)

# --- misure derivate ------------------------------------------------------------
proc hGradino*(p: Parete): float =
  (p.zonaBassa - p.passoGradini * float(p.nGradini - 1)) / float(p.nGradini)

proc hCassetto*(p: Parete): float =
  (p.zonaBassa - p.gapCassetti * float(p.nCassettiBassi - 1)) / float(p.nCassettiBassi)

proc wRibalta*(p: Parete): float = (p.larghezza - 2 * p.margineLato - 2 * p.gapAlti) / 3

proc fineColonneBasse*(p: Parete): float = p.colonneX[3] + p.colonneBasse[3]

proc sopraMaterasso*(p: Parete): float = p.pianoLetto + p.rete + p.materasso[2]

proc derivate*(p: Parete): seq[Derivata] =
  let s = p.spessore
  let c = p.catenaFronte
  let d = proc (nome, formula: string; v: float; allarme = false): Derivata =
    Derivata(nome: nome, formula: formula, valore: v, allarme: allarme)
  let fineBassa = c[2]
  let bordo = c[3] - p.sopraMaterasso
  let ultimo = c[1] + float(p.nGradini - 1) * (p.hGradino + p.passoGradini)
  let campata = p.xColonna - s / 2 - s
  result = @[
    d("Altezza totale", "somma della catena del fronte", p.altezza),
    d("Base della nicchia (bordo)", "zoccolo + zona bassa + fascia", c[3]),
    d("Spazio tra zona bassa e piano letto", "(pianoLetto − s) − (zoccolo + zona bassa)",
      p.pianoLetto - s - fineBassa, p.pianoLetto - s - fineBassa < 0),
    d("Bordo sopra il materasso", "base nicchia − (pianoLetto + rete + materasso)",
      bordo, bordo < 16),
    d("Schienale della testata", "testata − rete − materasso (deciso: 41)",
      p.testata - p.rete - p.materasso[2], abs(p.testata - p.rete - p.materasso[2] - 41) > 1),
    d("Altezza libera sopra il materasso", "(soffitto − s) − sopra materasso",
      p.soffittoNicchia - s - p.sopraMaterasso),
    d("Soffitto della nicchia", "catena fino allo stacco", p.soffittoNicchia),
    d("Comodino (base libreria)", "pianoLetto + testata", p.baseLibreria),
    d("Passo dei ripiani", "(soffitto − comodino) / nVani", (p.cimaLibreria - p.baseLibreria) / float(p.nVani)),
    d("Vano utile della libreria", "passo − s", p.vanoUtile, p.vanoUtile < p.altezzaLibri),
    d("Inizio della colonna", "larghezza − colonnaDx", p.xColonna),
    d("Campata della nicchia (interno)", "inizio colonna − s/2 − s", campata, campata < p.materasso[0]),
    d("Profondità della colonna", "profondità − risegaSporge", p.profColonna),
    d("Profondità del comodino", "colonnaDx − s/2 (a filo risega se = risegaLarga)",
      p.profComodino, abs(p.profComodino - p.risegaLarga) > 1),
    d("Tra fronte e muro", "profondità − s", p.profondita - s, p.profondita - s < p.materasso[1]),
    d("Fine delle colonne basse", "margine + colonne + spazi (deve fare larghezza − margine)",
      p.fineColonneBasse, abs(p.fineColonneBasse - (p.larghezza - p.margineLato)) > 0.05),
    d("Fine della nicchia", "nicchiaX + nicchiaL (prima della colonna)", p.nicchiaX + p.nicchiaL,
      p.nicchiaX + p.nicchiaL > p.xColonna - s / 2),
    d("Larghezza di una ribalta alta", "(larghezza − 2 margini − 2 spazi) / 3", p.wRibalta),
    d("Altezza di un gradino (foro)", "(zona bassa − spazi) / nGradini", p.hGradino),
    d("Passo dei gradini (piede → piede)", "foro + spazio", p.hGradino + p.passoGradini,
      p.hGradino + p.passoGradini > 30),
    d("Dall'ultimo gradino al bordo", "base nicchia − ultimo gradino", c[3] - ultimo,
      c[3] - ultimo > 30),
    d("Altezza di un cassetto", "(zona bassa − spazi) / nCassetti", p.hCassetto),
  ]

proc tabellaDerivate*(p: Parete): string =
  result = """<table class="derivate"><thead><tr><th>Misura</th><th>Formula</th><th class="num">cm</th></tr></thead><tbody>"""
  for d in p.derivate:
    let cls = if d.allarme: " class=\"allarme\"" else: ""
    result.add "<tr" & cls & "><td>" & d.nome & "</td><td>" & d.formula & "</td><td class=\"num\">" &
      fmtNum(d.valore) & "</td></tr>"
  result.add "</tbody></table>"

# --- schema delle due catene verticali -------------------------------------------
proc schemaCatene*(p: Parete): string =
  ## Due righelli verticali affiancati, in scala: a sinistra la catena del
  ## fronte (dove stanno i frontali), a destra la catena di dentro (pannelli,
  ## materasso, comodino, ripiani). In arancio le misure che non dipendono
  ## l'una dall'altra ma dovrebbero.
  let s = p.spessore
  let c = p.catenaFronte
  let H = p.altezza
  let k = 1.6        # px per cm
  let W = 440.0
  let top = 14.0
  proc Y(z: float): float = top + (H - z) * k
  var o = "<svg class=\"catene\" viewBox=\"0 0 " & $W & " " & fmtNum(H * k + 2 * top) &
    "\" role=\"img\" aria-label=\"Le due catene verticali\">"
  proc fasce(x, w: float; tratti: seq[(float, float, string, bool)]) =
    for (z0, z1, nome, caldo) in tratti:
      let cls = if caldo: "f caldo" else: "f"
      o.add "<rect class=\"" & cls & "\" x=\"" & $x & "\" y=\"" & fmtNum(Y(z1)) & "\" width=\"" & $w &
        "\" height=\"" & fmtNum(max(0.0, (z1 - z0) * k)) & "\"/>"
      if (z1 - z0) * k >= 11:
        o.add "<text x=\"" & $(x + w / 2) & "\" y=\"" & fmtNum((Y(z0) + Y(z1)) / 2 + 4) &
          "\" text-anchor=\"middle\">" & nome & " " & fmtNum(z1 - z0) & "</text>"
  let fn = @["zoccolo", "zona bassa", "fascia", "nicchia", "stacco", "ribalte", "margine"]
  var fronte: seq[(float, float, string, bool)]
  for i in 0 ..< 7: fronte.add (c[i], c[i + 1], fn[i], i == 2)
  fasce(10, 140, fronte)
  let mat = p.sopraMaterasso
  var dentro: seq[(float, float, string, bool)] = @[
    (0.0, p.pianoLetto - s, "sotto il letto", false),
    (p.pianoLetto - s, p.pianoLetto, "", false),
    (p.pianoLetto, mat, "materasso", false),
    (mat, p.baseLibreria, "schienale", true)]
  var z = p.baseLibreria
  for h in p.ripiani:
    dentro.add (z, p.baseLibreria + h - s, "vano", false)
    dentro.add (p.baseLibreria + h - s, p.baseLibreria + h, "", false)
    z = p.baseLibreria + h
  dentro.add (z, p.soffittoNicchia - s, "vano", false)
  dentro.add (p.soffittoNicchia - s, p.soffittoNicchia, "", false)
  dentro.add (p.soffittoNicchia, H, "vani alti", false)
  fasce(290, 140, dentro)
  # le linee che dovrebbero coincidere o stare a una distanza decisa
  proc linea(z: float; testo: string; cls = "l") =
    o.add "<line class=\"" & cls & "\" x1=\"150\" x2=\"290\" y1=\"" & fmtNum(Y(z)) & "\" y2=\"" & fmtNum(Y(z)) & "\"/>"
    o.add "<text class=\"t\" x=\"220\" y=\"" & fmtNum(Y(z) - 3) & "\" text-anchor=\"middle\">" & testo & "</text>"
  linea(c[2], "zona bassa " & fmtNum(c[2]) & " · piano " & fmtNum(p.pianoLetto - s), "l caldo")
  linea(c[3], "bordo " & fmtNum(c[3]) & " · mat. " & fmtNum(mat), "l caldo")
  linea(c[5], "soffitto " & fmtNum(c[5]))
  o.add "<text class=\"h\" x=\"80\" y=\"10\" text-anchor=\"middle\">fronte</text>"
  o.add "<text class=\"h\" x=\"360\" y=\"10\" text-anchor=\"middle\">dentro</text>"
  o.add "</svg>"
  o

# --- le quote proposte -------------------------------------------------------------
proc tavolaProposta*(p: Parete; m: Model): string =
  ## Una tavola con le quote proposte: le stesse viste più una seconda sezione
  ## laterale, dentro la nicchia, per le misure che servono a chi ci dorme.
  let s = p.spessore
  let L = p.larghezza
  let P = p.profondita
  let H = p.altezza
  let c = p.catenaFronte
  let mat = p.sopraMaterasso
  let fronte = View(kind: vFront, ox: 0, oy: 0)
  let latN = View(kind: vSide, cut: p.nicchiaX + p.nicchiaL / 2, ox: L + 110, oy: 0)
  let latC = View(kind: vSide, cut: 230, ox: L + 110 + P + 110, oy: 0)
  let pianta = View(kind: vPlan, cut: 200, ox: 0, oy: 60 + P)
  # prospetto: la catena dei frontali in verticale, quella delle colonne basse
  # in orizzontale sotto, nicchia/colonna e ribalte sopra
  var basse = @[0.0, p.margineLato]
  let cx = p.colonneX
  for i in 0..3:
    if i > 0: basse.add cx[i]
    basse.add cx[i] + p.colonneBasse[i]
  basse.add L
  var ribalte = @[0.0]
  let wR = p.wRibalta
  for i in 0..2:
    let x = p.margineLato + float(i) * (wR + p.gapAlti)
    ribalte.add x
    ribalte.add x + wR
  ribalte.add L
  var libreria = @[0.0, p.pianoLetto, mat, p.baseLibreria]
  for h in p.ripiani: libreria.add p.baseLibreria + h
  libreria.add p.cimaLibreria
  libreria.add H
  let viste = @[
    (fronte, @[
      DimChain(view: vFront, vertical: true, at: -22, ext: 0, stops: c),
      DimChain(view: vFront, vertical: true, at: -52, ext: -22, stops: @[0.0, H]),
      DimChain(view: vFront, vertical: false, at: -12, ext: 0, stops: basse),
      DimChain(view: vFront, vertical: false, at: -28, ext: -12, stops: @[0.0, L]),
      DimChain(view: vFront, vertical: false, at: H + 12, ext: H,
               stops: @[0.0, p.nicchiaX, p.nicchiaX + p.nicchiaL, p.xColonna, L]),
      DimChain(view: vFront, vertical: false, at: H + 28, ext: H + 12, stops: ribalte)]),
    # dentro la nicchia: piano letto, materasso, bordo, altezza libera, soffitto
    (latN, @[
      DimChain(view: vSide, vertical: true, at: -26, ext: 0,
               stops: @[0.0, p.pianoLetto, mat, c[3], p.soffittoNicchia - s, H]),
      DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, P])]),
    # nella colonna: schienale della testata, vani della libreria, risega
    (latC, @[
      DimChain(view: vSide, vertical: true, at: -26, ext: 0, stops: libreria),
      DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, p.profColonna, P])]),
    (pianta, @[
      DimChain(view: vPlan, vertical: false, at: P + 18, ext: P, stops: @[0.0, p.xColonna, L]),
      DimChain(view: vPlan, vertical: false, at: P + 32, ext: P + 18,
               stops: @[L - p.risegaLarga, L]),
      DimChain(view: vPlan, vertical: false, at: P / 2 - 14, ext: P / 2 - 14,
               stops: @[(p.xColonna - p.materasso[0]) / 2, (p.xColonna + p.materasso[0]) / 2]),
      DimChain(view: vPlan, vertical: true, at: -14, ext: 0, stops: @[0.0, P]),
      DimChain(view: vPlan, vertical: true, at: 40, ext: 40, stops: @[s, s + p.materasso[1]]),
      DimChain(view: vPlan, vertical: true, at: L + 14, ext: L, stops: @[0.0, p.profColonna, P]),
      DimChain(view: vPlan, vertical: false, at: -10, ext: 0,
               stops: @[L - s - p.profScaffali, L - s])])]
  var sh = initSheet()
  for (v, qs) in viste:
    sh.draw(v, m)
    for d in qs: sh.draw(v, d)
  sh.label(latN, P, H + 10, "SEZIONE NELLA NICCHIA")
  sh.label(latC, P, H + 10, "SEZIONE NELLA COLONNA")
  sh.render()
