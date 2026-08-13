# Cahier des charges fonctionnel, overlays Iron Squadron

Écrit le 12 août 2026, après la validation en jeu des projectors bi-plateforme.
À ce moment-là plus rien du fix de rendu ne passe par le Lua : notre couche devient un
module de confort, et on veut la reposer sur de vrais Projectors au lieu de décals plats.
Ce document décrit **ce que chaque objet doit faire**, pour que le changement de rendu ne
perde rien en silence, et pour servir de liste de recette en jeu après.

**Périmètre** : les **trois** familles qui passent par le toggle, à savoir **Range**,
**Cohésion** et **MaxMove**. Les silhouettes, les tokens de numéro d'unité et **les
zones de déploiement** en sont **sortis** (arbitrage Martin, 12/08) : leurs bundles sont
réparés, donc le vanilla suffit et le contournement Lua n'a plus lieu d'être. Le code
correspondant a été retiré du patcher et de `mod/src` le soir même. **La section 5
ci-dessous est donc caduque**, elle est conservée pour mémoire du comportement retiré.

**Source** : lecture du code, pas de la mémoire. Branche `mac-projector-fallback` pour
`mod/src`, et `mac-patcher/patch_save_for_mac.py` pour le moteur à jour. Les deux ne
disent pas la même chose partout, voir la section 9.

## 0. Vocabulaire et architecture

**Mode** : `overlayMode`, une seule valeur pour toute la table, `"windows"` (rendu
d'origine) ou `"mac"` (le nôtre). Lu par `gGetMode` et `gGetDeploymentMode`. Le per-seat
a été abandonné pour une raison structurelle : le Lua TTS ne tourne que chez l'hôte, et
tout overlay rendu est visible de tous les joueurs.

**Registre** : `activeOverlays`, une entrée par overlay actif, clé
`"<figGUID>:<famille>"` pour range, cohesion et maxmove, et
`"deploy:<cellule>:<x>:<z>"` pour le déploiement, qui n'a pas de figurine.

**Les quatre familles** :

| famille | porte sur | suit la figurine | déclenché par |
|---|---|---|---|
| range | figurine ou token | oui, en continu | bouton RANGE, raccourci de survol, bouton R d'un token |
| cohesion | figurine meneuse d'unité | oui, y compris pendant le drag | bouton COHESION, raccourci de survol |
| maxmove | figurine meneuse d'unité | **non**, ancré au départ | boutons MOVE, DEPLOY, 1, 2, 3, F, B, L, R |
| deployment | cellules de la table | sans objet | SETUP_CONTROLLER |

## 1. Global, le gestionnaire (`StarWarsLegion.lua` + `!/Overlays`)

**Rôle** : détient le registre, le mode, la boucle de suivi, et l'unique point de rendu.

**API appelée par les objets**

| fonction | effet attendu |
|---|---|
| `gRangeTrigger{figGUID}` | allume ou éteint la range de cette figurine, en respectant le mode |
| `gSpawnRange` / `gClearRange` / `gToggleRange` | manipulation directe d'une entrée range |
| `gCohesionTrigger{figGUID}` | idem pour la cohésion |
| `gSpawnCohesion` / `gClearCohesion` / `gToggleCohesion` | idem |
| `gSpawnMaxMove{figGUID, baseSize, speed}` | pose le gabarit de mouvement maximal |
| `gClearMaxMove{figGUID}` | retire celui de cette unité **seulement** |
| `gSpawnDeployment{cell, pos}` / `gClearAllDeployment` | zones de déploiement |
| `gGetMode` / `gGetDeploymentMode` | lisent `overlayMode` |

**Raccourcis clavier** (`StarWarsLegion.lua`, lignes 603 et 614)

1. « Show Range On Hovered Model » : `showRangeOnHoveredModel(hoverObject)`. Sémantique
   vanilla conservée : survoler à nouveau le **même** objet éteint, via la comparaison
   avec `selectedUnitObj`.
2. « Show Cohesion On Hovered Model » : `showCohesionOnHoveredModel(hoverObject)`, même
   sémantique.
3. Le raccourci de range force le rendu « figurine meneuse » à toutes ses bandes, via
   `params.forceFigMode`, même si l'objet survolé porte un `rangeKey`.

**Boucle de suivi** `macRangePoll`, toutes les 5 images

- Ne reconstruit **que** si une figurine suivie a réellement bougé, seuil 0,01 en
  position et 0,5 degré en lacet. Sans ce test, le suivi faisait chuter la fréquence
  d'affichage sur les figurines immobiles.
- S'arrête toute seule quand plus rien n'est suivi, pas de fuite.
- Ne suit que `range` et `cohesion`. **`maxmove` ne doit jamais être suivi.**

**Nettoyage automatique**

- `onObjectDestroy` purge toutes les entrées préfixées par le GUID de l'objet détruit.
- Une entrée dont la figurine n'est plus valide est éliminée au redessin suivant.

**Basculement de mode** `macModeToggle`

- Inverse `overlayMode`, efface les overlays des **deux** moteurs, puis rafraîchit le
  bouton. La range vanilla vit dans le scope Global et n'est pas couverte par
  `getAllObjects()`, elle doit être effacée explicitement.
- Le bouton vit dans `legionFloatingMenu`, gris par défaut comme ses voisins Welcome et
  Chess Clock, vert à l'état actif.

## 2. Order Token (`a57c41`)

L'objet le plus chargé : il porte trois des quatre familles.

### Bouton COHESION, `toggleCohesionRuler(_, playerColor)`

| | comportement attendu |
|---|---|
| garde | ne fait rien si `selectedUnitObj` est nil |
| allumage | `gClearCohesion` **d'abord**, puis `gCohesionTrigger` |
| pourquoi le clear d'abord | `gCohesionTrigger` bascule par GUID. Un overlay laissé par le raccourci de survol faisait que le premier clic du bouton **éteignait** au lieu d'allumer |
| extinction | passe par le même déclencheur |

### Bouton RANGE, `targetingMode(_, playerColor)`

| | comportement attendu |
|---|---|
| garde | ne fait rien si `selectedUnitObj` est nil |
| allumage | `exitAttackMode`, `highlightEnemies`, puis `gClearRange` et `gRangeTrigger` |
| extinction | `gClearRange` **puis** `exitTargetingMode` |
| pourquoi le clear à l'extinction | `exitTargetingMode` et `clearRangeRulers` n'atteignent que la règle vanilla. Sans ce clear, nos anneaux restaient affichés en position OFF |

### Boutons de mouvement, famille MaxMove

Chaînes : `MOVE` vers `initMove` vers `moveUnit(false)`, `DEPLOY` vers `initDeploy` vers
`moveUnit(true)`, et `1` / `2` / `3` vers `changeSpeed1..3` qui appellent `clearTemplates`
puis `moveUnit()` **sans argument**.

| | comportement attendu |
|---|---|
| condition de pose | `isDeploy ~= true`, condition permissive qui couvre nil **et** false. Une condition `isDeploy == false` raterait les appels des boutons de vitesse, qui n'ont pas d'argument. C'est le bug du « fill décalé au premier spawn » |
| ancrage | position **et** lacet capturés au moment de la pose. Le gabarit **ne suit pas** la figurine qui glisse vers sa destination. Le lacet compte pour les socles oblongs, dont l'anneau de base doit garder son orientation pendant que la figurine pivote |
| capture du joueur | chaque bouton stocke `playerColor` dans `macActivePlayerForMove`, hérité du per-seat. Sans objet depuis que le mode est global, à retirer un jour |
| nettoyage | `clearMovementTemplates` détruit `templateA`, `templateB`, l'objet `maxMoveTemplate` du mode vanilla, **et** appelle `gClearMaxMove` pour **cette unité seulement** |
| ⚠ portée du nettoyage | ne **jamais** revenir à un effacement global : `gClearAllMaxMove` supprimait les anneaux des autres tokens quand deux joueurs avaient MOVE ouvert en même temps |

### Filtre de sol partagé, `macHitIsGround`

Utilisé sur les six sites de lancer de rayon. Ignore les figurines, les objets en
mouvement, et le bundle nommé « Maximum Move » qui plane à +20 en mode vanilla.
Ce filtre **disparaît** avec les décals, voir section 8.

## 3. Unit Leader (`99f1c8`) et l'include `!/Cohesion`

**Rôle** : la figurine meneuse d'unité porte la cohésion. L'Order Token et le raccourci
de survol l'appellent tous les deux.

**Vanilla** : `spawnCohesionRuler` choisit le bundle selon `unitData.baseSize` parmi
`small` (27 mm), `medium` (50 mm) et `large` (70 mm), pose un `Custom_AssetBundle` 20
unités au-dessus de la figurine, à l'échelle 0 pour cacher la boîte TTS sans gêner le
Projector, verrouillé, sans gravité, nommé « Cohesion Ruler ».

**Iron Squadron**

| | comportement attendu |
|---|---|
| ⚡ suivi pendant le drag | la cohésion **reste visible et suit la figurine pendant qu'on la déplace**, comme la range. Arbitrage du 11/08, contraire au vanilla qui l'efface au ramassage |
| mise en œuvre | `gClearCohesion` **ignore** la demande tant que `fig.held_by_color` est vrai. Le seul appelant dans cet état est le `onPickedUp` vanilla |
| mode vanilla : toggle et non respawn | `spawnCohesionRuler` d'origine **respawne** au lieu de basculer. Sans interception, un deuxième clic la redessinait et elle ne s'éteignait jamais. On lit `fig.getVar("cohesionRuler")` pour connaître l'état réel |
| garde | l'objet survolé peut ne pas être une figurine et n'avoir aucune de ces fonctions. Le `pcall` retombe alors sur notre moteur |

**❓ Arbitrage ouvert, constaté au banc le 13/08 : les socles sans bundle de cohésion.**
`getCohesionLinks()` ne connaît que `small`, `medium` et `large`. Pour `huge`, `long`,
`laat`, `epic` et `snail`, le vanilla **ne dessine rien** et le moteur Projectors fait
pareil, donc on est à parité. Mais l'ancien moteur à décals retombait sur le rayon
`small` et dessinait quelque chose. Le trou compte surtout pour les **socles oblongs**,
dont les unités ont plusieurs figurines et donc une vraie cohésion à mesurer. Trois
issues : rester au vanilla, réétirer un bundle existant, ou refabriquer un anneau
oblong. **Non tranché.**

## 4. Les tokens à `rangeKey`, et le Bomb Cart

**Objets concernés**, 19 fichiers plus le Bomb Cart, tous via `!/TokenWithRangeRuler` ou
un `require('!/RangeRulers')` direct :

| `rangeKey` | objets | rendu attendu |
|---|---|---|
| `token` | Objectif et ses 4 états, Condition et ses 5 états, Cad Bane (3), Charge à protons, Complete the Mission | 1 anneau, portée 1, socle 25,1 mm |
| `smokeToken` | Fumée | 1 anneau, portée 1, socle 18,8 mm |
| `tokenRangeTwo` | Graffiti | 2 anneaux, portées 1 et 2 |
| `poi` | POI | 1 anneau à 3 pouces, portée 0,5, socle 50,8 mm soit un rayon de 1,000 pouce |
| `bombCart` | Bomb Cart | 2 anneaux, portées 1 et 2, socle 50 mm |

**Deux rendus différents selon le déclencheur.** Le bouton R d'un token rend **son**
anneau, celui de sa fiche ci-dessus. Le **raccourci de survol**, lui, force le rendu
« figurine meneuse » à toutes ses bandes via `forceFigMode`, et le dimensionne avec le
socle équivalent le plus proche, pour que le joueur voie ce que verrait une unité de
cette empreinte :

| token | socle équivalent au survol |
|---|---|
| Fumée, Objectif, Condition, Graffiti, Cad Bane, Charge à protons | `small` (27 mm) |
| **POI**, Bomb Cart | `medium` (50 mm) |

**Interface** : deux boutons « R » identiques, l'un à la rotation 0 et l'autre à 180,
pour que le token soit utilisable sur ses deux faces. État booléen local `rangeOn`.
`onDestroy` efface la règle.

**Comportement attendu**

| | |
|---|---|
| mode vanilla | délègue à la fonction d'origine **aliasée avant surcharge**, pour que le token garde **son** bundle. Sans cet alias le token recevrait le bundle de figurine meneuse, ou rien du tout |
| mode Iron Squadron | bascule via `gClearRange` et `gRangeTrigger`, et tient `rangeOn` à jour |
| dimensionnement | la famille vient de `rangeKey`, lu sur la variable de l'objet |

**⚠ Interdit, à ne jamais réintroduire** : surcharger `spawnRangeRuler`,
`clearRangeRulers` ou `clearRangeRuler` **sur les scripts de tokens**. Ça produisait un
plantage TTS reproductible sur Mac, dans le ramasse-miettes Mono, quand le raccourci
d'une figurine posait la règle vanilla. Le routage de la range passe par Global, pas par
les tokens. Le seul alias autorisé sur ces objets est `clearRangeRulersOriginal`, dont le
basculement de mode a besoin.

## 5. SETUP_CONTROLLER (`1cb552`), zones de déploiement — CADUQUE

⚠ **Sorti du toggle le 12/08 au soir.** `spawnBoundaryCell` et `clearDeploymentBoundary`
sont revenus au vanilla exact dans `mod/src`, et le patcher n'injecte plus rien ici : les
zones se posent comme dans le mod d'origine, sur les deux plateformes, leur bundle étant
réparé. La section reste pour mémoire de ce que faisait le double chemin.

**Rôle** : pose les cellules de la zone de déploiement d'une mission.

| | comportement attendu |
|---|---|
| point de branchement | `spawnBoundaryCell(cell, x, z)`, après le calcul de position, sur `gGetDeploymentMode` |
| mode vanilla | pose un `Custom_AssetBundle` nommé « Deployment Boundary », verrouillé, échelle 0, orienté par `deployRotations[cell]` |
| mode Iron Squadron | `gSpawnDeployment{cell, pos}` |
| nettoyage | `clearDeploymentBoundary` appelle `gClearAllDeployment` **d'abord**, puis détruit les objets nommés « Deployment Boundary » de la zone de bataille |
| couverture | les missions d'après mars (Cauldron, Contact Contact!, Outflank, Payload) sont **déjà couvertes**, matrices en cellules `r` et `b` plus inversion bleue, spawner unique routé. Rien à convertir |

## 6. Les projectors qui ne passent PAS par le toggle

Deux entrées du menu du GAME_CONTROLLER (`623b03`) posent des Projectors sans jamais
consulter `gGetMode`. Ils sont hors périmètre, mais il faut savoir qu'ils existent, sinon
on croit que le toggle couvre tous les projectors du mod.

| entrée de menu | fonction | objet posé | bundle | état sur Mac |
|---|---|---|---|---|
| « Toggle Poi Guide » | `togglePoiGuide` | « Poi Guide », posé en `{8, 30, 0}` | `projector_poiguide` | **n'a jamais été cassé** : pas de shader custom |
| « Toggle Masks : Mid » et ses variantes gauche et droite | `toggleMaskMid` / `Right` / `Left` puis `placeMask(x, z)` | « Masking Boundary », 4 par appel, posés en y = 75 | `projector_masking_3x3` | **était magenta, réparé par le bundle bi-plateforme** |

Ces deux familles servent à la **création de cartes**, pas au jeu. Elles tiennent leur
propre état, `existingPoiGuide` et la table `existingMasks`, et leur propre nettoyage,
`clearMasks`. Elles ne sont balayées par aucune des deux fonctions de la section suivante.

**C'est la démonstration en miniature de la direction générale** : le masking était cassé
sur Mac, personne n'a jamais écrit une ligne de Lua pour lui, et il est réparé par le seul
remplacement de son bundle.

## 7. Les balayeuses par nom, et pourquoi elles comptent

Deux fonctions détruisent des objets **par leur nom** :

- `standbyTokens` (`StarWarsLegion.lua`) : « Cohesion Ruler », « Movement Template »,
  « Range Ruler », « Deployment Boundary » ;
- `removeLockedRulers` (`GAME_CONTROLLER.623b03`) : « Cohesion Ruler » et « Range Ruler ».

**⚠ Conséquence directe du passage aux Projectors.** Aujourd'hui nos overlays sont des
lignes et des décals, sans objet dans la scène : les deux balayeuses ne les voient pas,
et tout notre nettoyage passe par les `gClear*`. Dès qu'on posera de vrais objets
Projector, ils deviendront balayables par nom. C'est à décider explicitement, pas à
subir : soit on les nomme comme le vanilla et on hérite du nettoyage gratuitement, soit
on les nomme autrement et on garde la main. Le piège est de les nommer par accident.

## 8. Ce qui disparaît avec les décals

Tout ceci n'existe que parce qu'un décal est plat et ne sait pas épouser le relief. Un
Projector drape et suit tout seul, donc le changement **supprime** du code :

- `macRayGroundY` et les lancers de rayon au sol, 64 par anneau, 32 par calotte de stade ;
- `macBuildRect`, `macBuildRing`, `macBuildStadium`, toute la géométrie à la main ;
- le cache de géométrie par entrée, qui n'existait que pour ne pas refaire 65 lancers de
  rayon par image sur les overlays immobiles ;
- la coalescence du redessin, report d'une image plus signature triée, qui évitait de
  reprojeter les décals et faisait sautiller les ombres ;
- le préchargement des PNG en décals invisibles sous la table, contre le flash de carré
  blanc au respawn ;
- le filtre `macHitIsGround` ;
- la boucle `macRangePoll`, puisque le Projector vanilla suit déjà nativement.

**⚠ Deux dépendances cachées à traiter avant de supprimer**

1. Le **MaxMove ancré** (section 2) dépend du fait que rien ne le fasse suivre. Un
   Projector suit son parent par nature : il faudra le poser **détaché**, à la position et
   au lacet capturés.
2. Les **socles oblongs** sont aujourd'hui rendus en stade, rectangle plus deux calottes,
   avec le lacet de la figurine. Le vanilla a ses propres bundles oblongs, désormais
   réparés. À vérifier en jeu : est-ce qu'ils suffisent, ou est-ce qu'on garde notre
   géométrie.

## 9. Les deux divergences source contre patcher, à trancher

Le moteur du patcher et la source de la branche ne disent pas la même chose. Le patcher
est celui qui a été validé en jeu.

**Divergence 1, la plus grave.** `mod/src/includes/RangeRulers.ttslua` surcharge
`spawnRangeRuler`, `clearRangeRulers` et `clearRangeRuler` sur tous les objets qui
incluent le fichier, donc sur les 20 tokens. C'est **exactement le motif que le patcher
interdit** dans un commentaire « HISTORY, do not re-introduce », pour cause de plantage
TTS Mac reproductible. Le patcher, lui, n'y pose qu'un alias. La source de la branche
porte donc un plantage latent, et un backport naïf le ferait remonter.

**Divergence 2.** La source appelle `gClearAllRange` et `gClearAllMaxMove`, qui existent
dans `Overlays.ttslua` mais **pas** dans le moteur du patcher, où l'effacement global de
MaxMove a été délibérément remplacé par un effacement ciblé sur l'unité, parce qu'il
supprimait les anneaux des autres joueurs. Ces appels sont donc soit sans effet, soit
porteurs du bug déjà corrigé.

**Conséquence pratique** : le backport ne doit pas se faire dans le sens qu'on croyait.
Ce n'est pas « compléter la source avec ce que le patcher a en plus », c'est **aligner la
source sur le patcher**, y compris en retirant des surcharges qu'elle porte en trop.
