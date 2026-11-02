## Genera la tavola e il 3D senza nimib (utile per provare al volo).
import ../src/cadero, ../models/parete

let p = rilievo()
let m = parete(p)
writeFile("tavola.svg", tavola(p, m))
writeFile("parete3d.html", "<!doctype html><meta charset=utf-8><body style='margin:0'>" & viewer3d(m, height = 700))
for r in bom(m):
  echo r.count, " x ", r.name, " ", fmtNum(r.dims[0]), " x ", fmtNum(r.dims[1]), " x ", fmtNum(r.dims[2])
