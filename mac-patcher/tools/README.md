# Outils de réparation Mac des AssetBundles

Ces scripts ont produit la réparation Mac du mod. Ils sont ici pour être
retrouvables et reproductibles, pas pour être jolis : ce sont des outils
d'atelier, en français, à usage interne Iron Squadron.

Le paquet destiné aux développeurs du mod, en anglais, est ailleurs :
`mac-support-package/`.

## Les deux causes racines

**1. Pas de variante Metal.** Les bundles ont été compilés pour
`StandaloneWindows64` uniquement, entre 2019 et 2022. Quand TTS est passé à
Metal sur Mac, leurs shaders custom n'avaient aucune variante pour cette API :
figurines magenta. Rien à voir avec Unity 6, contrairement à ce qu'on a cru
pendant des semaines.

**2. La couleur de sommet vaut zéro sur Metal.** Les shaders d'effets lumineux
lisent `v.color`, un canal que **aucun mesh du mod ne possède** (mesuré : 1 seul
sur 408, et il n'a pas de shader custom). DirectX et OpenGL remplacent un canal
absent par du blanc, Metal par du noir. Les passes étant en `Blend One One`,
multipliées par zéro elles n'ajoutent rien : sabres, yeux et boucliers éteints,
sans que rien ne paraisse cassé. Touche 12 bundles.

## La chaîne, dans l'ordre

Deux voies selon qu'on a les sources du modèle ou non.

### Voie rebuild — quand les sources existent

```
patch_shader_precision.py --apply        # fixed/half -> float (précision Metal)
patch_shader_vertexcolor.py --apply      # v.color -> blanc (effets lumineux)
Unity 6 -executeMethod BuildAllTargets.Run -target mac -out AssetBundles-mac
merge_all_bundles.py AssetBundles-win AssetBundles-mac AssetBundles-dual
patch_shader_precision.py --restore      # remet les sources d'origine
DUAL_DIR=AssetBundles-dual install_dual_to_cache.py --install
```

On ne rebuilde que la cible macOS : le SubShader Windows du bundle publié reste
bit pour bit celui d'aujourd'hui.

### Voie greffe — quand il n'y a pas de sources

C'est la voie des 8 orphelins, et la seule à dérive nulle : le bundle publié
garde ses maillages, ses textures et ses matériaux inchangés, on ne lui ajoute
qu'un SubShader.

```
Unity 2019.1.9f1 -executeMethod BuildMetalGraft.Run -out AssetBundles-graft
graft_metal_2019_1.py <publié.unity3d> <greffon> <sortie.unity3d>
install_grafted_to_cache.py --install
```

**La version d'Unity doit correspondre à celle du bundle publié.** Les 248
bundles se répartissent sur cinq versions : 2019.4.19f1 (144), 2019.1.9f1 (83),
2019.1.0f2 (11), 2019.4.40f1 (9), 5.3.4f1 (1). Elle se lit dans les 200 premiers
octets du fichier, en clair après la signature `UnityFS`.

Entre 2019.1 et 2019.4, la sérialisation des shaders change : les tables du blob
passent de plates à imbriquées. D'où deux scripts de fusion qui refusent chacun
le format de l'autre :

| script | format | produit par |
|---|---|---|
| `merge_subshader_platforms.py` | listes imbriquées, champ `stageCounts` | Unity 6 |
| `graft_metal_2019_1.py` | listes plates | Unity 2019.1 |

## Pourquoi un SubShader entier et pas une passe fusionnée

Les tables de liaison de paramètres (`m_NameIndices`, `m_CommonParameters`,
`m_ConstantBufferBindings`) sont stockées **une fois par passe** et partagées par
toutes les plateformes. DirectX et OpenGL cohabitent parce qu'ils partagent
cette disposition. Metal, lui, éclate les globals en `VGlobals`/`FGlobals` et
remet les offsets à zéro : greffer un programme Metal dans une passe DirectX lui
donne les mauvaises liaisons, et il rend faux **sans aucun message d'erreur**.

Un shader peut en revanche déclarer plusieurs SubShaders, chacun avec ses
propres passes donc ses propres tables. On empile donc le SubShader macOS
derrière celui d'origine : Unity descend au suivant quand le premier n'a pas de
variante pour l'API courante.

## Pièges rencontrés

- **La sauvegarde ne se juge pas à son existence mais à son contenu.** Un bundle
  simplement *déposé* au premier passage existe au second et se fait sauvegarder
  alors que c'est déjà le nôtre. 60 entrées sur 114 étaient dans ce cas. Le
  garde-fou est `is_ours()` : aucun bundle publié ne porte de variante Metal,
  donc en trouver une prouve que le fichier vient de nous.
- **Toujours greffer depuis le bundle publié**, jamais depuis un bundle déjà
  greffé, sinon on empile les SubShaders à chaque passage.
- **macOS tue les vieux éditeurs Unity** au lancement (`SIGKILL`, aucun log
  écrit), avec une alerte « Unity est endommagé ». Ce n'est pas une quarantaine :
  la réponse est Réglages Système → Confidentialité et sécurité → « Ouvrir quand
  même ». Ne jamais cliquer « Placer dans la corbeille ».
- **Certains shaders sont en latin-1** (l'en-tête « © Allen White ») : lire en
  binaire, ne pas réencoder.
- **UnityPy** : `m_Colors` donne des dictionnaires modifiables, `m_Floats` des
  tuples immuables. Pour modifier un float, reconstruire la liste.
- **zsh ne découpe pas les variables non quotées** : pour une longue liste de
  chemins, passer par `bash -c` avec un tableau.

## Ce qu'on ne touche jamais

- Les bundles **sans shader custom** : ils n'ont jamais été cassés.
- `stunt_double_bot_1` : son rebuild ajoute un socle absent du bundle publié.
- Les **Custom Models** (`mesh` + `diffuse` au lieu de `bundle`) : TTS leur
  applique son propre matériau, ils ne peuvent pas être magenta. Ils sont
  majoritaires dans le mod.
