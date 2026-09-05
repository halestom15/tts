import { ObjectState, SaveState } from '@matanlurey/tts-save-files';

/**
 * Moves everything that can safely wait into a hidden "setup crate" so the
 * table loads without paying for it, and the Global deploys it back one
 * object per frame under a loading screen (see DeferredSetup.ttslua).
 *
 * Why: TTS creates a script context for every scripted object on the table
 * during the loading bar (~40ms each, measured) and binds every visible
 * asset in the first rendered frame. Objects inside a container pay neither
 * until they are taken out - and a takeObject of a scripted object costs
 * ~40-50ms total, cheaper than the load-time path. Deferring therefore
 * shortens the loading bar and the post-load freeze, for the price of a
 * short, paced deployment cascade.
 *
 * What gets deferred is COMPUTED, never listed by hand: the mod keeps
 * growing, and a hardcoded list would rot at the first object someone adds
 * or removes. An object is deferred when nothing that stays on the table
 * can miss it while the crate is still closed - see pickDeferrable.
 *
 * The crate's GMNotes carries the deployment manifest: original position,
 * rotation and lock state per object, in dependency order.
 */

export const CRATE_GUID = 'd3f3a0';
export const CRATE_NICKNAME = 'ISQ Setup Crate';

/**
 * Object types that cannot live inside a container, whatever the rules
 * below conclude: TTS refuses to bag them, or silently breaks them.
 */
const NEVER_BAGGABLE = new Set([
  'HandTrigger',
  'ScriptingTrigger',
  'FogOfWarTrigger',
  'FogOfWar',
]);

/**
 * Escape hatch for hazards no static rule can see: an object that another
 * script finds by scanning (getAllObjects plus a name, a tag or a GMNotes
 * mark) rather than by GUID, and that is needed before the cascade ends.
 *
 * Empty on purpose. The two load-time scans in the mod - Global's
 * standbyTokens and the rules panel indexing its lecterns - are replayed
 * once the cascade finishes, so neither needs an entry here. Add a GUID
 * with a comment saying who looks for it and why waiting is not an option.
 */
const NEVER_DEFER = new Map<string, string>([]);

interface ManifestEntry {
  g: string;
  p: { x: number; y: number; z: number };
  r: { x: number; y: number; z: number };
  l: number;
}

function round(value: number): number {
  return Math.round(value * 10000) / 10000;
}

function walk(objects: ObjectState[], into: ObjectState[]): ObjectState[] {
  for (const o of objects) {
    into.push(o);
    if (o.ContainedObjects) {
      walk(o.ContainedObjects, into);
    }
    if (o.States) {
      walk(Object.values(o.States), into);
    }
  }
  return into;
}

/**
 * Every text an object can resolve a GUID from, itself and its contents.
 *
 * LuaScriptState matters as much as LuaScript: the battle decks keep the
 * GUIDs of their button and zone in their saved state and dereference them
 * in onLoad without a nil check - which is exactly how the first version
 * of this broke them.
 */
function textsOf(objects: ObjectState[]): string[] {
  const out: string[] = [];
  for (const o of walk(objects, [])) {
    for (const key of ['LuaScript', 'LuaScriptState', 'XmlUI', 'GMNotes']) {
      const value = (o as unknown as Record<string, unknown>)[key];
      if (typeof value === 'string' && value !== '') {
        out.push(value);
      }
    }
  }
  return out;
}

function citedBy(texts: string[], guid: string): boolean {
  const quoted = new RegExp(`['"]${guid}['"]`);
  return texts.some((t) => quoted.test(t));
}

/**
 * The deferrable set: every root object that nothing staying on the table
 * resolves by GUID, computed to a fixpoint.
 *
 * The fixpoint matters. Dropping an object from the set turns it back into
 * a stayer, and a stayer's own references must then be honoured too - the
 * mod reaches its answer in three rounds.
 */
function pickDeferrable(
  roots: ObjectState[],
  globalTexts: string[],
): Set<string> {
  const guids = roots.map((o) => o.GUID as string);
  const byGuid = new Map(roots.map((o) => [o.GUID as string, o]));
  const textsByGuid = new Map(
    roots.map((o) => [o.GUID as string, textsOf([o])]),
  );

  const candidates = new Set(
    guids.filter((g) => {
      const o = byGuid.get(g) as ObjectState;
      return !NEVER_BAGGABLE.has(o.Name) && !NEVER_DEFER.has(g);
    }),
  );

  for (;;) {
    // The Global script stays whatever happens, and it names a great deal
    // of the table - leaving it out was the fixpoint's first bug.
    const stayingTexts: string[] = globalTexts.slice();
    for (const g of guids) {
      if (!candidates.has(g)) {
        stayingTexts.push(...(textsByGuid.get(g) as string[]));
      }
    }
    const doomed = guids.filter(
      (g) => candidates.has(g) && citedBy(stayingTexts, g),
    );
    if (doomed.length === 0) {
      return candidates;
    }
    for (const g of doomed) {
      candidates.delete(g);
    }
  }
}

/**
 * Deployment order: an object comes out after everything it names, so its
 * onLoad never resolves a sibling still in the crate. Ties keep the save's
 * own order, which keeps diffs readable.
 *
 * A reference cycle cannot be satisfied by any order - both objects would
 * need the other out first - so the whole cycle stays on the table.
 */
function orderForDeployment(
  roots: ObjectState[],
  deferrable: Set<string>,
): string[] {
  const inOrder = roots
    .map((o) => o.GUID as string)
    .filter((g) => deferrable.has(g));
  const needs = new Map<string, string[]>();
  for (const g of inOrder) {
    const texts = textsOf([roots.find((o) => o.GUID === g) as ObjectState]);
    needs.set(
      g,
      inOrder.filter((other) => other !== g && citedBy(texts, other)),
    );
  }

  const placed = new Set<string>();
  const sorted: string[] = [];
  const stuck = new Set<string>();
  for (;;) {
    const ready = inOrder.filter(
      (g) =>
        !placed.has(g) &&
        !stuck.has(g) &&
        (needs.get(g) as string[]).every((n) => placed.has(n) || stuck.has(n)),
    );
    if (ready.length > 0) {
      for (const g of ready) {
        placed.add(g);
        sorted.push(g);
      }
      continue;
    }
    const left = inOrder.filter((g) => !placed.has(g) && !stuck.has(g));
    if (left.length === 0) {
      break;
    }
    // Whatever is left references itself in a loop: none of it can be
    // deferred, and dropping it may free the rest.
    for (const g of left) {
      stuck.add(g);
      deferrable.delete(g);
    }
    console.info(
      `Setup crate: ${left.join(', ')} reference each other in a cycle, ` +
        `left on the table.`,
    );
  }
  return sorted;
}

export function deferSetup(save: SaveState): void {
  const roots = save.ObjectStates.filter((o) => o.GUID);
  if (roots.length !== save.ObjectStates.length) {
    throw new Error('A root object has no GUID.');
  }
  if (roots.some((o) => o.GUID === CRATE_GUID)) {
    throw new Error(`Crate GUID ${CRATE_GUID} is already used in the save.`);
  }

  const deferrable = pickDeferrable(roots, [
    save.LuaScript || '',
    save.XmlUI || '',
  ]);
  const order = orderForDeployment(roots, deferrable);
  const byGuid = new Map(roots.map((o) => [o.GUID as string, o]));

  const contained: ObjectState[] = [];
  const manifest: ManifestEntry[] = [];
  for (const guid of order) {
    const o = byGuid.get(guid) as ObjectState;
    const t = o.Transform;
    manifest.push({
      g: guid,
      p: { x: round(t.posX), y: round(t.posY), z: round(t.posZ) },
      r: { x: round(t.rotX), y: round(t.rotY), z: round(t.rotZ) },
      l: o.Locked ? 1 : 0,
    });
    contained.push(o);
  }

  save.ObjectStates = roots.filter((o) => !deferrable.has(o.GUID as string));

  // The rules above are what keeps this safe, so they are checked rather
  // than trusted: anything still able to resolve a crated GUID at load
  // time would throw a red error in front of the players.
  const stayingTexts = textsOf(save.ObjectStates).concat([
    save.LuaScript || '',
    save.XmlUI || '',
  ]);
  for (const guid of order) {
    if (citedBy(stayingTexts, guid)) {
      throw new Error(
        `Deferred ${guid} is still referenced by an object that stays on ` +
          `the table - the deferrable fixpoint is wrong.`,
      );
    }
  }
  const position = new Map(order.map((g, index) => [g, index]));
  for (const o of contained) {
    const texts = textsOf([o]);
    for (const guid of order) {
      if (
        guid !== o.GUID &&
        citedBy(texts, guid) &&
        (position.get(guid) as number) >
          (position.get(o.GUID as string) as number)
      ) {
        throw new Error(
          `Deferred ${o.GUID} references ${guid}, which deploys later - ` +
            `the deployment sort is wrong.`,
        );
      }
    }
  }

  const scripted = contained.filter((o) => (o.LuaScript || '').trim() !== '');
  console.info(
    `Setup crate: deferring ${contained.length} of ${roots.length} objects ` +
      `(${scripted.length} scripted).`,
  );

  const crate = {
    GUID: CRATE_GUID,
    Name: 'Bag',
    Transform: {
      posX: 75,
      posY: -2.5,
      posZ: 30,
      rotX: 0,
      rotY: 0,
      rotZ: 0,
      scaleX: 1,
      scaleY: 1,
      scaleZ: 1,
    },
    Nickname: CRATE_NICKNAME,
    Description:
      'Holds the table furniture while the mod loads; ' +
      'it is deployed automatically. Leave it alone.',
    GMNotes: JSON.stringify(manifest),
    ColorDiffuse: { r: 0.1, g: 0.1, b: 0.1 },
    Locked: true,
    Grid: false,
    Snap: false,
    IgnoreFoW: false,
    MeasureMovement: false,
    DragSelectable: false,
    Autoraise: false,
    Sticky: false,
    Tooltip: false,
    GridProjection: false,
    HideWhenFaceDown: false,
    Hands: false,
    MaterialIndex: -1,
    MeshIndex: -1,
    LuaScript: '',
    LuaScriptState: '',
    XmlUI: '',
    Bag: { Order: 0 },
    ContainedObjects: contained,
  } as unknown as ObjectState;
  save.ObjectStates.push(crate);
}
