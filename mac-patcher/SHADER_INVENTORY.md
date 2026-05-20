# SW Legion TTS Mod — Shader Inventory

Scan effectué le 2026-05-07 sur `~/Library/Tabletop Simulator/Mods/Assetbundles/` (40 bundles `.unity3d`).
Outil : UnityPy 1.25.0, script `scan_bundles.py`. Output brut : `scan_bundles_2026-05-07.out`.

## TL;DR
**9 shaders custom distincts**, **tous embarqués dans le `.unity3d` qui les utilise**. Donc :
- L'astuce "Always Included Shaders" du player TTS est **non-applicable** : ces shaders ne sont pas chargés depuis le pool du player, ils vivent dans les bundles.
- Le bug magenta vient du fait que le bytecode/code source de ces shaders custom ne fonctionne plus correctement sous Unity 6 + Metal sur Mac.
- Les overlays magenta listés par Martin (cohésion, range, deployment, movement) correspondent **exactement** aux 4 shaders `BucketheadBits/Projector/*`.

## Inventaire complet (par catégorie)

### Shaders Projector (overlays affectés par le bug magenta)
| Shader | Materials | Bundles |
|---|---|---|
| `BucketheadBits/Projector/Movement` | `ProjectorMaterial_27mm_speed1_single`, `ProjectorMaterial_27mm_speed2_single`, `ProjectorMaterial_50mm_speed2_single` | 3 |
| `BucketheadBits/Projector/Deployment` | `Projector_Deployment_Blue` (×2), `Projector_Deployment_Red` (×2) | 4 |
| `BucketheadBits/Projector/Range` | `ProjectorMaterial_25mm_token`, `ProjectorMaterial_27mm`, `ProjectorMaterial_50mm` | 3 |
| `BucketheadBits/Projector/Cohesion` | `Cohesion_27mm` | 1 |

→ 11 materials projector au total, 4 shaders distincts à porter en priorité.

### Outils / autres custom
| Shader | Materials | Bundles |
|---|---|---|
| `BucketheadBits/MoveTool` | `Speed1`, `Speed2` | 2 |
| `BucketheadBits/Tokens/Lambert Channel Mask` | `unitIDtoken_1` à `unitIDtoken_10` | 10 |
| `BucketheadBits/Silhouette` | `BucketheadBits_Silhouette` | 1 |
| `BucketheadBits/Units/Color Replacer` | `Ewok_SharedMat` | 1 |
| `DWD/LightenSkybox` | `Skybox` | 1 |

→ Le shader `Tokens/Lambert Channel Mask` correspond aux 10 unitIDtokens loggés en console par TTS lors du bug : "Shader didn't load correctly for AssetBundle material unitIDtoken_X". Donc ce shader est **explicitement confirmé cassé**.

## Auteurs
- Préfixe **`BucketheadBits/`** sur 8/9 shaders → ancien contributeur "Buckethead". Aucun repo GitHub public trouvé sous ce handle. Possible que ce soit un handle alternatif de Tieren (crédité ailleurs comme "original mod creator").
- Préfixe **`DWD/`** sur 1 shader (LightenSkybox) → autre auteur, juste un tint skybox.

## Implications pour la conversation avec Ben

1. **L'angle "Always Included Shaders" n'est pas la bonne piste** pour ce bug, parce que les shaders custom sont embarqués dans les bundles. Si Ben a essayé cette piste, c'est cohérent que ça n'ait rien donné.

2. **Le scope minimum réaliste** : porter / remplacer ces 9 shaders sous Unity 6 (compilation Metal-compatible). Soit en partant des sources s'il les a, soit en réécrivant des équivalents stock.

3. **Materials = 11 projectors + 10 tokens + 4 outils + 1 skybox = 26 materials affectés au total** dans 27 bundles différents. Volumétrie raisonnable si les shaders sont swappable d'un coup.

4. **Type technique des shaders** :
   - Les `Projector/*` sont des shaders Unity Projector (transparent, projection avec bandes alternées) — historiquement tricky à porter Metal.
   - Le `Tokens/Lambert Channel Mask` est un shader de coloration par canaux (R/G/B/A) — utilisé pour appliquer la couleur du joueur sur un mesh à canaux. Classique mais codé custom.
   - Les autres (MoveTool, Silhouette, Color Replacer, LightenSkybox) sont des shaders d'effets simples.

## Sources non-trouvées
- Aucun repo public sous `swlegion`, `swlegion-dev`, `matanlurey`, `halestom15`, `Buckethead` ne contient les sources Unity de ces shaders.
- Le projet Unity vit donc en privé sur la machine d'un contributeur (probablement Decaf ou Ben).

## Prochaine étape
Attendre Ben pour confirmer si les sources sont disponibles. Cet inventaire répond déjà partiellement à ses questions 1 et 2 :
- Q1 ("custom shaders updated or just retargeted ?") : on sait maintenant exactement ce qu'il faut updater.
- Q2 ("which shaders are referenced ?") : liste complète ci-dessus.
