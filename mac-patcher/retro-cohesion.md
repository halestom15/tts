# Rétro-ingé Cohesion Ruler

Rédigé en mode prod, base pour le refactor event-driven vector lines (15 mai 2026, post-finding session 14-15 mai).

## 1. Définition fonctionnelle (rappel règles SWL)

Le **Cohesion Ruler** matérialise la **distance de cohésion d'unité** : tous les minis d'une même unité doivent rester à une distance maximale du leader d'unité (sinon malus / dispersion). Le ruler aide à vérifier visuellement cette contrainte pendant le tour.

Distance de cohésion : **0.5 inch** (1,27 cm) entre les bords des socles, règle officielle SWL.

## 2. Visuel attendu

3 tailles, indexées par `baseSize` du leader :

| Clé | Base size physique | Bundle |
|---|---|---|
| `small` | 27 mm | `https://steamusercontent-a.akamaihd.net/ugc/2482129948496305632/...` |
| `medium` | 50 mm | `https://steamusercontent-a.akamaihd.net/ugc/2482129948496305877/...` |
| `large` | 70 mm | `https://steamusercontent-a.akamaihd.net/ugc/2482129948496305957/...` |

Rendu côté Windows (TTS Unity 2019.4) : cercle semi-transparent vert/cyan projeté au sol via Unity Projector, centré sur la fig. **À extraire empiriquement** via UnityPy + référence Workshop pour la couleur/alpha exacts (en TODO ci-dessous).

Comportement Projector : drape sur le relief de la table (rochers, élévations) grâce au Projector legacy.

## 3. Déclencheurs (qui peut spawn/clear le ruler ?)

### Spawn

1. **Hotkey global "Show Cohesion On Hovered Model"** — `StarWarsLegion.lua:611-619`
   - Bind via `addHotkey()` côté Global
   - Appelle `showCohesionOnHoveredModel(hoverObject)` qui :
     - Si déjà selected → clear + reset `selectedUnitObj`
     - Sinon → `clearCohesionRuler() + spawnCohesionRuler(hoverObject)`
   - **État global** `selectedUnitObj` tracké côté Global (variable du script `StarWarsLegion.lua` via `require('!/Cohesion')`)

2. **Bouton "COHESION" sur Order Token** — `Order_Token.a57c41.lua:347-352, 369-378`
   - Bouton créé pendant l'activation d'une unité
   - `toggleCohesionRuler()` toggle via flag `rulerOn` local au Order Token
   - Appelle `selectedUnitObj.call("spawnCohesionRuler", selectedUnitObj)` → s'exécute dans le script de la **fig sélectionnée** (Unit_Leader.99f1c8)

3. **Re-spawn automatique après mouvement** — `Unit_Leader.99f1c8.lua:278-286`
   - `dropCoroutine()` attend que `getVelocity().y == 0` (fig au sol)
   - Si `moveState == true` (= en cours de mesure de mouvement) → `spawnCohesionRuler(self)`

### Clear

1. **Hotkey re-press** — toggle via `showCohesionOnHoveredModel` (idem spawn, second appel)

2. **Bouton COHESION re-press** — toggle via `toggleCohesionRuler` (idem)

3. **Bouton invisible "unitID" sur Unit_Leader** — `Unit_Leader.99f1c8.lua:45`
   - Bouton au centre de la fig avec label = numéro d'unité, couleur alpha 0.01 (quasi-invisible)
   - `click_function = "clearCohesionRuler"`
   - C'est l'overlay cliquable du numéro affiché sur chaque fig

4. **onPickedUp sur Unit_Leader** — `Unit_Leader.99f1c8.lua:274-276`
   - **Event-driven déjà existant** : pickup la fig → clear automatique

5. **`standbyTokens()` global** — `StarWarsLegion.lua:562-571`
   - Boucle sur `getAllObjects()` et destroy tout objet nommé `"Cohesion Ruler"` (et "Range Ruler", "Movement Template", "Deployment Boundary")
   - Déclenché par... à tracer (probablement reset de partie ou hotkey debug)

6. **`removeLockedRulers()` GAME_CONTROLLER** — `GAME_CONTROLLER.623b03.lua:148-155`
   - Boucle sur `getAllObjects()` et destroy "Cohesion Ruler" / "Range Ruler"
   - Appelé par la fonction de reload (`reloadObj` voisine)

7. **`clearCohesionRulers()` (pluriel) Order Token** — `Order_Token.a57c41.lua:788-793`
   - Appelé par `clearTemplates()` lors du reset après mouvement
   - `selectedUnitObj.setVar("moveState", false)` + `selectedUnitObj.call("clearCohesionRuler")`

## 4. Lifecycle complet

```
[Spawn]
  showCohesionOnHoveredModel(fig)      [hotkey hover]
  toggleCohesionRuler() [via Order Token bouton]
  dropCoroutine() [auto si moveState]
        ↓
  spawnCohesionRuler(fig):
    1. unitData = fig.getTable("unitData")
    2. bundleURL = getCohesionLinks()[unitData.baseSize]
    3. spawnObject(Custom_AssetBundle, pos = fig.pos + Y+20, scale = 0, rot = (0, fig.rot.y, 0))
    4. setCustomObject({type=0, assetbundle=bundleURL})
    5. setLock(true), use_gravity=false, setName("Cohesion Ruler")
        ↓
[Ruler affiché — STATIQUE, ne suit pas la fig]
  Note: pas de onFixedUpdate. Si fig bouge sans pickup (impossible normalement
  car les figs sont lockables), le ruler reste à l'ancienne position.

[Clear]
  showCohesionOnHoveredModel(same fig)   [hotkey re-press toggle]
  toggleCohesionRuler() [re-press toggle]
  onPickedUp(fig)                        [pickup auto]
  clearCohesionRuler() [click invisible "unitID" button]
  standbyTokens()                        [global reset]
  removeLockedRulers()                   [reload]
  clearCohesionRulers() [via Order Token clearTemplates]
        ↓
  clearCohesionRuler():
    1. destroyObject(cohesionRuler)
    2. cohesionRuler = nil

[Re-spawn auto post-drop]
  onDropped → checkVelocity → si moveState → startLuaCoroutine(dropCoroutine)
        ↓
  dropCoroutine:
    while velocity.y ~= 0: yield
    if moveState == true: spawnCohesionRuler(self)
```

## 5. État scopé : ATTENTION pattern hétérogène

`cohesionRuler` est une variable Lua **scopée au script Lua qui fait le require**. Chaque objet qui require `!/Cohesion` a SA propre `cohesionRuler`. Trois scopes coexistent :

| Site require | Scope `cohesionRuler` |
|---|---|
| `StarWarsLegion.lua:8` (Global) | Script Global |
| `Unit_Leader.99f1c8.lua:1` (chaque fig leader) | Par-fig |
| `Order_Token.a57c41.lua:4` (chaque Order Token) | Par-Order-Token |

**Conséquence pratique** :
- Hotkey hover → spawn dans le scope Global → `cohesionRuler` du Global mis à jour, **pas celui de la fig**
- Bouton COHESION → `selectedUnitObj.call("spawnCohesionRuler", selectedUnitObj)` → exécute dans le scope de la fig → `cohesionRuler` de la fig mis à jour
- `onPickedUp(fig)` → clear dans le scope de la fig → ne clear PAS un ruler spawn via hotkey hover (mais le bouton invisible "unitID" est sur la fig, donc dans le scope fig...)

**Bug latent connu (non reproduit)** : si tu spawn via hotkey hover, puis tu pickup une autre fig, le ruler du Global subsiste. À garder en tête pour le refactor (à corriger ou pas selon scope).

## 6. Filtres de cleanup global

Deux fonctions scannent `getAllObjects()` et destroy par nom :

| Fonction | Fichier | Cible |
|---|---|---|
| `standbyTokens()` | StarWarsLegion.lua:562 | "Cohesion Ruler" + "Range Ruler" + "Movement Template" + "Deployment Boundary" |
| `removeLockedRulers()` | GAME_CONTROLLER.623b03.lua:148 | "Cohesion Ruler" + "Range Ruler" |

**Impact refactor** : si on remplace l'Object Custom_AssetBundle par des vector lines (qui ne sont pas des Objects), ces deux filtres deviennent **caducs**. Il faudra leur substituer un clear de la table d'état globale + `Global.setVectorLines({})`.

## 7. Paramètres visuels exacts — TODO

À extraire empiriquement via UnityPy sur les bundles small/medium/large :

- [ ] Bundle `halfcohesion_27mm.unity3d` (ou équivalent small) : material color, alpha, orthographicSize du Projector, animation éventuelle
- [ ] Bundle medium (50mm) : idem
- [ ] Bundle large (70mm) : idem
- [ ] Screenshot référence côté Workshop (rendu attendu côté Windows TTS 2019.4 / U6 non-magenta)

Scripts UnityPy disponibles dans `Mod TTS SWL/` (`inspect_cohesion.py`, `inspect_externals.py`). À adapter pour extraire les params materials.

## 8. Implications pour le refactor

### Bonnes nouvelles
- API publique petite et conservable : `showCohesionOnHoveredModel`, `spawnCohesionRuler`, `clearCohesionRuler`
- 80% du pattern event-driven déjà en place (`onPickedUp`, `dropCoroutine`)
- Lifecycle bien défini, déclencheurs énumérés exhaustivement

### Décisions à prendre dans le design doc
1. **Unifier les scopes** : faire que `cohesionRuler` soit une table globale indexée par GUID (Variante A) plutôt que par-script. Résout le bug latent (§5) et permet le pattern multi-figs simultanées.
2. **Remplacer les filtres de cleanup** (§6) par des appels à la fonction de clear globale.
3. **Reproduire le drape sur relief** via `Physics.cast()` par segment, comme le POC validé du 14-15 mai.
4. **Compatibilité Order Token bouton** : conserver la sémantique toggle `rulerOn` ou simplifier.

(Note : esthétique du rendu vector lines hors specs — on traitera une fois le dossier refactor clos.)

## 9. Références

- Code : `swlegion-tts/mod/src/includes/Cohesion.ttslua`, `data/CohesionLinks.ttslua`, `StarWarsLegion.lua`, `StarWarsLegion/Unit_Leader.99f1c8.lua`, `StarWarsLegion/Order_Token.a57c41.lua`, `StarWarsLegion/GAME_CONTROLLER.623b03.lua`
- Bundles : cache TTS local, sources Unity dans `Mod TTS SWL/UnityProject-U6/Assets/`
- Session 14-15 mai validation empirique : `~/.claude/projects/-Users-martinpourrat-MARTIN-Star-Wars-Legion/memory/mod-tts-swl/session-14-mai.md`
- Plan B identifié : `~/.claude/projects/-Users-martinpourrat-MARTIN-Star-Wars-Legion/memory/mod-tts-swl/paths-forward.md`
