# three.js 0.160.0 (copia locale)

Le sole parti di [three.js](https://threejs.org) che usano i visori 3D di Caderò,
copiate dal pacchetto npm `three@0.160.0` con la stessa struttura di cartelle,
così le pagine non chiamano nessun CDN:

- `build/three.module.min.js`
- `examples/jsm/controls/OrbitControls.js`
- `LICENSE` (MIT)

Generando i documenti questa cartella viene copiata in `docs/three/`
(`copiaThree` in `src/cadero/web.nim`). Per cambiare versione: `npm pack three@X`,
ricopiare gli stessi file e aggiornare `threeVersion` in `src/cadero/web.nim`.
