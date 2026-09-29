/**
 * `attest.allowedAppIds` (03 §8.2, RC78) lists iOS App Attest app IDs as
 * `"{TEAM}.com.vshyrochuk.taro"` and Android package names as
 * `"com.vshyrochuk.taro"`. `{TEAM}` is replaced with `APPLE_TEAM_ID`; entries
 * that still hold a placeholder (no team ID configured) are dropped, so an
 * unconfigured Worker accepts no iOS attestation rather than a wrong one.
 */
export const TEAM_PLACEHOLDER = '{TEAM}';

export function resolveAllowedAppIds(
  allowedAppIds: readonly string[],
  appleTeamId: string | undefined,
): string[] {
  return allowedAppIds
    .map((id) => (appleTeamId === undefined ? id : id.split(TEAM_PLACEHOLDER).join(appleTeamId)))
    .filter((id) => !id.includes('{'));
}
