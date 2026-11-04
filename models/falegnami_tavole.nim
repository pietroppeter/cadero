## Le sette tavole dei falegnami rifatte dal nostro modello (`falegnami.nim`).
##
## Ogni tavola disegna gli stessi pezzi della loro, in proiezione, con le stesse
## quote. Ogni misura è confrontata con quella scritta sulla loro tavola:
## nera se torna, rossa con la loro accanto se è diversa, arancio se sulla loro
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
      (v, catena(vFront, false, H + 26, H, @[0.0, c[0], c[0] + f.nicchiaL, L], @[no, 156.7, no])),
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
      (v, catena(vFront, false, H + 26, H, @[0.0, c[0], c[0] + f.nicchiaL, L], @[no, 156.7, no])),
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
    nota: "vista dal lato (la loro la guarda dal letto, qui è specchiata: il fronte è a sinistra); " &
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
