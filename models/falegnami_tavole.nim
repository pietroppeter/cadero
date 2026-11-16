## Le sette tavole dei falegnami rifatte dal nostro modello (`falegnami.nim`).
##
## Ogni tavola disegna gli stessi pezzi della loro, in proiezione, con le stesse
## quote. Ogni misura è confrontata con quella scritta sulla loro tavola:
## nera se torna, rossa con la loro accanto se è diversa, blu se sulla loro
## tavola non c'è (l'abbiamo dedotta). Serve a vedere se ci siamo persi dei pezzi
## o se qualche misura non torna.
##
## Le loro misure sono in mm sulle tavole: qui in cm. `no` = non c'è.
import std/[math, strutils]
import ../src/cadero
import falegnami

const no = NaN

type TavolaRifatta* = object
  nome*: string
  nota*: string      ## cosa si vede, cosa manca rispetto alla loro
  svg*: string
  rosse*: seq[string] ## le misure che non tornano, "cosa: nostra (loro) · perché"

proc filtra(m: Model; tieni: proc (p: Part): bool): Model =
  result.name = m.name
  for p in m.parts:
    if tieni(p): result.parts.add p

proc catena(view: ViewKind; vertical: bool; at, ext: float; stops: seq[float];
            loro: seq[float]): DimChain =
  assert loro.len == stops.len - 1
  DimChain(view: view, vertical: vertical, at: at, ext: ext, stops: stops, loro: loro)

proc foglio(views: openArray[(View, Model)]; quote: openArray[(View, DimChain)]): string =
  var s = initSheet()
  for (v, m) in views: s.draw(v, m)
  for (v, d) in quote: s.draw(v, d)
  s.render()

proc fronte(p: Part): bool = p.name.startsWith("fronte")

# --- 1. il fronte senza ante: le aperture ------------------------------------------
proc tavola1(f: Falegnami; m: Model): TavolaRifatta =
  let (so, sc) = (f.sormonto, f.sormontoCassetti)
  let (L, H) = (f.larghezza, f.altezza)
  let c = f.colonne
  let v = View(kind: vFront)
  let fr = m.filtra(fronte)
  # in alto: le aperture dei vani (643 × 326) e la nicchia (1567 × 1220)
  var su = @[0.0]
  var suL: seq[float]
  for x in f.xRibalte:
    su.add x + so; su.add x + f.ribaltaL - so
    suL.add no; suL.add 64.3
  su.add L; suL.add no
  # in basso: anta A 715, gradini 250, cassetti 462, anta D 462
  let giu = @[0.0, c[0] + so, c[0] + f.antaA - so, c[1], c[1] + f.aperturaGradini,
              c[2] + so, c[2] + f.cassetti - so, c[3] + so, c[3] + f.antaD - so, L]
  # a destra: in altezza anta A (140 da terra, 910), gradini (120 da terra, 158 e
  # 143) e cassetti (270)
  var gr = @[0.0]
  var grL: seq[float]
  for i, z in f.zGradini:
    grL.add (if i == 0: 12.0 else: no)   # il primo da terra: 120
    gr.add z; gr.add z + f.gradini[i]
    grL.add f.gradini[i]
  gr.add H; grL.add no
  var cas = @[0.0]
  var casL: seq[float]
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    cas.add z + sc; cas.add z + f.hCassetto - sc
    casL.add no; casL.add 27.0
  cas.add H; casL.add no
  let alto = f.zRibalte + so
  result = TavolaRifatta(nome: "Il fronte senza ante",
    nota: "il pannello frontale con le aperture: quelle dei vani, la nicchia, le ante, i gradini, i cassetti",
    svg: foglio([(v, fr)], [
      (v, catena(vFront, false, H + 12, H, su, suL)),
      (v, catena(vFront, false, H + 26, H, @[0.0, f.nicchiaX, f.nicchiaX + f.nicchiaL, L], @[no, 156.7, no])),
      (v, catena(vFront, false, -12, 0, giu, @[no, 71.5, no, 25.0, no, 46.2, no, 46.2, no])),
      (v, catena(vFront, true, -14, 0, @[0.0, alto, alto + f.ribaltaH - 2 * so, H], @[no, 32.6, no])),
      (v, catena(vFront, true, -28, 0, @[0.0, f.nicchiaZ, f.nicchiaZ + f.nicchiaH, H], @[no, 122.0, no])),
      (v, catena(vFront, true, L + 14, L, @[0.0, f.zBassi + so, f.zBassi + f.altezzaAnte - so, H], @[14.0, 91.0, no])),
      (v, catena(vFront, true, L + 28, L, gr, grL)),
      (v, catena(vFront, true, L + 42, L, cas, casL))]))

# --- 2. il pannellino estraibile -----------------------------------------------------
proc tavola2(f: Falegnami; m: Model): TavolaRifatta =
  ## La tavola 2 è il fronte in prospettiva con il pannellino tirato fuori (670):
  ## qui la sezione nei gradini, con il pannellino fuori.
  let c = f.colonne
  var mm = m.filtra(proc (p: Part): bool =
    p.blocco == "mobile B" or p.gruppo == "pannellino" or p.fronte or p.blocco == "cassone letto")
  for p in mm.parts.mitems:
    if p.gruppo == "pannellino":
      p.pos.y -= f.lungPannello - 12
      p.kind = kPanel   # nella sezione si disegnano i pannelli
  let v = View(kind: vSide, cut: c[1] + f.aperturaGradini / 2)
  let yP = -(f.lungPannello - 12)
  var q: seq[(View, DimChain)]
  q.add (v, catena(vSide, false, -14, 0, @[f.yMobili, f.yMobili + f.profGradini], @[30.0]))
  if f.pannello:
    q.add (v, catena(vSide, false, f.zFessura + 12, f.zFessura, @[yP, yP + f.lungPannello], @[67.0]))
    let yB = f.yMobili + f.profGradini
    q.add (v, catena(vSide, true, yB + 12, yB,
                     @[0.0, f.zFessura, f.zFessura + f.fessura, f.hBassi], @[no, no, no]))
  result = TavolaRifatta(nome: "Il fronte con ante e ribalte",
    nota: "la loro è il fronte in prospettiva con il pannellino tirato fuori (670): qui la sezione nei gradini, " &
      "con il mobile B (300) e il pannellino fuori; il resto delle misure è nella 3",
    svg: foglio([(v, mm)], q))

# --- 3. il prospetto con ante e ribalte -------------------------------------------
proc tavola3(f: Falegnami; m: Model): TavolaRifatta =
  let (L, H) = (f.larghezza, f.altezza)
  let c = f.colonne
  let v = View(kind: vFront)
  let r = f.xRibalte
  let su = @[0.0, r[0], r[0] + f.parteFissa, r[0] + f.ribaltaL, r[1], r[1] + f.ribaltaL,
             r[2], r[2] + f.ribaltaL, L]
  let giu = @[0.0, c[0], c[0] + f.antaA, c[1], c[1] + f.aperturaGradini, c[2], c[2] + f.cassetti,
              c[3], c[3] + f.antaD, L]
  var cas = @[0.0]
  var casL: seq[float]
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    cas.add z; cas.add z + f.hCassetto
    casL.add no; casL.add 29.0
  cas.add H; casL.add no
  result = TavolaRifatta(nome: "Il prospetto",
    nota: "il fronte com'è chiuso, con le ante (è anche la tavola 2, in prospettiva)",
    svg: foglio([(v, m)], [
      (v, catena(vFront, false, H + 12, H, su, @[no, 15.0, 53.0, no, 68.3, no, 68.3, no])),
      (v, catena(vFront, false, H + 26, H, @[0.0, f.nicchiaX, f.nicchiaX + f.nicchiaL, L], @[no, 156.7, no])),
      (v, catena(vFront, false, -12, 0, giu, @[no, 75.5, no, no, no, 50.2, no, 50.2, no])),
      (v, catena(vFront, false, -26, -12, @[0.0, f.spalla, f.spalla + f.pannelloL, L - f.spalla, L],
                 @[5.9, 112.5, 112.5, 5.9])),
      (v, catena(vFront, true, -14, 0, @[0.0, f.pannelloH, 2 * f.pannelloH, H], @[156.8, 156.8, 6.0])),
      (v, catena(vFront, true, -28, 0, @[0.0, f.nicchiaZ, f.nicchiaZ + f.nicchiaH, f.zRibalte,
                                          f.zRibalte + f.ribaltaH, H], @[no, 121.9, no, 36.6, no])),
      (v, catena(vFront, true, L + 14, L, @[0.0, f.zBassi, f.zBassi + f.altezzaAnte, H], @[no, 95.0, no])),
      (v, catena(vFront, true, L + 28, L, cas, casL))]))

# --- 4. i mobili senza il fronte ----------------------------------------------------
proc tavola4(f: Falegnami; m: Model): TavolaRifatta =
  let (L, H) = (f.larghezza, f.altezza)
  let mm = m.filtra(proc (p: Part): bool =
    p.blocco.len > 0 or p.gruppo.startsWith("coperchio"))
  let v = View(kind: vFront, contorni: true)
  let pl = View(kind: vPlan, cut: 200, oy: f.profondita + 40)
  result = TavolaRifatta(nome: "I mobili senza il fronte",
    nota: "tutti i mobili, senza il fronte e senza ante (quelle sono nella 3): cassone, libreria, vani alti, mobili bassi; sotto, la pianta a 200",
    svg: foglio([(v, mm), (pl, mm)], [
      (v, catena(vFront, true, -14, 0, @[0.0, f.pannelloH, 2 * f.pannelloH, H], @[156.8, 156.8, 6.0])),
      (v, catena(vFront, true, -28, 0, @[0.0, f.hBassi, f.hBassi + f.hNicchia,
                                          f.hBassi + f.hNicchia + f.vanoH, H], @[109.0, 150.0, 40.9, no])),
      (v, catena(vFront, false, f.pianoLetto + 10, f.pianoLetto,
                 @[0.0, f.sMulti, f.sMulti + f.interno, f.xLibreria, L], @[no, 193.0, no, no])),
      (v, catena(vFront, false, -12, 0, @[0.0, f.spalla, f.spalla + f.pannelloL, L - f.spalla, L],
                 @[5.9, 112.5, 112.5, 5.9])),
      (pl, catena(vPlan, true, -14, 0, @[0.0, f.yMobili, f.yMobili + f.prof], @[no, 77.5]))]))

# --- 5. la libreria ------------------------------------------------------------------
proc tavola5(f: Falegnami; m: Model): TavolaRifatta =
  let sm = f.sMulti
  let L = f.larghezza
  let mm = m.filtra(proc (p: Part): bool =
    p.blocco == "libreria" or p.gruppo.startsWith("coperchio"))
  let (y0, pl, zl) = (f.yMobili, f.profLibreria, f.hBassi)
  let v = View(kind: vSide, cut: L + 1)
  let pianta = View(kind: vPlan, cut: 200, ox: -(f.xLibreria - 2 * sm), oy: -zl + f.profondita + 45)
  let s = f.zScaffali
  let top = zl + f.hLibreria
  # in altezza: gavone 320, comodino, poi le luci tra gli scaffali (277 e 274
  # dalla loro tavola, tra il 1° e il 2° e tra il 2° e il 3° scaffale dal basso)
  let alt = @[zl, zl + f.gavone, f.pianoComodino, s[0], s[0] + sm, s[1], s[1] + sm, s[2], s[2] + sm,
              top - sm, top]
  let altL = @[32.0, no, no, no, 27.7, no, 27.4, no, no, no]
  let xl = f.xLibreria
  result = TavolaRifatta(nome: "La libreria",
    nota: "vista dal lato (la tavola la guarda dal letto, qui è specchiata: il fronte è a sinistra); " &
      "sotto la pianta a 200 con la profondità degli scaffali e il pannello della risega. " &
      "Il triangolo fuori e il taglio per i cavi non ci sono",
    svg: foglio([(v, mm), (pianta, mm)], [
      (v, catena(vSide, false, zl - 10, zl, @[y0, y0 + pl], @[63.5])),
      (v, catena(vSide, false, zl - 22, zl - 10, @[y0, y0 + sm, y0 + pl - sm, y0 + pl], @[no, 59.9, no])),
      (v, catena(vSide, true, y0 - 12, y0, @[zl, top], @[150.0])),
      (v, catena(vSide, true, y0 + pl + 14, y0 + pl, alt, altL)),
      (pianta, catena(vPlan, false, y0 - 12, y0, @[L - sm - f.scaffali, L - sm], @[27.0])),
      (pianta, catena(vPlan, false, y0 - 24, y0, @[xl - sm, L], @[no])),
      (pianta, catena(vPlan, true, xl - sm - 12, xl - sm,
                      @[y0 + pl - sm, f.profondita], @[no]))]))

# --- 6. i tre vani alti ----------------------------------------------------------------
proc tavola6(f: Falegnami; m: Model): TavolaRifatta =
  let mm = m.filtra(proc (p: Part): bool = p.blocco.startsWith("vano alto"))
  var xs: seq[float]
  for p in mm.parts:
    if p.name.startsWith("fianco"): xs.add p.pos.x
  let x0 = xs[0]
  let v = View(kind: vFront, contorni: true)
  let z0 = f.fondoVani
  let pianta = View(kind: vPlan, cut: z0 + 20, oy: -z0 + f.profondita + 30)
  var lar: seq[float]
  var larL: seq[float]
  for i in 0..2:
    let x = f.xRibalte[i] + (f.ribaltaL - f.vanoL) / 2
    if i > 0: larL.add no
    lar.add x; lar.add x + f.vanoL
    larL.add 68.1
  let xUltimo = lar[^1]
  result = TavolaRifatta(nome: "I tre vani alti",
    nota: "tre scatole in melaminico appoggiate sul cassone; sotto la pianta con le profondità (775, quella sopra la risega 622)",
    svg: foglio([(v, mm), (pianta, mm)], [
      (v, catena(vFront, false, z0 + f.vanoH + 10, z0 + f.vanoH, lar, larL)),
      (v, catena(vFront, true, x0 - 12, x0, @[z0, z0 + f.vanoH], @[40.9])),
      (v, catena(vFront, true, x0 - 26, x0, @[z0, z0 + f.sMel, z0 + f.vanoH - f.sMel, z0 + f.vanoH],
                 @[no, 37.1, no])),
      (pianta, catena(vPlan, true, x0 - 12, x0, @[f.yMobili, f.yMobili + f.prof], @[77.5])),
      (pianta, catena(vPlan, true, xUltimo + 12, xUltimo, @[f.yMobili, f.yMobili + f.profRisega], @[62.2]))]))

# --- 7. i mobili bassi -----------------------------------------------------------------
proc tavola7(f: Falegnami; m: Model): TavolaRifatta =
  let mm = m.filtra(proc (p: Part): bool = p.blocco.startsWith("mobile"))
  proc xDi(nome: string): (float, float) =
    var a = Inf
    var b = -Inf
    for p in mm.parts:
      if p.blocco == nome: a = min(a, p.pos.x); b = max(b, p.x1)
    (a, b)
  let (a0, a1) = xDi("mobile A")
  let (b0, b1) = xDi("mobile B")
  let (c0, c1) = xDi("mobile C")
  let (d0, d1) = xDi("mobile D")
  let (sl, h) = (f.sMel, f.hBassi)
  var rip: seq[float]
  for p in mm.parts:
    if p.name == "ripiano mobile A": rip.add p.pos.z
  let zIn = f.zoccolo + sl
  let v = View(kind: vFront, contorni: true)
  let pianta = View(kind: vPlan, cut: 60, oy: f.profondita + 40)
  result = TavolaRifatta(nome: "I mobili bassi",
    nota: "A con due ripiani mobili, B dei gradini (in multistrato), C dei cassetti, D con l'appenderia; sotto la pianta con le profondità",
    svg: foglio([(v, mm), (pianta, mm)], [
      (v, catena(vFront, false, h + 10, h, @[a0, a1, b0, b1, c0, c1, d0, d1],
                 @[75.3, no, 28.6, no, 50.0, no, 50.0])),
      (v, catena(vFront, false, -12, 0, @[c0, c0 + sl, c1 - sl, c1, d0, d0 + sl, d1 - sl, d1],
                 @[no, 46.2, no, no, no, 46.2, no])),
      (v, catena(vFront, true, a0 - 12, a0, @[0.0, h], @[109.0])),
      (v, catena(vFront, true, a0 - 26, a0, @[0.0, f.zoccolo, zIn, rip[0], rip[0] + sl, rip[1], rip[1] + sl,
                                               h - sl, h], @[no, no, no, no, 29.8, no, no, no])),
      (pianta, catena(vPlan, true, a0 - 12, a0, @[f.yMobili, f.yMobili + f.prof], @[77.5])),
      (pianta, catena(vPlan, true, a0 - 26, a0, @[f.yMobili, f.yMobili + f.profGradini], @[30.0])),
      (pianta, catena(vPlan, true, d1 + 12, d1, @[f.yMobili, f.yMobili + f.profRisega], @[62.2]))]))

proc tavoleRifatte*(f: Falegnami): seq[TavolaRifatta] =
  ## Le sette tavole dei falegnami, rifatte dal modello `f`.
  let m = modello(f)
  @[tavola1(f, m), tavola2(f, m), tavola3(f, m), tavola4(f, m), tavola5(f, m), tavola6(f, m),
    tavola7(f, m)]

# --- v2: le tavole del progetto aggiornato, rifatte da `falegnamiV2()` -----------------
#
# Le tavole della v2 sono sette pagine: la 1 e la 2 sono lo stesso prospetto (in
# prospettiva e di fronte), con accanto il fronte senza ante. Le misure rosse sono
# raccolte in `rosse`, con il motivo quando lo sappiamo.

type Bozza = object
  views: seq[(View, Model)]
  quote: seq[(View, DimChain)]
  rosse: seq[string]

proc vista(b: var Bozza; v: View; m: Model) = b.views.add (v, m)

proc q(b: var Bozza; v: View; cosa: string; vertical: bool; at, ext: float;
       stops, loro: seq[float]; cose: seq[string] = @[]; perche = "") =
  ## una catena di quote; quelle che non tornano finiscono nella lista delle rosse.
  ## `cose` dà un nome a ogni misura della catena (se no vale `cosa` per tutte)
  b.quote.add (v, catena(v.kind, vertical, at, ext, stops, loro))
  for i, l in loro:
    if l.isNaN: continue
    let m = stops[i + 1] - stops[i]
    if abs(m - l) >= 0.05:
      let nome = if cose.len == loro.len: cose[i] else: cosa
      var r = nome & ": " & fmtNum(m) & " (" & fmtNum(l) & ")"
      if perche.len > 0: r.add " · " & perche
      b.rosse.add r

proc finita(b: Bozza; nome, nota: string): TavolaRifatta =
  TavolaRifatta(nome: nome, nota: nota, svg: foglio(b.views, b.quote), rosse: b.rosse)

proc nelProspetto(p: Part): bool =
  ## quello che si vede nel prospetto: niente muro, materasso, presa e lampada
  p.kind notin {kWall, kSoft, kAccessory}

proc estremi(m: Model; blocco: string): (float, float) =
  var a = Inf
  var b = -Inf
  for p in m.parts:
    if p.blocco == blocco: a = min(a, p.pos.x); b = max(b, p.x1)
  (a, b)

# --- 1 e 2. il prospetto e il fronte senza ante ---------------------------------------
proc tavolaV2uno(f: Falegnami; m: Model): TavolaRifatta =
  let (L, H) = (f.larghezza, f.altezza)
  let (so, sc) = (f.sormonto, f.sormontoCassetti)
  let c = f.colonne
  let r = f.xRibalte
  var b: Bozza
  # a sinistra: chiuso, con ante e ribalte
  let v = View(kind: vFront)
  b.vista(v, m.filtra(nelProspetto))
  b.q(v, "ribalte", false, H + 12, H,
      @[0.0, r[0] + f.parteFissa + 0.3, r[0] + f.ribaltaL, r[1], r[1] + f.ribaltaL, r[2],
        r[2] + f.ribaltaL, L], @[no, 51.0, no, 67.3, no, no, no])
  b.q(v, "parte fissa della prima ribalta", false, H + 26, H,
      @[0.0, r[0], r[0] + f.parteFissa, L], @[no, 16.0, no])
  b.q(v, "nicchia in larghezza", false, H + 40, H,
      @[0.0, f.nicchiaX, f.nicchiaX + f.nicchiaL, L], @[15.0, 167.8, 52.0],
      cose = @["dal bordo sinistro alla nicchia", "nicchia, larghezza", "dalla nicchia al bordo destro"])
  b.q(v, "larghezza", false, H + 54, H, @[0.0, L], @[234.8])
  b.q(v, "riga in basso", false, -12, 0,
      @[0.0, c[0], c[0] + f.antaA, c[1], c[1] + f.aperturaGradini, c[2], c[2] + f.cassetti,
        c[3], c[3] + f.antaD, L], @[12.0, 75.5, 4.0, 30.0, 4.0, 50.2, 4.0, 43.1, 12.0],
      cose = @["margine sinistro", "anta A", "spazio", "gradini", "spazio", "cassetti", "spazio",
               "anta D", "margine destro"])
  b.q(v, "altezza", true, -14, 0, @[0.0, H], @[317.6])
  b.q(v, "in altezza", true, -28, 0,
      @[0.0, f.zBassi, f.zBassi + f.altezzaAnte, f.nicchiaZ, f.nicchiaZ + f.nicchiaH, f.zRibalte,
        f.zRibalte + f.ribaltaH, H], @[6.0, 95.0, 31.0, 122.0, 12.0, 45.6, 6.0],
      cose = @["da terra alle ante", "ante", "dalle ante alla nicchia", "nicchia, altezza",
               "dalla nicchia alle ribalte", "ribalte, altezza", "dalle ribalte in cima"])
  var gr = @[0.0]
  var grL: seq[float]
  for i, z in f.zGradini:
    grL.add (if i == 0: 6.0 else: no)
    gr.add z; gr.add z + f.gradini[i]
    grL.add 15.8
  gr.add H; grL.add no
  b.q(v, "gradini", true, L + 14, L, gr, grL)
  var cas = @[0.0]
  var casL: seq[float]
  for i in 0 ..< f.nCassetti:
    let z = f.zBassi + float(i) * (f.hCassetto + f.spazioCassetti)
    cas.add z; cas.add z + f.hCassetto
    casL.add no; casL.add 29.0
  cas.add H; casL.add no
  b.q(v, "cassetti", true, L + 28, L, cas, casL)
  # a destra: il fronte senza ante, con le aperture e i tre pezzi
  let d = L + 120
  let w = View(kind: vFront, ox: d)
  b.vista(w, m.filtra(fronte))
  let ap = f.aperture
  var vano, antaA, antaD, cassetto: RRect
  for a in ap:
    if a.z >= f.zRibalte and vano.w == 0: vano = a
    elif a.x == c[0] + so: antaA = a
    elif a.x == c[3] + so: antaD = a
    elif a.x == c[2] + so and cassetto.w == 0: cassetto = a
  const pVano = "l'apertura nel fronte è la ribalta meno 2 di sormonto per lato; " &
    "63.6 × 40.6 è il dentro della scatola del vano (tavola 7)"
  b.q(w, "apertura del vano alto, larghezza", false, H + 12, H, @[vano.x, vano.x + vano.w],
      @[63.6], perche = pVano)
  b.q(w, "apertura del vano alto, altezza", true, -14, 0, @[vano.z, vano.z + vano.h], @[40.6],
      perche = pVano)
  b.q(w, "aperture in basso", false, -12, 0,
      @[0.0, antaA.x, antaA.x + antaA.w, cassetto.x, cassetto.x + cassetto.w, antaD.x,
        antaD.x + antaD.w, L], @[no, 71.5, no, 46.2, no, 39.1, no],
      cose = @["", "apertura anta A", "", "apertura cassetti", "", "apertura anta D", ""])
  b.q(w, "apertura anta A, altezza", true, -14, 0, @[antaA.z, antaA.z + antaA.h], @[91.0])
  b.q(w, "apertura cassetto, altezza", true, -28, 0, @[cassetto.z, cassetto.z + cassetto.h], @[27.0])
  b.q(w, "i tre pezzi del fronte", true, L + 14, L, @[0.0, f.tagliTre[0], f.tagliTre[1], H],
      @[118.0, 97.8, 101.8])
  discard sc
  b.finita("Il prospetto e il fronte senza ante",
    "le tavole 1 e 2 (la 1 in prospettiva, la 2 di fronte): a sinistra chiuso, con ante e ribalte; " &
    "a destra il fronte senza ante, in tre pezzi, con le aperture")

# --- 3. il cassone --------------------------------------------------------------------
proc tavolaV2tre(f: Falegnami; m: Model): TavolaRifatta =
  let (L, H) = (f.larghezza, f.altezza)
  let sm = f.sMulti
  let tieni = proc (p: Part): bool =
    p.blocco in ["cassone letto", "libreria", "listello vani alti"] or
      p.blocco.startsWith("vano alto") or p.gruppo.startsWith("coperchio")
  let mm = m.filtra(tieni)
  var b: Bozza
  let v = View(kind: vFront, contorni: true)
  b.vista(v, mm)
  let s = View(kind: vSide, cut: 100, ox: L + 40)
  b.vista(s, m.filtra(proc (p: Part): bool = p.blocco == "cassone letto" or p.kind == kSoft))
  var pl, cc: float   # sotto il piano letto e sotto il cielo del cassone
  for p in mm.parts:
    if p.name == "piano letto": pl = p.pos.z
    if p.name == "cielo cassone": cc = p.pos.z
  b.q(v, "cassone, larghezza dentro", false, pl + 12, pl, @[0.0, sm, sm + f.interno, L],
      @[no, 193.4, no])
  b.q(v, "cassone, altezza dentro", true, 120, 120, @[pl + sm, cc], @[155.7])
  b.q(v, "cassone, altezza fuori", true, -14, 0, @[pl, cc + sm], @[no])
  b.q(s, "piano letto, profondità", false, pl - 12, pl, @[f.yMobili, f.yMobili + f.prof], @[77.5])
  b.finita("Il cassone",
    "il cassone del letto con la libreria e i vani alti sopra, senza il fronte; a destra la sezione " &
    "a 100 dal bordo sinistro, con la profondità del piano letto")

# --- 4. i mobili senza il fronte --------------------------------------------------------
proc tavolaV2quattro(f: Falegnami; m: Model): TavolaRifatta =
  let L = f.larghezza
  let mm = m.filtra(proc (p: Part): bool = p.blocco.len > 0 or p.gruppo.startsWith("coperchio"))
  var b: Bozza
  let v = View(kind: vFront, contorni: true)
  let pl = View(kind: vPlan, cut: 200, oy: f.profondita + 40)
  b.vista(v, mm)
  b.vista(pl, mm)
  let (a0, a1) = mm.estremi("mobile A")
  let (b0, b1) = mm.estremi("mobile B")
  let (c0, c1) = mm.estremi("mobile C")
  let (d0, d1) = mm.estremi("mobile D")
  let topC = f.cieloNicchia + f.sMulti
  b.q(v, "in altezza", true, -14, 0, @[0.0, f.hBassi, topC, f.fondoVani, f.fondoVani + f.vanoH],
      @[no, no, no, no])
  b.q(v, "mobili bassi", false, -12, 0, @[a0, a1, b0, b1, c0, c1, d0, d1],
      @[no, no, no, no, no, no, no])
  b.q(v, "cassone e libreria", false, topC + 10, topC, @[0.0, f.xLibreria - f.sMulti, f.xLibreria, L],
      @[no, no, no])
  b.q(pl, "profondità", true, -14, 0, @[f.yMobili, f.yMobili + f.prof], @[no])
  b.finita("I mobili senza il fronte",
    "tutti i mobili, senza il fronte e senza ante: mobili bassi, cassone, libreria, vani alti; " &
    "sotto la pianta a 200. sulla tavola non ci sono misure: sono tutte blu")

# --- 5. la libreria ------------------------------------------------------------------
proc tavolaV2cinque(f: Falegnami; m: Model): TavolaRifatta =
  let sm = f.sMulti
  let L = f.larghezza
  let mm = m.filtra(proc (p: Part): bool = p.blocco == "libreria" or p.gruppo.startsWith("coperchio"))
  let (y0, pl, zl) = (f.yMobili, f.profLibreria, f.hBassi)
  var b: Bozza
  let v = View(kind: vSide, cut: L + 1)
  let s = f.zScaffali
  let pianta = View(kind: vPlan, cut: s[0] + sm / 2, ox: -(f.xLibreria - 2 * sm),
                    oy: -zl + f.profondita + 50)
  b.vista(v, mm)
  b.vista(pianta, mm)
  let top = zl + f.hLibreria
  let yF = f.profondita
  b.q(v, "libreria, profondità", false, zl - 10, zl, @[y0, y0 + pl], @[63.5])
  b.q(v, "libreria, dentro e pannello della colonna", false, zl - 22, zl,
      @[y0, y0 + sm, y0 + pl - sm, yF], @[no, 59.9, 15.8],
      cose = @["", "libreria, profondità dentro", "pannello della colonna"])
  b.q(v, "profondità totale", false, zl - 34, zl, @[y0, yF], @[77.5])
  b.q(v, "libreria, altezza dentro", true, y0 - 12, y0, @[zl + sm, top - sm], @[155.7])
  b.q(v, "libreria, altezza fuori", true, y0 - 26, y0, @[zl, top], @[no])
  let alt = @[zl + sm, f.pianoComodino, s[0], s[0] + sm, s[1], s[1] + sm, top - sm]
  b.q(v, "in altezza", true, yF + 14, yF, alt, @[58.0, 30.7, no, no, no, no],
      cose = @["gavone, dal fondo al piano del comodino", "dal piano del comodino al primo scaffale",
               "", "", "", ""],
      perche = "con 155.7 letto come altezza dentro la libreria è 3.6 più alta e i tre spazi " &
        "uguali sopra il comodino vengono 31.4")
  b.q(pianta, "scaffale, profondità", false, y0 - 12, y0, @[L - sm - f.scaffali, L - sm], @[27.0])
  b.q(pianta, "libreria, larghezza in cima", false, y0 - 24, y0, @[f.xLibreria, L], @[37.0],
      perche = "per noi è il cielo (36) più la schiena (1.8); il 37 della tavola non lo sappiamo spiegare")
  b.finita("La libreria",
    "vista dal lato (la tavola la guarda dal letto, qui è specchiata: il fronte è a sinistra); " &
    "sotto la pianta al primo scaffale. Il taglio per i cavi non c'è")

# --- 6. i mobili bassi -----------------------------------------------------------------
proc tavolaV2sei(f: Falegnami; m: Model): TavolaRifatta =
  let mm = m.filtra(proc (p: Part): bool = p.blocco.startsWith("mobile"))
  let (a0, a1) = mm.estremi("mobile A")
  let (b0, b1) = mm.estremi("mobile B")
  let (c0, c1) = mm.estremi("mobile C")
  let (d0, d1) = mm.estremi("mobile D")
  let (sl, h) = (f.sMel, f.hBassi)
  var rip: seq[float]
  var zFondo, zCielo, zCieloB, yCieloB, yGradino: float
  for p in mm.parts:
    if p.name == "ripiano mobile A": rip.add p.pos.z
    if p.name == "fondo mobile C": zFondo = p.z1
    if p.name == "cielo mobile C": zCielo = p.pos.z
    if p.name == "cielo mobile B": zCieloB = p.pos.z; yCieloB = p.y1
    if p.name == "piano gradino": yGradino = p.y1
  var b: Bozza
  let v = View(kind: vFront, contorni: true)
  let pianta = View(kind: vPlan, cut: 60, oy: f.profondita + 40)
  let lato = View(kind: vSide, cut: b1 + 1, ox: d1 + 40)
  b.vista(v, mm)
  b.vista(pianta, mm)
  b.vista(lato, mm.filtra(proc (p: Part): bool = p.blocco == "mobile B"))
  b.q(v, "larghezze", false, h + 10, h, @[a0, a1, b0, b1, c0, c1, d0, d1],
      @[75.3, no, 33.6, no, 50.0, no, no],
      cose = @["mobile A", "", "mobile B", "", "mobile C", "", "mobile D"])
  b.q(v, "mobile A, dentro", false, -12, 0, @[a0 + sl, a1 - sl], @[71.5])
  b.q(v, "mobile C, dentro", false, -12, 0, @[c0 + sl, c1 - sl], @[46.2])
  b.q(v, "mobile D, dentro", false, -12, 0, @[d0 + sl, d1 - sl], @[39.1])
  b.q(v, "altezza", true, a0 - 12, a0, @[0.0, h], @[102.8])
  b.q(v, "mobile A in altezza", true, a0 - 26, a0,
      @[0.0, f.zoccolo, zFondo, rip[0], rip[0] + sl, rip[1], rip[1] + sl, zCielo, h],
      @[6.1, no, 29.7, no, 29.7, no, no, no],
      cose = @["zoccolo", "", "mobile A, primo spazio", "", "mobile A, secondo spazio", "", "", ""])
  b.q(v, "mobile C, altezza dentro", true, (c0 + c1) / 2, (c0 + c1) / 2, @[zFondo, zCielo], @[93.9],
      perche = "per noi C è fatto come D, con il fondo sullo zoccolo: 92.9 come D. Sulla tavola " &
        "C è 1 più alto dentro: forse il fondo di C sta più in basso")
  b.q(v, "mobile D, altezza dentro", true, (d0 + d1) / 2, (d0 + d1) / 2, @[zFondo, zCielo], @[92.9])
  b.q(v, "altezza", true, d1 + 12, d1, @[0.0, h], @[102.8])
  let y0 = f.yMobili
  b.q(lato, "mobile B, cielo, profondità", false, h + 10, h, @[y0, yCieloB], @[19.0],
      perche = "per noi il cielo di B è profondo come i gradini (17); 19 sarebbe più dei fianchi (17.8)")
  b.q(lato, "mobile B, gradini, profondità", false, -12, 0, @[y0, yGradino], @[17.0])
  b.q(lato, "mobile B, fianchi, profondità", false, -24, 0, @[y0, y0 + f.profGradini], @[no])
  discard zCieloB
  b.q(pianta, "profondità", true, a0 - 12, a0, @[y0, y0 + f.prof], @[no])
  b.q(pianta, "profondità sotto la risega", true, d1 + 12, d1, @[y0, y0 + f.profRisega], @[no])
  b.finita("I mobili bassi",
    "A con due ripiani, B dei gradini, C dei cassetti, D con l'appenderia; a destra il mobile B " &
    "di lato, sotto la pianta con le profondità")

# --- 7. i tre vani alti ----------------------------------------------------------------
proc tavolaV2sette(f: Falegnami; m: Model): TavolaRifatta =
  let mm = m.filtra(proc (p: Part): bool = p.blocco.startsWith("vano alto"))
  let (x0, x1) = mm.estremi("vano alto 1")
  let (_, xU) = mm.estremi("vano alto 3")
  let sl = f.sMel
  let z0 = f.fondoVani
  let hV = f.vanoH
  var b: Bozza
  let v = View(kind: vFront, contorni: true)
  let pianta = View(kind: vPlan, cut: z0 + 20, oy: -z0 + f.profondita + 30)
  b.vista(v, mm)
  b.vista(pianta, mm)
  var lar: seq[float]
  var larL: seq[float]
  for i in 1..3:
    let (a, c) = mm.estremi("vano alto " & $i)
    if i > 1: larL.add no
    lar.add a; lar.add c
    larL.add (if i == 1: 67.4 else: no)
  const pAlto = "voluto: la scatola è 1 più alta del disegno, così fondo e cielo sono a filo " &
    "con l'apertura della ribalta e il bordo della scatola non si vede"
  b.q(v, "vani alti, larghezza", false, z0 + hV + 10, z0 + hV, lar, larL)
  b.q(v, "vano alto, larghezza dentro", false, z0 + hV / 2, z0 + hV / 2, @[x0 + sl, x1 - sl], @[63.6])
  b.q(v, "vano alto, altezza", true, x0 - 12, x0, @[z0, z0 + hV], @[44.4], perche = pAlto)
  b.q(v, "vano alto, altezza dentro", true, x0 - 26, x0, @[z0 + sl, z0 + hV - sl], @[40.6],
      perche = pAlto)
  b.q(pianta, "profondità", true, x0 - 12, x0, @[f.yMobili, f.yMobili + f.prof], @[no])
  b.q(pianta, "profondità sopra la risega", true, xU + 12, xU,
      @[f.yMobili, f.yMobili + f.profRisega], @[no])
  b.finita("I tre vani alti",
    "tre scatole in melaminico sul listello sopra il cassone; sotto la pianta con le profondità")

proc tavoleRifatteV2*(f: Falegnami): seq[TavolaRifatta] =
  ## Le tavole della v2 (16 novembre), rifatte dal modello `f` (di solito `falegnamiV2()`):
  ## la prima è le loro tavole 1 e 2 insieme, poi una per ognuna delle altre.
  let m = modello(f)
  @[tavolaV2uno(f, m), tavolaV2tre(f, m), tavolaV2quattro(f, m), tavolaV2cinque(f, m),
    tavolaV2sei(f, m), tavolaV2sette(f, m)]

proc disegnoNicchia*(f: Falegnami): string =
  ## Solo frontale, cassone del letto, materasso e libreria: prospetto e sezione
  ## laterale a x = 100, con le altezze della nicchia (blu = dedotte).
  let m = modello(f).filtra(proc (p: Part): bool =
    p.blocco in ["cassone letto", "libreria"] or p.fronte or p.name == "materasso")
  let (L, pl, zc, sm) = (f.larghezza, f.pianoLetto, f.cieloNicchia, f.sMulti)
  let mat = pl + f.materasso.altezza
  let v = View(kind: vFront)
  let vs = View(kind: vSide, cut: 100, ox: L + 70)
  # nel prospetto la libreria sta dietro al frontale: la disegniamo tratteggiata
  # (fianchi, schiena, cielo e il pannello che copre la risega)
  var mf = m.filtra(proc (p: Part): bool = p.blocco != "libreria")
  for p in m.parts:
    if p.blocco == "libreria" and (p.name.startsWith("fianco") or p.name.startsWith("schiena") or
        p.name.startsWith("cielo") or p.name == "pannello risega"):
      var q = p
      q.kind = kSoft
      q.hiddenFront = true
      q.r = 0
      mf.parts.add q
  let c0 = f.colonne[0]
  let xl = f.xLibreria
  foglio([(v, mf), (vs, m)], [
    (v, catena(vFront, false, f.altezza + 12, f.altezza,
      @[0.0, f.nicchiaX, f.nicchiaX + f.nicchiaL, xl - sm, xl, L], @[no, 156.7, no, no, no])),
    (v, catena(vFront, true, -14, 0,
      @[0.0, f.hBassi, pl, mat, f.nicchiaZ, f.nicchiaZ + f.nicchiaH, zc + sm, 2 * f.pannelloH],
      @[109.0, no, no, no, 121.9, no, no])),
    (v, catena(vFront, true, -30, 0, @[f.hBassi, f.hBassi + f.hNicchia], @[150.0])),
    (v, catena(vFront, true, L + 14, L, @[f.hBassi, f.hBassi + f.hLibreria], @[150.0])),
    (vs, catena(vSide, true, -14, 0, @[f.hBassi, pl, mat, f.nicchiaZ, zc, zc + sm],
      @[no, no, no, no, no])),
    (vs, catena(vSide, true, f.profondita + 14, f.profondita, @[pl, zc], @[no]))])

proc disegnoVaniAlti*(f: Falegnami): string =
  ## La zona alta: il fronte sopra il pannello di sotto, le ribalte, i vani alti e
  ## il cielo del cassone. Prospetto e sezione laterale nel vano di mezzo (le
  ## ribalte si vedono di fianco), con le altezze di apertura e scatole.
  let m = modello(f)
  let tieni = proc (p: Part): bool =
    p.name in ["fronte alto sx", "fronte alto dx", "fronte fascia", "cielo cassone"] or
      p.name.startsWith("ribalta") or p.blocco.startsWith("vano alto")
  let mf = m.filtra(tieni)
  var ms = mf                          # nella sezione le ribalte come pannelli, di fianco
  for q in ms.parts.mitems:
    if q.kind == kFront: q.kind = kPanel
  let (so, sl, H) = (f.sormonto, f.sMel, f.altezza)
  let xs = f.xRibalte[1] + f.ribaltaL / 2
  let v = View(kind: vFront)
  let vs = View(kind: vSide, cut: xs, ox: f.larghezza + 60)
  let (a0, a1) = (f.zRibalte + so, f.zRibalte + f.ribaltaH - so)   # l'apertura
  let cima = f.fondoVani + f.vanoH
  var s = initSheet()
  s.draw(v, mf)
  s.draw(vs, ms)
  s.draw(v, DimChain(view: vFront, vertical: true, at: -14, ext: 0,
    stops: @[f.cieloNicchia, f.fondoVani, a0, a1, 2 * f.pannelloH, H]))
  s.draw(v, DimChain(view: vFront, vertical: true, at: -30, ext: -14,
    stops: @[f.zRibalte, f.zRibalte + f.ribaltaH]))
  s.draw(v, DimChain(view: vFront, vertical: true, at: f.larghezza + 14, ext: f.larghezza,
    stops: @[f.pannelloH, 2 * f.pannelloH, H]))
  s.draw(vs, DimChain(view: vSide, vertical: true, at: -14, ext: 0,
    stops: @[f.fondoVani, f.fondoVani + sl, a0, a1, cima - sl, cima]))
  s.draw(vs, DimChain(view: vSide, vertical: true, at: f.profondita + 14, ext: f.profondita,
    stops: @[f.fondoVani, cima, f.muro.altezza]))
  s.render()

# --- il taglio del pannello frontale ------------------------------------------------
proc pezziDelFronte*(f: Falegnami): seq[Part] =
  ## I pezzi del pannello frontale (spalle comprese) con il taglio di `f`.
  for p in modello(f).parts:
    if p.fronte: result.add p

proc inLastra*(p: Part; lastra = [300.0, 150.0]): bool =
  ## Il pezzo si ricava da una lastra (in un verso o nell'altro)?
  let (a, b) = (max(p.size.x, p.size.z), min(p.size.x, p.size.z))
  a <= lastra[0] + 0.01 and b <= lastra[1] + 0.01

var disegniTagli = 0   ## per dare id diversi ai clipPath di più disegni nella stessa pagina

proc disegnoTagli*(f: Falegnami; modi: openArray[(string, Falegnami)] = []): string =
  ## Alcuni modi di dividere il pannello frontale, affiancati (di serie: a croce e
  ## in 3, senza cornice): ogni pezzo color betulla con le righe della sua
  ## venatura, le misure, verde se sta in una lastra 300 × 150, rosso se no.
  var modi = @modi
  if modi.len == 0:
    for t in [tCroce, tTre]: modi.add ("", f.conTaglio(t).conCornice(false))
  let (L, H) = (f.larghezza, f.altezza)
  const (gap, testa, piede) = (46.0, 26.0, 18.0)
  let W = float(modi.len) * L + float(modi.len - 1) * gap
  var s = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"-6 " & fmtNum(-testa) & " " &
    fmtNum(W + 12) & " " & fmtNum(H + testa + piede) & "\" style=\"width:100%;height:auto;font-family:IBM Plex Sans,sans-serif\">"
  var nClip = 0
  inc disegniTagli
  for k, (titolo, fk) in modi:
    let t = fk.taglio
    let ox = float(k) * (L + gap)
    let pezzi = pezziDelFronte(fk)
    proc px(x: float): string = fmtNum(ox + x)
    proc pz(z: float): string = fmtNum(H - z)
    s.add "<text x=\"" & px(L / 2) & "\" y=\"-10\" text-anchor=\"middle\" font-size=\"13\" font-weight=\"600\">" &
      (if titolo.len > 0: titolo else: (if t == tCroce: "A croce" else: "In 3 orizzontali") &
        (if fk.cornice: ", con cornice" else: "")) & "</text>"
    for p in pezzi:
      var pts = p.contorno
      if pts.len == 0:
        pts = @[(p.pos.x, p.pos.z), (p.x1, p.pos.z), (p.x1, p.z1), (p.pos.x, p.z1)]
      var d = ""
      for i, (x, z) in pts: d.add (if i == 0: "M" else: "L") & px(x) & " " & pz(z) & " "
      d.add "Z "
      for h in p.holes:
        for i, (x, z) in poligono(h): d.add (if i == 0: "M" else: "L") & px(x) & " " & pz(z) & " "
        d.add "Z "
      inc nClip
      let id = "taglio" & $disegniTagli & "-" & $nClip
      s.add "<clipPath id=\"" & id & "\"><path d=\"" & d & "\" clip-rule=\"evenodd\"/></clipPath>"
      s.add "<path d=\"" & d & "\" fill=\"#efe0c2\" fill-rule=\"evenodd\"/>"
      # le righe della venatura, ogni 4 cm
      s.add "<g clip-path=\"url(#" & id & ")\" stroke=\"#b8935c\" stroke-width=\"0.5\" opacity=\"0.8\">"
      if p.verso == venVerticale:
        var x = p.pos.x + 2
        while x < p.x1:
          s.add "<line x1=\"" & px(x) & "\" y1=\"" & pz(p.pos.z) & "\" x2=\"" & px(x) & "\" y2=\"" & pz(p.z1) & "\"/>"
          x += 4
      else:
        var z = p.pos.z + 2
        while z < p.z1:
          s.add "<line x1=\"" & px(p.pos.x) & "\" y1=\"" & pz(z) & "\" x2=\"" & px(p.x1) & "\" y2=\"" & pz(z) & "\"/>"
          z += 4
      s.add "</g>"
      let ok = inLastra(p)
      s.add "<path d=\"" & d & "\" fill=\"none\" fill-rule=\"evenodd\" stroke=\"" &
        (if ok: "#2f7a3b" else: "#c0392b") & "\" stroke-width=\"1.2\"/>"
      # la misura, al centro del pezzo (le spalle, strette, solo il colore)
      if p.size.x > 20 and p.size.z > 8:
        let (cx, cz) = (p.pos.x + p.size.x / 2, p.pos.z + p.size.z / 2)
        # dove il pezzo è pieno: sotto le ante, sopra le ribalte, tra ante e nicchia
        let zt = if p.pos.z < 1: p.pos.z + 4
                 elif p.z1 > H - 1: p.z1 - 12
                 elif p.name.startsWith("fronte alto"): p.z1 - 10
                 elif p.name.startsWith("fronte mezzo"): p.pos.z + 12
                 else: cz
        s.add "<text x=\"" & px(cx) & "\" y=\"" & pz(zt) & "\" text-anchor=\"middle\" font-size=\"9.5\" " &
          "paint-order=\"stroke\" stroke=\"#efe0c2\" stroke-width=\"3\" fill=\"" &
          (if ok: "#1f5a2a" else: "#a02a1e") & "\">" & fmtNum(p.size.x) & " × " & fmtNum(p.size.z) & "</text>"
    s.add "<text x=\"" & px(L / 2) & "\" y=\"" & fmtNum(H + 13) & "\" text-anchor=\"middle\" font-size=\"10\" fill=\"#555\">" &
      (if fk.cornice: "spalle " & fmtNum(f.spalla) & " × " & fmtNum(H) else: "senza spalle") & "</text>"
  s.add "</svg>"
  s
