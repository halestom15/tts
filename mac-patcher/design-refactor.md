# Design refactor — Overlays Projector SWL TTS (Mac/Unity 6)

**Status** : draft 15 mai 2026. Spec pour le patch event-driven hybride (decals plats + vector lines drapants). Base : 4 retro-*.md + materials-reference.md + shaders Allen White lus.

## 1. Contexte (résumé exécutif)

Le passage du player TTS à Unity 6 a strippé les variants Standard receiver des Projectors legacy. Sur Mac, **tous les overlays Projector du mod SWL s'affichent en magenta** : Cohesion Ruler, Range Ruler, Maximum Move, Deployment Boundary. Validation empirique session 14-15 mai : aucun fix côté bundle/shader ne marche (le strip est player-side TTS U6). Fix Berserk = ticket à ouvrir mais sans garantie de calendrier.

**Solution mod-side validée** : remplacer le pattern Custom_AssetBundle (Projector) par un combo **Decal plat (PNG hébergé) + Vector lines (drapant via raycast)** orchestré par un manager Global event-driven.

## 1bis. Fallback per-seat avec auto-test au boot

Le refactor ne **remplace pas** le Projector legacy, il l'**augmente** d'un fallback per-seat. Chaque joueur a un compat flag détecté au boot, et le rendu s'adapte :

- **Seats non-Mac** (TTS U6 OK) → voient le **Projector legacy** (rendu original préservé)
- **Seats Mac** (bug magenta) → voient le **patch hybride** (decal + vector lines)

Quand Berserk corrigera le bug, l'auto-test au boot suivant désactivera le compat pour les seats Mac → retour automatique au comportement legacy, zéro action utilisateur.

### 1bis.1 État par-seat (Global script)

```lua
compatBySeat = {}  -- {Red=true|false, Blue=true|false, ...} true = Mac/needs patch

function onLoad(script_state)
   if script_state ~= "" then
      compatBySeat = JSON.decode(script_state) or {}
   end
   testCompatForAllSeated()
end

function onSave()
   return JSON.encode(compatBySeat)
end

function getMacSeats()
   local out = {}
   for color, isMac in pairs(compatBySeat) do
      if isMac then table.insert(out, color) end
   end
   return out
end

function getNonMacSeats()
   local out = {}
   for color, isMac in pairs(compatBySeat) do
      if not isMac then table.insert(out, color) end
   end
   return out
end
```

### 1bis.2 Test compat au boot

```lua
function testCompatForAllSeated()
   for _, player in pairs(Player.getPlayers()) do
      if player.seated then
         offerCompatTest(player)
      end
   end
end

function offerCompatTest(player)
   -- Spawn un canary Projector en zone hors-jeu (sous la table)
   local canary = spawnObject({
      type="Custom_AssetBundle",
      position={-50, -10, -50},
      scale={0,0,0}
   })
   canary.setCustomObject({assetbundle = COHESION_27MM_URL})

   -- Wait quelques secondes le temps que le bundle charge
   Wait.time(function()
      -- UI popup pour ce joueur uniquement
      player.broadcast("Test rendu : cliquez sur ce que vous voyez sur le canary (Y=-10)")
      -- Buttons "Couleurs OK" et "Magenta/rose"
      -- onClick stocke compatBySeat[player.color] = true|false
      -- destruct canary
   end, 3)
end
```

### 1bis.3 Spawn d'un overlay (pattern unifié)

```lua
function spawnOverlay(type, fig, params)
   local macSeats = getMacSeats()
   local nonMacSeats = getNonMacSeats()
   local entry = {type=type, fig=fig, params=params, objects={}}

   -- 1. Projector legacy pour les seats non-Mac
   if #nonMacSeats > 0 then
      local projector = spawnObject({type="Custom_AssetBundle", ...})
      projector.setCustomObject({assetbundle = bundleURLs[type][fig.baseSize]})
      projector.setLock(true)
      projector.setName(type .. "_legacy")
      if #macSeats > 0 then projector.setInvisibleTo(macSeats) end
      entry.objects.projector = projector
   end

   -- 2. Custom_Tile (PNG plat) pour les seats Mac
   if #macSeats > 0 then
      local tile = spawnObject({type="Custom_Tile", position=fig.pos+Y0.1, scale=...})
      tile.setCustomObject({image = pngURLs[type][fig.baseSize]})
      tile.setLock(true)
      tile.setName(type .. "_patch")
      if #nonMacSeats > 0 then tile.setInvisibleTo(nonMacSeats) end
      entry.objects.tile = tile
   end

   -- 3. Vector lines (drape relief) pour les seats Mac
   if #macSeats > 0 then
      entry.lines = buildVectorLines(type, fig, params, macSeats)
      -- ajoutées au batch global
   end

   activeOverlays[fig.getGUID() .. ":" .. type] = entry
   redrawAll()
end
```

### 1bis.4 Bug Berserk fix → reset auto

Quand Berserk corrigera les variants Standard receiver dans le player TTS U6 :
- Au prochain boot de partie, `testCompatForAllSeated` re-run pour chaque seat
- Les Mac users verront maintenant le canary correctement → cliquent "Couleurs OK" → `compatBySeat[color] = false`
- Le patch ne s'active plus pour eux, comportement legacy restauré
- Aucun changement de code requis côté mod

**Re-test manuel** : un bouton "Re-test compatibility" dans l'UI Notes du mod permet de forcer un nouveau test à tout moment (utile si le user veut vérifier après une mise à jour TTS).

### 1bis.5 Incertitudes à valider empiriquement au POC

| Incertitude | Plan B si KO |
|---|---|
| `Object.setInvisibleTo` cache-t-il le **rendu de la projection** d'un Projector ou seulement le GameObject parent ? | Si KO : si au moins 1 Mac seat présent, on ne spawn PAS le Projector du tout (tout le monde voit le patch — compromis : 1 Mac dans la partie = tout le monde adopte le rendu patch) |
| `Global.setDecals()` supporte-t-il un filtre `players` per entry ? | Si KO : utiliser `Custom_Tile` Objects (déjà ce qu'on a au-dessus, avec `setInvisibleTo`). Plus propre et déjà compatible per-seat |

À tester en début de phase d'implémentation, avant de pousser tout le code.

## 2. Architecture event-driven (manager Global)

### 2.1 État global unique

```lua
-- mod/src/includes/Overlays.ttslua (nouveau)
local activeOverlays = {}  -- clé = "{guid}:{type}" → {type, fig, params}
local hiddenWhilePickedUp = {}  -- buffer pour les overlays cachés temporairement
```

### 2.2 API publique unifiée

```lua
-- Spawn / clear par type, scopé à une fig
function spawnOverlay(type, fig, params)
function clearOverlayForFig(type, fig)
function clearAllOverlays()  -- reset complet

-- Adapters pour conserver l'API existante des callers
function spawnCohesionRuler(fig)       -- → spawnOverlay("cohesion", fig, {})
function clearCohesionRuler()           -- → clearOverlayForFig("cohesion", self)
function spawnRangeRuler(fig, override) -- → spawnOverlay("range", fig, {override=override})
function clearRangeRulers()             -- → clearOverlayForFig("range", selectedUnitObj)
-- etc.
```

### 2.3 Event handlers (Global)

```lua
function onObjectPickUp(player_color, obj)
   -- buffer tous les overlays attachés à obj puis les retirer du draw
   hidePickedUp(obj)
   redrawAll()
end

function onObjectDrop(player_color, obj)
   -- restaurer les overlays de obj depuis le buffer
   restorePickedUp(obj)
   redrawAll()
end

function onObjectDestroy(obj)
   -- nettoyage définitif
   purgeForFig(obj)
   redrawAll()
end
```

### 2.4 Rendu unique par tick d'event

```lua
function redrawAll()
   local lines, decals = {}, {}
   for _, entry in pairs(activeOverlays) do
      local l, d = builders[entry.type](entry.fig, entry.params)
      for _, line in ipairs(l) do table.insert(lines, line) end
      for _, decal in ipairs(d) do table.insert(decals, decal) end
   end
   Global.setVectorLines(lines)
   Global.setDecals(decals)
end
```

**Important** : `setVectorLines` et `setDecals` sont des **singletons** côté TTS — chaque appel remplace toute la collection. D'où le manager global qui agrège.

## 3. Spec par overlay

### 3.1 Cohesion

| Composant | Détail |
|---|---|
| Trigger spawn | Hotkey "Show Cohesion On Hovered Model" / bouton COHESION Order Token / dropCoroutine post-mouvement (`moveState=true`) |
| Trigger clear | Mêmes triggers (toggle) + onPickedUp (auto) + standby/reload globaux |
| Decal PNG | `cohesion_halo.png` — gradient radial blanc fade depuis le centre, fond transparent, 512×512px |
| Decal params | `position = fig.pos + Y0.1`, `rotation = (90, 0, 0)` (face vers le haut), `scale = (baseRadius+1, baseRadius+1, baseRadius+1) × 2` |
| Vector line | 1 cercle filaire blanc à `r = base_radius + 0.5"` du centre, drapé par raycast 32 segments |
| Couleur | #FFFFFF α=0.6 |

API conservée : `showCohesionOnHoveredModel`, `spawnCohesionRuler`, `clearCohesionRuler`. Compatible avec les 3 sites de require existants (Global, Unit_Leader, Order_Token) car redirigés vers le manager global.

### 3.2 Range Ruler

| Composant | Détail |
|---|---|
| Trigger spawn | Hotkey "Show Range On Hovered Model" / bouton RANGE Order Token (targetingMode/attackMode) / bouton R sur POI/tokens |
| Trigger clear | Mêmes triggers (toggle) + clearTemplates (post-drop mouvement) + exit modes |
| Decal PNG | `range_bands.png` (universel) — 4 anneaux concentriques à 6/12/18/24 inches relatifs, couleurs jaune/orange/rouge/magenta foncé, fond transparent, 1024×1024px |
| Decal params | `position = fig.pos + Y0.1`, `scale = (60, 60, 60)` (couvre 24" de rayon + marge) |
| Vector lines | 4 cercles filaires aux rayons absolus **6", 12", 18", 24"** du centre, mêmes couleurs que les bandes du PNG |
| Couleur (par anneau) | R1 #FFC300, R2 #FF7500, R3 #FF1400, R4 #C20042 (alpha 0.6 sur les lignes) |
| Variantes | Tokens (smokeToken/token/tokenRangeTwo/bombCart/POI) → moins d'anneaux (1 ou 2), PNG distincts ou même PNG avec scale ajusté |

API conservée : `showRangeOnHoveredModel`, `spawnRangeRuler(fig, override)`, `clearRangeRuler/clearRangeRulers`.

Pour les variantes, le `override` permet de passer un type explicite (`"smokeToken"`, `"poi"`, etc.) au lieu du baseSize de la fig.

### 3.3 Maximum Move

| Composant | Détail |
|---|---|
| Trigger spawn | Lors du clic sur bouton speed (1/2/3) sur Order Token (flow mouvement) |
| Trigger clear | clearMovementTemplates (drop final) |
| Decal PNG | `max_move_disk.png` — disque plein bleu ciel #55CCFF α=0.48, fond transparent, 512×512px |
| Decal params | `position = fig.pos + Y0.1`, `scale = ProjectorRadius × 2` selon (baseSize, speed) |
| Vector line | 1 cercle filaire bleu ciel au rayon = ProjectorRadius (drape relief) + 1 anneau base blanc fin à r = baseRadius + 0.5" |
| Couleur | Cercle principal #55CCFF α=0.6, anneau base #FFFFFF α=0.5 |
| Rayons | Lookup table `maxMoveRadius[baseSize][speed]` (ex: `27mm.speed1=4.55", speed2=6.52", speed3=8.48"`) — extraits de `_ProjectorRadius` dans les materials Movement |

API conservée : flow existant dans `Order_Token.a57c41.lua:552-574`, remplacement du `spawnObject Custom_AssetBundle` par `spawnOverlay("maxmove", fig, {speed=selectedSpeed, baseSize=unitData.baseSize})`.

### 3.4 Deployment Boundary

| Composant | Détail |
|---|---|
| Trigger spawn | `spawnDeploymentBoundary(matrix)` au setup (depuis menu UI Deployment) |
| Trigger clear | `clearDeploymentBoundary()` (menu UI Remove Overlay) + standby global |
| Decal PNG | `deployment_red.png` + `deployment_blue.png` — rectangle plein uniforme α=0.5, 256×256px |
| Decal params | Par cellule de la matrix, `position = grid pos + offset`, `scale = (6, 6, 6)` (taille standard d'une cellule SWL), rotation selon `deployRotations[cell]` |
| Vector lines | Contour rectangle drapant (4 côtés × N segments via raycast) par cellule, couleur match decal |
| Couleur | Rouge #FF0000 / Bleu #0000FF α=0.5 |
| Variantes | Half/L/Corner/Round → combinaisons de cellules dans la matrix, le manager gère chaque cellule individuellement (1 decal + 1 contour par cellule) |

API conservée : `spawnDeploymentBoundary(matrix)`, `clearDeploymentBoundary()`. Internement, chaque cellule est enregistrée comme un overlay distinct avec un GUID synthétique (ex `"deployment:bs:5:3"`).

## 4. Assets PNG à générer

| Fichier | Dimensions | Description | Hosting |
|---|---|---|---|
| `cohesion_halo.png` | 512×512 | Gradient radial blanc centre → transparent bord, RGBA | iron-squadron.fr/tts-assets/ |
| `range_bands.png` | 1024×1024 | 4 anneaux concentriques aux rayons relatifs 0.25/0.5/0.75/1.0, gradient discret (pas blend), couleurs jaune/orange/rouge/magenta, alpha 0.6 | iron-squadron.fr/tts-assets/ |
| `range_smoke.png` | 256×256 | 1 anneau à rayon relatif 1.0, blanc opaque | idem |
| `range_token.png` | 256×256 | 1 anneau à rayon relatif 1.0, jaune | idem |
| `range_tokenRangeTwo.png` | 256×256 | 2 anneaux, jaune + orange | idem |
| `range_poi.png` | 256×256 | 1 anneau pour POI (range 0.5 / 3") | idem |
| `range_bombCart.png` | 256×256 | 2 anneaux | idem |
| `max_move_disk.png` | 512×512 | Disque plein bleu ciel #55CCFF α=0.48, RGBA | idem |
| `deployment_red.png` | 256×256 | Carré rouge plein #FF0000 α=0.5 | idem |
| `deployment_blue.png` | 256×256 | Carré bleu plein #0000FF α=0.5 | idem |

**Génération** : script Python Pillow `generate_overlay_assets.py` qui produit tous les PNG d'un coup. Reproductible, versionnable dans `swlegion-tts/tool/`.

**Upload** : `rsync` vers le VPS Iron Squadron, dossier `/var/www/iron-squadron/tts-assets/` (ou similaire). URL stable indépendante de Steam.

## 5. Edge cases et invariants

| Cas | Gestion |
|---|---|
| Multi-overlays simultanés (plusieurs figs avec cohesion + range) | Cohabitent dans la table `activeOverlays`, un `redrawAll()` au moindre changement |
| Fig détruite (mort en combat) | `onObjectDestroy` → `purgeForFig` → redraw |
| Pickup pendant overlay actif | `onObjectPickUp` → buffer dans `hiddenWhilePickedUp`, retire du rendu |
| Drop après pickup | `onObjectDrop` → restore depuis buffer, redraw (positions recalculées par les builders) |
| Pickup d'un objet sans overlay | Handler skip silencieux (test sur présence dans la table) |
| Reload de partie | `activeOverlays` se reset au boot (variable Lua locale du Global), OK |
| Filtres `standbyTokens` / `removeLockedRulers` (scans `getAllObjects()` par nom) | Deviennent caducs (plus d'Object physique). À supprimer ou laisser comme no-op |
| Test multi-joueurs réseau | Le manager Global est synchronisé par TTS (Lua sync), donc tous les joueurs voient les mêmes overlays |
| Drape impossible sur certains terrains custom | Limitation acceptable (déjà flag par Ben). Le decal plat sert de fallback visuel |

## 6. Chemin de migration (séquentiel, testable étape par étape)

1. **Setup Manager Global** : créer `mod/src/includes/Overlays.ttslua`. Aucun caller encore branché. Test : `npm run compile && load mod`, no-op confirmé
2. **Cohesion** (60 lignes, le plus simple) : réécrire `mod/src/includes/Cohesion.ttslua` pour rediriger vers le manager. Test : spawn via hotkey + bouton + dropCoroutine sur Mac
3. **Range Ruler** : réécrire `mod/src/includes/RangeRulers.ttslua` + adapter `POI_Token.lua` + `TokenWithRangeRuler.ttslua`. Test : 4 anneaux + tokens
4. **Maximum Move** : adapter `Order_Token.a57c41.lua:552-574` (spawn inline → call manager) + `clearMovementTemplates`. Test : flow mouvement complet sur Mac
5. **Deployment** : réécrire `SETUP_CONTROLLER.1cb552.lua:243-323`. Test : sélection scenario + spawn de la zone
6. **Cleanup** : supprimer les filtres `standbyTokens` / `removeLockedRulers` pour les types qui ne sont plus des Objects. Garder le filtre pour Movement Template (mesh, toujours Object)
7. **PR sur swlegion/tts** : branche `mac-overlays-refactor`, description du bug + solution + diff. Test communauté

## 7. Compatibilité conservée

- **Tous les sites de require existants** continuent à fonctionner sans modif (`require('!/Cohesion')`, `require('!/RangeRulers')`)
- **Toutes les fonctions globales conservent leur signature** (`spawnCohesionRuler(fig)`, `clearRangeRulers()`, etc.)
- **Pas de change d'API publique** → callers (Unit_Leader, Order_Token, POI_Token, etc.) inchangés
- **Variables d'état globales** comme `selectedUnitObj` conservées pour compat avec les filtres et la logique de toggle

## 8. Risques connus à surveiller

| Risque | Mitigation |
|---|---|
| Performance multi-overlays (N décals + N×64 vectors) | Tester empiriquement sur table chargée. Si lag, sparse raycast (32 segments) ou skip raycast si table plate détectée |
| Synchronisation decal/vector lines pas pixel-perfect | Vector lines au-dessus du decal (Y légèrement supérieur), tolérance visuelle |
| URL Iron Squadron offline | Hosting sur 2 destinations (VPS + GitHub Pages backup) ou inclure le CDN dans le repo si TTS supporte les data URIs |
| Bug U6 sur les decals aussi (improbable, POC validé le 14 mai) | Garder Path B = ticket Berserk en parallèle |
| Refactor casse un caller obscur | Test exhaustif des 5 sites de spawn + tous les triggers connus |

## 9. Annexes

- `materials-reference.md` : tous les params visuels extraits
- `retro-cohesion.md`, `retro-range.md`, `retro-deployment.md`, `retro-movement.md` : déclencheurs et call graphs
- `swlegion-tts/mod/src/includes/` : code source des modules à patcher
