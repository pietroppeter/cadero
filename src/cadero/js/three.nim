## Le parti di three.js che usa il visore 3D, viste da Nim (backend JS).
##
## Non è un binding completo: solo le classi e i metodi che servono, con i
## nomi di three.js, così il codice del visore si legge come la documentazione
## di three.js. three.js si carica nella pagina come modulo ES (importmap) e
## viene messo in `window.THREE` (vedi `quandoThreePronto`): qui ogni
## costruttore è `new THREE.Qualcosa(...)`.
##
## Come funziona un binding:
## - un tipo `{.importc.}` che eredita da `JsRoot` è un oggetto JavaScript
##   qualunque; i suoi campi (es. `x`, `position`) si leggono e scrivono così
##   come sono, senza conversioni;
## - un proc `{.importjs: "modello".}` scrive il JavaScript del modello al posto
##   della chiamata: `#` è il prossimo argomento, `@` tutti i restanti.
##   Es. `newBox3()` diventa `new THREE.Box3()`, `v.clone()` resta `v.clone()`.
## - i parametri "oggetto" di three.js (es. `{color: 0xffffff, roughness: 1}`)
##   si scrivono con `js{...}` di `std/jsffi`.

import std/jsffi
export jsffi

{.push importc.}
type
  Vector2* = ref object of JsRoot
    x*, y*: float
  Vector3* = ref object of JsRoot
    x*, y*, z*: float
  Euler* = ref object of JsRoot
    x*, y*, z*: float
  Color* = ref object of JsRoot
  Box3* = ref object of JsRoot
    min*, max*: Vector3

  BufferAttribute* = ref object of JsRoot
    count*: int
  Attributi* = ref object of JsRoot
    ## `geometry.attributes`: le coordinate dei vertici
    uv*, position*, normal*: BufferAttribute
  BufferGeometry* = ref object of JsRoot
    attributes*: Attributi
    boundingBox*: Box3

  Texture* = ref object of JsRoot
    wrapS*, wrapT*, anisotropy*: int
    colorSpace*: cstring
  Material* = ref object of JsRoot
    color*: Color
    opacity*: float

  Object3D* = ref object of JsRoot
    position*: Vector3
    rotation*: Euler
    visible*: bool
    parent*: Object3D
    children*: seq[Object3D]
    userData*: JsObject
    renderOrder*: int
    isLineSegments*: bool
  Group* = ref object of Object3D
  Scene* = ref object of Object3D
    background*: Color
  Mesh* = ref object of Object3D
    geometry*: BufferGeometry
    material*: Material
  LineSegments* = ref object of Object3D
    material*: Material
  Light* = ref object of Object3D
  PerspectiveCamera* = ref object of Object3D
    fov*, aspect*: float

  Path* = ref object of JsRoot
  Shape* = ref object of Path
    holes*: seq[Path]

  WebGLRenderer* = ref object of JsRoot
    domElement*: JsObject   ## il <canvas>

  Intersezione* = ref object of JsRoot
    ## Quello che un raggio tocca: l'oggetto, il punto e la distanza.
    `object`*: Object3D
    point*: Vector3
    distance*: float
  Raycaster* = ref object of JsRoot
    params*: JsObject

  OrbitControls* = ref object of JsRoot
    target*: Vector3
    enabled*, enableDamping*: bool
    minDistance*, maxDistance*: float
    zoomSpeed*: float
{.pop.}

# le costanti si leggono quando servono: al caricamento del modulo three.js non c'è ancora
proc RepeatWrapping*(): int {.importjs: "(THREE.RepeatWrapping)".}
proc SRGBColorSpace*(): cstring {.importjs: "(THREE.SRGBColorSpace)".}
proc DoubleSide*(): int {.importjs: "(THREE.DoubleSide)".}

# --- vettori e scatole -------------------------------------------------------
proc newVector2*(): Vector2 {.importjs: "new THREE.Vector2()".}
proc newVector3*(x, y, z = 0.0): Vector3 {.importjs: "new THREE.Vector3(@)".}
proc set*(v: Vector2; x, y: float) {.importjs: "#.set(@)".}
proc set*(v: Vector3; x, y, z: float) {.importjs: "#.set(@)".}
proc copy*(v, w: Vector3): Vector3 {.importjs: "#.copy(@)", discardable.}
proc length*(v: Vector3): float {.importjs: "#.length()".}
proc clone*(v: Vector3): Vector3 {.importjs: "#.clone()".}
proc negate*(v: Vector3): Vector3 {.importjs: "#.negate()", discardable.}
proc add*(v, w: Vector3): Vector3 {.importjs: "#.add(@)", discardable.}
proc sub*(v, w: Vector3): Vector3 {.importjs: "#.sub(@)", discardable.}
proc multiply*(v, w: Vector3): Vector3 {.importjs: "#.multiply(@)", discardable.}
proc multiplyScalar*(v: Vector3; s: float): Vector3 {.importjs: "#.multiplyScalar(@)", discardable.}
proc project*(v: Vector3; cam: PerspectiveCamera): Vector3 {.importjs: "#.project(@)", discardable.}
proc lerpVectors*(v, a, b: Vector3; t: float): Vector3 {.importjs: "#.lerpVectors(@)", discardable.}

proc containsPoint*(b: Box3; p: Vector3): bool {.importjs: "#.containsPoint(@)".}
proc newBox3*(): Box3 {.importjs: "new THREE.Box3()".}
proc setFromObject*(b: Box3; o: Object3D): Box3 {.importjs: "#.setFromObject(@)", discardable.}
proc expandByObject*(b: Box3; o: Object3D): Box3 {.importjs: "#.expandByObject(@)", discardable.}
proc getCenter*(b: Box3; v: Vector3): Vector3 {.importjs: "#.getCenter(@)", discardable.}
proc getSize*(b: Box3; v: Vector3): Vector3 {.importjs: "#.getSize(@)", discardable.}

proc newColor*(css: cstring): Color {.importjs: "new THREE.Color(@)".}
proc setHex*(c: Color; hex: int) {.importjs: "#.setHex(@)".}
proc degToRad*(gradi: float): float {.importjs: "THREE.MathUtils.degToRad(@)".}

# --- la scena ----------------------------------------------------------------
proc newScene*(): Scene {.importjs: "new THREE.Scene()".}
proc newGroup*(): Group {.importjs: "new THREE.Group()".}
proc add*(o, figlio: Object3D) {.importjs: "#.add(@)".}
proc remove*(o, figlio: Object3D) {.importjs: "#.remove(@)".}
proc getWorldPosition*(o: Object3D; v: Vector3): Vector3 {.importjs: "#.getWorldPosition(@)".}
proc worldToLocal*(o: Object3D; v: Vector3): Vector3 {.importjs: "#.worldToLocal(@)".}

proc newPerspectiveCamera*(fov, aspect, near, far: float): PerspectiveCamera {.importjs: "new THREE.PerspectiveCamera(@)".}
proc updateProjectionMatrix*(c: PerspectiveCamera) {.importjs: "#.updateProjectionMatrix()".}

proc newWebGLRenderer*(params: JsObject): WebGLRenderer {.importjs: "new THREE.WebGLRenderer(@)".}
proc setPixelRatio*(r: WebGLRenderer; ratio: float) {.importjs: "#.setPixelRatio(@)".}
proc setSize*(r: WebGLRenderer; w, h: float) {.importjs: "#.setSize(@)".}
proc render*(r: WebGLRenderer; s: Scene; c: PerspectiveCamera) {.importjs: "#.render(@)".}

proc newHemisphereLight*(cielo, terra: int; intensita: float): Light {.importjs: "new THREE.HemisphereLight(@)".}
proc newDirectionalLight*(colore: int; intensita: float): Light {.importjs: "new THREE.DirectionalLight(@)".}

# --- materiali e texture -----------------------------------------------------
proc newMeshStandardMaterial*(params: JsObject): Material {.importjs: "new THREE.MeshStandardMaterial(@)".}
proc newMeshBasicMaterial*(params: JsObject): Material {.importjs: "new THREE.MeshBasicMaterial(@)".}
proc newLineBasicMaterial*(params: JsObject): Material {.importjs: "new THREE.LineBasicMaterial(@)".}
proc newCanvasTexture*(canvas: JsObject): Texture {.importjs: "new THREE.CanvasTexture(@)".}
proc caricaTexture*(src: cstring): Texture {.importjs: "new THREE.TextureLoader().load(@)".}

# --- geometrie ---------------------------------------------------------------
proc newBoxGeometry*(w, h, d: float): BufferGeometry {.importjs: "new THREE.BoxGeometry(@)".}
proc newCylinderGeometry*(r1, r2, h: float; segmenti: int): BufferGeometry {.importjs: "new THREE.CylinderGeometry(@)".}
proc newPlaneGeometry*(w, h: float): BufferGeometry {.importjs: "new THREE.PlaneGeometry(@)".}
proc newExtrudeGeometry*(s: Shape; params: JsObject): BufferGeometry {.importjs: "new THREE.ExtrudeGeometry(@)".}
proc newEdgesGeometry*(g: BufferGeometry; soglia = 1.0): BufferGeometry {.importjs: "new THREE.EdgesGeometry(@)".}
proc dispose*(g: BufferGeometry) {.importjs: "#.dispose()".}
  ## libera la memoria della scheda video (quando la scena si ricostruisce)
proc translate*(g: BufferGeometry; x, y, z: float): BufferGeometry {.importjs: "#.translate(@)", discardable.}
proc rotateX*(g: BufferGeometry; a: float): BufferGeometry {.importjs: "#.rotateX(@)", discardable.}
proc rotateY*(g: BufferGeometry; a: float): BufferGeometry {.importjs: "#.rotateY(@)", discardable.}
proc computeBoundingBox*(g: BufferGeometry) {.importjs: "#.computeBoundingBox()".}
proc getX*(a: BufferAttribute; i: int): float {.importjs: "#.getX(@)".}
proc getY*(a: BufferAttribute; i: int): float {.importjs: "#.getY(@)".}
proc getZ*(a: BufferAttribute; i: int): float {.importjs: "#.getZ(@)".}
proc setXY*(a: BufferAttribute; i: int; x, y: float) {.importjs: "#.setXY(@)".}

proc newShape*(): Shape {.importjs: "new THREE.Shape()".}
proc newPath*(): Path {.importjs: "new THREE.Path()".}
proc moveTo*(p: Path; x, y: float) {.importjs: "#.moveTo(@)".}
proc lineTo*(p: Path; x, y: float) {.importjs: "#.lineTo(@)".}
proc quadraticCurveTo*(p: Path; cx, cy, x, y: float) {.importjs: "#.quadraticCurveTo(@)".}
proc closePath*(p: Path) {.importjs: "#.closePath()".}

proc newMesh*(g: BufferGeometry; m: Material): Mesh {.importjs: "new THREE.Mesh(@)".}
proc newMesh*(g: BufferGeometry; m: seq[Material]): Mesh {.importjs: "new THREE.Mesh(@)".}
  ## una faccia per materiale: ±x, ±y, ±z (come il materasso)
proc newLineSegments*(g: BufferGeometry; m: Material): LineSegments {.importjs: "new THREE.LineSegments(@)".}

# --- interazione -------------------------------------------------------------
proc newRaycaster*(): Raycaster {.importjs: "new THREE.Raycaster()".}
proc setFromCamera*(r: Raycaster; ndc: Vector2; c: PerspectiveCamera) {.importjs: "#.setFromCamera(@)".}
proc intersectObject*(r: Raycaster; o: Object3D; ricorsivo: bool): seq[Intersezione] {.importjs: "#.intersectObject(@)".}
proc intersectObjects*(r: Raycaster; o: seq[Object3D]; ricorsivo: bool): seq[Intersezione] {.importjs: "#.intersectObjects(@)".}

proc newOrbitControls*(c: PerspectiveCamera; el: JsObject): OrbitControls {.importjs: "new THREE.OrbitControls(@)".}
proc update*(c: OrbitControls) {.importjs: "#.update()".}

# --- caricamento -------------------------------------------------------------
proc quandoThreePronto*(avvia: proc ()) =
  ## three.js è un modulo ES: si carica dopo gli script normali (come quello
  ## generato da Nim). La pagina lo mette in `window.THREE` e manda l'evento
  ## "three-pronto"; se è già arrivato, si parte subito.
  proc giaPronto(): bool {.importjs: "(typeof window.THREE === 'object')".}
  proc aspetta(f: proc ()) {.importjs: "window.addEventListener('three-pronto', #, {once: true})".}
  if giaPronto(): avvia() else: aspetta(avvia)
