## Il visore 3D della parete, in Nim compilato in JavaScript.
##
## Gira nel browser: riceve i modelli (oggetti `Model` di Caderò, calcolati
## nel browser dallo stesso codice Nim che fa le tavole) e li disegna con
## three.js, attraverso i binding di `js/three.nim`. La pagina (pulsanti,
## stile, tavola) è in `tools/visore3d.tpl.html`; il documento nimib
## `docsrc/visore3d.nim` mette insieme pagina, modelli e questo codice.
##
## Assi: x CAD -> x three, z CAD (altezza) -> y three, y CAD (profondità) -> -z three.
##
## Le parti principali:
## - `costruisci`: dal modello alla scena (geometrie, gruppi apribili, esploso)
## - `posa`: dove sta un gruppo apribile quando è aperto per una frazione k
## - `viste`: i punti di vista dei pulsanti "Vista"
## - eventi: tocco = apri/chiudi, pulsanti

import std/[algorithm, math, strutils, tables]
import model
import js/[three, pagina]
export model, tables
export three.quandoThreePronto

when not defined(js):
  {.error: "il visore si compila solo con il backend JavaScript (nim js)".}

type
  Carta* = object
    ## La carta da parati sul muro: un'immagine (data URL) e le misure reali
    ## di una piastrella del motivo, in cm. `src` vuoto: niente carta.
    src*: string
    w*, h*: float

  Unita = ref object
    ## Un gruppo apribile: cassetto, anta, ribalta, coperchio, materasso, tavolino.
    nome, apre: string
    corsa, alzata: float
    pivot, inner: Group     ## pivot ruota/trasla, inner riporta le parti al loro posto
    k, target: float        ## 0 chiuso, 1 aperto; k insegue target a ogni fotogramma
    disegnataAperta: bool   ## il modello la disegna già aperta (y < 0)
    soglia: float           ## da dove comincia in profondità (per l'antina nel tavolino)
    dentro: Unita           ## il contenitore che la porta con sé (o nil)
    centro: Vector3
    verso: float            ## per "alza": avanti (+1) o indietro (-1)

  Pezzo = ref object
    ## Quello che l'esploso sposta: un pannello, o un gruppo/blocco tutto insieme.
    wrap: Group
    fisso, fronte, apribile: bool
    apre: string            ## come si apre, se è un gruppo apribile
    blocco: string          ## il mobile a cui appartiene un gruppo apribile (es. un cassetto)
    dir: Vector3

  Vista = object
    pos, target: array[3, float]
    fov: float


# --- le misure di una parte, con i nomi brevi del JSON di prima ---------------
proc x(p: Part): float = p.pos.x
proc y(p: Part): float = p.pos.y
proc z(p: Part): float = p.pos.z
proc w(p: Part): float = p.size.x
proc d(p: Part): float = p.size.y
proc h(p: Part): float = p.size.z

proc isFronte(p: Part): bool =
  ## il pannello frontale, o uno dei suoi pezzi ("fronte alto sx", "fronte fascia"...)
  p.name == "fronte" or p.name.startsWith("fronte ")

proc preparato(m: Model): Model =
  ## Il modello come lo disegna il visore: il pannello frontale riceve come
  ## fori anche le sagome dei frontali, che vanno a occuparli (vedi `foriVisti`).
  result = m
  for p in result.parts.mitems: p.holes = foriVisti(m, p)

# --- le misure che si regolano a mano --------------------------------------------
type
  Regolazione* = object
    ## Una misura che si sceglie nel visore (es. la larghezza dell'anta di sinistra):
    ## pulsanti − e + di `passo` e un campo per scrivere il numero.
    nome*: string
    valore*: float       ## quella di partenza
    passo*: float        ## di quanto cambiano i pulsanti − e +
  Ricalcolo* = proc (chiave: string; valori: seq[float]): tuple[modello: Model, nota, tavola: string]
    ## il modello della variante `chiave` con le misure scelte (nell'ordine delle
    ## regolazioni), una nota (gli spazi calcolati, cosa non torna) e la sua tavola

# --- stato del visore ---------------------------------------------------------
var
  modelli: Table[string, Model]
  carta: Carta
  modello: Model         ## il modello mostrato ora
  stage, status: Element
  scene: Scene
  camera: PerspectiveCamera
  renderer: WebGLRenderer
  controls: OrbitControls
  mats: Table[Kind, Material]
  matMaterasso: seq[Material]
  matMelaminico: Material  ## le scatole in melaminico grigio dei falegnami
  matVetro, matGiallo: Material  ## la lampada: la sfera di vetro e la base
  cielo, sole, lucina: Light    ## le luci della stanza e quella della lampada
  sera = false                  ## la stanza di sera: luci basse, si vede la lampada
  lampadaAccesa = true          ## la lampada si accende e si spegne toccandola
  cartaMat: Material
  edgeMat: Material
  group: Group
  units: seq[Unita]
  frontPanel: seq[Object3D]
  walls: seq[Mesh]
  pezzi: seq[Pezzo]
  esploso, esplosoTarget: float
  box: Box3
  c: Vector3          ## il centro del mobile
  size: float         ## la diagonale del mobile
  anim: tuple[attiva: bool, fromPos, fromTarget, toPos, toTarget: Vector3, t0: float]
  geometrie: seq[BufferGeometry]   ## della scena di ora: si liberano quando si ricostruisce
  aggiorna: proc (m: Model)        ## ricostruisce la scena con un altro modello (vedi `mostra`)
  betulla = true         ## il pulsante "Betulla": il multistrato con la sua venatura
  matFaccia, matFacciaFrontali, matBordo: Material   ## betulla: faccia, faccia dei frontali, bordo
  legni: seq[(Mesh, Part)]         ## le parti in multistrato della scena di ora
  sceltaVenatura: Table[string, Venatura]   ## le venature girate a mano nel visore, per parte
  guideAccese = false    ## il pulsante "Guide": le linee guida del modello, tratteggiate
  matGuida: Material

# --- materiali ------------------------------------------------------------------
proc tessuto(disegna: proc (x: Ctx2D)): Material =
  ## Un materiale di tessuto avorio: una piastrella 128 × 128 disegnata su un canvas.
  let cv = nuovoCanvas(128)
  let x = cv.ctx2d
  x.fillStyle = "#f8f3e6"; x.fillRect(0, 0, 128, 128)
  disegna(x)
  let t = newCanvasTexture(cv.toJs)
  t.wrapS = RepeatWrapping(); t.wrapT = RepeatWrapping(); t.colorSpace = SRGBColorSpace()
  t.anisotropy = 4
  newMeshStandardMaterial(js{map: t, roughness: 0.95})

proc materiali() =
  let ply = newMeshStandardMaterial(js{color: 0xe3c9a0, roughness: 0.8})
  let front = newMeshStandardMaterial(js{color: 0xead3ad, roughness: 0.8})
  # il materasso: sopra e sotto trapuntato a rombi con un bottoncino a ogni
  # incrocio, sui lati una fascia rigata. Le piastrelle sono di 20 cm.
  let trapunta = tessuto(proc (x: Ctx2D) =
    x.strokeStyle = "#d9cfb6"; x.lineWidth = 3
    x.beginPath(); x.moveTo(0, 64); x.lineTo(64, 0); x.lineTo(128, 64); x.lineTo(64, 128); x.closePath()
    x.stroke()
    x.fillStyle = "#cbbf9f"
    for (a, b) in [(0.0, 64.0), (64.0, 0.0), (128.0, 64.0), (64.0, 128.0)]:
      x.beginPath(); x.arc(a, b, 4, 0, 7); x.fill())
  let fascia = tessuto(proc (x: Ctx2D) =
    x.fillStyle = "#ece6d8"
    for i in countup(0, 127, 32): x.fillRect(i.float, 0, 10, 128)
    x.fillStyle = "#c9bfa8"; x.fillRect(0, 0, 128, 6); x.fillRect(0, 122, 128, 6))   # i cordoncini
  matMaterasso = @[fascia, fascia, trapunta, trapunta, fascia, fascia]   # ±x, ±y, ±z
  mats[kPanel] = ply
  matMelaminico = newMeshStandardMaterial(js{color: 0xc9cdd1, roughness: 0.6})
  mats[kFront] = front
  mats[kBox] = front
  mats[kKnob] = newMeshStandardMaterial(js{color: 0x3a2e22})
  mats[kAccessory] = newMeshStandardMaterial(js{color: 0xf5f5f5, roughness: 0.4})
  # la lampada: vetro bianco che si accende un poco, base gialla lucida
  matVetro = newMeshStandardMaterial(js{color: 0xfffaf0, roughness: 0.3, emissive: 0xffe9b8, emissiveIntensity: 0.75})
  matGiallo = newMeshStandardMaterial(js{color: 0xf2e49c, roughness: 0.15, metalness: 0.05})
  mats[kWall] = newMeshStandardMaterial(js{color: 0xb8bcc0, roughness: 1, transparent: true, opacity: 0.45})
  # la carta da parati: una piastrella del motivo ripetuta alle sue misure reali (cm)
  if carta.src.len > 0:
    let tex = caricaTexture(carta.src.cstring)
    tex.wrapS = RepeatWrapping(); tex.wrapT = RepeatWrapping()
    tex.colorSpace = SRGBColorSpace()
    tex.anisotropy = 4
    cartaMat = newMeshStandardMaterial(js{map: tex, roughness: 0.9, emissive: 0xffffff,
                                          emissiveMap: tex, emissiveIntensity: 0.3})
  edgeMat = newLineBasicMaterial(js{color: 0x6b5a45})

proc uvMaterasso(g: BufferGeometry) =
  ## uv in cm sulle facce, per ripetere il tessuto a 20 cm
  let uv = g.attributes.uv
  let pos = g.attributes.position
  let nor = g.attributes.normal
  g.computeBoundingBox()
  let b = g.boundingBox
  for i in 0 ..< uv.count:
    let (px, py, pz) = (pos.getX(i), pos.getY(i), pos.getZ(i))
    if abs(nor.getY(i)) > 0.5: uv.setXY(i, px / 20, pz / 20)
    else:   # sui lati la fascia copre tutta l'altezza, le righe vanno ripetute in lunghezza
      let u = if abs(nor.getX(i)) > 0.5: pz else: px
      uv.setXY(i, u / 20, (py - b.min.y) / (b.max.y - b.min.y))

proc uvCarta(g: BufferGeometry) =
  ## coordinate uv in cm sulla faccia verso la stanza, per ripetere il motivo
  ## (sulle facce di fianco, come quella della risega, u va lungo la profondità)
  let uv = g.attributes.uv
  let pos = g.attributes.position
  let nor = g.attributes.normal
  for i in 0 ..< uv.count:
    let u = if abs(nor.getX(i)) > 0.5: pos.getZ(i) else: pos.getX(i)
    if carta.w > 0: uv.setXY(i, u / carta.w, pos.getY(i) / carta.h)
    else: uv.setXY(i, 0, 0)

# --- il multistrato di betulla --------------------------------------------------
# Ogni parte in multistrato ha due materiali: la faccia, con la venatura, e il
# bordo, con gli strati incollati. Le coordinate uv sono in cm (come per la carta
# da parati): sulla faccia u va lungo la venatura, sul bordo v attraversa lo spessore.
const
  lungoVenatura = 120.0 ## la piastrella della venatura: 120 cm lungo la venatura
  latoVenatura = 60.0   ## e 60 di traverso
  latoBordo = 10.0      ## la piastrella del bordo: 10 cm lungo il bordo, tutto lo spessore
  strati = 13           ## gli strati di un multistrato di betulla da 18 mm

proc rnd(i: int): float =
  ## un numero tra 0 e 1, sempre lo stesso per lo stesso i (la venatura non cambia)
  let x = sin(float(i) * 12.9898 + 78.233) * 43758.5453
  x - floor(x)

proc rgba(r, g, b: int; a: float): cstring =
  cstring("rgba(" & $r & "," & $g & "," & $b & "," & formatFloat(a, ffDecimal, 3) & ")")

proc hash2(i, j, seme: int): float =
  ## un numero tra 0 e 1 per il nodo (i, j) della griglia: sempre lo stesso
  let x = sin(float(i) * 127.1 + float(j) * 311.7 + float(seme) * 74.7) * 43758.5453
  x - floor(x)

proc rumore(x, y: float; gx, gy, seme: int): float =
  ## rumore liscio e periodico: x, y in [0, 1), una griglia gx × gy che si richiude
  let (fx0, fy0) = (x * float(gx), y * float(gy))
  let (i0, j0) = (int(floor(fx0)), int(floor(fy0)))
  var (fx, fy) = (fx0 - float(i0), fy0 - float(j0))
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  let (ia, ib) = (floorMod(i0, gx), floorMod(i0 + 1, gx))
  let (ja, jb) = (floorMod(j0, gy), floorMod(j0 + 1, gy))
  let (a, b) = (hash2(ia, ja, seme), hash2(ib, ja, seme))
  let (c, d) = (hash2(ia, jb, seme), hash2(ib, jb, seme))
  (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy

proc fbm(x, y: float; gx, gy, seme, ottave: int): float =
  ## più rumori sovrapposti, ognuno fitto il doppio e forte la metà
  var (amp, tot) = (1.0, 0.0)
  for o in 0 ..< ottave:
    result += amp * rumore(x, y, gx shl o, gy shl o, seme + o)
    tot += amp; amp *= 0.5
  result /= tot

const lucePropria = 0.4   ## la luce propria della betulla, di giorno

proc texBetulla(): Texture =
  ## La faccia: betulla sfogliata, come nei disegni dei falegnami. Fibre fitte lungo
  ## u che si piegano in archi larghi, fasce morbide e qualche nuvola più chiara o
  ## più scura. Tutto periodico, così la piastrella si ripete senza giunte.
  const (w, h) = (1024, 512)
  let cv = nuovoCanvas(w, h)
  let x = cv.ctx2d
  let img = x.pixel(w, h)
  for j in 0 ..< h:
    let v = float(j) / float(h)
    for i in 0 ..< w:
      let u = float(i) / float(w)
      let vv = floorMod(v + (fbm(u, v, 2, 2, 1, 3) - 0.5) * 0.18, 1.0)   # gli archi
      let fibre = fbm(0, vv, 1, 220, 7, 3) * 0.6 + fbm(u, vv, 3, 90, 9, 2) * 0.4
      let nuvole = fbm(u, v, 3, 6, 20, 4)
      let fasce = fbm(u, vv, 1, 14, 30, 2)
      let t = clamp(0.45 + 0.66 * (fasce - 0.5) + 0.56 * (fibre - 0.5) + 0.5 * (nuvole - 0.5), 0.0, 1.0)
      # i colori dei disegni dei falegnami (Pietro: "la loro era perfetta"): giallo
      # caldo e chiaro, venatura leggera
      img.metti(j * w + i, int(248 - 12 * t), int(230 - 22 * t), int(192 - 30 * t))
  x.disegna(img)
  result = newCanvasTexture(cv.toJs)
  result.wrapS = RepeatWrapping(); result.wrapT = RepeatWrapping(); result.colorSpace = SRGBColorSpace()
  result.anisotropy = 8

proc texStrati(): Texture =
  ## Il bordo: gli strati del multistrato, chiari e scuri alternati, con la colla in mezzo.
  const n = 128
  let N = float(n)
  let cv = nuovoCanvas(n)
  let x = cv.ctx2d
  let passo = N / float(strati)
  for i in 0 ..< strati:
    x.fillStyle = if i mod 2 == 0: cstring"#efe0bf" else: cstring"#d9bf92"
    x.fillRect(0, float(i) * passo, N, passo + 0.5)
    x.fillStyle = rgba(104, 76, 40, 0.45)
    x.fillRect(0, float(i) * passo, N, 0.9)
  result = newCanvasTexture(cv.toJs)
  result.wrapS = RepeatWrapping(); result.wrapT = RepeatWrapping(); result.colorSpace = SRGBColorSpace()
  result.anisotropy = 8

proc materialiBetulla() =
  let faccia = texBetulla()
  # un po' di luce propria (emissive con la stessa texture): anche le facce in ombra
  # restano chiare e calde come nei disegni dei falegnami; di sera si spegne (`luci`)
  matFaccia = newMeshStandardMaterial(js{map: faccia, roughness: 0.75, emissive: 0xffffff,
                                         emissiveMap: faccia, emissiveIntensity: lucePropria})
  matFacciaFrontali = newMeshStandardMaterial(js{map: faccia, color: 0xfff8ee, roughness: 0.7,
    emissive: 0xffffff, emissiveMap: faccia, emissiveIntensity: lucePropria})
  matBordo = newMeshStandardMaterial(js{map: texStrati(), roughness: 0.85})

proc diLegno(p: Part): bool =
  ## le parti in multistrato: pannelli, frontali e cassetti che non sono melaminico
  p.kind in {kPanel, kFront, kBox} and p.materiale != "melaminico"

proc chiaveParte(p: Part): string =
  ## una parte, per ricordare la venatura girata anche cambiando variante
  p.name & "@" & $round(p.pos.x) & "," & $round(p.pos.y) & "," & $round(p.pos.z)

proc versoDi(p: Part): Venatura =
  ## la venatura di una parte: girata nel visore o scelta nel modello
  let k = chiaveParte(p)
  if k in sceltaVenatura: sceltaVenatura[k] else: p.verso

proc sottile(p: Part): int =
  ## l'asse dello spessore, in coordinate three: 0 x, 1 y (altezza), 2 z (profondità)
  let s = p.size
  if s.y <= s.x and s.y <= s.z: 2 elif s.z <= s.x and s.z <= s.y: 1 else: 0

proc uvBetulla(g: BufferGeometry; p: Part; v: Venatura) =
  ## Le coordinate uv per la betulla: sulla faccia lungo la venatura, sul bordo
  ## attraverso lo spessore (v da 0 a 1 = tutti gli strati).
  let uv = g.attributes.uv
  let pos = g.attributes.position
  let nor = g.attributes.normal
  let t = sottile(p)
  let tmin = [p.x, p.z, -(p.y + p.d)][t]
  let spess = max([p.w, p.h, p.d][t], 0.01)
  for i in 0 ..< uv.count:
    let q = [pos.getX(i), pos.getY(i), pos.getZ(i)]
    let nn = [abs(nor.getX(i)), abs(nor.getY(i)), abs(nor.getZ(i))]
    let a = if nn[0] >= nn[1] and nn[0] >= nn[2]: 0 elif nn[1] >= nn[2]: 1 else: 2
    if a == t:   # la faccia: orizzontale lungo il primo asse del piano, verticale lungo il secondo
      let (p1, p2) = case a
                     of 2: (0, 1)    # in piedi, di faccia: x e altezza
                     of 1: (0, 2)    # steso: x e profondità
                     else: (2, 1)    # un fianco: profondità e altezza
      let (lungo, traverso) = if v == venVerticale: (q[p2], q[p1]) else: (q[p1], q[p2])
      uv.setXY(i, lungo / lungoVenatura, traverso / latoVenatura)
    else:
      let altro = 3 - a - t
      uv.setXY(i, q[altro] / latoBordo, (q[t] - tmin) / spess)
  uv.needsUpdate = true

proc eScatola(p: Part): bool =
  ## la parte è una scatola semplice (BoxGeometry), non una sagoma estrusa
  p.kind != kKnob and p.holesPiano.len == 0 and p.taccheP.len == 0 and p.holes.len == 0 and
    p.contorno.len == 0 and p.contornoLato.len == 0 and not (p.kind in {kFront, kBox} and p.r > 0)

proc vestiBetulla(m: Mesh; p: Part) =
  ## Mette alla parte la betulla (o il colore semplice, se il pulsante è spento).
  if not betulla:
    m.material = mats[p.kind]; return
  uvBetulla(m.geometry, p, versoDi(p))
  let faccia = if p.kind == kPanel: matFaccia else: matFacciaFrontali
  if eScatola(p):   # BoxGeometry: un gruppo per faccia, ±x, ±y, ±z
    let t = sottile(p)
    var ms: seq[Material]
    for i in 0 ..< 6: ms.add(if i div 2 == t: faccia else: matBordo)
    m.materiali = ms
  else:             # ExtrudeGeometry: prima le facce, poi i bordi
    m.materiali = @[faccia, matBordo]

# --- geometrie --------------------------------------------------------------------
proc roundRect[P: Path](path: P; x, y, w, h, r: float): P =
  ## Un rettangolo con gli angoli arrotondati, come contorno o come foro.
  let r = min(r, min(w / 2, h / 2))
  path.moveTo(x + r, y)
  path.lineTo(x + w - r, y); path.quadraticCurveTo(x + w, y, x + w, y + r)
  path.lineTo(x + w, y + h - r); path.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
  path.lineTo(x + r, y + h); path.quadraticCurveTo(x, y + h, x, y + h - r)
  path.lineTo(x, y + r); path.quadraticCurveTo(x, y, x + r, y)
  path

proc extruded(p: Part): BufferGeometry =
  ## Una sagoma vista di fronte (con i suoi fori) estrusa in profondità.
  var shape: Shape
  if p.contorno.len > 0:      # un pezzo del fronte, con le tacche delle aperture
    shape = newShape()
    for i, (x, z) in p.contorno:
      if i > 0: shape.lineTo(x, z) else: shape.moveTo(x, z)
    shape.closePath()
  else: shape = newShape().roundRect(p.x, p.z, p.w, p.h, p.r)
  for h in p.holes: shape.holes.add newPath().roundRect(h.x, h.z, h.w, h.h, h.r)
  result = newExtrudeGeometry(shape, js{depth: p.d, bevelEnabled: false, curveSegments: 8})
  result.translate(0, 0, -(p.y + p.d))

proc contornoTop(p: Part): seq[(float, float)] =
  ## Il contorno di un pannello orizzontale visto dall'alto: un rettangolo,
  ## con le tacche (`taccheP`) tolte dagli angoli.
  let c = [(p.x, p.y), (p.x + p.w, p.y), (p.x + p.w, p.y + p.d), (p.x, p.y + p.d)]
  for k, (cx, cy) in c:
    var trovata = -1
    for i, n in p.taccheP:   # nelle tacche `z` e `h` valgono come y e profondità
      if cx >= n.x - 0.01 and cx <= n.x + n.w + 0.01 and cy >= n.z - 0.01 and cy <= n.z + n.h + 0.01:
        trovata = i; break
    if trovata < 0: result.add (cx, cy); continue
    let n = p.taccheP[trovata]
    let ix = if abs(cx - n.x) < 0.01: n.x + n.w else: n.x     # l'angolo interno
    let iy = if abs(cy - n.z) < 0.01: n.z + n.h else: n.z
    let prev = c[(k + 3) mod 4]
    if prev[1] == cy: result.add [(ix, cy), (ix, iy), (cx, iy)]
    else: result.add [(cx, iy), (ix, iy), (ix, cy)]

proc extrudedTop(p: Part): BufferGeometry =
  ## Un pannello orizzontale con aperture o tacche (il piano del comodino, il
  ## piano letto): la sagoma vista dall'alto, estrusa verso l'alto per il suo spessore.
  let shape = newShape()
  for i, (x, y) in contornoTop(p):
    if i > 0: shape.lineTo(x, y) else: shape.moveTo(x, y)
  shape.closePath()
  for h in p.holesPiano: shape.holes.add newPath().roundRect(h.x, h.z, h.w, h.h, h.r)
  result = newExtrudeGeometry(shape, js{depth: p.h, bevelEnabled: false, curveSegments: 8})
  result.rotateX(-PI / 2)          # (x, y, z) -> (x, z, -y): y CAD -> -z three
  result.translate(0, p.z, 0)

proc extrudedLato(p: Part): BufferGeometry =
  ## Un pannello sottile in x con una sagoma vista di fianco (il pannello a L):
  ## il contorno nel piano (y, z), estruso in x per il suo spessore.
  let shape = newShape()
  for i, (y, z) in p.contornoLato:
    if i > 0: shape.lineTo(y, z) else: shape.moveTo(y, z)
  shape.closePath()
  result = newExtrudeGeometry(shape, js{depth: p.w, bevelEnabled: false, curveSegments: 8})
  result.rotateY(PI / 2)           # (y, z, e) -> (e, z, -y): y CAD -> -z three
  result.translate(p.x, 0, 0)

proc geometria(p: Part): BufferGeometry =
  ## La forma di una parte: cilindro (foro maniglia), sagoma estrusa o scatola.
  if p.name == "lampada: sfera":       # la sfera di vetro, grande quanto la scatola
    result = newSphereGeometry(p.w / 2, 32, 20)
    result.translate(p.x + p.w / 2, p.z + p.h / 2, -(p.y + p.d / 2))
  elif p.name == "lampada: base":      # la capsula, per metà dentro la striscia
    result = newCapsuleGeometry(p.d / 2, p.h - p.d, 8, 24)
    result.scale(p.w / (p.d / 2), 1, 1)
    result.translate(p.x + p.w, p.z + p.h / 2, -(p.y + p.d / 2))
  elif p.kind == kKnob:
    result = newCylinderGeometry(p.w / 2, p.w / 2, 0.4, 20)
    result.rotateX(PI / 2)
    result.translate(p.x, p.z, -p.y + 0.15)
  elif p.contornoLato.len > 0:
    result = extrudedLato(p)
  elif p.holesPiano.len > 0 or p.taccheP.len > 0:
    result = extrudedTop(p)
  elif p.holes.len > 0 or p.contorno.len > 0 or (p.kind in {kFront, kBox} and p.r > 0):
    result = extruded(p)
  else:
    result = newBoxGeometry(p.w, p.h, p.d)
    result.translate(p.x + p.w / 2, p.z + p.h / 2, -(p.y + p.d / 2))

# --- dal modello alla scena -------------------------------------------------------
proc unitaDi(o: Object3D): Unita =
  ## Il gruppo apribile di un oggetto della scena (salvato in `userData.unit`), o nil.
  if o.userData.hasOwnProperty("unit"): o.userData["unit"].to(Unita) else: nil

proc costruisci(m: Model) =
  ## Ricostruisce la scena per il modello `m`. Ogni parte diventa un oggetto
  ## (mesh + spigoli); le parti con un gruppo apribile vanno dentro la sua
  ## coppia pivot/inner; ogni pezzo dell'esploso ha il suo contenitore `wrap`.
  if group != nil and group.parent != nil: scene.remove(group)
  for g in geometrie: g.dispose()
  group = newGroup(); units = @[]; frontPanel = @[]; walls = @[]; pezzi = @[]; geometrie = @[]
  legni = @[]
  var byName: Table[string, Unita]
  var wrapByName: Table[string, Pezzo]
  # il contenitore che l'esploso sposta: uno per gruppo, uno per ogni altra parte.
  # Il blocco tiene insieme le parti di un mobile; i gruppi apribili (cassetti,
  # ante) hanno un contenitore loro, che nell'esploso esce in avanti dal mobile
  proc wrapOf(p: Part): Group =
    let gruppoApribile = p.apre.len > 0 and p.gruppo.len > 0
    let chiave = if gruppoApribile: p.gruppo
                 elif p.blocco.len > 0: p.blocco else: p.gruppo
    if chiave.len > 0 and chiave in wrapByName:
      return wrapByName[chiave].wrap
    let pz = Pezzo(wrap: newGroup(), fisso: p.kind == kWall, fronte: p.isFronte,
                   apribile: p.apre.len > 0, apre: p.apre,
                   blocco: if gruppoApribile: p.blocco else: "")
    group.add(pz.wrap); pezzi.add pz
    if chiave.len > 0: wrapByName[chiave] = pz
    pz.wrap

  for p in m.parts:
    let g = geometria(p)
    geometrie.add g
    let obj = newGroup()
    let mesh = if p.kind == kSoft: (uvMaterasso(g); newMesh(g, matMaterasso))
               elif p.name == "lampada: sfera": newMesh(g, matVetro)
               elif p.name == "lampada: base": newMesh(g, matGiallo)
               elif p.materiale == "melaminico": newMesh(g, matMelaminico)
               else: newMesh(g, mats[p.kind])
    if diLegno(p):
      vestiBetulla(mesh, p)
      mesh.userData["legno"] = legni.len
      legni.add (mesh, p)
    mesh.userData["nome"] = cstring(p.name)
    obj.add(mesh)
    if p.kind notin {kKnob, kSoft, kWall} and not p.name.startsWith("lampada"):
      let e = newEdgesGeometry(g, 30)
      geometrie.add e
      obj.add(newLineSegments(e, edgeMat))
    if p.kind == kWall and "carta" in p.name:
      uvCarta(g)
      walls.add mesh
    if p.gruppo.len > 0 and p.apre.len > 0:
      var u = byName.getOrDefault(p.gruppo)
      if u == nil:
        u = Unita(nome: p.gruppo, apre: p.apre, corsa: p.corsa, alzata: p.alzata,
                  pivot: newGroup(), inner: newGroup(), soglia: Inf)
        byName[p.gruppo] = u
        # un gruppo "dentro" un altro (l'antina nel tavolino) si muove con lui
        u.dentro = byName.getOrDefault(p.dentro)
        u.pivot.add(u.inner)
        (if u.dentro != nil: u.dentro.inner else: wrapOf(p)).add(u.pivot)
        units.add u
      u.soglia = min(u.soglia, p.y)        # da dove comincia, in profondità
      if p.y < 0: u.disegnataAperta = true  # disegnato già aperto
      u.inner.add(obj)
      obj.userData["unit"] = u.toJs
    else: wrapOf(p).add(obj)
    if p.isFronte: frontPanel.add obj

  # le linee guida (es. i bordi e il centro della nicchia): tratteggiate su tutta
  # l'altezza, appena davanti ai frontali; non si muovono nell'esploso
  if guideAccese and m.guide.len > 0:
    let tutto = newBox3().setFromObject(group)
    if matGuida == nil:
      matGuida = newLineDashedMaterial(js{color: 0x7d8790, dashSize: 6, gapSize: 4,
                                          transparent: true, opacity: 0.85})
    var punti: seq[Vector3]
    for x in m.guide:
      punti.add newVector3(x, 0, 0.4)
      punti.add newVector3(x, tutto.max.y, 0.4)
    let linee = newLinee(punti, matGuida)
    linee.distanzeTratteggio()
    linee.userData["nome"] = cstring"guida"
    geometrie.add cast[Mesh](linee).geometry
    group.add(linee)

  # il perno di ogni gruppo: lo spigolo della cerniera, sul piano del fronte
  for u in units:
    let b = newBox3().setFromObject(u.inner)
    let P = newVector3(0, 0, 0)
    case u.apre
    of "sx": P.set(b.min.x, 0, b.max.z)
    of "dx": P.set(b.max.x, 0, b.max.z)
    of "su": P.set(0, b.max.y, b.max.z)
    of "ribalta dx": P.set(b.max.x, b.max.y, 0)   # spigolo in alto a destra
    else: discard
    u.pivot.position.copy(P); u.inner.position.copy(P).negate()
    if u.disegnataAperta: u.k = 1; u.target = 1
    u.centro = b.getCenter(newVector3())
  # per "alza": chi sta davanti va avanti, chi sta dietro va indietro
  var alzati: seq[Unita]
  for u in units:
    if u.apre == "alza": alzati.add u
  var zMedio = 0.0
  for u in alzati: zMedio += u.centro.z
  zMedio /= max(alzati.len, 1).float
  for u in alzati: u.verso = sgn(u.centro.z - zMedio).float
  # l'esploso, a strati in profondità perché niente si sovrapponga: il muro va
  # indietro, i mobili restano dove sono e si allargano nel piano del fronte
  # (tutti dello stesso fattore: due mobili che non si toccano non si toccano
  # neanche dopo), il fronte va avanti, ante, ribalte e cassetti ancora più
  # avanti. Un cassetto esce dritto dal suo mobile, senza spostarsi di lato; i
  # coperchi del gavone salgono, come aperti.
  const allarga = 0.3
  const (muro, fronte, apribili, sollevati) = (-90.0, 90.0, 170.0, 30.0)
  let C = newBox3()
  for pz in pezzi:
    if not pz.fisso: C.expandByObject(pz.wrap)
  let c0 = C.getCenter(newVector3())
  var dirBlocco: Table[string, Vector3]
  proc nelPiano(o: Object3D): Vector3 =
    newBox3().setFromObject(o).getCenter(newVector3()).sub(c0).multiply(newVector3(allarga, allarga, 0))
  for k, pz in wrapByName:
    if not pz.apribile and not pz.fronte: dirBlocco[k] = nelPiano(pz.wrap)
  proc dirContenitore(o: Object3D): Vector3 =
    ## lo spostamento del mobile che contiene `o` (il materasso nel cassone, un
    ## cassetto nel suo mobile); se nessun mobile lo contiene, il suo
    let c = newBox3().setFromObject(o).getCenter(newVector3())
    for k, pz in wrapByName:
      if k in dirBlocco and newBox3().setFromObject(pz.wrap).containsPoint(c):
        return dirBlocco[k].clone()
    nelPiano(o)
  for pz in pezzi:
    pz.dir =
      if pz.fisso: newVector3(0, 0, muro)
      elif pz.blocco.len > 0 and pz.blocco in dirBlocco:   # cassetto: con il suo mobile, in avanti
        dirBlocco[pz.blocco].clone().add(newVector3(0, 0, apribili))
      elif pz.apre == "alza": nelPiano(pz.wrap).add(newVector3(0, sollevati, 0))
      elif pz.apre == "esce": dirContenitore(pz.wrap)        # il materasso resta sul piano del cassone
      elif pz.apribile: dirContenitore(pz.wrap).add(newVector3(0, 0, apribili))   # cassetti: dritti
      elif pz.fronte: nelPiano(pz.wrap).add(newVector3(0, 0, fronte))
      else: nelPiano(pz.wrap)
  scene.add(group)

proc applyEsploso() =
  for pz in pezzi: pz.wrap.position.copy(pz.dir).multiplyScalar(esploso)

# --- aprire e chiudere ------------------------------------------------------------
proc posa(u: Unita) =
  ## Muove un gruppo: k va da 0 (chiuso) a 1 (aperto).
  let k = u.k
  case u.apre
  of "tira": u.pivot.position.z = (if u.disegnataAperta: k - 1 else: k) * u.corsa
  of "sx": u.pivot.rotation.y = -k * 1.75
  of "dx": u.pivot.rotation.y = k * 1.75
  of "su": u.pivot.rotation.x = -k * 1.6
  of "alza":   # i coperchi si sollevano nel vuoto e si allontanano un poco l'uno dall'altro
    u.pivot.position.y = k * u.corsa; u.pivot.position.z = k * 5 * u.verso
  of "solleva": u.pivot.position.y = k * u.corsa
  of "esce":   # il materasso sale sopra la fascia e poi esce dalla nicchia verso chi guarda
    const f = 0.3
    u.pivot.position.y = min(k / f, 1) * u.alzata
    u.pivot.position.z = max(0, (k - f) / (1 - f)) * u.corsa
  of "ribalta dx":   # l'antina scende, gira intorno alla cerniera e si affianca a destra
    u.pivot.rotation.z = k * PI
  else: discard

proc unitByName(n: string): Unita =
  for u in units:
    if u.nome == n: return u

proc setOpen(u: Unita; open: bool; instant = false) =
  if u == nil: return
  if open and u.dentro != nil and u.dentro.target < 0.5: return   # prima si apre il contenitore
  u.target = if open: 1 else: 0
  if instant or movimentoRidotto(): u.k = u.target; posa(u)
  # chiudendo il tavolino si chiude anche l'antina; aprendo tutto si apre dopo
  for f in units:
    if f.dentro == u and not open: setOpen(f, false, instant)

# --- punti di vista (in cm, coordinate three) -------------------------------------
proc vistaFronte(): Vista =
  ## il mobile intero, alla distanza giusta per lo schermo (anche in verticale)
  let t = tan(degToRad(35) / 2)
  let m = box.getSize(newVector3())
  let d = max(m.y / 2 / t, m.x / 2 / (t * camera.aspect)) * 1.12 + m.z / 2
  Vista(pos: [c.x, c.y, c.z + d], target: [c.x, c.y, c.z])

proc vista(nome: string): Vista =
  case nome
  of "iniziale":   # di tre quarti, alla stessa distanza di "Fronte"
    let d = vistaFronte().pos[2] - c.z
    Vista(pos: [c.x - d * 0.42, c.y + d * 0.12, c.z + d * 0.92], target: [c.x, c.y, c.z])
  of "fronte": vistaFronte()
  # dentro la nicchia, al centro e un po' in alto: si vedono libreria, comodino e gavone
  of "dentro": Vista(pos: [40.0, 200, -45], target: [200.0, 160, -40], fov: 72)
  else: vistaFronte()

const nomiViste = ["iniziale", "dentro"]   ## i pulsanti; "fronte" serve solo a calcolare la distanza

proc goTo(nome: string; instant = false) =
  let v = vista(nome)
  let toPos = newVector3(v.pos[0], v.pos[1], v.pos[2])
  let toTarget = newVector3(v.target[0], v.target[1], v.target[2])
  camera.fov = if v.fov > 0: v.fov else: 35
  camera.updateProjectionMatrix()
  if instant or movimentoRidotto():
    camera.position.copy(toPos); controls.target.copy(toTarget); controls.update(); return
  anim = (true, camera.position.clone(), controls.target.clone(), toPos, toTarget, adesso())

proc zoom(fattore: float) =
  ## Avvicina (fattore < 1) o allontana la camera dal punto che guarda, con la
  ## stessa animazione delle viste: per i pulsanti + e − (la rotella è lenta).
  let t = controls.target.clone()
  let d = camera.position.clone().sub(t)
  let l = d.length
  if l <= 0: return
  d.multiplyScalar(clamp(l * fattore, controls.minDistance, controls.maxDistance) / l)
  let toPos = t.clone().add(d)
  if movimentoRidotto():
    camera.position.copy(toPos); controls.update(); return
  anim = (true, camera.position.clone(), controls.target.clone(), toPos, t, adesso())

proc pulsantiZoom(stage: Element) =
  ## I pulsanti + e − in alto a destra sulla scena, creati qui perché ogni
  ## pagina con il visore li abbia (lo stile dei pulsanti è quello della pagina).
  let box = document.createElement("div")
  box.setAttribute("style", "position:absolute;top:10px;right:10px;display:flex;flex-direction:column;gap:6px;z-index:1")
  let stile = "width:38px;height:38px;padding:0;font-size:22px;line-height:1;opacity:.92"
  for (testo, titolo, fattore) in [("+", "Avvicina", 0.7), ("−", "Allontana", 1 / 0.7)]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let fattore = fattore
      let b = document.createElement("button")
      b.setAttribute("type", "button")
      b.setAttribute("title", titolo.cstring)
      b.setAttribute("aria-label", titolo.cstring)
      b.setAttribute("style", stile.cstring)
      b.textContent = testo.cstring
      b.addEventListener("click", proc (ev: Event) = zoom(fattore))
      box.appendChild(b)
  stage.appendChild(box)

# --- toccare il mobile ------------------------------------------------------------
var
  ray: Raycaster
  ndc: Vector2

proc visibile(o: Object3D): bool =
  var o = o
  while o != nil:
    if not o.visible: return false
    o = o.parent
  true

proc mira(ev: PointerEv) =
  ## Punta il raggio dalla camera verso il punto toccato.
  let r = rettangolo(renderer.domElement.to(Element))
  ndc.set(((ev.clientX - r.left) / r.width) * 2 - 1, -((ev.clientY - r.top) / r.height) * 2 + 1)
  ray.setFromCamera(ndc, camera)

proc unitAt(ev: PointerEv): Unita =
  ## Il gruppo apribile toccato: la prima superficie visibile decide.
  mira(ev)
  for h in ray.intersectObject(group, true):
    if not visibile(h.`object`) or h.`object`.isLineSegments: continue
    var o = h.`object`
    while o != nil and unitaDi(o) == nil: o = o.parent
    if o == nil: return nil
    var u = unitaDi(o)
    # con il tavolino aperto, un tocco sul piano dietro i cassetti apre l'antina
    var figlio: Unita
    for f in units:
      if f.dentro == u: figlio = f; break
    if figlio != nil and u.target > 0.5:
      let loc = u.inner.worldToLocal(h.point.clone())
      if -loc.z >= figlio.soglia - 0.5: u = figlio
    # l'antina chiusa, toccata da sotto, apre prima il tavolino
    if u.dentro != nil and u.dentro.target < 0.5 and u.target < 0.5: u = u.dentro
    return u
  nil

proc legnoAt(ev: PointerEv): int =
  ## La parte in multistrato toccata (il suo posto in `legni`), o -1.
  mira(ev)
  for h in ray.intersectObject(group, true):
    if not visibile(h.`object`) or h.`object`.isLineSegments: continue
    let o = h.`object`
    if o.userData.hasOwnProperty("legno"): return o.userData["legno"].to(int)
    return -1
  -1

proc giraVenatura(i: int): string =
  ## Gira la venatura della parte i (orizzontale <-> verticale) e dice com'è ora.
  let (m, p) = legni[i]
  let v = if versoDi(p) == venVerticale: venOrizzontale else: venVerticale
  sceltaVenatura[chiaveParte(p)] = v
  vestiBetulla(m, p)
  p.name & ": venatura " & $v

# --- misurare toccando -----------------------------------------------------------------
# Con "Misura" premuto, un tocco prende le misure della superficie toccata: in
# orizzontale e in verticale (sul piano della faccia), fino al punto notevole più
# vicino da ogni parte. Un punto notevole è dove la superficie finisce (un bordo,
# un foro, uno scalino) o dove qualcosa le sta davanti (un muro, un pannello, il
# materasso). Così toccando un'anta si leggono le sue misure, toccando il fronte
# appena sopra l'anta lo stacco fino al bordo, toccando il muro dentro la nicchia
# l'altezza dal materasso al cielo.
type Misura = object
  a, b: Vector3        ## i due estremi
  testo: string
  etichetta: Element   ## il numero, sopra la scena
  gruppo: int          ## le misure di un trascinamento (l'anteprima) vanno via insieme
  id: int              ## toccando il numero o la linea si toglie solo questa misura
  trascinata: bool     ## presa trascinando da un punto all'altro: arancione, non blu
var
  misure: seq[Misura]
  prossimaMisura = 0
  prossimoGruppo, anteprima = -1   ## anteprima: il gruppo che si sta trascinando
  lavagna: Element   ## l'SVG sopra la scena dove si disegnano le linee delle misure

proc togli(e: Element) {.importjs: "#.remove()".}

proc solidi(): seq[Object3D] =
  ## le mesh visibili della scena, senza spigoli né misure
  proc giu(o: Object3D; acc: var seq[Object3D]) =
    if not o.visible: return
    if o.isMesh: acc.add o
    for f in o.children: giu(f, acc)
  giu(group, result)

proc primo(ss: seq[Object3D]; o, d: Vector3; lontano: float): Intersezione =
  ## il primo solido sul raggio da o lungo d, entro `lontano`, o nil
  ray.set(o, d); ray.near = 0; ray.far = lontano
  let hs = ray.intersectObjects(ss, false)
  result = if hs.len > 0: hs[0] else: nil
  ray.near = 0; ray.far = 1e9

proc fino(ss: seq[Object3D]; p, n, d: Vector3; ogg: Object3D; massimo = 700.0): float =
  ## Da p (sulla faccia di normale n) lungo d: la distanza dal primo punto notevole
  ## (al più `massimo`).
  const eps = 0.4      # ci si stacca un poco dalla faccia
  let o = p.clone().addScaledVector(n, eps)
  var tMax = massimo
  let h = primo(ss, o, d, massimo)
  if h != nil: tMax = h.distance      # qualcosa sporge davanti alla faccia
  let giu = n.clone().negate()
  proc sopra(t: float): bool =
    ## a distanza t la faccia c'è ancora, alla stessa profondità e dello stesso pezzo
    let q = p.clone().addScaledVector(d, t).addScaledVector(n, eps)
    let k = primo(ss, q, giu, eps + 0.6)
    k != nil and k.`object` == ogg and abs(k.distance - eps) < 0.2
  var (a, t) = (0.0, 0.0)
  let passo = min(1.0, massimo / 4)
  while t < tMax:
    let t2 = min(t + passo, tMax)
    if not sopra(t2):
      a = t
      var b = t2
      for _ in 0 ..< 12:     # il bordo, al decimo di millimetro
        let m = (a + b) / 2
        if sopra(m): a = m else: b = m
      return min((a + b) / 2, tMax)
    t = t2
  tMax

proc asse(n: Vector3): int =
  let (x, y, z) = (abs(n.x), abs(n.y), abs(n.z))
  if x >= y and x >= z: 0 elif y >= z: 1 else: 2

proc versore(i: int): Vector3 =
  case i
  of 0: newVector3(1, 0, 0)
  of 1: newVector3(0, 1, 0)
  else: newVector3(0, 0, 1)

proc cancellaMisure() =
  for m in misure: togli(m.etichetta)
  misure = @[]
  anteprima = -1
  if lavagna != nil: lavagna.innerHTML = ""
  el("t-cancella").nascosto(true)

proc numero(v: float): string =
  let r = round(v * 10) / 10
  if abs(r - round(r)) < 0.05: $int(round(r)) else: formatFloat(r, ffDecimal, 1)

proc colpito(ev: PointerEv): Intersezione =
  ## la prima superficie visibile sotto il dito, o nil; i muri trasparenti (senza
  ## carta da parati) si attraversano, così si misura il mobile anche da dietro
  mira(ev)
  for k in ray.intersectObject(group, true):
    if visibile(k.`object`) and k.`object`.isMesh and
        not cast[Mesh](k.`object`).material.transparent: return k
  nil

proc normaleAsse(h: Intersezione): Vector3 =
  ## la normale della faccia toccata, sull'asse più vicino
  let nm = normaleMondo(h)
  result = versore(asse(nm))
  if nm.dot(result) < 0: result.negate()

proc assiFaccia(ax: int): seq[int] =
  ## sul piano della faccia: orizzontale e verticale; su un piano steso, x e profondità
  case ax
  of 0: @[2, 1]
  of 2: @[0, 1]
  else: @[0, 2]

proc nomeDi(o: Object3D): string =
  if o.userData.hasOwnProperty("nome"): $o.userData["nome"].to(cstring) else: ""

proc cmPerPixel(p: Vector3): float =
  ## quanti cm fa un pixel dello schermo, alla distanza di p
  let d = camera.position.clone().sub(p).length
  2 * d * tan(degToRad(camera.fov) / 2) / stage.altezza

proc aggancia(ss: seq[Object3D]; h: Intersezione; soloAsse = -1): Vector3 =
  ## Il punto toccato, spostato sul bordo più vicino se ce n'è uno a pochi pixel:
  ## lungo `soloAsse`, o su ognuno dei due assi della faccia (così si aggancia un angolo).
  let n = normaleAsse(h)
  result = h.point.clone()
  let raggio = 14 * cmPerPixel(h.point)
  for i in assiFaccia(asse(n)):
    if soloAsse >= 0 and i != soloAsse: continue
    let d = versore(i)
    let piu = fino(ss, h.point, n, d, h.`object`, raggio)
    let meno = fino(ss, h.point, n, d.clone().negate(), h.`object`, raggio)
    if min(piu, meno) < raggio - 1e-6:
      if piu <= meno: result.addScaledVector(d, piu) else: result.addScaledVector(d, -meno)

proc togliGruppo(g: int) =
  ## toglie le misure di un tocco
  var resta: seq[Misura]
  for m in misure:
    if m.gruppo == g: togli(m.etichetta) else: resta.add m
  misure = resta
  if misure.len == 0: cancellaMisure()

proc togliMisura(id: int) =
  ## toglie una sola misura (toccata sul numero o sulla linea)
  var resta: seq[Misura]
  for m in misure:
    if m.id == id: togli(m.etichetta) else: resta.add m
  misure = resta
  if misure.len == 0: cancellaMisure()

proc nuovoGruppo(): int =
  inc prossimoGruppo
  prossimoGruppo

proc mettiMisura(a, b: Vector3; testo: string; trascinata = false) =
  ## una misura nel gruppo corrente; toccando il numero si toglie lei sola
  let g = prossimoGruppo
  let id = prossimaMisura
  inc prossimaMisura
  let lab = document.createElement("div")
  lab.setAttribute("class", if trascinata: cstring"quota trascinata" else: cstring"quota")
  lab.setAttribute("title", "Tocca per togliere questa misura")
  lab.textContent = cstring(testo)
  lab.addEventListener("click", proc (ev: Event) = togliMisura(id))
  stage.appendChild(lab)
  misure.add Misura(a: a, b: b, testo: testo, etichetta: lab, gruppo: g, id: id, trascinata: trascinata)
  el("t-cancella").nascosto(false)

proc componente(v: Vector3; i: int): float =
  case i
  of 0: v.x
  of 1: v.y
  else: v.z

var
  partenza: Intersezione   ## il tocco da cui parte il trascinamento
  puntoPartenza: Vector3   ## lo stesso, agganciato al punto notevole più vicino

proc schermo(p: Vector3): (float, float) =
  ## dove cade p sullo schermo, in pixel
  let q = p.clone().project(camera)
  ((q.x + 1) / 2 * stage.larghezza, (1 - q.y) / 2 * stage.altezza)

proc misuraTra(ha, hb: Intersezione; finale: bool): string =
  ## La misura trascinata da ha a hb, sempre dritta (Pietro): orizzontale o verticale
  ## sul piano della faccia da cui parte (su un piano steso: larghezza o profondità),
  ## quella che sullo schermo va più come il dito. Parte dal punto notevole più vicino
  ## al tocco (un bordo o un angolo, entro 14 pixel) e arriva dove si lascia il dito,
  ## alla fine agganciata a un bordo se ce n'è uno a pochi pixel.
  if anteprima >= 0: togliGruppo(anteprima)
  anteprima = if finale: -1 else: nuovoGruppo()
  if finale: discard nuovoGruppo()
  if partenza != ha:
    partenza = ha
    puntoPartenza = aggancia(solidi(), ha)
  let a = puntoPartenza.clone()
  var b = hb.point.clone()
  let n0 = normaleAsse(ha)
  # l'asse: quello della faccia che sullo schermo va più come il trascinamento
  let (ax, ay) = schermo(a)
  let (bx, by) = schermo(b)
  let (dx, dy) = (bx - ax, by - ay)
  var (lungo, meglio) = (-1, -1.0)
  for i in assiFaccia(asse(n0)):
    let (px, py) = schermo(a.clone().addScaledVector(versore(i), 10))
    let (ex, ey) = (px - ax, py - ay)
    let c = abs(ex * dx + ey * dy) / max(hypot(ex, ey) * hypot(dx, dy), 1e-9)
    if c > meglio: (lungo, meglio) = (i, c)
  if finale: b = aggancia(solidi(), hb, lungo)
  let fuori = n0.clone().multiplyScalar(0.25)
  let nomeAsse = ["in orizzontale", "in verticale", "in profondità"]
  let l = componente(b.clone().sub(a), lungo)
  let fine = a.clone().addScaledVector(versore(lungo), l)
  let testo = numero(abs(l))
  let dettaglio = nomeAsse[lungo]
  mettiMisura(a.clone().add(fuori), fine.add(fuori), testo, true)
  let (da, verso) = (nomeDi(ha.`object`), nomeDi(hb.`object`))
  result = testo & " cm " & dettaglio
  if finale and da.len > 0:
    result.add " · da " & da & (if verso.len > 0 and verso != da: " a " & verso else: "")

proc trova(prefisso: string): Object3D =
  ## la prima mesh della scena con il nome che comincia così, o nil
  proc giu(o: Object3D): Object3D =
    if o.isMesh and nomeDi(o).startsWith(prefisso): return o
    for f in o.children:
      let r = giu(f)
      if r != nil: return r
  giu(group)

proc misuraPresa(): string =
  ## Le misure per chi fa la traccia: dal centro della placca alla faccia della
  ## risega (in orizzontale) e al pavimento.
  let placca = trova("presa: placca")
  let risega = trova("risega")
  if placca == nil: return ""
  let c = newBox3().setFromObject(placca).getCenter(newVector3())
  let fuori = newVector3(-0.5, 0, 0)
  var testo = "presa, dal centro della placca: "
  if risega != nil:
    let zR = newBox3().setFromObject(risega).max.z     # la faccia della risega verso la stanza
    let d = c.z - zR
    mettiMisura(c.clone().add(fuori), newVector3(c.x, c.y, zR).add(fuori), numero(abs(d)))
    testo.add numero(abs(d)) & " dalla risega, "
  mettiMisura(c.clone().add(fuori), newVector3(c.x, 0, c.z).add(fuori), numero(c.y))
  testo & numero(c.y) & " da terra"

proc misuraAt(ev: PointerEv): string =
  ## Prende le misure dal punto toccato; dice cosa ha misurato. Le misure di prima restano.
  let h = colpito(ev)
  if h == nil: return "Tocca una superficie per misurarla"
  discard nuovoGruppo()
  if nomeDi(h.`object`).startsWith("presa"): return misuraPresa()
  let ss = solidi()
  let n = normaleAsse(h)
  let ax = asse(n)
  # sul piano della faccia: orizzontale e verticale; su un piano steso, larghezza e profondità
  let assi = assiFaccia(ax)
  let nomiAssi = if ax == 1: @["larghezza", "profondità"] else: @["larghezza", "altezza"]
  let p = h.point.clone()
  var parti: seq[string]
  for j, i in assi:
    let d = versore(i)
    let piu = fino(ss, p, n, d, h.`object`)
    let meno = fino(ss, p, n, d.clone().negate(), h.`object`)
    let fuori = 0.25        # le linee appena davanti alla faccia
    let a = p.clone().addScaledVector(d, -meno).addScaledVector(n, fuori)
    let b = p.clone().addScaledVector(d, piu).addScaledVector(n, fuori)
    let testo = numero(piu + meno)
    mettiMisura(a, b, testo)
    parti.add nomiAssi[j] & " " & testo
  let nome = nomeDi(h.`object`)
  (if nome.len > 0: nome & ": " else: "") & parti.join(" · ") & " cm"

proc posaEtichette() =
  ## Ogni fotogramma: le linee delle misure sullo schermo (il tratto che si vede, con
  ## le stanghette agli estremi) e ogni numero a metà del suo tratto; se due numeri si
  ## toccano, il secondo scende un poco.
  let (w, hh) = (stage.larghezza, stage.altezza)
  if lavagna == nil:
    lavagna = svg("svg")
    lavagna.setAttribute("class", "lavagna")
    # toccando una linea si toglie la sua misura
    lavagna.addEventListener("click", proc (ev: Event) =
      let g = ev.target.Element.getAttribute("data-m")
      if g != nil and g.len > 0: togliMisura(parseInt($g)))
    stage.appendChild(lavagna)
  lavagna.setAttribute("viewBox", cstring("0 0 " & $w & " " & $hh))
  var disegno = ""
  var posti: seq[(float, float)]
  for m in misure:
    var n = 0
    var primo, ultimo: (float, float)
    var (kPrimo, kUltimo) = (-1, -1)
    for k in 0 .. 40:
      let q = m.a.clone().lerpVectors(m.a, m.b, float(k) / 40).project(camera)
      if q.z > 1 or abs(q.x) > 0.98 or abs(q.y) > 0.98: continue
      let pt = ((q.x + 1) / 2 * w, (1 - q.y) / 2 * hh)
      if n == 0: (primo, kPrimo) = (pt, k)
      (ultimo, kUltimo) = (pt, k); inc n
    if n < 2:
      m.etichetta.setAttribute("style", "display:none"); continue
    let linea = "M" & $primo[0] & " " & $primo[1] & "L" & $ultimo[0] & " " & $ultimo[1]
    var stanghette = ""
    let (dx, dy) = (ultimo[0] - primo[0], ultimo[1] - primo[1])
    let l = max(hypot(dx, dy), 1e-6)
    let (ox, oy) = (-dy / l * 7, dx / l * 7)
    for (pt, k, fine) in [(primo, kPrimo, 0), (ultimo, kUltimo, 40)]:
      if k == fine:
        stanghette.add "M" & $(pt[0] + ox) & " " & $(pt[1] + oy) & "L" & $(pt[0] - ox) & " " & $(pt[1] - oy)
    let g = " data-m=\"" & $m.id & "\""
    disegno.add "<path class=\"alone\"" & g & " d=\"" & linea & stanghette & "\"/>"
    disegno.add "<path class=\"tratto" & (if m.trascinata: " trascinata" else: "") & "\"" & g & " d=\"" & linea & stanghette & "\"/>"
    var (x, y) = ((primo[0] + ultimo[0]) / 2, (primo[1] + ultimo[1]) / 2)
    for (px, py) in posti:
      if abs(px - x) < 50 and abs(py - y) < 22: y += 26
    posti.add (x, y)
    m.etichetta.setAttribute("style", cstring("left:" & $x & "px;top:" & $y & "px"))
  lavagna.innerHTML = cstring(disegno)

proc luci() =
  ## Giorno o sera, lampada accesa o spenta: di sera la stanza è quasi buia e la
  ## lampada fa luce intorno; di giorno accesa si vede solo la sfera che brilla.
  let sfera = trova("lampada: sfera")
  let c = if sfera != nil: newBox3().setFromObject(sfera).getCenter(newVector3()) else: newVector3()
  let accesa = lampadaAccesa and sfera != nil and visibile(sfera)
  lucina.position.copy(c)
  cielo.intensity = if sera: 0.12 else: 1.6
  sole.intensity = if sera: 0.04 else: 1.4
  lucina.intensity = if not accesa: 0.0 elif sera: 6000.0 else: 1500.0
  matVetro.emissiveIntensity = if accesa: (if sera: 1.6 else: 0.75) else: 0.04
  if cartaMat != nil: cartaMat.emissiveIntensity = if sera: 0.02 else: 0.3
  for m in [matFaccia, matFacciaFrontali]:
    if m != nil: m.emissiveIntensity = if sera: 0.0 else: lucePropria
  let s = cssVar("--stage")
  scene.background = newColor(if sera: cstring"#14171b" elif s.len > 0: s else: cstring"#dfe3e6")

proc mostra*(m: Model) =
  ## Mostra un altro modello nel visore già avviato (la camera resta dov'è).
  if aggiorna != nil: aggiorna(m)

# --- l'avvio ------------------------------------------------------------------------
proc mostraTavola(chiave: string) =
  ## Se la pagina ha una tavola per variante (`data-chiave`), mostra quella del
  ## modello nel visore; le chiavi senza tavola lasciano tutto com'è.
  let tavole = document.querySelectorAll(".tavola [data-chiave]")
  var c = false
  for t in tavole:
    if t.getAttribute("data-chiave") == chiave.cstring: c = true
  if not c: return
  for t in tavole: t.nascosto(t.getAttribute("data-chiave") != chiave.cstring)

proc avviaVisore*(varianti: Table[string, Model]; cartaDaParati: Carta;
                  regolazioni: seq[Regolazione] = @[]; ricalcola: Ricalcolo = nil) =
  ## Avvia il visore nella pagina. `varianti` ha un modello per ogni combinazione
  ## delle opzioni. Per la nostra idea la chiave è "base" o "tavolino" seguita da
  ## "Scoperta" (risega), "Antina" (solo con il tavolino), "Comodino" (prese sul
  ## comodino): es. "tavolinoScopertaComodino". Per il modello dei falegnami è
  ## "falegnami" seguita dalle modifiche proposte accese, sempre in quest'ordine:
  ## "Tavolino", "Testata", "Risega", "Vani" (es. "falegnamiTestataVani"). Si parte da "base" se c'è, se no
  ## dai falegnami; i pulsanti dei modelli che la pagina non ha restano nascosti.
  ## Con `regolazioni` e `ricalcola` il pulsante "Larghezze in basso" apre un pannello
  ## dove si scelgono quelle misure: il modello si ricalcola a ogni cambio.
  for k, m in varianti: modelli[k] = preparato(m)
  carta = cartaDaParati
  let idea = "base" in modelli
  let falegnami = "falegnami" in modelli
  var variante = if idea: "base" else: "falegnami"
  # i falegnami partono senza il pannellino, se il pulsante non è premuto
  let chiave0 = if idea: "base" else: "falegnami"   # le modifiche partono spente
  modello = modelli[chiave0]
  mostraTavola(chiave0)
  stage = el("stage")
  status = el("status")

  scene = newScene()
  camera = newPerspectiveCamera(35, stage.larghezza / stage.altezza, 1, 5000)
  renderer = newWebGLRenderer(js{antialias: true})
  renderer.setPixelRatio(min(rapportoPixel(), 2))
  renderer.setSize(stage.larghezza, stage.altezza)
  let canvas = renderer.domElement.to(Element)
  stage.prepend(canvas)
  cielo = newHemisphereLight(0xffffff, 0xb0a890, 1.6)
  scene.add(cielo)
  sole = newDirectionalLight(0xffffff, 1.4)
  sole.position.set(-150, 400, 300)
  scene.add(sole)
  # la luce della lampada: calda, nel centro della sfera (le misure sono in cm,
  # quindi l'intensità è grande: cala con il quadrato della distanza)
  lucina = newPointLight(0xffc98a, 0, 0, 2)
  scene.add(lucina)
  materiali()
  materialiBetulla()

  costruisci(modello)
  box = newBox3().setFromObject(group)
  c = box.getCenter(newVector3())
  size = box.getSize(newVector3()).length
  controls = newOrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.minDistance = 1
  controls.maxDistance = size * 4
  controls.zoomSpeed = 2   # la rotella del mouse, di serie, avvicina poco
  pulsantiZoom(stage)
  goTo("iniziale", true)

  for nome in nomiViste:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let nome = nome
      el("v-" & nome).addEventListener("click", proc (ev: Event) =
        goTo(nome))

  # toccare una parte apribile la apre o la chiude (un tocco, non un trascinamento)
  ray = newRaycaster()
  ndc = newVector2()
  ray.params["Line"]["threshold"] = 0.5
  var down: tuple[attivo: bool, x, y, t: float]
  var inizio: Intersezione      # misurando: dove è cominciato il trascinamento
  var ultimoPunto: Intersezione # e l'ultimo punto su una superficie, trascinando
  var dita = 0                  # quante dita sono sullo schermo (con due si zooma)
  proc misurando(): bool = premuto(el("t-misura"))
  canvas.addEventListener("pointerdown", proc (e: Event) =
    let ev = cast[PointerEv](e)
    inc dita
    down = (dita == 1, ev.clientX, ev.clientY, adesso())
    inizio = if misurando() and dita == 1: colpito(ev) else: nil
    ultimoPunto = nil)
  canvas.addEventListener("pointercancel", proc (e: Event) =
    dita = max(0, dita - 1); down.attivo = false; inizio = nil)
  canvas.addEventListener("pointerup", proc (e: Event) =
    let ev = cast[PointerEv](e)
    dita = max(0, dita - 1)
    if not down.attivo: return
    let moved = hypot(ev.clientX - down.x, ev.clientY - down.y)
    let dt = adesso() - down.t
    down.attivo = false
    if misurando():                 # si misura invece di aprire
      if moved > 6 and inizio != nil:   # trascinato: da un punto all'altro
        # se il dito si lascia fuori da ogni superficie, vale l'ultimo punto toccato
        var fine = colpito(ev)
        if fine == nil: fine = ultimoPunto
        if fine != nil: status.textContent = cstring(misuraTra(inizio, fine, true))
        elif anteprima >= 0:
          togliGruppo(anteprima)
          anteprima = -1
      elif moved <= 6:
        status.textContent = cstring(misuraAt(ev))
      inizio = nil
      return
    if moved > 6 or dt > 600: return
    if premuto(el("t-venatura")):   # si gira la venatura invece di aprire
      let i = legnoAt(ev)
      if i >= 0:
        if not betulla: el("t-betulla").click()
        status.textContent = cstring(giraVenatura(i))
      return
    let h = colpito(ev)
    if h != nil and nomeDi(h.`object`).startsWith("lampada"):   # la lampada si accende
      lampadaAccesa = not lampadaAccesa
      luci()
      status.textContent = cstring(if lampadaAccesa: "Lampada accesa" else: "Lampada spenta")
      return
    let u = unitAt(ev)
    if u != nil: setOpen(u, u.target < 0.5))
  canvas.addEventListener("pointermove", proc (e: Event) =
    let ev = cast[PointerEv](e)
    if misurando():
      if down.attivo and inizio != nil and dita == 1 and
          hypot(ev.clientX - down.x, ev.clientY - down.y) > 6:
        let qui = colpito(ev)
        if qui != nil:
          ultimoPunto = qui
          status.textContent = cstring(misuraTra(inizio, qui, false))
      if ev.pointerType == "mouse": canvas.cursore("crosshair")
      return
    if ev.pointerType != "mouse" or ev.buttons != 0: return
    canvas.cursore(if unitAt(ev) != nil: cstring"pointer" else: cstring""))

  # i pulsanti
  let tFront = el("t-fronte")
  let tCarta = el("t-carta")
  tCarta.nascosto(carta.src.len == 0)
  let tPresa = el("t-presa")
  let tLampada = el("t-lampada")
  proc applyToggles() =
    for f in frontPanel: f.visible = not premuto(tFront)
    proc presa(o: Object3D) =
      if o.isMesh and nomeDi(o).startsWith("presa"): o.parent.visible = not premuto(tPresa)
      if o.isMesh and nomeDi(o).startsWith("lampada"): o.parent.visible = premuto(tLampada)
      for f in o.children: presa(f)
    presa(group)
    let on = carta.src.len > 0 and not premuto(tCarta)
    for w in walls: w.material = if on: cartaMat else: mats[kWall]
    luci()
  # Sera: la stanza quasi al buio, la lampada (se accesa) fa luce
  let tSera = el("t-sera")
  tSera.addEventListener("click", proc (ev: Event) =
    sera = not premuto(tSera)
    tSera.premi(sera)
    if sera and not premuto(tLampada): tLampada.premi(true); applyToggles()
    luci())
  for btn in [tFront, tCarta, tPresa, tLampada]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let btn = btn
      btn.addEventListener("click", proc (ev: Event) = btn.premi(not premuto(btn)); applyToggles())
  let tBetulla = el("t-betulla")
  tBetulla.addEventListener("click", proc (ev: Event) =
    betulla = not premuto(tBetulla)
    tBetulla.premi(betulla)
    for (m, p) in legni: vestiBetulla(m, p))
  # cosa fa un tocco sulla scena: apre e chiude, gira la venatura o misura
  const modi = [("t-tocca", "Tocca le parti mobili per aprirle o chiuderle"),
                ("t-venatura", "Tocca un pannello per girarne la venatura"),
                ("t-misura", "Tocca un punto per le misure fino ai bordi più vicini, o trascina da un bordo all'altro (la vista è ferma: si può solo zoomare)")]
  for (id, aiuto) in modi:
    closureScope:
      let (id, aiuto) = (id, aiuto)
      el(id).addEventListener("click", proc (ev: Event) =
        # Misurare premuto di nuovo si spegne: si torna ad aprire
        let id = if id == "t-misura" and premuto(el(id)): "t-tocca" else: id
        for (b, _) in modi: el(b).premi(b == id)
        # misurando la scena sta ferma: niente rotazione né spostamento, solo lo zoom;
        # spento Misurare, le misure restano (si tolgono toccandole o con Togli le misure)
        let mis = id == "t-misura"
        controls.enableRotate = not mis
        controls.enablePan = not mis
        if not mis: canvas.cursore("")
        for (b, a) in modi:
          if b == id: status.textContent = cstring(a))
  el("t-cancella").addEventListener("click", proc (ev: Event) =
    cancellaMisure())
  el("t-chiudi").addEventListener("click", proc (ev: Event) =
    for u in units: setOpen(u, false))
  el("t-apri").addEventListener("click", proc (ev: Event) =
    for u in units:
      if u.dentro == nil: setOpen(u, true)
    for u in units:
      if u.dentro != nil: setOpen(u, true))
  let tEsploso = el("t-esploso")
  tEsploso.addEventListener("click", proc (ev: Event) =
    let on = not premuto(tEsploso)
    tEsploso.premi(on)
    esplosoTarget = if on: 1 else: 0
    if movimentoRidotto(): esploso = esplosoTarget; applyEsploso())

  # cambio di variante: si ricostruisce la scena con l'altro modello
  let tRisega = el("m-risega")
  let tAntina = el("m-antina")
  let tPrese = el("m-prese")
  # le quattro modifiche proposte al modello dei falegnami, indipendenti
  let modifiche = [("p-tavolino", "Tavolino"), ("p-testata", "Testata"), ("p-risega", "Risega"),
                   ("p-vani", "Vani"), ("p-pannellol", "PannelloL"),
                   ("p-nicchia", "Nicchia")]
  el("g-modifiche").nascosto(not falegnami)
  el("g-taglio").nascosto(not falegnami)
  # il taglio del pannello frontale dei falegnami: "" a croce, "Tre" in 3 orizzontali;
  # "Cornice" (pulsante) rimette le due spalle ai lati
  var taglio = if premuto(el("f-tre")): "Tre" else: ""
  let tCornice = el("f-cornice")
  el("g-mobile").nascosto(not idea)
  # il pulsante di un modello compare solo se la pagina ha anche l'altro
  for n in ["base", "tavolino"]: el("m-" & n).nascosto(not idea)
  el("m-falegnami").nascosto(not (idea and falegnami))
  proc pulsanti() =
    let fal = variante == "falegnami"
    tAntina.nascosto(variante != "tavolino")
    for b in [tRisega, tPrese]: b.nascosto(fal)
  pulsanti()
  # le misure regolate a mano (le larghezze della zona bassa): un pannello che si
  # apre con il suo pulsante, una riga per misura con − e + e il numero
  let tRegola = el("p-larghezze")
  let regola = el("regola")
  var valori: seq[float]
  for r in regolazioni: valori.add r.valore
  # (una pagina senza il pannello, come quella dei parametri, non ha niente da regolare)
  let conRegola = tRegola != nil and regola != nil and regolazioni.len > 0 and ricalcola != nil
  if tRegola != nil: tRegola.nascosto(not conRegola or not falegnami)
  proc regolate(): bool =
    if ricalcola == nil: return false
    for i, r in regolazioni:
      if abs(valori[i] - r.valore) > 1e-6: return true
    false
  var notaPartenza = ""
  proc tavolaRegolata(svg: string) =
    var t = document.querySelector(".tavola [data-chiave=\"regolata\"]")
    if t == nil:
      let prima = document.querySelector(".tavola [data-chiave]")
      if prima == nil: return
      t = nuovoDiv()
      t.setAttribute("data-chiave", "regolata")
      prima.parentNode.Element.aggiungi(t)
    t.html = cstring(svg)
  var rifai: proc ()   ## `cambiaModello`, definito più sotto
  if conRegola:
    var righe = "<div class=\"righe-regola\">"
    for i, r in regolazioni:
      let p = (if r.passo == round(r.passo): $int(r.passo) else: $r.passo)
      righe.add "<label for=\"rg-" & $i & "\">" & r.nome & "</label>" &
        "<button type=\"button\" id=\"rg-meno-" & $i & "\" aria-label=\"meno " & p & "\">−" & p & "</button>" &
        "<input id=\"rg-" & $i & "\" type=\"number\" step=\"0.1\" inputmode=\"decimal\">" &
        "<button type=\"button\" id=\"rg-piu-" & $i & "\" aria-label=\"più " & p & "\">+" & p & "</button>" &
        "<span class=\"cm\">cm</span>"
    righe.add "</div><p class=\"nota-regola\"></p>" &
      "<button type=\"button\" id=\"rg-partenza\">Come nel disegno</button>"
    regola.html = cstring(righe)
    proc scrivi() =
      for i in 0 ..< regolazioni.len: el("rg-" & $i).valore = round(valori[i] * 100) / 100
    scrivi()
    notaPartenza = ricalcola("", valori)[1]
    for i in 0 ..< regolazioni.len:
      closureScope:   # ogni giro ha le sue variabili, anche nelle closure
        let i = i
        let passo = regolazioni[i].passo
        el("rg-meno-" & $i).addEventListener("click", proc (ev: Event) =
          valori[i] -= passo; scrivi(); rifai())
        el("rg-piu-" & $i).addEventListener("click", proc (ev: Event) =
          valori[i] += passo; scrivi(); rifai())
        el("rg-" & $i).addEventListener("change", proc (ev: Event) =
          let v = el("rg-" & $i).valore
          if v == v and v > 0: valori[i] = v   # v == v: non è NaN (campo vuoto)
          scrivi(); rifai())
    el("rg-partenza").addEventListener("click", proc (ev: Event) =
      for i, r in regolazioni: valori[i] = r.valore
      scrivi(); rifai())
    tRegola.addEventListener("click", proc (ev: Event) =
      let on = not premuto(tRegola)
      tRegola.premi(on)
      regola.nascosto(not on))
  elif regola != nil:
    regola.html = cstring("<p class=\"nota-regola\"></p>")
  # le linee guida: si ricostruisce la scena con o senza
  let tGuide = el("t-guide")
  if tGuide != nil:
    tGuide.nascosto(modelli[chiave0].guide.len == 0)
    tGuide.addEventListener("click", proc (ev: Event) =
      guideAccese = not premuto(tGuide)
      tGuide.premi(guideAccese)
      rifai())
  proc cambiaModello() =
    pulsanti()
    let fal = variante == "falegnami"
    var chiave = "falegnami"
    if fal:
      for (id, nome) in modifiche:
        if premuto(el(id)): chiave.add nome
      chiave.add taglio
      if premuto(tCornice): chiave.add "Cornice"
    else:
      chiave = variante
      chiave.add (if premuto(tRisega): "Scoperta" else: "") &
                   (if variante == "tavolino" and premuto(tAntina): "Antina" else: "") &
                   (if premuto(tPrese): "Comodino" else: "")
    var nota = ""
    if regolate() and fal:
      # le misure scelte a mano: il modello si calcola adesso, con la sua tavola
      let r = ricalcola(chiave, valori)
      modello = preparato(r.modello)
      nota = r.nota
      tavolaRegolata(r.tavola)
      mostraTavola("regolata")
    else:
      if chiave in modelli: modello = modelli[chiave]
      mostraTavola(chiave)
      if regolazioni.len > 0: nota = notaPartenza
    if regola != nil: regola.querySelector(".nota-regola").html = cstring(nota)
    for n in ["base", "tavolino", "falegnami"]: el("m-" & n).premi(n == variante)
    # le misure restano anche cambiando modello: si tolgono a mano; quello che era
    # aperto resta aperto
    var aperti: Table[string, float]
    for u in units: aperti[u.nome] = u.target
    costruisci(modello); applyToggles(); applyEsploso()
    for u in units:
      if u.nome in aperti and not u.disegnataAperta:
        u.target = aperti[u.nome]; u.k = u.target; posa(u)
    status.textContent = cstring($modello.parts.len & " parti")
  rifai = cambiaModello
  const tagli = [("f-croce", ""), ("f-tre", "Tre")]
  for (id, t) in tagli:
    closureScope:   # ogni giro ha le sue variabili
      let (id, t) = (id, t)
      el(id).addEventListener("click", proc (ev: Event) =
        taglio = t
        for (b, _) in tagli: el(b).premi(b == id)
        cambiaModello())
  for name in ["base", "tavolino", "falegnami"]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let name = name
      el("m-" & name).addEventListener("click", proc (ev: Event) =
        variante = name; cambiaModello())
  var interruttori = @[tRisega, tAntina, tPrese, tCornice]
  for (id, _) in modifiche: interruttori.add el(id)
  for i in 0 ..< interruttori.len:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let b = interruttori[i]
      b.addEventListener("click", proc (ev: Event) = b.premi(not premuto(b)); cambiaModello())
  # si parte dalle opzioni premute nella pagina (per i falegnami: 3 orizzontali,
  # testata alta, vani alti, pannello a L e nicchia, decise da Pietro)
  if falegnami and not idea: cambiaModello()
  applyToggles()
  # un modello qualsiasi (la pagina dei parametri): ricostruisce la scena e
  # rimette aperto quello che era aperto
  aggiorna = proc (m: Model) =
    var aperti: Table[string, float]
    for u in units: aperti[u.nome] = u.target
    modello = preparato(m)
    costruisci(modello); applyToggles(); applyEsploso()
    for u in units:
      if u.nome in aperti and not u.disegnataAperta:
        u.target = aperti[u.nome]; u.k = u.target; posa(u)
    status.textContent = cstring($modello.parts.len & " parti")
  # la tavola sotto il visore si scarica com'è
  el("scarica-tavola").addEventListener("click", proc (ev: Event) =
    let vista = document.querySelector(".tavola [data-chiave]:not([hidden]) svg")
    let svg = if vista != nil: vista else: document.querySelector(".tavola svg")
    scarica(svg.outerHTML, "tavola.svg"))

  # lo sfondo segue il tema chiaro/scuro
  proc applyTheme() =
    let s = cssVar("--stage")
    scene.background = newColor(if s.len > 0: s else: "#dfe3e6")
    luci()
  applyTheme()
  quandoCambiaTema(applyTheme)

  proc loop(now: float) =
    if anim.attiva:
      let k = min(1.0, (now - anim.t0) / 700)
      let e = if k < 0.5: 2 * k * k else: 1 - pow(-2 * k + 2, 2) / 2
      camera.position.lerpVectors(anim.fromPos, anim.toPos, e)
      controls.target.lerpVectors(anim.fromTarget, anim.toTarget, e)
      if k >= 1: anim.attiva = false
    if esploso != esplosoTarget:
      esploso += (esplosoTarget - esploso) * 0.08
      if abs(esplosoTarget - esploso) < 0.002: esploso = esplosoTarget
      applyEsploso()
    for u in units:
      if abs(u.target - u.k) > 0.001: u.k += (u.target - u.k) * 0.15; posa(u)
      elif u.k != u.target: u.k = u.target; posa(u)
    controls.update()
    if misure.len > 0: posaEtichette()
    renderer.render(scene, camera)
    prossimoFotogramma(loop)
  prossimoFotogramma(loop)
  status.textContent = cstring($modello.parts.len & " parti")
  osservaDimensioni(stage, proc () =
    camera.aspect = stage.larghezza / stage.altezza; camera.updateProjectionMatrix()
    renderer.setSize(stage.larghezza, stage.altezza))
