# Making the mod's AssetBundles work on Mac

Short version: **build each bundle twice and merge the two files.** One extra step
in whoever builds the bundles, and every mini from then on renders correctly on
both platforms. Nothing changes for Windows players.

---

## What is broken and why

Shader variants inside an AssetBundle are compiled **per graphics API**, decided
by the build target. The mod's bundles were built for Windows, so they carry
`d3d11` and `glcore` variants (we scanned them: 60 of 62 shaders are exactly that
pair). That was correct at the time, and it is why the mod used to work on Mac:
TTS ran OpenGL there.

Since **TTS v14** the Mac player runs **Metal** and has no usable OpenGL path
left. `-force-glcore` reaches the process and is silently ignored. So the custom
shaders never find a variant they can load. TTS substitutes the Standard shader
where it can, which is why minis show their raw team-colour mask, and renders
**magenta** where it cannot, which is why the projectors look worst.

Nothing is wrong with the shader code. It was simply never compiled for Metal.

## The fix, in two parts

### 1. One shader-source change, worth doing once and for all

In `ColorReplacer.shader` (and the other `BucketheadBits` shaders), the team
colour swap is computed in `fixed` precision:

```hlsl
fixed ramp     = 1.0 - distance(c.rgb, _SwapColor.rgb);
fixed swapMask = saturate((ramp - _SwapCutoff) * _SwapContrast);
```

On DirectX, `fixed` and `half` are treated as **32-bit floats**. On Metal, `half`
is a real **16-bit float**. The mask is a near-binary threshold amplified by
`_SwapContrast` (5.0 by default), so in 16 bits the pixels sitting near the
threshold flip at random: speckled bases, cape linings left green, magenta
fringes along the swapped areas.

**Changing `fixed` and `half` to `float` in these shaders is a no-op on Windows**
(they were already 32-bit there) and fixes Metal for good. That is the cleanest
place to fix it: once, in the source.

### 2. Build each bundle twice, then merge

Unity cannot produce a single bundle covering both platforms: ask for Metal in a
Windows build and it silently drops it. But a `Shader` object can declare several
**SubShaders**, and Unity falls through to the next one when the first has no
variant for the current graphics API.

So: build the prefab for `StandaloneWindows64`, build it again for
`StandaloneOSX`, and stack the macOS SubShader behind the Windows one in the same
file.

```
# 1. build both (Editor menu: Assets > Build Bundle (Windows + macOS))
#    -> BiPlatformBundles/win/<name> and BiPlatformBundles/mac/<name>

# 2. merge
pip install UnityPy
python3 merge_subshader_bundles.py BiPlatformBundles/win/<name> \
                                   BiPlatformBundles/mac/<name> <name>

# 3. upload <name> as usual
```

The Windows SubShader stays first and byte-identical, so Windows players get
exactly what they get today. The extra SubShader is inert for them.

## Files here

- `BuildBiPlatformBundle.cs` — drop into any `Editor/` folder. Adds
  **Assets > Build Bundle (Windows + macOS)**, and works in batch mode via
  `-executeMethod BuildBiPlatformBundle.Run`.
- `merge_subshader_bundles.py` — the merge step. Requires `UnityPy`.

## One trap, if you go digging

Merging the variants **inside a single pass** does not work. The parameter
binding tables (`m_NameIndices`, `m_CommonParameters`,
`m_ConstantBufferBindings`) are stored once per pass and shared by every platform
in it, and Metal lays them out differently from DirectX (`VGlobals`/`FGlobals`
instead of `$Globals`, offsets reset to zero). The result loads, logs nothing,
and renders wrong, which costs a lot of time to diagnose. A SubShader carries its
own tables. It is also why `d3d11` and `glcore` coexist happily in the current
bundles: those two share the layout.

## Status on our side

Tested in game on **both** platforms with the same merged file: an A-A5 Speeder
Truck renders correctly on Mac and on Windows.

Of the 190 bundles the mod references, 105 use no custom shader and were never
broken. 85 are affected, and 77 of those are already rebuilt and running. The
remaining 8 belong to seven older units nobody has the sources for any more
(Yoda, the Wookiee Warriors line, the Wookiee Chieftain, the Raddaugh Gnasp
Fluttercraft, the Infantry Support Platform, and the shared materials bundle used
by Kalani and Kraken). Those need a different route, or their sources.

Happy to help wire this into your build, or to hand over the rebuilt bundles.
