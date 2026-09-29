/**
 * Minimal `Reflect` metadata shim for `@peculiar/x509`, whose `tsyringe`
 * dependency refuses to load without `Reflect.getMetadata` ("tsyringe
 * requires a reflect polyfill"). tsyringe only uses `getMetadata`,
 * `getOwnMetadata` and `defineMetadata`, so this covers exactly those
 * instead of pulling in the full `reflect-metadata` package.
 *
 * Imported for its side effect by `./x509` before the library itself.
 */
interface MetadataReflect {
  getMetadata?: (key: unknown, target: object) => unknown;
  getOwnMetadata?: (key: unknown, target: object) => unknown;
  defineMetadata?: (key: unknown, value: unknown, target: object) => void;
}

/** Installs the shim on `target` unless it already has metadata support. Returns true when installed. */
export function installReflectMetadataShim(target: object): boolean {
  const reflect = target as MetadataReflect;
  if (typeof reflect.getMetadata === 'function') {
    return false;
  }
  const store = new WeakMap<object, Map<unknown, unknown>>();
  const own = (key: unknown, object: object): unknown => store.get(object)?.get(key);
  reflect.getOwnMetadata = own;
  reflect.getMetadata = (key, object) => {
    for (let o: object | null = object; o !== null; o = Object.getPrototypeOf(o) as object | null) {
      const value = own(key, o);
      if (value !== undefined) {
        return value;
      }
    }
    return undefined;
  };
  reflect.defineMetadata = (key, value, object) => {
    const map = store.get(object) ?? new Map<unknown, unknown>();
    map.set(key, value);
    store.set(object, map);
  };
  return true;
}

installReflectMetadataShim(Reflect);
