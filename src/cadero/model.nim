## Il modello: parti (scatole) raccolte in un mobile.
##
## Convenzione degli assi, in cm:
## - x: larghezza, da sinistra a destra guardando il mobile di fronte
## - y: profondità, da 0 sul fronte fino al muro
## - z: altezza, da 0 sul pavimento

import std/strutils

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

  Part* = object
    name*: string
    kind*: Kind
    pos*: Vec3          ## angolo con x, y, z minimi
    size*: Vec3         ## larghezza, profondità, altezza
    r*: float           ## raggio degli angoli visti di fronte
    holes*: seq[RRect]  ## aperture vuote (pannello frontale, frontale del tavolino)
    hiddenFront*: bool  ## disegnata tratteggiata nel prospetto frontale
    gruppo*: string     ## parti che si muovono insieme nel 3D (es. "cassetto", "tavolino")

  Model* = object
    name*: string
    parts*: seq[Part]

proc v3*(x, y, z: float): Vec3 = Vec3(x: x, y: y, z: z)

proc part*(name: string; kind: Kind; x, y, z, w, d, h: float; r = 0.0): Part =
  Part(name: name, kind: kind, pos: v3(x, y, z), size: v3(w, d, h), r: r)

proc rrect*(x, z, w, h: float; r = 0.0): RRect = RRect(x: x, z: z, w: w, h: h, r: r)

proc x1*(p: Part): float = p.pos.x + p.size.x
proc y1*(p: Part): float = p.pos.y + p.size.y
proc z1*(p: Part): float = p.pos.z + p.size.z

proc frontRect*(p: Part): RRect =
  ## Il contorno della parte vista di fronte.
  rrect(p.pos.x, p.pos.z, p.size.x, p.size.z, p.r)

proc add*(m: var Model; p: Part) = m.parts.add p

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
