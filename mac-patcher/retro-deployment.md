# Rétro-ingé Deployment Boundary

## Visuel attendu

Zones de déploiement rouge/bleu peintes au sol au début de la partie selon le scenario. Pattern matriciel avec 14 codes de cellule :

| Code | Sens |
|---|---|
| `r` / `b` | Base red / blue |
| `rh` / `bh` | Home (zone arrière) |
| `rs` / `bs` | Side (zone latérale) |
| `rss` / `bss` | Side stretched |
| `rl` / `bl` | Long (zone allongée, spawn 2 cellules : sX + ccX) |
| `rc` / `bc` | Corner |
| `rcc` / `bcc` | Corner-corner (autre orientation) |

URLs bundles dans `deployLinks` (`SETUP_CONTROLLER.1cb552.lua:188-202`).

Plusieurs codes partagent la même URL (e.g. `rh = rs = rss` → même bundle, rotation différente). Distinct rotations : `r=0, rh=0, rs=90, rss=90, ...` (`deployRotations` ligne 204).

Rendu côté Windows : grand rectangle/zone projeté au sol via Projector. Couleurs rouge/bleu. **À extraire via UnityPy** (task #13).

## Spawn

**1 seul déclencheur** : `spawnDeploymentBoundary(matrix)` — `SETUP_CONTROLLER.1cb552.lua:267-314`

- Reçoit une matrice 12×N (codes par cellule) inversée puis lue ligne par ligne
- Pour chaque cellule non-vide : `spawnBoundaryCell(cell, x, z)` qui spawn 1 Custom_AssetBundle au pos calculé `{xStart + 6*(x-1), yValue, zStart - 6*(z-1)}` + `deployOffset[cell]`
- Cas spécial `bl`/`rl` : spawn 2 cellules (sX + ccX) pour matérialiser le L

Appelé par `SETUP_CONTROLLER.1cb552.lua:369` (probablement après sélection de la carte Deployment via UI menu).

## Clear

**1 seul déclencheur** : `clearDeploymentBoundary()` — ligne 316-323
- Boucle sur `battlefieldZone.getObjects()` et `destroyObject` chaque objet nommé `"Deployment Boundary"`

Aussi via :
- **`standbyTokens()`** — `StarWarsLegion.lua:567` — destroy global par nom

(Pas dans `removeLockedRulers` de GAME_CONTROLLER : Deployment n'est pas dans la liste.)

## Lifecycle

```
[Setup partie]
  Menu UI "Mount Deployment" → checkDeployment() → spawnDeploymentBoundary(matrix)
      ↓
  Loop sur matrix → pour chaque cell : spawnBoundaryCell
      ↓
  Custom_AssetBundle spawn statique (scale 0, locked, no gravity)

[Clear]
  Menu UI "Remove Overlay" → clearDeploymentBoundary()
      ↓
  Boucle battlefieldZone → destroyObject par nom

[Aussi : standbyTokens() global au reset]
```

**Pattern : 100% statique.** Pas de suivi, pas d'event. Spawn au setup, clear quand on remove. Plus simple que Cohesion et Range.

## Différences clés vs Cohesion/Range

1. **Pas de fig source** — c'est un overlay de zone, pas un overlay attaché à un objet mobile. Pas besoin de drape sur relief si la table est plate (à confirmer : sur certaines tables custom avec relief, est-ce que la zone de déploiement doit draper ? probablement oui pour cohérence visuelle).
2. **Multi-cellules** par scenario — peut-être 10-20 Custom_AssetBundle spawn simultanément (vs 1 pour Cohesion/Range).
3. **Pas de variable d'état scopée** — pas de `deploymentRuler = nil` ; le code itère sur `battlefieldZone.getObjects()` filtré par nom pour le cleanup.

## Implications refactor

- API publique à conserver : `spawnDeploymentBoundary(matrix)`, `clearDeploymentBoundary()`
- 14 bundle URLs (mais visuellement ~6 zones distinctes vu les doublons URL) → 6 sets de params visuels à extraire (task #13)
- Pas d'event-driven nécessaire — statique simple
- En vector lines : chaque cellule = un polygone fermé `setVectorLines({{points={p1,p2,p3,p4,p1}, ...}, ...})`. Pas de Physics.cast si table plate, sinon raycast par segment du contour
- Filtre cleanup `standbyTokens` à adapter pour clear la table d'état globale (ou laisser un `Global.setVectorLines({})` de la collection deployment)
- **Décision design** : Deployment partage-t-il la même collection `Global.setVectorLines()` que Cohesion/Range, ou faut-il un canal séparé ? `Global.setVectorLines` est singleton donc tout doit cohabiter dans la même collection. Implication : la table d'état globale doit indexer par type (`cohesion` / `range` / `deployment`) pour gérer les clears partiels.
