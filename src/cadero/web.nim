## Vista 3D nel browser: il modello diventa JSON e three.js lo disegna.
##
## Le scatole diventano parallelepipedi; il pannello frontale e i frontali
## sono profili arrotondati estrusi, con le aperture ritagliate.

import std/[json, strformat]
import model

const threeVersion* = "0.160.0"

proc toJson*(m: Model): JsonNode =
  ## Il pannello frontale riceve come fori sia le aperture vuote (nicchia,
  ## gradini) sia le sagome dei frontali, che vanno ad occuparle.
  var fronts: seq[RRect]
  for p in m.parts:
    if p.kind in {kFront, kBox}:
      fronts.add p.frontRect
  var parts = newJArray()
  for p in m.parts:
    var holes = newJArray()
    # solo il pannello frontale riceve le sagome dei frontali come fori
    let fori = if p.kind == kPanel and p.holes.len > 0: p.holes & fronts else: p.holes
    if fori.len > 0:
      for h in fori:
        holes.add %*{"x": h.x, "z": h.z, "w": h.w, "h": h.h, "r": h.r}
    var holesTop = newJArray()
    for h in p.holesPiano:
      holesTop.add %*{"x": h.x, "y": h.z, "w": h.w, "d": h.h, "r": h.r}
    var notchTop = newJArray()
    for h in p.taccheP:
      notchTop.add %*{"x": h.x, "y": h.z, "w": h.w, "d": h.h}
    parts.add %*{
      "name": p.name, "kind": $p.kind,
      "x": p.pos.x, "y": p.pos.y, "z": p.pos.z,
      "w": p.size.x, "d": p.size.y, "h": p.size.z,
      "r": p.r, "holes": holes, "gruppo": p.gruppo, "blocco": p.blocco,
      "apre": p.apre, "corsa": p.corsa,
      "holesTop": holesTop, "notchTop": notchTop}
  %*{"name": m.name, "parts": parts}

proc viewer3d*(m: Model; id = "cadero3d"; height = 520): string =
  ## Un frammento HTML autosufficiente (da inserire con nbRawHtml).
  let data = $toJson(m)
  result = &"""
<div id="{id}" style="width:100%;height:{height}px;border:1px solid var(--line, #ddd);border-radius:6px;position:relative;touch-action:none"></div>
<p style="font-size:0.85em;color:var(--muted, #666)">Trascina per ruotare, pizzica o usa la rotella per lo zoom.</p>
<script type="importmap">
{{"imports": {{"three": "https://cdn.jsdelivr.net/npm/three@{threeVersion}/build/three.module.js",
  "three/addons/": "https://cdn.jsdelivr.net/npm/three@{threeVersion}/examples/jsm/"}}}}
</script>
<script type="module">
import * as THREE from 'three';
import {{ OrbitControls }} from 'three/addons/controls/OrbitControls.js';
const model = {data};
const el = document.getElementById('{id}');
const scene = new THREE.Scene();
// lo sfondo segue il tema della pagina (variabile CSS --stage), se c'è
scene.background = new THREE.Color(getComputedStyle(el).getPropertyValue('--stage').trim() || '#f4f2ee');
const camera = new THREE.PerspectiveCamera(35, el.clientWidth / el.clientHeight, 1, 5000);
const renderer = new THREE.WebGLRenderer({{antialias: true}});
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(el.clientWidth, el.clientHeight);
el.appendChild(renderer.domElement);
scene.add(new THREE.HemisphereLight(0xffffff, 0xb0a890, 1.6));
const sun = new THREE.DirectionalLight(0xffffff, 1.4);
sun.position.set(-150, 400, 300);
scene.add(sun);

const mats = {{
  "pannello": new THREE.MeshStandardMaterial({{color: 0xe3c9a0, roughness: 0.8}}),
  "frontale": new THREE.MeshStandardMaterial({{color: 0xead3ad, roughness: 0.8}}),
  "cassetto": new THREE.MeshStandardMaterial({{color: 0xead3ad, roughness: 0.8}}),
  "materasso": new THREE.MeshStandardMaterial({{color: 0xffffff, roughness: 1}}),
  "foro": new THREE.MeshStandardMaterial({{color: 0x3a2e22}}),
  "accessorio": new THREE.MeshStandardMaterial({{color: 0xf5f5f5, roughness: 0.4}}),
  "muro": new THREE.MeshStandardMaterial({{color: 0xb8bcc0, roughness: 1, transparent: true, opacity: 0.45}}),
}};
const edgeMat = new THREE.LineBasicMaterial({{color: 0x6b5a45}});

function roundRect(path, x, y, w, h, r) {{
  r = Math.min(r, w / 2, h / 2);
  path.moveTo(x + r, y);
  path.lineTo(x + w - r, y); path.quadraticCurveTo(x + w, y, x + w, y + r);
  path.lineTo(x + w, y + h - r); path.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  path.lineTo(x + r, y + h); path.quadraticCurveTo(x, y + h, x, y + h - r);
  path.lineTo(x, y + r); path.quadraticCurveTo(x, y, x + r, y);
  return path;
}}
// Assi: x CAD -> x three, z CAD (altezza) -> y three, y CAD (profondità) -> -z three
function extruded(p) {{
  const shape = roundRect(new THREE.Shape(), p.x, p.z, p.w, p.h, p.r || 0);
  for (const h of p.holes) shape.holes.push(roundRect(new THREE.Path(), h.x, h.z, h.w, h.h, h.r));
  const g = new THREE.ExtrudeGeometry(shape, {{depth: p.d, bevelEnabled: false, curveSegments: 6}});
  g.translate(0, 0, -(p.y + p.d));
  return g;
}}
const group = new THREE.Group();
for (const p of model.parts) {{
  let g;
  if (p.kind === "foro") {{
    g = new THREE.CylinderGeometry(p.w / 2, p.w / 2, 0.4, 20);
    g.rotateX(Math.PI / 2);
    g.translate(p.x, p.z, -p.y + 0.15);
  }} else if (p.holes.length > 0 || ((p.kind === "frontale" || p.kind === "cassetto") && p.r > 0)) {{
    g = extruded(p);
  }} else {{
    g = new THREE.BoxGeometry(p.w, p.h, p.d);
    g.translate(p.x + p.w / 2, p.z + p.h / 2, -(p.y + p.d / 2));
  }}
  const mesh = new THREE.Mesh(g, mats[p.kind]);
  group.add(mesh);
  if (p.kind !== "foro" && p.kind !== "materasso")
    group.add(new THREE.LineSegments(new THREE.EdgesGeometry(g, 30), edgeMat));
}}
scene.add(group);
const box = new THREE.Box3().setFromObject(group);
const c = box.getCenter(new THREE.Vector3());
const size = box.getSize(new THREE.Vector3()).length();
camera.position.set(c.x - size * 0.6, c.y + size * 0.2, c.z + size * 1.45);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.copy(c);
controls.update();
function loop() {{ renderer.render(scene, camera); requestAnimationFrame(loop); }}
loop();
new ResizeObserver(() => {{
  camera.aspect = el.clientWidth / el.clientHeight; camera.updateProjectionMatrix();
  renderer.setSize(el.clientWidth, el.clientHeight);
}}).observe(el);
</script>
"""
