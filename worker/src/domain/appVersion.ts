/** App version strings `X.Y.Z` or `X.Y.Z+B` (03 §2.1, 06 §10.1). Pure. */
export interface AppVersion {
  readonly major: number;
  readonly minor: number;
  readonly patch: number;
  readonly build?: number;
}

const VERSION = /^(\d{1,4})\.(\d{1,4})\.(\d{1,4})(?:\+(\d{1,9}))?$/;

export function parseAppVersion(text: string): AppVersion | undefined {
  const match = VERSION.exec(text.trim());
  if (match === null) {
    return undefined;
  }
  const [, major, minor, patch, build] = match;
  return {
    major: Number(major),
    minor: Number(minor),
    patch: Number(patch),
    ...(build === undefined ? {} : { build: Number(build) }),
  };
}

/**
 * Negative when `a < b`. The build number only breaks ties when both sides
 * carry one (a minimum of `1.2.0` accepts every `1.2.0+B`).
 */
export function compareAppVersions(a: AppVersion, b: AppVersion): number {
  const byParts = a.major - b.major || a.minor - b.minor || a.patch - b.patch;
  if (byParts !== 0 || a.build === undefined || b.build === undefined) {
    return byParts;
  }
  return a.build - b.build;
}
