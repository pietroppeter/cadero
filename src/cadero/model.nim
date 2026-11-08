## Il modello: parti (scatole) raccolte in un mobile.
##
## Convenzione degli assi, in cm:
## - x: larghezza, da sinistra a destra guardando il mobile di fronte
## - y: profondità, da 0 sul fronte fino al muro
## - z: altezza, da 0 sul pavimento

import std/[algorithm, math, strutils]

type
  Vec3* = object
    x*, y*, z*: float

  Kind* = enum
    kPanel = "pannello"     ## struttura: fianchi, schienale, ripiani...
    kFront = "frontale"     ## ante e frontali di cassetto, a filo del fronte
    kBox = "cassetto"       ## corpo di un cassetto (compreso il frontale)
    kSoft = "materasso"     ## oggetti morbidi, disegnati tratteggiati se nascosti
    kKnob = "foro"          ## foro maniglia (pos = centro, size.x = diametro)
    kAccessory = "accessorio" ## prese, lampade...: solo nel 3D e in distinta
    kWall = "muro"           ## parti dell'edificio (pilastri, riseghe): non si costruiscono

  RRect* = object
    ## Rettangolo con angoli arrotondati nel piano del fronte (x, z).
    x*, z*, w*, h*, r*: float

  Venatura* = enum
    ## Il verso della venatura del multistrato (betulla) sulla faccia grande di un
    ## pannello. `venLunga`: lungo il lato più lungo (come si taglia di solito dalla
    ## lastra). Su un pannello in piedi "orizzontale" è lungo x, "verticale" lungo z;
    ## su uno steso "orizzontale" è lungo x e "verticale" in profondità; su un
    ## fianco "orizzontale" è in profondità.
    venLunga = "lungo il lato lungo"
    venOrizzontale = "orizzontale"
    venVerticale = "verticale"

  Part* = object
    name*: string
    kind*: Kind
    pos*: Vec3          ## angolo con x, y, z minimi
    size*: Vec3         ## larghezza, profondità, altezza
    r*: float           ## raggio degli angoli visti di fronte
    holes*: seq[RRect]  ## aperture vuote (pannello frontale, frontale del tavolino)
    holesPiano*: seq[RRect]  ## aperture in un pannello orizzontale, viste dall'alto:
                             ## x come sempre, `z` e `h` qui sono y e profondità
    taccheP*: seq[RRect]     ## tacche ad angolo in un pannello orizzontale, viste dall'alto
                             ## (come `holesPiano`): il rettangolo tolto da un angolo, per
                             ## girare intorno a un ostacolo come la risega
    hiddenFront*: bool  ## disegnata tratteggiata nel prospetto frontale
    gruppo*: string     ## parti che si muovono insieme nel 3D (es. "cassetto 1", "tavolino"):
                        ## si aprono insieme e nell'esploso restano unite
    blocco*: string     ## nell'esploso restano insieme le parti con lo stesso blocco (se
                        ## c'è, vale al posto del gruppo): es. i cassetti con i loro fianchi
    apre*: string       ## come si apre il gruppo nel visore: "" fisso, "tira" (esce verso
                        ## chi guarda), "sx"/"dx" (anta con cerniere a sinistra/destra),
                        ## "su" (ribalta che si alza), "alza" (coperchio che si solleva
                        ## e si allontana dagli altri), "solleva" (sale e basta), "esce"
                        ## (sale di `alzata` e poi esce verso chi guarda di `corsa`),
                        ## "ribalta dx" (pannello orizzontale incernierato sullo spigolo
                        ## in alto a destra: gira di 180° e si affianca a destra)
    corsa*: float       ## per "tira" ed "esce": di quanto esce
    alzata*: float      ## per "esce": di quanto sale prima di uscire
    dentro*: string     ## il gruppo apribile che porta con sé questo (es. l'antina dentro
                        ## il tavolino): si apre solo quando quello è aperto
    contorno*: seq[(float, float)]
                        ## il contorno vero visto di fronte (x, z), se non è un rettangolo:
                        ## un pannello frontale diviso in più pezzi, dove un'apertura passa
                        ## da un pezzo all'altro (vedi `pannelloForato`). Vuoto: il rettangolo
    materiale*: string  ## "" multistrato; "melaminico": le scatole grigie dei falegnami
    venatura*: Venatura ## il verso della venatura del multistrato (vedi `Venatura`)
    contornoLato*: seq[(float, float)]
                        ## il contorno vero visto di fianco (y, z), per un pannello sottile
                        ## in x che non è un rettangolo (il pannello a L della libreria)

  Model* = object
    name*: string
    parts*: seq[Part]
    guide*: seq[float]   ## linee guida verticali sul fronte, per allineare (le x): nel
                         ## visore tratteggiate su tutta l'altezza (pulsante "Guide")

proc v3*(x, y, z: float): Vec3 = Vec3(x: x, y: y, z: z)

proc apribile*(p: var Part; gruppo, apre: string; corsa = 0.0) =
  ## Segna la parte come apribile nel visore 3D, insieme al resto del suo gruppo.
  p.gruppo = gruppo
  p.apre = apre
  p.corsa = corsa

proc part*(name: string; kind: Kind; x, y, z, w, d, h: float; r = 0.0): Part =
  Part(name: name, kind: kind, pos: v3(x, y, z), size: v3(w, d, h), r: r)

proc rrect*(x, z, w, h: float; r = 0.0): RRect = RRect(x: x, z: z, w: w, h: h, r: r)

proc x1*(p: Part): float = p.pos.x + p.size.x
proc y1*(p: Part): float = p.pos.y + p.size.y
proc z1*(p: Part): float = p.pos.z + p.size.z

proc frontRect*(p: Part): RRect =
  ## Il contorno della parte vista di fronte.
  rrect(p.pos.x, p.pos.z, p.size.x, p.size.z, p.r)

proc foriVisti*(m: Model; p: Part): seq[RRect] =
  ## Le aperture di una parte come le disegna il 3D. Il pannello frontale
  ## (un pannello con aperture) riceve come fori anche le sagome dei frontali
  ## e dei cassetti, che vanno a occuparle; le altre parti tengono le loro.
  if p.kind == kPanel and p.holes.len > 0 and p.name == "fronte":
    result = p.holes
    for q in m.parts:
      if q.kind in {kFront, kBox}: result.add q.frontRect
  else: result = p.holes

proc add*(m: var Model; p: Part) = m.parts.add p

proc verso*(p: Part): Venatura =
  ## La venatura vera della parte: quella scelta o, se `venLunga`, quella lungo il
  ## lato più lungo della sua faccia grande (orizzontale a pari misura).
  if p.venatura != venLunga: return p.venatura
  let s = p.size
  let (a, b) = if s.y <= s.x and s.y <= s.z: (s.x, s.z)     # in piedi, di faccia
               elif s.z <= s.x and s.z <= s.y: (s.x, s.y)   # steso
               else: (s.y, s.z)                            # un fianco
  if b > a: venVerticale else: venOrizzontale

# --- pannelli frontali divisi in pezzi ---------------------------------------------
# Un'apertura che passa da un pezzo all'altro del fronte (la nicchia sul giunto dei
# quattro pannelli) non è un foro di nessuno dei due: in ognuno è una tacca sul
# bordo. Il contorno del pezzo si calcola: il rettangolo del pannello meno
# l'apertura, con gli angoli stondati approssimati da segmenti.

proc poligono*(h: RRect; passi = 6): seq[(float, float)] =
  ## Il rettangolo stondato come poligono, in senso antiorario (x, z).
  let r = min(h.r, min(h.w / 2, h.h / 2))
  let centri = [(h.x + h.w - r, h.z + r, -PI / 2), (h.x + h.w - r, h.z + h.h - r, 0.0),
                (h.x + r, h.z + h.h - r, PI / 2), (h.x + r, h.z + r, PI)]
  for (cx, cz, a0) in centri:
    if r <= 0:
      result.add (cx, cz)
      continue
    for i in 0 .. passi:
      let a = a0 + PI / 2 * float(i) / float(passi)
      result.add (cx + r * cos(a), cz + r * sin(a))

proc pannelloForato*(name: string; x, y, z, w, d, h: float; fori: seq[RRect]): Part =
  ## Un pezzo del pannello frontale: le aperture tutte dentro diventano fori,
  ## quelle che escono dal bordo diventano tacche nel contorno (`contorno`),
  ## quelle tutte fuori non contano.
  result = part(name, kPanel, x, y, z, w, d, h)
  let (x0, z0, x1, z1) = (x, z, x + w, z + h)
  proc dentro(q: (float, float)): bool =
    q[0] > x0 + 1e-6 and q[0] < x1 - 1e-6 and q[1] > z0 + 1e-6 and q[1] < z1 - 1e-6
  proc lungo(q: (float, float)): float =
    ## la posizione lungo il bordo, in senso antiorario dall'angolo in basso a sinistra
    if abs(q[1] - z0) < 1e-6: q[0] - x0
    elif abs(q[0] - x1) < 1e-6: w + q[1] - z0
    elif abs(q[1] - z1) < 1e-6: w + h + x1 - q[0]
    else: 2 * w + h + z1 - q[1]
  proc bordo(a, b: (float, float)): (float, float) =
    ## dove il segmento da a (dentro) a b (fuori) esce dal rettangolo
    var t = 1.0
    let (dx, dz) = (b[0] - a[0], b[1] - a[1])
    if dx > 0: t = min(t, (x1 - a[0]) / dx)
    if dx < 0: t = min(t, (x0 - a[0]) / dx)
    if dz > 0: t = min(t, (z1 - a[1]) / dz)
    if dz < 0: t = min(t, (z0 - a[1]) / dz)
    (a[0] + t * dx, a[1] + t * dz)
  type Tacca = tuple[da, a: float; catena: seq[(float, float)]]
  var tacche: seq[Tacca]
  for f in fori:
    if f.x >= x1 or f.x + f.w <= x0 or f.z >= z1 or f.z + f.h <= z0: continue   # fuori
    if f.x > x0 and f.x + f.w < x1 and f.z > z0 and f.z + f.h < z1:
      result.holes.add f; continue
    # il tratto del contorno dell'apertura che sta dentro il pannello: entra in e1,
    # esce in e2; nel pannello forato si percorre al contrario, da e2 a e1
    let pg = poligono(f)
    let n = pg.len
    var k0 = -1
    for i in 0 ..< n:
      if not dentro(pg[i]) and dentro(pg[(i + 1) mod n]): k0 = i; break
    if k0 < 0: continue   # l'apertura copre tutto il pannello: non succede
    let e1 = bordo(pg[(k0 + 1) mod n], pg[k0])
    var catena = @[e1]
    var i = (k0 + 1) mod n
    while dentro(pg[i]):
      catena.add pg[i]
      i = (i + 1) mod n
    let e2 = bordo(pg[(i + n - 1) mod n], pg[i])
    catena.add e2
    tacche.add (lungo(e2), lungo(e1), catena)
  if tacche.len == 0: return
  let angoli = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
  proc tolto(t: float): bool =
    for tc in tacche:
      if tc.da <= tc.a:
        if t > tc.da and t < tc.a: return true
      elif t > tc.da or t < tc.a: return true   # la tacca passa sull'angolo di partenza
  # gli eventi lungo il bordo: gli angoli tenuti e, dove comincia una tacca, la
  # sua catena al contrario
  var eventi: seq[(float, seq[(float, float)])]
  for k, q in angoli:
    let t = [0.0, w, w + h, 2 * w + h][k]
    if not tolto(t): eventi.add (t, @[q])
  for tc in tacche:
    var c: seq[(float, float)]
    for j in countdown(tc.catena.high, 0): c.add tc.catena[j]
    eventi.add (tc.da, c)
  eventi.sort(proc (a, b: (float, seq[(float, float)])): int = cmp(a[0], b[0]))
  for (_, pts) in eventi:
    for q in pts: result.contorno.add q

proc pieni*(p: Part; asse: char; c: float): seq[(float, float)] =
  ## Dove un pannello con contorno è pieno lungo una linea: per `asse` 'z' la
  ## linea z = c (tratti in x), per 'x' la linea x = c (tratti in z). Senza
  ## contorno: tutto il pannello. I fori non contano qui.
  if p.contorno.len == 0:
    return (if asse == 'z': @[(p.pos.x, p.x1)] else: @[(p.pos.z, p.z1)])
  var tagli: seq[float]
  let n = p.contorno.len
  for i in 0 ..< n:
    let (a, b) = (p.contorno[i], p.contorno[(i + 1) mod n])
    let (ua, va, ub, vb) = if asse == 'z': (a[0], a[1], b[0], b[1]) else: (a[1], a[0], b[1], b[0])
    if (va <= c and vb > c) or (vb <= c and va > c):
      tagli.add ua + (c - va) / (vb - va) * (ub - ua)
  tagli.sort()
  var i = 0
  while i + 1 < tagli.len:
    result.add (tagli[i], tagli[i + 1])
    i += 2

proc find*(m: Model; name: string): Part =
  for p in m.parts:
    if p.name == name: return p
  raise newException(KeyError, "parte non trovata: " & name)

proc has*(m: Model; name: string): bool =
  ## C'è almeno una parte con questo nome?
  for p in m.parts:
    if p.name == name: return true

type BomRow* = object
  name*: string
  kind*: Kind
  dims*: array[3, float]   ## dimensioni ordinate dalla più grande
  count*: int

proc sortedDims(p: Part): array[3, float] =
  var a = [p.size.x, p.size.y, p.size.z]
  for i in 0..1:
    for j in i+1..2:
      if a[j] > a[i]: swap(a[i], a[j])
  a

proc bom*(m: Model): seq[BomRow] =
  ## Distinta: pezzi uguali (stesso tipo e stesse misure) contati insieme.
  for p in m.parts:
    if p.kind in {kKnob, kWall}: continue
    let d = sortedDims(p)
    var found = false
    for row in result.mitems:
      if row.kind == p.kind and row.dims == d:
        inc row.count
        if p.name notin row.name.split(", "): row.name.add ", " & p.name
        found = true
        break
    if not found:
      result.add BomRow(name: p.name, kind: p.kind, dims: d, count: 1)
