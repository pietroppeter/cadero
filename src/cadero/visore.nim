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
## - eventi: tocco = apri/chiudi, pulsanti, piani di taglio
## - `disegna`: le sezioni in SVG

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
    dir: Vector3

  Vista = object
    pos, target: array[3, float]
    fov: float

  VistaTaglio = object
    ## Una delle tre sezioni: su quale asse si taglia e come si proietta una parte.
    nome, asse: string
    def: int

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
  piani: OrderedTable[string, Mesh]
  assi: Table[string, Vector3]
  tagli: Table[string, int]
  selezionato = ""
  tSez, boxSez: Element
  geometrie: seq[BufferGeometry]   ## della scena di ora: si liberano quando si ricostruisce
  aggiorna: proc (m: Model)        ## ricostruisce la scena con un altro modello (vedi `mostra`)

const
  colPiano = 0x2b8fd6   ## piano di taglio
  colSel = 0xe04a2f     ## piano di taglio selezionato

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

proc geometria(p: Part): BufferGeometry =
  ## La forma di una parte: cilindro (foro maniglia), sagoma estrusa o scatola.
  if p.kind == kKnob:
    result = newCylinderGeometry(p.w / 2, p.w / 2, 0.4, 20)
    result.rotateX(PI / 2)
    result.translate(p.x, p.z, -p.y + 0.15)
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
  var byName: Table[string, Unita]
  var wrapByName: Table[string, Pezzo]
  # il contenitore che l'esploso sposta: uno per gruppo, uno per ogni altra parte
  proc wrapOf(p: Part): Group =
    let chiave = if p.blocco.len > 0: p.blocco else: p.gruppo   # il blocco tiene insieme più gruppi
    if chiave.len > 0 and chiave in wrapByName:
      if p.apre.len > 0: wrapByName[chiave].apribile = true
      return wrapByName[chiave].wrap
    let pz = Pezzo(wrap: newGroup(), fisso: p.kind == kWall, fronte: p.isFronte,
                   apribile: p.apre.len > 0)
    group.add(pz.wrap); pezzi.add pz
    if chiave.len > 0: wrapByName[chiave] = pz
    pz.wrap

  for p in m.parts:
    let g = geometria(p)
    geometrie.add g
    let obj = newGroup()
    let mesh = if p.kind == kSoft: (uvMaterasso(g); newMesh(g, matMaterasso))
               elif p.materiale == "melaminico": newMesh(g, matMelaminico)
               else: newMesh(g, mats[p.kind])
    obj.add(mesh)
    if p.kind notin {kKnob, kSoft, kWall}:
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
  # l'esploso: ogni pezzo si allontana dal centro del mobile; il fronte va
  # avanti, e ancora più avanti ante, cassetti, ribalte e tavolino
  let C = newBox3()
  for pz in pezzi:
    if not pz.fisso: C.expandByObject(pz.wrap)
  let c0 = C.getCenter(newVector3())
  for pz in pezzi:
    let cz = newBox3().setFromObject(pz.wrap).getCenter(newVector3())
    pz.dir = if pz.fisso: newVector3() else: cz.sub(c0).multiply(newVector3(0.7, 0.5, 1.2))
    if pz.fronte:   # il fronte va avanti; i suoi pezzi, se è diviso, si allargano un poco
      pz.dir = cz.clone().sub(c0).multiply(newVector3(0.25, 0.25, 0)).add(newVector3(0, 0, 70))
    if pz.apribile: pz.dir.z += 110
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

proc pianoAt(ev: PointerEv): string =
  ## Il piano di taglio sotto il puntatore, se è più vicino del mobile.
  if not premuto(tSez): return ""
  mira(ev)
  var tutti: seq[Object3D]
  for p in piani.values: tutti.add p
  let hp = ray.intersectObjects(tutti, false)
  if hp.len == 0: return ""
  for hm in ray.intersectObject(group, true):
    if visibile(hm.`object`) and not hm.`object`.isLineSegments:
      if hp[0].distance >= hm.distance: return ""
      break
  $hp[0].`object`.userData["nome"].to(cstring)

# --- sezioni: tre piani di taglio, disegnati in 2D --------------------------------
# Dal modello (tutto chiuso): le parti tagliate sono piene, quelle oltre il
# taglio sono solo contornate, il muro è tratteggiato.
const viste = [
  VistaTaglio(nome: "pianta", asse: "z", def: 200),
  VistaTaglio(nome: "laterale", asse: "x", def: 230),
  VistaTaglio(nome: "prospetto", asse: "y", def: 40)]

proc ext(): tuple[L, P, H: float] =
  ## l'ingombro del mobile, senza il muro
  for p in modello.parts:
    if p.kind != kWall:
      result.L = max(result.L, p.x + p.w); result.P = max(result.P, p.y + p.d)
      result.H = max(result.H, p.z + p.h)

proc massimo(nome: string): float =
  let e = ext()
  case nome
  of "pianta": e.H
  of "laterale": e.L
  else: e.P

proc rect(nome: string; p: Part): array[4, float] =
  ## u0, v0, u1, v1: la parte nelle coordinate del disegno
  case nome
  of "pianta": [p.x, p.y, p.x + p.w, p.y + p.d]
  of "laterale": [p.y, p.z, p.y + p.d, p.z + p.h]
  else: [p.x, p.z, p.x + p.w, p.z + p.h]

proc cut(nome: string; p: Part; c: float): bool =
  ## la parte è tagliata dal piano
  case nome
  of "pianta": p.z <= c and c <= p.z + p.h
  of "laterale": p.x <= c and c <= p.x + p.w
  else: p.y <= c and c <= p.y + p.d

proc oltre(nome: string; p: Part; c: float): bool =
  ## la parte si vede oltre il piano
  case nome
  of "pianta": p.z + p.h < c
  of "laterale": p.x + p.w < c
  else: p.y > c

proc foriTaglio(nome: string; p: Part; c: float): seq[(float, float)] =
  ## dove il taglio attraversa un'apertura del pannello (o, per un pezzo del
  ## fronte con le tacche, dove non è pieno)
  if p.contorno.len > 0 and nome in ["pianta", "laterale"]:
    let (a0, a1) = if nome == "pianta": (p.x, p.x + p.w) else: (p.z, p.z + p.h)
    var da = a0
    for (u0, u1) in p.pieni(if nome == "pianta": 'z' else: 'x', c):
      if u0 > da: result.add (da, u0)
      da = u1
    if da < a1: result.add (da, a1)
  for h in p.holes:
    case nome
    of "pianta":
      if h.z <= c and c <= h.z + h.h: result.add (h.x, h.x + h.w)
    of "laterale":
      if h.x <= c and c <= h.x + h.w: result.add (h.z, h.z + h.h)
    else: discard

proc fmt(v: float): string =
  ## i numeri nei path SVG come li scrive JavaScript (18, non 18.0)
  proc jsStr(v: float): cstring {.importjs: "String(#)".}
  $jsStr(v)

proc rr(x0, y0, x1, y1: float; r = 0.0): string =
  ## rettangolo stondato come path SVG, coordinate del disegno
  let r = min(r, min((x1 - x0) / 2, (y1 - y0) / 2))
  let f = fmt
  "M" & f(x0 + r) & "," & f(y0) & "H" & f(x1 - r) & "Q" & f(x1) & "," & f(y0) & " " & f(x1) & "," & f(y0 + r) &
    "V" & f(y1 - r) & "Q" & f(x1) & "," & f(y1) & " " & f(x1 - r) & "," & f(y1) & "H" & f(x0 + r) &
    "Q" & f(x0) & "," & f(y1) & " " & f(x0) & "," & f(y1 - r) & "V" & f(y0 + r) &
    "Q" & f(x0) & "," & f(y0) & " " & f(x0 + r) & "," & f(y0) & "Z"

proc contornoSvg(p: Part; fv: float): string =
  ## il contorno vero di un pezzo del fronte, come path SVG del prospetto
  for i, (x, z) in p.contorno:
    result.add (if i == 0: "M" else: "L") & fmt(x) & "," & fmt(fv - z)
  result.add "Z"

proc el2(tag: string; attrs: openArray[(string, string)]): Element =
  result = svg(tag.cstring)
  for (k, v) in attrs: result.setAttribute(k.cstring, v.cstring)

proc scheda(nome: string): Element = boxSez.querySelector(cstring("[data-vista=" & nome & "]"))

proc disegna(nome: string) =
  ## Disegna una sezione nel suo SVG.
  let c = tagli[nome].float
  let e = ext()
  let card = scheda(nome)
  let svgEl = card.querySelector("svg")
  svgEl.svuota()
  # l'asse verticale del disegno va verso l'alto: v' = fv - v
  let fv = if nome == "pianta": e.P else: e.H
  proc R(p: Part): array[4, float] =
    let q = rect(nome, p)
    [q[0], fv - q[3], q[2], fv - q[1]]
  var (minU, minV, maxU, maxV) = (Inf, Inf, -Inf, -Inf)
  let gO = el2("g", {"fill": "none", "stroke": "#8a939a", "stroke-width": "0.25"})
  let gC = el2("g", {"fill": "#2a3035", "stroke": "#2a3035", "stroke-width": "0.15", "fill-rule": "evenodd"})
  let gM = el2("g", {"fill": "none", "stroke": "#9aa3a9", "stroke-width": "0.3", "stroke-dasharray": "2 1.5"})
  for p in modello.parts:
    if p.kind == kKnob: continue
    let q = R(p)
    let (a, b, c2, d) = (q[0], q[1], q[2], q[3])
    minU = min(minU, a); minV = min(minV, b); maxU = max(maxU, c2); maxV = max(maxV, d)
    if p.kind == kWall: gM.appendChild el2("path", {"d": rr(a, b, c2, d)}); continue
    if nome == "pianta" and p.taccheP.len > 0 and not cut(nome, p, c) and oltre(nome, p, c):
      # in pianta un pannello con una tacca: il suo contorno vero
      var pts: seq[string]
      for (x, y) in contornoTop(p): pts.add fmt(x) & " " & fmt(fv - y)
      gO.appendChild el2("path", {"d": "M" & pts.join(" L") & " Z"})
      continue
    if cut(nome, p, c) and p.kind notin {kSoft, kAccessory}:
      if nome == "prospetto":     # pannello tagliato di piatto: pieno meno le aperture
        var dd = if p.contorno.len > 0: contornoSvg(p, fv)
                 else: rr(a, b, c2, d, if p.kind == kFront: p.r else: 0)
        for h in p.holes: dd &= rr(h.x, fv - h.z - h.h, h.x + h.w, fv - h.z, h.r)
        gC.appendChild el2("path", {"d": dd})
      else:                       # i pannelli forati si interrompono dove c'è un'apertura
        var fori = foriTaglio(nome, p, c)
        fori.sort()
        let vert = nome == "laterale"
        var da = if vert: b else: a
        let fino = if vert: d else: c2
        proc pezzo(s0, s1: float) =
          if s1 > s0: gC.appendChild el2("path", {"d": (if vert: rr(a, s0, c2, s1) else: rr(s0, b, s1, d))})
        for (h0, h1) in fori:
          let (s0, s1) = if vert: (fv - h1, fv - h0) else: (h0, h1)
          pezzo(da, s0); da = max(da, s1)
        pezzo(da, fino)
    elif oltre(nome, p, c):
      let pathD = if nome == "prospetto" and p.contorno.len > 0: contornoSvg(p, fv)
                  else: rr(a, b, c2, d, if nome == "prospetto": p.r else: 0)
      if p.kind == kSoft: gO.appendChild el2("path", {"d": pathD, "stroke-dasharray": "1.5 1"})
      else: gO.appendChild el2("path", {"d": pathD})
      if nome == "prospetto":
        for h in p.holes: gO.appendChild el2("path", {"d": rr(h.x, fv - h.z - h.h, h.x + h.w, fv - h.z, h.r)})
      if nome == "pianta":
        for h in p.holesPiano: gO.appendChild el2("path", {"d": rr(h.x, fv - h.z - h.h, h.x + h.w, fv - h.z, h.r)})
  svgEl.appendChild gM; svgEl.appendChild gO; svgEl.appendChild gC
  const m = 6.0
  svgEl.setAttribute("viewBox", cstring(fmt(minU - m) & " " & fmt(minV - m) & " " &
    fmt(maxU - minU + 2 * m) & " " & fmt(maxV - minV + 2 * m)))
  card.querySelector("output").textContent = cstring($tagli[nome] & " cm")

proc posizionaPiani() =
  piani["pianta"].position.y = tagli["pianta"].float
  piani["laterale"].position.x = tagli["laterale"].float
  piani["prospetto"].position.z = -tagli["prospetto"].float

proc seleziona(nome: string) =
  selezionato = nome
  for k, piano in piani:
    let sel = k == nome
    let col = if sel: colSel else: colPiano
    piano.material.color.setHex(col); piano.material.opacity = if sel: 0.4 else: 0.28
    cast[LineSegments](piano.children[0]).material.color.setHex(col)
  for card in boxSez.querySelectorAll(".taglio"):
    card.toggleClass("scelta", $card.dataVista == nome)

proc pianiTaglio() =
  ## I piani di taglio nel 3D: azzurri; quello selezionato diventa rosso e si trascina.
  for p in piani.values: scene.remove(p)
  let e = ext()
  const m = 15.0
  proc mat(): Material = newMeshBasicMaterial(js{color: colPiano, transparent: true, opacity: 0.28,
                                                 side: DoubleSide(), depthWrite: false})
  piani["pianta"] = newMesh(newPlaneGeometry(e.L + 2 * m, e.P + 2 * m).rotateX(-PI / 2).translate(e.L / 2, 0, -e.P / 2), mat())
  piani["laterale"] = newMesh(newPlaneGeometry(e.P + 2 * m, e.H + 2 * m).rotateY(PI / 2).translate(0, e.H / 2, -e.P / 2), mat())
  piani["prospetto"] = newMesh(newPlaneGeometry(e.L + 2 * m, e.H + 2 * m).translate(e.L / 2, e.H / 2, 0), mat())
  for k, piano in piani:
    piano.visible = premuto(tSez); piano.userData["nome"] = k.cstring; piano.renderOrder = 10
    # il bordo del piano, per vederlo anche di taglio
    piano.add(newLineSegments(newEdgesGeometry(piano.geometry), newLineBasicMaterial(js{color: colPiano})))
    scene.add(piano)
  seleziona(selezionato)
  posizionaPiani()

proc spostaTaglio(nome: string; val: float) =
  let inp = scheda(nome).querySelector("input")
  let v = round(min(inp.maxValore, max(0.0, val))).int
  if v == tagli[nome]: return
  tagli[nome] = v; inp.valore = v.float
  disegna(nome); posizionaPiani()

proc aggiornaSezioni() =
  for v in viste: disegna(v.nome)
  posizionaPiani()

proc mostra*(m: Model) =
  ## Mostra un altro modello nel visore già avviato (la camera resta dov'è).
  if aggiorna != nil: aggiorna(m)

# --- l'avvio ------------------------------------------------------------------------
proc avviaVisore*(varianti: Table[string, Model]; cartaDaParati: Carta) =
  ## Avvia il visore nella pagina. `varianti` ha un modello per ogni combinazione
  ## delle opzioni. Per la nostra idea la chiave è "base" o "tavolino" seguita da
  ## "Scoperta" (risega), "Antina" (solo con il tavolino), "Comodino" (prese sul
  ## comodino): es. "tavolinoScopertaComodino". Per il modello dei falegnami è
  ## "falegnami" o "falegnamiSenzaPannello". Si parte da "base" se c'è, se no
  ## dai falegnami; i pulsanti dei modelli che la pagina non ha restano nascosti.
  for k, m in varianti: modelli[k] = preparato(m)
  carta = cartaDaParati
  let idea = "base" in modelli
  let falegnami = "falegnami" in modelli
  var variante = if idea: "base" else: "falegnami"
  modello = modelli[variante]
  stage = el("stage")
  status = el("status")

  scene = newScene()
  camera = newPerspectiveCamera(35, stage.larghezza / stage.altezza, 1, 5000)
  renderer = newWebGLRenderer(js{antialias: true})
  renderer.setPixelRatio(min(rapportoPixel(), 2))
  renderer.setSize(stage.larghezza, stage.altezza)
  let canvas = renderer.domElement.to(Element)
  stage.prepend(canvas)
  scene.add(newHemisphereLight(0xffffff, 0xb0a890, 1.6))
  let sun = newDirectionalLight(0xffffff, 1.4)
  sun.position.set(-150, 400, 300)
  scene.add(sun)
  materiali()

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

  # toccare una parte apribile la apre o la chiude (un tocco, non un trascinamento);
  # trascinando il piano selezionato lo si sposta lungo il suo asse: si misura
  # quanti pixel sullo schermo vale un cm lungo l'asse
  ray = newRaycaster()
  ndc = newVector2()
  ray.params["Line"]["threshold"] = 0.5
  var down: tuple[attivo: bool, x, y, t: float]
  var trascina: tuple[attivo: bool, nome: string, vx, vy, n2: float, da: int]
  canvas.addEventListener("pointerdown", proc (e: Event) =
    let ev = cast[PointerEv](e)
    down = (true, ev.clientX, ev.clientY, adesso())
    let nome = pianoAt(ev)
    if nome.len > 0 and nome == selezionato:
      let o = piani[nome].getWorldPosition(newVector3())
      let a = o.clone().project(camera)
      let b = o.clone().add(assi[nome]).project(camera)
      let r = rettangolo(canvas)
      let vx = (b.x - a.x) * r.width / 2
      let vy = -(b.y - a.y) * r.height / 2
      let n2 = vx * vx + vy * vy
      if n2 > 1e-4:
        trascina = (true, nome, vx, vy, n2, tagli[nome])
        controls.enabled = false
        canvas.setPointerCapture(ev.pointerId))
  canvas.addEventListener("pointerup", proc (e: Event) =
    let ev = cast[PointerEv](e)
    if trascina.attivo: trascina.attivo = false; controls.enabled = true
    if not down.attivo: return
    let moved = hypot(ev.clientX - down.x, ev.clientY - down.y)
    let dt = adesso() - down.t
    down.attivo = false
    if moved > 6 or dt > 600: return
    let nome = pianoAt(ev)
    if nome.len > 0:
      seleziona(if selezionato == nome: "" else: nome); return
    let u = unitAt(ev)
    if u != nil: setOpen(u, u.target < 0.5))
  canvas.addEventListener("pointermove", proc (e: Event) =
    let ev = cast[PointerEv](e)
    if trascina.attivo and down.attivo:
      let dx = ev.clientX - down.x
      let dy = ev.clientY - down.y
      let cm = (dx * trascina.vx + dy * trascina.vy) / trascina.n2
      spostaTaglio(trascina.nome, trascina.da.float + cm)
      return
    if ev.pointerType != "mouse" or ev.buttons != 0: return
    let nome = pianoAt(ev)
    let cursore = if nome.len > 0: (if nome == selezionato: "grab" else: "pointer")
                  elif unitAt(ev) != nil: "pointer" else: ""
    canvas.cursore(cursore.cstring))

  # i pulsanti
  let tFront = el("t-fronte")
  let tCarta = el("t-carta")
  tCarta.nascosto(carta.src.len == 0)
  proc applyToggles() =
    for f in frontPanel: f.visible = not premuto(tFront)
    let on = carta.src.len > 0 and not premuto(tCarta)
    for w in walls: w.material = if on: cartaMat else: mats[kWall]
  for btn in [tFront, tCarta]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let btn = btn
      btn.addEventListener("click", proc (ev: Event) = btn.premi(not premuto(btn)); applyToggles())
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
  tSez = el("t-sezioni")
  boxSez = el("sezioni")
  let tRisega = el("m-risega")
  let tAntina = el("m-antina")
  let tPrese = el("m-prese")
  let tPannello = el("m-pannello")
  # il pulsante di un modello compare solo se la pagina ha anche l'altro
  for n in ["base", "tavolino"]: el("m-" & n).nascosto(not idea)
  el("m-falegnami").nascosto(not (idea and falegnami))
  proc pulsanti() =
    let fal = variante == "falegnami"
    tAntina.nascosto(variante != "tavolino")
    tPannello.nascosto(not fal)
    for b in [tRisega, tPrese]: b.nascosto(fal)
  pulsanti()
  proc cambiaModello() =
    pulsanti()
    let fal = variante == "falegnami"
    modello = if fal: modelli["falegnami" & (if premuto(tPannello): "" else: "SenzaPannello")]
              else: modelli[variante & (if premuto(tRisega): "Scoperta" else: "") &
                    (if variante == "tavolino" and premuto(tAntina): "Antina" else: "") &
                    (if premuto(tPrese): "Comodino" else: "")]
    for n in ["base", "tavolino", "falegnami"]: el("m-" & n).premi(n == variante)
    costruisci(modello); applyToggles(); applyEsploso(); pianiTaglio()
    if premuto(tSez): aggiornaSezioni()
    status.textContent = cstring($modello.parts.len & " parti")
  for name in ["base", "tavolino", "falegnami"]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let name = name
      el("m-" & name).addEventListener("click", proc (ev: Event) =
        variante = name; cambiaModello())
  for b in [tRisega, tAntina, tPrese, tPannello]:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let b = b
      b.addEventListener("click", proc (ev: Event) = b.premi(not premuto(b)); cambiaModello())
  applyToggles()
  # un modello qualsiasi (la pagina dei parametri): ricostruisce la scena e
  # rimette aperto quello che era aperto
  aggiorna = proc (m: Model) =
    var aperti: Table[string, float]
    for u in units: aperti[u.nome] = u.target
    modello = preparato(m)
    costruisci(modello); applyToggles(); applyEsploso(); pianiTaglio()
    for u in units:
      if u.nome in aperti and not u.disegnataAperta:
        u.target = aperti[u.nome]; u.k = u.target; posa(u)
    if premuto(tSez): aggiornaSezioni()
    status.textContent = cstring($modello.parts.len & " parti")
  # la tavola sotto il visore si scarica com'è
  el("scarica-tavola").addEventListener("click", proc (ev: Event) =
    scarica(document.querySelector(".tavola svg").outerHTML, "tavola.svg"))

  # le sezioni
  assi = {"pianta": newVector3(0, 1, 0), "laterale": newVector3(1, 0, 0),
          "prospetto": newVector3(0, 0, -1)}.toTable
  for v in viste:
    closureScope:   # ogni giro ha le sue variabili, anche nelle closure
      let nome = v.nome
      let card = scheda(nome)
      let inp = card.querySelector("input")
      inp.min = 0; inp.max = round(massimo(nome)); inp.valore = v.def.float
      tagli[nome] = v.def
      inp.addEventListener("input", proc (ev: Event) =
        tagli[nome] = inp.valore.int; disegna(nome); posizionaPiani())
      card.querySelector("h2").addEventListener("click", proc (ev: Event) =
        seleziona(if selezionato == nome: "" else: nome))
      card.querySelector(".scarica").addEventListener("click", proc (ev: Event) =
        scarica(card.querySelector("svg").svgConXmlns, cstring(nome & "-" & $tagli[nome] & ".svg")))
  pianiTaglio()
  tSez.addEventListener("click", proc (ev: Event) =
    let on = not premuto(tSez)
    tSez.premi(on)
    boxSez.nascosto(not on)
    for p in piani.values: p.visible = on
    if on: aggiornaSezioni())

  # lo sfondo segue il tema chiaro/scuro
  proc applyTheme() =
    let s = cssVar("--stage")
    scene.background = newColor(if s.len > 0: s else: "#dfe3e6")
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
    renderer.render(scene, camera)
    prossimoFotogramma(loop)
  prossimoFotogramma(loop)
  status.textContent = cstring($modello.parts.len & " parti")
  osservaDimensioni(stage, proc () =
    camera.aspect = stage.larghezza / stage.altezza; camera.updateProjectionMatrix()
    renderer.setSize(stage.larghezza, stage.altezza))
