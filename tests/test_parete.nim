import std/unittest
import std/strutils
import ../src/cadero, ../models/parete

let p = rilievo()
let m = parete(p)

proc near(a, b: float): bool = abs(a - b) < 0.06

suite "parete di riferimento":
  test "la catena del fronte riproduce le quote della tavola":
    check p.catenaFronte == @[0.0, 6, 101, 131, 253, 265, 308, 316]
    check p.altezza == 316

  test "colonna destra e campata":
    check near(p.xColonna, 198.2)
    let cx = p.colonneX
    check near(cx[3] + p.colonneBasse[3], p.larghezza - p.margineLato)

  test "vista laterale: piano letto 104, testata 55, libreria fino al soffitto":
    check near(p.baseLibreria - p.pianoLetto, 55)     # testata (= comodino)
    check near(p.cimaLibreria, p.soffittoNicchia)     # libreria fino al soffitto
    check abs(p.vanoUtile - 33.5) < 0.5               # 3 vani da circa 33.5
    check near(p.soffittoNicchia, 265)                # un pannello solo sotto i vani alti
    check near(p.margineBasso + p.zonaBassa + p.fascia - p.pianoLetto, 27)

  test "il pannello frontale ha la nicchia e i gradini come aperture":
    check m.find("fronte").holes.len == 1 + p.nGradini

  test "tutto sta dentro l'ingombro (tranne il cassetto aperto)":
    for q in m.parts:
      if q.gruppo != "" and q.pos.y < 0: continue   # aperto
      if q.kind == kSoft: continue      # il materasso lo verificano i controlli
      if q.kind == kWall: continue      # il muro dietro, fuori dal mobile
      check q.pos.x >= -0.01 and q.x1 <= p.larghezza + 0.01
      check q.pos.z >= -0.01 and q.z1 <= p.altezza + 0.01
      check q.pos.y >= -0.01 and q.y1 <= p.profondita + 0.01

  test "il materasso sta sotto il bordo della fascia":
    let mat = m.find("materasso")
    check mat.z1 < p.catenaFronte[3]

  test "distinta":
    var cassetti = 0
    for r in bom(m):
      if r.name == "frontale cassetto": cassetti += r.count
    check cassetti == p.nCassettiBassi

  test "variante: cambiando la nicchia cambia l'altezza":
    var p2 = rilievo()
    p2.nicchia = 112
    check p2.altezza == 306
    check near(p2.soffittoNicchia, 255)
    check p2.cimaLibreria <= p2.soffittoNicchia   # la libreria ci sta ancora

  test "i ripiani stanno dentro la libreria":
    for h in p.ripiani:
      check h > 0 and p.baseLibreria + h < p.cimaLibreria

  test "formato delle quote":
    check fmtNum(198.2) == "198.2"
    check fmtNum(316.0) == "316"

  test "vincoli costruttivi: muro dietro, ai lati, sopra e sotto":
    check near(p.profColonna, 73)
    let r = m.find("risega (muro)")
    check r.kind == kWall and near(r.y1, p.profondita)
    # niente schienali, cielo o fondo
    for nome in ["schienale", "fondo", "cielo", "cielo libreria", "fondo gavone",
                 "fondo vani alti", "schiena vani alti"]:
      check not m.has(nome)
    # due soli pannelli lunghi orizzontali, da un muro all'altro, con la tacca per la
    # risega e il suo rivestimento
    for nome in ["piano letto", "soffitto nicchia"]:
      let q = m.find(nome)
      check near(q.size.x, p.larghezza) and near(q.y1, p.profondita)
      check q.taccheP.len == 1 and near(q.taccheP[0].z, p.profColonna - p.spessore)
    check near(m.find("piano letto").z1, p.pianoLetto)
    check near(m.find("soffitto nicchia").z1, p.catenaFronte[5])
    # tre fianchi per lato, spezzati dai pannelli lunghi
    for lato in ["sx", "dx"]:
      var h = 0.0
      for t in ["basso", "medio", "alto"]: h += m.find("fianco " & lato & " " & t).size.z
      check near(h + 2 * p.spessore, p.altezza)
    # il divisorio poggia sul piano letto e arriva al rivestimento della risega
    let d = m.find("divisorio")
    check near(d.pos.z, p.pianoLetto) and near(d.y1, p.profColonna - p.spessore)
    for row in bom(m): check row.kind != kWall           # il muro non va in distinta

  test "risega rivestita (in tre pezzi come i fianchi) o scoperta":
    var h = 0.0
    for t in ["basso", "medio", "alto"]:
      let sc = m.find("schienale colonna " & t)
      let pan = m.find("pannellino risega " & t)
      check near(sc.y1, p.profColonna) and near(pan.y1, p.profondita)
      check near(pan.pos.x, m.find("divisorio").pos.x)   # stesso piano del divisorio
      h += sc.size.z
    check near(h + 2 * p.spessore, p.altezza)
    var ps = rilievo()
    ps.risegaScoperta = true
    let ms = parete(ps)
    check not ms.has("schienale colonna basso") and not ms.has("pannellino risega basso")
    check ms.find("risega (muro, carta da parati)").kind == kWall
    check near(ms.find("piano letto").taccheP[0].z, p.profColonna)
    check near(ms.find("divisorio").y1, p.profColonna)
    check ps.controlli.len == 0

  test "nell'esploso i cassetti restano tra i loro fianchi":
    for q in m.parts:
      if q.name in ["fianco cassetti", "frontale cassetto", "fianco cassetto"]:
        check q.blocco == "cassetti"

  test "il fronte da solo non sta in una lastra":
    let f = fuoriLastra(m)
    check f.len == 1 and f[0].startsWith("fronte")

  test "dietro i gradini una scatola profonda 30, con due fianchi da terra":
    var n, fianchi = 0
    for q in m.parts:
      if q.name == "ripiano gradino": inc n
      if q.name == "fianco gradini":
        inc fianchi
        check near(q.pos.z, 0) and near(q.z1, p.pianoLetto - p.spessore)
    check n == p.nGradini and fianchi == 2
    check near(m.find("fondo gradini").pos.y, p.spessore + p.profGradini)

  test "i cassetti scorrono tra due fianchi fissi":
    var n = 0
    for q in m.parts:
      if q.name == "fianco cassetti":
        inc n
        check near(q.pos.z, 0) and near(q.z1, p.pianoLetto - p.spessore)
    check n == 2

  test "gavone: apertura nel comodino e due coperchi":
    let com = m.find("piano testata (comodino)")
    check com.holesPiano.len == 1
    let h = com.holesPiano[0]
    var n = 0
    var area = 0.0
    for q in m.parts:
      if q.name == "coperchio gavone":
        inc n
        area += q.size.x * q.size.y
        check q.apre == "alza" and near(q.z1, com.z1)
        check q.pos.x >= h.x and q.x1 <= h.x + h.w and q.pos.y >= h.z and q.y1 <= h.z + h.h
    check n == 2 and area > 0.95 * h.w * h.h
    # il fondo del gavone è il piano letto, che arriva fin sotto la testata
    check m.find("piano letto").x1 >= com.x1

  test "comodino a filo della risega, scaffali meno profondi":
    check abs(m.find("piano testata (comodino)").size.x - p.risegaLarga) < 0.2
    check near(m.find("ripiano libreria").size.x, 26)

  test "controlli: niente da segnalare, ma il materasso da 80 non entra":
    check p.controlli.len == 0
    var p3 = rilievo()
    p3.materasso[1] = 80
    check p3.controlli.len == 1 and "materasso largo 80" in p3.controlli[0]

  test "variante con tavolino":
    let pt = rilievo().conTavolino
    let mt = parete(pt)
    # il fronte ha un'apertura sola al posto dei primi 3 gradini
    check mt.find("fronte").holes.len == 1 + (pt.nGradini - pt.gradiniTavolino) + 1
    let fr = mt.find("frontale tavolino")
    check fr.holes.len == pt.gradiniTavolino and fr.gruppo == "tavolino"
    # estratto del tutto: il retro arriva al fronte del mobile
    var yMax = -Inf
    for q in mt.parts:
      if q.gruppo == "tavolino": yMax = max(yMax, q.y1)
    check near(yMax, 0)
    # il piano è un'altezza da tavolino per bambini e sta sotto il quarto gradino
    let piano = mt.find("piano tavolino")
    check piano.z1 > 55 and piano.z1 < 66
    # davanti poggia sui fianchi, da terra al piano; dietro su due gambe a pannello
    var gambe, fianchi = 0
    for q in mt.parts:
      if q.name == "gamba tavolino":
        inc gambe
        check near(q.pos.z, 0) and near(q.z1, piano.pos.z) and near(q.y1, piano.y1)
      if q.name == "fianco tavolino":
        inc fianchi
        check near(q.pos.z, 0) and near(q.z1, piano.pos.z)
    check gambe == 2 and fianchi == 2
    # un ripiano sotto ogni gradino e il fondo dei cassetti a profGradini dal frontale
    var ripiani = 0
    for q in mt.parts:
      if q.name == "ripiano gradino" and q.gruppo == "tavolino": inc ripiani
    check ripiani == pt.gradiniTavolino
    check near(mt.find("fondo cassetti").pos.y, fr.y1 + pt.profCassettiTavolino)
    # frontale e apertura a spigoli dritti: tondi solo i vani
    check fr.r == 0
    check pt.controlli.len == 0
    # chiuso, tutto sta dentro il mobile
    for q in parete(rilievo().conTavolino(aperto = false)).parts:
      if q.gruppo == "tavolino": check q.pos.y >= 0 and q.y1 <= pt.profondita

  test "variante: antina ribaltabile sotto il tavolino":
    var pa = rilievo().conTavolino(aperto = false)
    pa.antinaTavolino = true
    let ma = parete(pa)
    let a = ma.find("antina tavolino")
    let piano = ma.find("piano tavolino")
    check a.apre == "ribalta dx" and a.dentro == "tavolino"
    # chiusa: sotto il piano, solo dietro i cassetti-gradino e davanti alle gambe
    check near(a.z1, piano.pos.z) and near(a.size.x, piano.size.x)
    check a.pos.y > ma.find("fondo cassetti").y1
    for q in ma.parts:
      if q.name == "gamba tavolino": check a.y1 < q.pos.y
    check pa.controlli.len == 0
    # aperta, con il tavolino estratto: affiancata a destra, alla quota del piano
    var po = rilievo().conTavolino(aperto = true)
    po.antinaTavolino = true
    po.antinaAperta = true
    let mo = parete(po)
    let ao = mo.find("antina tavolino")
    let pianoO = mo.find("piano tavolino")
    check near(ao.pos.x, pianoO.x1) and near(ao.pos.z, pianoO.pos.z)
    # senza la variante non c'è
    check not parete(rilievo().conTavolino).has("antina tavolino")

  test "scatola delle prese: sotto lo scaffale o sul comodino":
    const nome = "scatola prese (schuko, 2 USB-C, interruttore luce)"
    let sc = m.find(nome)
    let fianco = m.find("fianco dx medio")
    check near(sc.x1, fianco.pos.x)                      # contro il fianco destro
    var primo = Inf
    for q in m.parts:
      if q.name == "ripiano libreria": primo = min(primo, q.pos.z)
    check near(sc.z1, primo)                             # appesa sotto il primo scaffale
    let wBase = m.find("piano testata (comodino)").holesPiano[0].w
    var pc = rilievo()
    pc.preseSulComodino = true
    let mc = parete(pc)
    let sc2 = mc.find(nome)
    let com = mc.find("piano testata (comodino)")
    check near(sc2.pos.z, com.z1)                        # appoggiata sul comodino
    let h = com.holesPiano[0]
    check h.x + h.w <= sc2.pos.x - 1.9 and h.w < wBase   # il gavone si stringe
    check pc.controlli.len == 0
