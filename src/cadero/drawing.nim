## Disegni 2D: proiezioni del modello (prospetto, laterale, pianta) e quote, in SVG.
##
## Ogni vista trasforma un punto 3D (x, y, z) in un punto 2D (u, w) del foglio:
## u verso destra, w verso l'alto. L'SVG lavora in cm: la scala la decide
## chi mostra il disegno (il viewBox).

import std/[math, strformat, strutils]
import model

type
  ViewKind* = enum
    vFront = "prospetto frontale"
    vSide = "vista laterale"    ## dal lato destro, sezione al piano x = cut
    vPlan = "pianta"            ## dall'alto, sezione al piano z = cut

  View* = object
    kind*: ViewKind
    cut*: float          ## piano di sezione (x per la laterale, z per la pianta)
    ox*, oy*: float      ## dove sta l'origine della vista sul foglio
    contorni*: bool      ## prospetto: disegna il contorno di tutti i pannelli
                         ## (per i mobili senza il fronte davanti)

  DimChain* = object
    ## Catena di quote: una linea con tante misure consecutive.
    view*: ViewKind
    vertical*: bool
    at*: float           ## posizione della linea di quota (u se verticale, w se orizzontale)
    ext*: float          ## da dove partono le linee di richiamo
    stops*: seq[float]   ## coordinate lungo la quota; ogni coppia vicina è una misura
    loro*: seq[float]    ## facoltativo, una per misura: quella scritta su un disegno
                         ## di riferimento (cm), NaN se non c'è. Il testo è nero se
                         ## torna, blu se è dedotta (NaN), rosso con la loro se no

  Sheet* = object
    ## Un foglio SVG che tiene traccia dei propri limiti.
    body: seq[string]
    minX, minY, maxX, maxY: float

const
  thick = 0.45
  thin = 0.2
  dashed = "2 1"
  dotted = "0.5 0.7"
  ink = "#1a1a1a"
  inkDedotta* = "#1f6fd1"   ## una misura che sul disegno di riferimento non c'è
  inkDiversa* = "#d0312d"   ## una misura diversa da quella del disegno di riferimento

proc fmtNum*(v: float): string =
  if abs(v - round(v)) < 0.05: $int(round(v))
  else: formatFloat(v, ffDecimal, 1)

proc initSheet*(): Sheet =
  Sheet(minX: Inf, minY: Inf, maxX: -Inf, maxY: -Inf)

proc grow(s: var Sheet; x, y: float) =
  s.minX = min(s.minX, x); s.maxX = max(s.maxX, x)
  s.minY = min(s.minY, y); s.maxY = max(s.maxY, y)

# --- primitive SVG, in coordinate di vista (u, w) ---------------------------

proc toSvg(v: View; u, w: float): (float, float) = (v.ox + u, v.oy - w)

proc dashAttr(dash: string): string =
  if dash.len > 0: &" stroke-dasharray=\"{dash}\"" else: ""

proc rect(s: var Sheet; v: View; u0, w0, u1, w1: float; r = 0.0;
          width = thin; dash = "") =
  let (x, y) = v.toSvg(min(u0, u1), max(w0, w1))
  let (w, h) = (abs(u1 - u0), abs(w1 - w0))
  let rr = min(r, min(w, h) / 2)
  s.body.add &"""<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" rx="{rr:.2f}" fill="none" stroke="{ink}" stroke-width="{width}"{dashAttr(dash)}/>"""
  s.grow(x, y); s.grow(x + w, y + h)

proc line(s: var Sheet; v: View; u0, w0, u1, w1: float; width = thin; dash = "") =
  let (x0, y0) = v.toSvg(u0, w0)
  let (x1, y1) = v.toSvg(u1, w1)
  s.body.add &"""<line x1="{x0:.2f}" y1="{y0:.2f}" x2="{x1:.2f}" y2="{y1:.2f}" stroke="{ink}" stroke-width="{width}"{dashAttr(dash)}/>"""
  s.grow(x0, y0); s.grow(x1, y1)

proc poly(s: var Sheet; v: View; pts: seq[(float, float)]; width = thin) =
  ## un poligono chiuso, in coordinate di vista
  var d = ""
  for i, (u, w) in pts:
    let (x, y) = v.toSvg(u, w)
    d.add (if i == 0: "M" else: "L") & &"{x:.2f},{y:.2f}"
    s.grow(x, y)
  s.body.add &"""<path d="{d}Z" fill="none" stroke="{ink}" stroke-width="{width}"/>"""

proc circle(s: var Sheet; v: View; u, w, r: float) =
  let (x, y) = v.toSvg(u, w)
  s.body.add &"""<circle cx="{x:.2f}" cy="{y:.2f}" r="{r:.2f}" fill="none" stroke="{ink}" stroke-width="{thin}"/>"""

proc text(s: var Sheet; v: View; u, w: float; t: string; size = 4.2;
          vertical = false; anchor = "middle"; italic = true; col = ink) =
  let (x, y) = v.toSvg(u, w)
  let rot = if vertical: &" transform=\"rotate(-90 {x:.2f} {y:.2f})\"" else: ""
  let style = if italic: " font-style=\"italic\"" else: ""
  s.body.add &"""<text x="{x:.2f}" y="{y:.2f}" font-size="{size}" text-anchor="{anchor}"{style} fill="{col}"{rot}>{t}</text>"""
  s.grow(x - size, y - size); s.grow(x + size, y + size)

# --- proiezioni -------------------------------------------------------------

proc viewBox(p: Part; k: ViewKind): (float, float, float, float) =
  ## Il rettangolo che la scatola occupa nella vista: (u0, w0, u1, w1).
  case k
  of vFront: (p.pos.x, p.pos.z, p.x1, p.z1)
  of vSide: (p.pos.y, p.pos.z, p.y1, p.z1)
  of vPlan: (p.pos.x, p.pos.y, p.x1, p.y1)

proc drawFront(s: var Sheet; v: View; m: Model) =
  for p in m.parts:
    let (u0, w0, u1, w1) = p.viewBox(vFront)
    case p.kind
    of kPanel:
      if p.contorno.len > 0:            # un pezzo del fronte con le tacche delle aperture
        s.poly(v, p.contorno, width = thick)
        for h in p.holes:
          s.rect(v, h.x, h.z, h.x + h.w, h.z + h.h, h.r)
      elif p.holes.len > 0:             # il pannello frontale e le sue aperture
        s.rect(v, u0, w0, u1, w1, width = thick)
        for h in p.holes:
          s.rect(v, h.x, h.z, h.x + h.w, h.z + h.h, h.r)
      elif v.contorni:                  # i mobili senza il fronte: tutti i pannelli
        s.rect(v, u0, w0, u1, w1)
      elif p.hiddenFront:               # struttura nascosta che vogliamo indicare
        s.line(v, (u0 + u1) / 2, w0, (u0 + u1) / 2, w1, dash = dotted)
    of kFront, kBox:
      s.rect(v, u0, w0, u1, w1, p.r)
      for h in p.holes:                 # es. i gradini nel frontale del tavolino
        s.rect(v, h.x, h.z, h.x + h.w, h.z + h.h, h.r)
    of kSoft:
      if p.hiddenFront: s.rect(v, u0, w0, u1, w1, p.r, dash = dotted)
    of kKnob:
      s.circle(v, p.pos.x, p.pos.z, p.size.x / 2)
    of kAccessory, kWall: discard

proc drawSide(s: var Sheet; v: View; m: Model) =
  ## Sezione al piano x = cut, guardando verso sinistra: si vede quello
  ## che è tagliato e quello che sta oltre (x < cut).
  for p in m.parts:
    if p.pos.x >= v.cut: continue
    let (u0, w0, u1, w1) = p.viewBox(vSide)
    case p.kind
    of kPanel: s.rect(v, u0, w0, u1, w1, width = if p.size.y >= 50: thick else: thin)
    of kBox: s.rect(v, u0, w0, u1, w1)
    of kSoft: s.rect(v, u0, w0, u1, w1, 3)
    of kWall: s.rect(v, u0, w0, u1, w1, dash = dashed)
    of kFront, kKnob, kAccessory: discard

proc drawPlan(s: var Sheet; v: View; m: Model) =
  ## Sezione al piano z = cut, vista dall'alto.
  for p in m.parts:
    let (u0, w0, u1, w1) = p.viewBox(vPlan)
    if p.kind == kSoft:                  # il materasso sta sotto il taglio
      s.rect(v, u0, w0, u1, w1, p.r, dash = dotted)
      continue
    if p.kind == kWall:                  # il muro, tratteggiato
      s.rect(v, u0, w0, u1, w1, dash = dashed)
      continue
    if not (p.pos.z <= v.cut and v.cut <= p.z1): continue
    if p.kind notin {kPanel, kBox}: continue
    if p.contorno.len > 0:               # un pezzo del fronte: i tratti pieni del contorno
      for (a, b) in p.pieni('z', v.cut):
        var t = a
        for h in p.holes:
          if h.z <= v.cut and v.cut <= h.z + h.h and h.x >= a and h.x + h.w <= b:
            s.rect(v, t, w0, h.x, w1, width = thick)
            t = h.x + h.w
        s.rect(v, t, w0, b, w1, width = thick)
      continue
    if p.holes.len == 0:
      s.rect(v, u0, w0, u1, w1, width = thick)
      continue
    # pannello forato: si disegnano solo i tratti pieni lungo il taglio
    var a = u0
    for h in p.holes:
      if h.z <= v.cut and v.cut <= h.z + h.h:
        s.rect(v, a, w0, h.x, w1, width = thick)
        a = h.x + h.w
    s.rect(v, a, w0, u1, w1, width = thick)

proc draw*(s: var Sheet; v: View; m: Model) =
  case v.kind
  of vFront: s.drawFront(v, m)
  of vSide: s.drawSide(v, m)
  of vPlan: s.drawPlan(v, m)

# --- quote ------------------------------------------------------------------

proc testo(d: DimChain; i: int): (string, string) =
  ## il testo e il colore della misura i: confrontata, se c'è, con la loro
  let m = d.stops[i + 1] - d.stops[i]
  if d.loro.len == 0: return (fmtNum(m), ink)
  let l = d.loro[i]
  if l.isNaN: (fmtNum(m), inkDedotta)
  elif abs(l - m) < 0.05: (fmtNum(m), ink)
  else: (fmtNum(m) & " (loro " & fmtNum(l) & ")", inkDiversa)

proc draw*(s: var Sheet; v: View; d: DimChain) =
  ## Linea di quota, linee di richiamo, tratti obliqui e testo, come nei
  ## disegni di architettura.
  let a = d.stops[0]
  let b = d.stops[^1]
  const over = 2.0    # quanto la linea sborda oltre gli estremi
  const tick = 1.4
  let sgn = if d.at >= d.ext: 1.0 else: -1.0
  if d.vertical:
    s.line(v, d.at, a - over, d.at, b + over)
    for t in d.stops:
      s.line(v, d.ext + sgn * 1.0, t, d.at + sgn * 1.5, t)       # richiamo
      s.line(v, d.at - tick, t - tick, d.at + tick, t + tick, width = thick)
    for i in 0 ..< d.stops.high:
      let (p, q) = (d.stops[i], d.stops[i+1])
      let (t, col) = d.testo(i)
      s.text(v, d.at - 1.3, (p + q) / 2, t, vertical = true, col = col)
  else:
    s.line(v, a - over, d.at, b + over, d.at)
    for t in d.stops:
      s.line(v, t, d.ext + sgn * 1.0, t, d.at + sgn * 1.5)
      s.line(v, t - tick, d.at - tick, t + tick, d.at + tick, width = thick)
    for i in 0 ..< d.stops.high:
      let (p, q) = (d.stops[i], d.stops[i+1])
      let (t, col) = d.testo(i)
      s.text(v, (p + q) / 2, d.at + 1.3, t, col = col)

proc label*(s: var Sheet; v: View; u, w: float; t: string; size = 5.0) =
  s.text(v, u, w, t, size = size, anchor = "end", italic = false)

proc render*(s: Sheet; pxPerCm = 2.5; margin = 8.0): string =
  ## L'SVG finale; il viewBox è in cm, width/height in pixel.
  let x = s.minX - margin
  let y = s.minY - margin
  let w = s.maxX - s.minX + 2 * margin
  let h = s.maxY - s.minY + 2 * margin
  result = &"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x:.1f} {y:.1f} {w:.1f} {h:.1f}" width="{int(round(w * pxPerCm))}" height="{int(round(h * pxPerCm))}" font-family="Helvetica, Arial, sans-serif" style="max-width:100%;height:auto;background:white">""" & "\n"
  result.add &"""<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" fill="white"/>""" & "\n"
  result.add s.body.join("\n")
  result.add "\n</svg>\n"
