## Le poche cose del browser che servono al visore e che `std/dom` non ha
## (o ha con tipi scomodi): eventi del puntatore, osservatori, download,
## SVG, canvas. Stesso stile di `three.nim`: `importjs` scrive il JavaScript.

import std/[dom, jsffi]
export dom

type
  PointerEv* = ref object of Event
    ## Un evento del puntatore (mouse, dito o penna).
    clientX*, clientY*: float
    pointerId*: int
    pointerType*: cstring
    buttons*: int
  Ctx2D* {.importc.} = ref object of JsRoot
    ## Il contesto 2D di un canvas: qui serve solo per disegnare il tessuto del materasso.
    fillStyle*, strokeStyle*: cstring
    lineWidth*: float

proc el*(id: string): Element = document.getElementById(id.cstring)
proc premuto*(b: Element): bool = b.getAttribute("aria-pressed") == "true"
  ## Un pulsante acceso/spento tiene lo stato in `aria-pressed`.
proc premi*(b: Element; on: bool) = b.setAttribute("aria-pressed", if on: cstring"true" else: cstring"false")
proc nascosto*(e: Element; v: bool) {.importjs: "#.hidden = #".}
proc dataVista*(e: Element): cstring {.importjs: "#.dataset.vista".}
proc valore*(e: Element): float {.importjs: "(+#.value)".}
proc `valore=`*(e: Element; v: float) {.importjs: "#.value = #".}
proc `min=`*(e: Element; v: float) {.importjs: "#.min = #".}
proc `max=`*(e: Element; v: float) {.importjs: "#.max = #".}
proc maxValore*(e: Element): float {.importjs: "(+#.max)".}
proc prepend*(e, figlio: Element) {.importjs: "#.prepend(#)".}
proc svuota*(e: Element) {.importjs: "#.replaceChildren()".}
proc toggleClass*(e: Element; c: cstring; on: bool) {.importjs: "#.classList.toggle(@)".}
proc larghezza*(e: Element): float {.importjs: "#.clientWidth".}
proc altezza*(e: Element): float {.importjs: "#.clientHeight".}
proc rettangolo*(e: Element): BoundingRect {.importjs: "#.getBoundingClientRect()".}
proc setPointerCapture*(e: Element; id: int) {.importjs: "#.setPointerCapture(@)".}
proc cursore*(e: Element; c: cstring) {.importjs: "#.style.cursor = #".}

proc cssVar*(nome: cstring): cstring {.importjs: "getComputedStyle(document.documentElement).getPropertyValue(#).trim()".}
proc movimentoRidotto*(): bool {.importjs: "matchMedia('(prefers-reduced-motion: reduce)').matches".}
  ## Chi ha chiesto meno animazioni vede subito la posizione finale.
proc rapportoPixel*(): float {.importjs: "(window.devicePixelRatio)".}
proc adesso*(): float {.importjs: "performance.now()".}
proc prossimoFotogramma*(f: proc (t: float)) {.importjs: "requestAnimationFrame(#)".}
proc osservaDimensioni*(e: Element; f: proc ()) {.importjs: "((e, f) => new ResizeObserver(f).observe(e))(@)".}
proc quandoCambiaTema*(f: proc ()) {.importjs: """(f => { matchMedia('(prefers-color-scheme: dark)').addEventListener('change', f);
  new MutationObserver(f).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] }); })(#)""".}
  ## Il sistema passa a chiaro/scuro, o la pagina cambia `data-theme`.

proc svg*(tag: cstring): Element {.importjs: "document.createElementNS('http://www.w3.org/2000/svg', #)".}
proc svgConXmlns*(e: Element): cstring {.importjs: "(c => (c.setAttribute('xmlns', 'http://www.w3.org/2000/svg'), c.outerHTML))(#.cloneNode(true))".}
proc scarica*(testo, nomeFile: cstring) {.importjs: """((t, n) => {
  const url = URL.createObjectURL(new Blob([t], { type: 'image/svg+xml' }));
  const a = Object.assign(document.createElement('a'), { href: url, download: n });
  document.body.append(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000); })(@)""".}
  ## Fa scaricare un file SVG con questo testo.

proc nuovoCanvas*(lato: int): Element {.importjs: "(l => Object.assign(document.createElement('canvas'), {width: l, height: l}))(#)".}
proc ctx2d*(c: Element): Ctx2D {.importjs: "#.getContext('2d')".}
proc fillRect*(x: Ctx2D; a, b, w, h: float) {.importjs: "#.fillRect(@)".}
proc beginPath*(x: Ctx2D) {.importjs: "#.beginPath()".}
proc moveTo*(x: Ctx2D; a, b: float) {.importjs: "#.moveTo(@)".}
proc lineTo*(x: Ctx2D; a, b: float) {.importjs: "#.lineTo(@)".}
proc closePath*(x: Ctx2D) {.importjs: "#.closePath()".}
proc stroke*(x: Ctx2D) {.importjs: "#.stroke()".}
proc fill*(x: Ctx2D) {.importjs: "#.fill()".}
proc arc*(x: Ctx2D; a, b, r, da, fino: float) {.importjs: "#.arc(@)".}
