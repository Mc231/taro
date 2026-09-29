/**
 * Placeholder for a port whose production adapter lands in a later phase.
 * Every method rejects with a descriptive error, so a route that reaches it
 * fails with `500 INTERNAL` instead of silently succeeding.
 */
// eslint-disable-next-line @typescript-eslint/no-unnecessary-type-parameters -- T names the port the proxy stands in for
export function unimplementedPort<T extends object>(port: string, phase: string): T {
  return new Proxy(
    {},
    {
      get(_target, property) {
        if (typeof property !== 'string' || property === 'then') {
          return undefined;
        }
        return () =>
          Promise.reject(new Error(`${port}.${property} is not implemented until ${phase}`));
      },
    },
  ) as T;
}
