# Rétro-ingé Range Ruler

## Visuel attendu

12 tailles dans `getRangeRulerLinks()` (`mod/src/includes/data/RangeRulerLinks.ttslua`) :

| Clé | Cible | Range |
|---|---|---|
| `small` | base 27mm | range mini |
| `medium` | base 50mm | range mini |
| `large` | base 70mm | range mini |
| `huge` | base 100mm | range véhicule |
| `laat` | base 120mm | range LAAT |
| `epic` | base 150mm | range épique |
| `long` | base 100mm oblong | range véhicule long |
| `snail` | base 100x200mm | range escargot |
| `bombCart` | bomb cart | range spécifique |
| `smokeToken` | jeton fumée 18.8mm | range 1 |
| `token` | jeton charge/objectif/condition 25.1mm | range 1 |
| `tokenRangeTwo` | jeton graffiti 25.1mm | range 2 |
| `poi` | POI token 50.8mm | range 0.5 (3") |

Rendu côté Windows : **4 cercles concentriques** projetés au sol via Unity Projector legacy (1 bundle = N Projectors embarqués pour les bandes de portée 1/2/3/4). Couleurs/alphas/rayons par bande **à extraire via UnityPy** (task #13).

**Configurations par overlay** :
- Rulers de fig (small/med/large/huge/laat/epic/long/snail) : **4 cercles** (range 1/2/3/4)
- `smokeToken` : 1 cercle (range 1, effet smoke 1 pouce)
- `token` (charge/obj/cond) : 1 cercle (range 1)
- `tokenRangeTwo` (graffiti) : 2 cercles (range 1 + 2)
- `poi` : 1 cercle (range 0.5 = 3")
- `bombCart` : à confirmer empiriquement

## Déclencheurs

### Spawn
1. **Hotkey "Show Range On Hovered Model"** — `StarWarsLegion.lua:601-608` → `showRangeOnHoveredModel(hoverObject)`
2. **Bouton "RANGE" sur Order Token** — `Order_Token.a57c41.lua:354-365` → `targetingMode()` ligne 922 → `spawnRangeRuler(selectedUnitObj)`
3. **Bouton "RANGE" via attackMode** — `Order_Token.a57c41.lua:934` → `spawnRangeRuler(selectedUnitObj)`
4. **Bouton "R" sur POI Token** — `POI_Tokens/POI_Token.761483.lua:23,41-46` → `toggleRangeRuler()` → `spawnTokenRangeRuler()` → `spawnRangeRuler(self, tokenRulerBundle)` avec override
5. **Bouton "R" sur autres tokens** — `includes/TokenWithRangeRuler.ttslua:37-43,52-56` (smokeToken, token, tokenRangeTwo via `rangeKey` scopé par-token)

### Clear
1. **Hotkey re-press** — toggle via `showRangeOnHoveredModel`
2. **`clearRangeRulers()` (pluriel)** — Order Token : appelé par `clearTemplates`, `exitTargetingMode`, `exitAttackMode`, `attackMenu`
3. **`clearRangeRuler()` (singulier)** — POI/Token : appelé par `toggleRangeRuler` et `onDestroy`
4. **`standbyTokens()` global** — `StarWarsLegion.lua:567` — destroy tout objet nommé `"Range Ruler"`
5. **`removeLockedRulers()`** — `GAME_CONTROLLER.623b03.lua:151` — destroy par nom

## Différence clé vs Cohesion : suivi temps réel

`RangeRulers.ttslua:78-79` :

```lua
luaScript = "targetGUID = '"..rangeSourceObject.getGUID().."'\n"
         .. "function onFixedUpdate()\n"
         .. "  if targetGUID ~= nil then\n"
         .. "    targetObj = getObjectFromGUID(targetGUID)\n"
         .. "    local targetPosition = targetObj.getPosition()\n"
         .. "    self.setPosition({targetPosition.x, targetPosition.y + 20, targetPosition.z})\n"
         .. "    self.setRotation({0,targetObj.getRotation().y,0})\n"
         .. "  end\n"
         .. "end"
rangeRuler.setLuaScript(luaScript)
```

→ Le ruler **se repositionne 60 fois/sec** côté objet ruler (pas côté Lua de la fig). Différent de Cohesion qui est statique.

**Implication refactor** : pour Range, le suivi temps réel est utile gameplay (tu mesures pendant que tu déplaces la fig pour évaluer si tu vas être en range). On ne peut pas simplement passer en pur event-driven sans perte UX. Le drape sur relief recalculé doit suivre — soit redraw à chaque tick visible (avec mémoization de position pour éviter le leak), soit accepter une dégradation UX (redraw au drop seulement).

## État scopé (même problème que Cohesion §5)

Variable `rangeRuler` scopée par script-objet (Global, chaque fig leader, chaque POI Token, chaque token générique). Pattern identique à Cohesion : 3+ scopes peuvent désaccorder.

`selectedUnitObj` global aussi tracké côté Range (`showRangeOnHoveredModel` ligne 7-17 de RangeRulers.ttslua).

## Override bundle (paramètre `projectorBundleOverride`)

`spawnRangeRuler(rangeSourceObject, projectorBundleOverride)` — le 2e paramètre permet de fournir une URL bundle au lieu de la lookuper via `unitData.baseSize`. Utilisé par POI Token et TokenWithRangeRuler qui passent `rangeRulerTable[rangeKey]` directement. À conserver dans le refactor.

## Implications refactor

- API publique à conserver : `showRangeOnHoveredModel`, `spawnRangeRuler` (avec override), `clearRangeRulers` (Order Token), `clearRangeRuler` (POI/Token)
- 12 bundle URLs → 12 sets de params visuels à extraire (chacun avec **1 à 4 cercles concentriques** selon le type) et reproduire en vector lines (task #13)
- Pattern suivi temps réel → décision design (redraw par tick avec mémoization vs redraw event-driven uniquement)
- Filtres cleanup global (`standbyTokens`, `removeLockedRulers`) à adapter pour la table d'état
- Override `projectorBundleOverride` → s'inscrit naturellement dans une table d'état `{fig=obj, rangeKey="poi"}` ou similaire
