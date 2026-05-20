# Rétro-ingé Movement Template + Maximum Move

**Correction** : Movement implique **2 objets visuels** spawn ensemble lors de l'activation de mouvement. Un seul des deux est cassé magenta.

## Composant 1 : Movement Template A/B (templates 3D courbes) — NON AFFECTÉ

Code : `Order_Token.a57c41.lua:480-529`

```lua
templateA = spawnObject({ type = "Custom_AssetBundle", scale = {1,1,1} ... })
templateA.setCustomObject({ assetbundle = ..., material = 1 })
templateA.setColorTint(...)
templateA.setName("Movement Template (A)")
```

- **scale = {1,1,1}** → mesh visible (pas un Projector caché)
- **`material = 1`** + **`setColorTint()`** → material standard avec colorTint TTS exposé
- Bundles `longBundle` / `shortBundle` / `sharedBundle` par speed (templateInfo)
- **Pas affecté par bug magenta** : c'est un mesh classique, pas un Projector receiver

## Composant 2 : Maximum Move (cercle de portée) — CASSÉ MAGENTA ✅

Code : `Order_Token.a57c41.lua:552-574`

```lua
maxMoveTemplate = spawnObject({
    type = "Custom_AssetBundle",
    position = {basePos.x, basePos.y + 20, basePos.z},
    scale = {0,0,0}  -- ← scale 0, pattern Projector
})
maxMoveTemplate.setCustomObject({
    type = 0,
    assetbundle = maxMoveTemplateBundleToSpawn
})
maxMoveTemplate.setLock(true)
maxMoveTemplate.use_gravity = false
maxMoveTemplate.setName("Maximum Move")  -- ← nom différent de "Movement Template"
```

- **scale = {0,0,0}** → Projector legacy (même pattern que Cohesion/Range/Deployment)
- **Pas de setColorTint** sur ce spawn
- **CASSÉ MAGENTA** sur Mac confirmé par Martin

### Bundles (`includes/data/MovementLinks.ttslua`)

`getMovementLinks()` retourne table indexée `[baseSize][selectedSpeed]` :

| baseSize | Taille | Speeds |
|---|---|---|
| `small` | 27mm | 3 bundles (speed 1/2/3) |
| `medium` | 50mm | 3 |
| `large` | 70mm | 3 |
| `huge` | 100mm | 3 |
| `laat` | 120mm | 3 |
| `epic` | 150mm | 3 |
| `long` | 100×175mm oblong | 3 |
| `snail` | 100×200mm oblong | 3 |

**Total : 24 bundles uniques** pour le cercle de portée max.

Rendu visuel attendu côté Windows : cercle/anneau projeté au sol matérialisant la portée maximale de mouvement à cette vitesse. **Couleur/alpha à extraire via UnityPy** (task #13).

## Déclencheurs

### Spawn
**1 seul déclencheur** : flow d'activation mouvement via Order Token
- Bouton speed (1/2/3) cliqué sur Order Token → set `unitData.selectedSpeed`
- Une fonction de mouvement (autour de `Order_Token.a57c41.lua:480+`) spawn `templateA`, `templateB`, ET `maxMoveTemplate` ensemble
- Conditional : `if isDeploy == false` → pas de Maximum Move pendant la phase de déploiement (ligne 556)

### Clear
**Fonction `clearMovementTemplates()`** — `Order_Token.a57c41.lua:776-786`
```lua
function clearMovementTemplates()
    if templateA ~= nil then destroyObject(templateA) end
    if templateB ~= nil then destroyObject(templateB) end
    if maxMoveTemplate ~= nil then destroyObject(maxMoveTemplate) end
end
```

Appelé par :
- `clearTemplates()` (ligne 770-774) → appelé après le drop final du mouvement
- Aucun cleanup global (Maximum Move PAS dans `standbyTokens()` ni `removeLockedRulers()`)

## Lifecycle

```
[Spawn]
  Order Token bouton speed (1/2/3) → spawn flow
      ↓
  templateA, templateB (mesh visible) + maxMoveTemplate (Projector)
      ↓
  L'utilisateur déplace templateA jusqu'à la position cible
  → contrôle visuel "ma fig peut-elle aller là" avec le cercle Maximum Move

[Clear]
  Drop final (fig placée) → clearTemplates() → destruct 3 objets ensemble
```

**Pattern : statique au spawn, pas de suivi de fig**. Le cercle Maximum Move est positionné une fois à `basePos + Y20` et reste là pendant que tu manipules les templates de mouvement.

## État scopé

`maxMoveTemplate` est une variable par Order Token (`require('!/Cohesion')` ligne 4 mais maxMoveTemplate vient du flow Order_Token directement, pas d'include). Pas de partage Global / Unit_Leader.

## Implications refactor

- API publique à conserver : le spawn et `clearMovementTemplates()` (mais cette dernière mélange templates A/B + maxMoveTemplate)
- 24 bundles cercle de portée → 8 sets de params visuels distincts par baseSize (les 3 speeds partagent probablement le même material avec rayon différent ; à extraire task #13)
- Pattern statique simple : spawn une fois, clear ensemble avec templates A/B
- En vector lines : 1 cercle par maxMoveTemplate, dessiné via setVectorLines + Physics.cast par segment pour drape relief
- Cleanup propre : `clearMovementTemplates` doit clear la table d'état globale spécifique au maxMove de cet Order Token
- **Templates A/B (mesh) restent inchangés** — pas dans le scope du refactor

## Couleur attendue

Le cercle Maximum Move devrait visuellement matcher la couleur du template de speed correspondant :
- Speed 1 : couleur 1 (vert ?)
- Speed 2 : couleur 2 (jaune ?)
- Speed 3 : couleur 3 (rouge ?)

Note `templateInfo.moveTemplate[selectedSpeed].colorTint` — c'est le tint des templates A/B, mais le cercle Maximum Move utilise un bundle distinct sans colorTint (le bundle embarque sa propre couleur). À vérifier empiriquement / via UnityPy quelle est la couleur baked-in de chaque bundle Maximum Move par speed.
