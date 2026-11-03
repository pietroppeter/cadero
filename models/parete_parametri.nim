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
    oStanza = "stanza"          ## misurato nella stanza
    oDisegno = "disegno"        ## scritto sulla tavola di riferimento
    oRilevato = "rilevato"      ## misurato in scala sul disegno
    oPietro = "deciso"          ## deciso da Pietro
    oIpotesi = "ipotesi"        ## inventato, da verificare
    oVariante = "variante"      ## un'opzione sì/no

  Param* = object
    campo*: string      ## "gruppo.campo" in `Parete` ("libreria.vani.0" per le liste)
    etichetta*: string
    min*, max*, passo*: float
    origine*: Origine
    nota*: string       ## da cosa si misura, cosa muove

  Gruppo* = object
    nome*, spiega*: string
    params*: seq[Param]

  Derivata* = object
    nome*, formula*: string
    valore*: float
    allarme*: bool      ## vale qualcosa che non torna

proc pr(campo, etichetta: string; mn, mx, ps: float; o: Origine; nota = ""): Param =
  Param(campo: campo, etichetta: etichetta, min: mn, max: mx, passo: ps, origine: o, nota: nota)

const maxVani* = 5   ## quanti cursori di vano mostra il banco (fino a 4 scaffali)

proc gruppi*(): seq[Gruppo] =
  ## I gruppi di parametri, come li ha descritti Pietro (revisione del 3 novembre).
  var vani: seq[Param]
  for i in 0 ..< maxVani:
    vani.add pr("libreria.vani." & $i, "Vano " & $(i + 1) & " (0 = libero)", 0, 70, 0.5, oPietro)
  @[
    Gruppo(nome: "Vincoli muro", spiega: "Le misure della stanza: fisse, si cambiano solo se rimisurando si trova altro. Sono massime: il mobile non ne esce.",
      params: @[
        pr("muro.altezza", "Altezza della stanza", 280, 340, 0.5, oStanza),
        pr("muro.larghezza", "Larghezza della parete", 200, 280, 0.5, oStanza),
        pr("muro.profondita", "Profondità massima", 60, 90, 0.5, oStanza, "a 80 c'è la cornice della porta"),
        pr("muro.risegaProf", "Profondità della risega", 0, 20, 0.5, oStanza),
        pr("muro.risegaLarga", "Larghezza della risega", 20, 60, 0.1, oStanza, "è anche la larghezza dentro la colonna destra")]),
    Gruppo(nome: "Vincoli di costruzione", spiega: "Come si costruisce: pannelli, giochi e spazi minimi.",
      params: @[
        pr("costruzione.spessore", "Spessore dei pannelli", 1.2, 2.5, 0.1, oIpotesi),
        pr("costruzione.gioco", "Gioco di montaggio (per lato)", 0, 2, 0.1, oIpotesi, "verso i muri e il soffitto"),
        pr("costruzione.spazioMinimo", "Spazio minimo tra frontali", 0, 10, 0.5, oPietro, "controllo: tra le ribalte e tra cassetti e anta stretta")]),
    Gruppo(nome: "Altezze chiave", spiega: "Le tre altezze che decidono il letto.",
      params: @[
        pr("altezze.baseLetto", "Base del letto", 80, 140, 0.5, oDisegno, "da terra alla cima del pannello sotto il materasso"),
        pr("altezze.nicchia", "Altezza della nicchia", 120, 190, 0.1, oDisegno, "dalla base letto al sotto del soffitto della nicchia"),
        pr("altezze.testata", "Testata", 30, 90, 0.5, oPietro, "dalla base letto alla cima del comodino; lo schienale si calcola")]),
    Gruppo(nome: "Materasso", spiega: "Centrato nella nicchia su tutti e due gli assi: il gioco si calcola.",
      params: @[
        pr("materasso.altezza", "Altezza", 8, 30, 0.5, oPietro),
        pr("materasso.lunghezza", "Lunghezza", 160, 200, 1, oPietro, "quello che ci sta"),
        pr("materasso.larghezza", "Larghezza", 60, 90, 0.5, oPietro, "non più della profondità meno lo spessore")]),
    Gruppo(nome: "Libreria", spiega: "Sopra il comodino. Con n scaffali ci sono n + 1 vani: se ne fissano al massimo n, i liberi si dividono il resto.",
      params: @[
        pr("libreria.scaffali", "Scaffali", 1, 4, 1, oPietro, "di solito 2, al massimo 3")] & vani & @[
        pr("libreria.profScaffali", "Profondità degli scaffali", 15, 38, 0.5, oPietro),
        pr("libreria.vanoMinimo", "Vano minimo (controllo)", 15, 40, 0.5, oIpotesi),
        pr("libreria.risegaRivestita", "Risega rivestita (faccia e bordo)", 0, 1, 1, oVariante)]),
    Gruppo(nome: "Cornice della nicchia", spiega: "L'apertura nel pannello frontale, misurata da quattro riferimenti.",
      params: @[
        pr("cornice.sinistra", "Sinistra, dal muro", 1, 40, 0.1, oRilevato),
        pr("cornice.destra", "Destra", 0, 80, 0.1, oRilevato, "dalla risega, o dal muro se scelto sotto"),
        pr("cornice.destraDalMuro", "Destra misurata dal muro", 0, 1, 1, oVariante),
        pr("cornice.bassa", "Bassa, dalla base letto", 10, 60, 0.5, oDisegno, "meno il materasso fa il bordo (almeno 16)"),
        pr("cornice.alta", "Alta, dal soffitto della nicchia", 0, 40, 0.1, oDisegno),
        pr("cornice.raggio", "Raggio", 0, 40, 0.5, oRilevato)]),
    Gruppo(nome: "Zona bassa", spiega: "Ante, gradini e cassetti. Il margine ai lati vale anche per la zona alta; lo spazio tra cassetti e anta stretta si calcola.",
      params: @[
        pr("bassa.zoccolo", "Zoccolo", 0, 20, 0.5, oDisegno),
        pr("bassa.altezzaAnte", "Altezza delle ante", 60, 120, 0.5, oDisegno),
        pr("bassa.margineLato", "Margine ai lati", 2, 30, 0.5, oRilevato),
        pr("bassa.antaGrande", "Anta grande", 30, 100, 0.5, oRilevato),
        pr("bassa.gradini", "Gradini", 20, 50, 0.5, oRilevato),
        pr("bassa.cassetti", "Cassetti", 30, 80, 0.5, oRilevato),
        pr("bassa.antaStretta", "Anta stretta", 20, 60, 0.5, oRilevato),
        pr("bassa.spazioGradini", "Spazio ai lati dei gradini", 2, 15, 0.5, oIpotesi, "uno solo, a sinistra e a destra")]),
    Gruppo(nome: "Gradini, cassetti, ante", spiega: "Come erano.",
      params: @[
        pr("bassa.nGradini", "Gradini", 3, 8, 1, oDisegno),
        pr("bassa.passoGradini", "Spazio tra i gradini", 2, 15, 0.5, oRilevato),
        pr("bassa.profGradini", "Profondità dei gradini", 15, 60, 0.5, oPietro),
        pr("bassa.nCassetti", "Cassetti", 1, 5, 1, oDisegno),
        pr("bassa.gapCassetti", "Spazio tra i cassetti", 0, 10, 0.5, oRilevato),
        pr("bassa.profCassetti", "Profondità cassetti (e anta grande)", 30, 78, 0.5, oRilevato),
        pr("bassa.corsa", "Corsa dei cassetti", 20, 75, 0.5, oIpotesi)]),
    Gruppo(nome: "Zona alta", spiega: "Le tre ribalte, uguali. Lo spazio tra loro si calcola e deve restare sopra lo spazio minimo.",
      params: @[
        pr("alta.margineAlto", "Margine in alto", 0, 20, 0.5, oDisegno, "dal soffitto della stanza"),
        pr("alta.altezzaRibalta", "Altezza delle ribalte", 20, 70, 0.5, oDisegno),
        pr("alta.larghezzaRibalta", "Larghezza delle ribalte", 40, 80, 0.5, oIpotesi)]),
    Gruppo(nome: "Frontali e fori", spiega: "Come erano.",
      params: @[
        pr("frontali.raggio", "Raggio dei frontali", 0, 8, 0.5, oRilevato),
        pr("frontali.diamForo", "Diametro dei fori maniglia", 2, 6, 0.5, oIpotesi)]),
    Gruppo(nome: "Prese", spiega: "La scatola con presa, USB-C e interruttore.",
      params: @[
        pr("prese.sulComodino", "Sul comodino", 0, 1, 1, oVariante),
        pr("prese.sporgenza", "Sporgenza", 3, 12, 0.5, oIpotesi),
        pr("prese.lunghezza", "Lunghezza", 8, 30, 0.5, oIpotesi),
        pr("prese.altezza", "Altezza", 5, 15, 0.5, oIpotesi)]),
    Gruppo(nome: "Tavolino", spiega: "Come era; la corsa ora si calcola (si estrae del tutto).",
      params: @[
        pr("tavolino.attivo", "Con tavolino", 0, 1, 1, oVariante),
        pr("tavolino.gradini", "Gradini nel tavolino", 1, 4, 1, oPietro),
        pr("tavolino.prof", "Profondità del piano", 40, 78, 0.1, oIpotesi),
        pr("tavolino.profCassetti", "Profondità cassetti-gradino", 10, 40, 0.5, oIpotesi),
        pr("tavolino.gamba", "Larghezza delle gambe", 4, 15, 0.5, oIpotesi),
        pr("tavolino.antina", "Antina che si ribalta", 0, 1, 1, oVariante)]),
  ]

proc statoDisegno*(): seq[(string, string)] =
  ## Il gruppo `disegno`: non descrive il mobile ma cosa la tavola disegna aperto.
  @[("disegno.cassettoAperto", "quale cassetto la tavola disegna aperto"),
    ("disegno.tavolinoAperto", "disegnare il tavolino estratto"),
    ("disegno.antinaAperta", "disegnare l'antina aperta")]

# --- leggere e scrivere un campo per nome ("gruppo.campo") --------------------------
proc valore*(p: Parete; campo: string): float =
  for gn, g in p.fieldPairs:
    for n, v in g.fieldPairs:
      let k = gn & "." & n
      when v is float:
        if k == campo: return v
      elif v is int:
        if k == campo: return float(v)
      elif v is bool:
        if k == campo: return (if v: 1.0 else: 0.0)
      elif v is seq[float]:
        for i in 0 ..< maxVani:
          if k & "." & $i == campo: return (if i < v.len: v[i] else: 0.0)
  NaN

proc imposta*(p: var Parete; campo: string; x: float) =
  for gn, g in p.fieldPairs:
    for n, v in g.fieldPairs:
      let k = gn & "." & n
      when v is float:
        if k == campo: v = x
      elif v is int:
        if k == campo: v = int(round(x))
      elif v is bool:
        if k == campo: v = x > 0.5
      elif v is seq[float]:
        for i in 0 ..< maxVani:
          if k & "." & $i == campo:
            if v.len <= i: v.setLen(i + 1)
            v[i] = x

proc sicuro*(p: Parete): Parete =
  ## I valori che farebbero cadere `parete(p)` tenuti dentro i limiti.
  result = p
  result.libreria.scaffali = max(result.libreria.scaffali, 1)
  result.bassa.nGradini = max(result.bassa.nGradini, 2)
  result.bassa.nCassetti = max(result.bassa.nCassetti, 1)
  result.tavolino.gradini = clamp(result.tavolino.gradini, 1, result.bassa.nGradini - 1)

# --- misure derivate ------------------------------------------------------------
proc derivate*(p: Parete): seq[Derivata] =
  let s = p.spessore
  let c = p.catenaFronte
  let d = proc (nome, formula: string; v: float; allarme = false): Derivata =
    Derivata(nome: nome, formula: formula, valore: v, allarme: allarme)
  let ultimo = c[1] + float(p.bassa.nGradini - 1) * (p.hGradino + p.bassa.passoGradini)
  let (gL, gP) = p.giocoMaterasso
  let altraDestra = if p.cornice.destraDalMuro: p.xRisega - p.nicchiaFine
                    else: p.larghezza + p.costruzione.gioco - p.nicchiaFine
  let sm = p.costruzione.spazioMinimo
  result = @[
    d("Altezza del mobile", "stanza − gioco", p.altezza),
    d("Larghezza del mobile", "parete − 2 giochi", p.larghezza),
    d("Profondità del mobile", "massima − gioco", p.profondita),
    d("Bordo davanti al materasso", "cornice bassa − materasso (almeno 16)", p.bordo, p.bordo < 16),
    d("Schienale sopra il materasso", "testata − materasso (almeno 40)", p.schienale, p.schienale < 40),
    d("Apertura della nicchia: altezza", "altezza nicchia − cornice bassa − cornice alta", p.nicchiaH, p.nicchiaH <= 0),
    d("Apertura della nicchia: larghezza", "fine − cornice sinistra", p.nicchiaL),
    d((if p.cornice.destraDalMuro: "Cornice destra dalla risega" else: "Cornice destra dal muro"),
      "l'altra misura della cornice destra", altraDestra),
    d("Sotto del soffitto della nicchia", "base letto + altezza nicchia", p.sottoSoffitto),
    d("Comodino (base della libreria)", "base letto + testata", p.baseLibreria),
    d("Vano più basso della libreria", "i liberi si dividono il resto", p.vanoUtile, p.vanoUtile < p.libreria.vanoMinimo),
    d("Fascia sul fronte", "base letto + cornice bassa − zoccolo − ante", p.nicchiaZ - p.fineBassa),
    d("Aria tra ante e piano letto", "base letto − s − zoccolo − ante", p.sottoLetto, p.sottoLetto < 0),
    d("Fondo delle ribalte", "stanza − margine alto − ribalta", p.ribaltaZ),
    d("Ribalte sopra il soffitto della nicchia", "fondo ribalte − (sotto soffitto + s)", p.ribaltaZ - p.soffittoNicchia,
      p.ribaltaZ < p.soffittoNicchia - 0.05),
    d("Stacco tra nicchia e ribalte", "fondo ribalte − cima dell'apertura", p.ribaltaZ - p.nicchiaZ - p.nicchiaH),
    d("Vani alti (dentro)", "altezza − cima del soffitto della nicchia", p.altezza - p.soffittoNicchia),
    d("Spazio tra le ribalte", "(larghezza − 2 margini − 3 ribalte) / 2", p.gapAlti, p.gapAlti < sm),
    d("Spazio tra cassetti e anta stretta", "quello che resta", p.spazioCassetti, p.spazioCassetti < sm),
    d("Inizio della risega", "parete − gioco − risega", p.xRisega),
    d("Campata della nicchia (dentro)", "divisorio − fianco", p.campata),
    d("Gioco del materasso in lunghezza", "(campata − lunghezza) / 2, per lato", gL, gL < 0),
    d("Gioco del materasso in larghezza", "(profondità − s − larghezza) / 2, per lato", gP, gP < 0),
    d("Profondità della colonna", "profondità − risega", p.profColonna),
    d("Altezza di un gradino (foro)", "(ante − spazi) / gradini", p.hGradino),
    d("Passo dei gradini (piede → piede)", "foro + spazio", p.hGradino + p.bassa.passoGradini),
    d("Dall'ultimo gradino al bordo", "bordo della nicchia − ultimo gradino", c[3] - ultimo, c[3] - ultimo > 30),
    d("Altezza di un cassetto", "(ante − spazi) / cassetti", p.hCassetto),
    d("Corsa del tavolino", "profondità del piano + s", p.corsaTavolino),
  ]
  discard s

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
  ## materasso, comodino, ripiani). In arancio le fasce del fronte che si
  ## calcolano (fascia, stacco) e i punti dove le due catene si incontrano.
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
  let fn = @["zoccolo", "ante", "fascia", "apertura", "stacco", "ribalte", "margine"]
  var fronte: seq[(float, float, string, bool)]
  for i in 0 ..< 7: fronte.add (c[i], c[i + 1], fn[i], i in [2, 4])
  fasce(10, 140, fronte)
  let mat = p.sopraMaterasso
  var dentro: seq[(float, float, string, bool)] = @[
    (0.0, p.pianoLetto - s, "sotto il letto", false),
    (p.pianoLetto - s, p.pianoLetto, "", false),
    (p.pianoLetto, mat, "materasso", false),
    (mat, p.baseLibreria, "schienale", false)]
  var z = p.baseLibreria
  for h in p.ripiani:
    dentro.add (z, p.baseLibreria + h - s, "vano", false)
    dentro.add (p.baseLibreria + h - s, p.baseLibreria + h, "", false)
    z = p.baseLibreria + h
  dentro.add (z, p.sottoSoffitto, "vano", false)
  dentro.add (p.sottoSoffitto, p.soffittoNicchia, "", false)
  dentro.add (p.soffittoNicchia, H, "vani alti", false)
  fasce(290, 140, dentro)
  # le linee che dovrebbero coincidere o stare a una distanza decisa
  proc linea(z: float; testo: string; cls = "l") =
    o.add "<line class=\"" & cls & "\" x1=\"150\" x2=\"290\" y1=\"" & fmtNum(Y(z)) & "\" y2=\"" & fmtNum(Y(z)) & "\"/>"
    o.add "<text class=\"t\" x=\"220\" y=\"" & fmtNum(Y(z) - 3) & "\" text-anchor=\"middle\">" & testo & "</text>"
  linea(c[2], "ante " & fmtNum(c[2]) & " · piano " & fmtNum(p.pianoLetto - s), "l caldo")
  linea(c[3], "bordo " & fmtNum(c[3]) & " · mat. " & fmtNum(mat), "l caldo")
  linea(c[5], "ribalte " & fmtNum(c[5]) & " · soffitto " & fmtNum(p.soffittoNicchia), "l caldo")
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
  var basse = @[0.0, p.bassa.margineLato]
  let cx = p.colonneX
  let lb = p.larghezzeBasse
  for i in 0..3:
    if i > 0: basse.add cx[i]
    basse.add cx[i] + lb[i]
  basse.add L
  var ribalte = @[0.0]
  let wR = p.alta.larghezzaRibalta
  for i in 0..2:
    let x = p.bassa.margineLato + float(i) * (wR + p.gapAlti)
    ribalte.add x
    ribalte.add x + wR
  ribalte.add L
  var libreria = @[0.0, p.pianoLetto, mat, p.baseLibreria]
  for h in p.ripiani: libreria.add p.baseLibreria + h
  libreria.add p.soffittoNicchia
  libreria.add H
  let viste = @[
    (fronte, @[
      DimChain(view: vFront, vertical: true, at: -22, ext: 0, stops: c),
      DimChain(view: vFront, vertical: true, at: -52, ext: -22, stops: @[0.0, H]),
      DimChain(view: vFront, vertical: false, at: -12, ext: 0, stops: basse),
      DimChain(view: vFront, vertical: false, at: -28, ext: -12, stops: @[0.0, L]),
      DimChain(view: vFront, vertical: false, at: H + 12, ext: H,
               stops: @[0.0, p.nicchiaX, p.nicchiaFine, p.xRisega, L]),
      DimChain(view: vFront, vertical: false, at: H + 28, ext: H + 12, stops: ribalte)]),
    # dentro la nicchia: le altezze chiave (base letto, nicchia) e la cornice
    # (bassa = materasso + bordo, alta)
    (latN, @[
      DimChain(view: vSide, vertical: true, at: -26, ext: 0,
               stops: @[0.0, p.pianoLetto, mat, c[3], c[4], p.sottoSoffitto, H]),
      DimChain(view: vSide, vertical: true, at: -46, ext: -26,
               stops: @[p.pianoLetto, p.sottoSoffitto]),
      DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, P])]),
    # nella colonna: schienale della testata, vani della libreria, risega
    (latC, @[
      DimChain(view: vSide, vertical: true, at: -26, ext: 0, stops: libreria),
      DimChain(view: vSide, vertical: true, at: -46, ext: -26, stops: @[p.pianoLetto, p.baseLibreria]),
      DimChain(view: vSide, vertical: false, at: -18, ext: 0, stops: @[0.0, p.profColonna, P])]),
    (pianta, @[
      DimChain(view: vPlan, vertical: false, at: P + 18, ext: P, stops: @[0.0, p.xRisega, L]),
      DimChain(view: vPlan, vertical: false, at: P / 2 - 14, ext: P / 2 - 14,
               stops: @[s + p.giocoMaterasso[0], s + p.giocoMaterasso[0] + p.materasso.lunghezza]),
      DimChain(view: vPlan, vertical: true, at: -14, ext: 0, stops: @[0.0, P]),
      DimChain(view: vPlan, vertical: true, at: 40, ext: 40, stops: @[s + p.giocoMaterasso[1], s + p.giocoMaterasso[1] + p.materasso.larghezza]),
      DimChain(view: vPlan, vertical: true, at: L + 14, ext: L, stops: @[0.0, p.profColonna, P]),
      DimChain(view: vPlan, vertical: false, at: -10, ext: 0,
               stops: @[L - s - p.libreria.profScaffali, L - s])])]
  var sh = initSheet()
  for (v, qs) in viste:
    sh.draw(v, m)
    for d in qs: sh.draw(v, d)
  sh.label(latN, P, H + 10, "SEZIONE NELLA NICCHIA")
  sh.label(latC, P, H + 10, "SEZIONE NELLA COLONNA")
  sh.render()
