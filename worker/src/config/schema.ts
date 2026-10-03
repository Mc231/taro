import { z } from 'zod';
import { PACK_PRODUCT_IDS } from '../monetization/catalog';

/**
 * The one remote-config schema (03 §8, RC8; GLOSSARY §8). Types, ranges and
 * enums for every key of `config:public` and `config:server` in `CONFIG_KV`.
 *
 * - Push (`src/admin/configPush.ts`) validates a complete document with the
 *   strict variants: every key present, no unknown key, values in range.
 * - Read (`ConfigService`) overlays a stored document on the compiled
 *   defaults and validates the result with the lenient variants (unknown keys
 *   are dropped so a Worker rollback survives a newer push); an invalid
 *   document falls back to the defaults as a whole.
 * - `config/remote_config.schema.json` is exported from `RemoteConfigFileSchema`
 *   (`scripts/export-config-schema.ts`) for `tools/check_remote_config.py`.
 *
 * Ranges: 03 §8.2 and 04 §13 where they give one; the remaining server-only
 * ranges are sanity bounds chosen here (documented per key). Keep every quoted
 * dotted string in this file a GLOSSARY §8 key (`check_glossary.py`).
 */

/** GLOSSARY §2 spread IDs (`spreads.enabled`, `ai.maxTokensBySpread`). */
export const SPREAD_IDS = [
  'single',
  'three_ppf',
  'three_sao',
  'relationship',
  'two_paths',
  'celtic_cross',
] as const;

/** `kBannerAllowList` (RC18, MO11): `ads.bannerScreens` may only narrow it. */
export const BANNER_ALLOW_LIST = ['home', 'journal_list', 'learn_library'] as const;

/** `ai.effort` values accepted by the model API. */
export const AI_EFFORTS = ['low', 'medium', 'high'] as const;

/**
 * `ai.serviceTier` values: `standard`, or `fast` (OpenAI Fast mode, formerly
 * Priority processing: about 40 % lower latency at 2x the token price, 03 §9.3).
 */
export const AI_SERVICE_TIERS = ['standard', 'fast'] as const;

/** Routable AI providers (RC97): `ai.provider.*`, `ai.outageFallback.provider`, `ai.disclosedProviders`. */
export const AI_PROVIDER_IDS = ['anthropic', 'openai'] as const;
export type AiProviderId = (typeof AI_PROVIDER_IDS)[number];

/** `ai.moderation.provider` values (RC97): `none` or a provider with a moderation endpoint. */
export const AI_MODERATION_PROVIDERS = ['none', 'openai'] as const;

/**
 * Model ID families per provider (Sprint 8.1 API check, 2026-09-30): Anthropic
 * IDs start `claude-`, OpenAI IDs `gpt-` (or an `o<n>` reasoning model). A
 * model routed to the wrong provider is rejected at push time.
 */
const MODEL_FAMILY: Readonly<Record<AiProviderId, RegExp>> = {
  anthropic: /^claude-/,
  openai: /^(gpt-|o\d)/,
};

const int = (min: number, max: number) => z.int().min(min).max(max);
const usd = (max: number) => z.number().min(0).max(max);
const semver = z.string().regex(/^\d+\.\d+\.\d+(\+\d+)?$/, 'expected x.y.z or x.y.z+build');
const modelId = z.string().regex(/^[a-z0-9][a-z0-9.-]{0,63}$/, 'expected a model id');
const aiProvider = z.enum(AI_PROVIDER_IDS);
const httpsUrl = z.url({ protocol: /^https$/ });
const nonEmptyStrings = z.array(z.string().min(1)).min(1);

const StorePackSchema = z.strictObject({
  productId: z.enum(PACK_PRODUCT_IDS),
  enabled: z.boolean(),
  sortOrder: int(0, 9),
});

const MaxTokensBySpreadSchema = z.strictObject({
  single: int(256, 32000),
  three_ppf: int(256, 32000),
  three_sao: int(256, 32000),
  relationship: int(256, 32000),
  two_paths: int(256, 32000),
  celtic_cross: int(256, 32000),
  '*': int(256, 32000),
});

/** `config:public` (`PublicConfigDto` minus the Worker-injected pack credits), GLOSSARY §8.1. */
const publicShape = {
  version: z.int().min(0),
  'readings.enabled': z.boolean(),
  'readings.freeDaily': int(1, 5),
  'readings.maxPerInstallPerDay': int(5, 100),
  'readings.tzCooldownHours': int(12, 168),
  'spreads.enabled': z.array(z.enum(SPREAD_IDS)).max(SPREAD_IDS.length),
  'rewarded.enabled': z.boolean(),
  'rewarded.amount': int(1, 2),
  'rewarded.dailyCap': int(0, 10),
  'rewarded.cooldownSec': int(0, 3600),
  'rewarded.intentTtlSec': int(300, 3600),
  'rewarded.loadTimeoutSec': int(5, 30),
  'rewarded.grantPollTimeoutSec': int(5, 60),
  'ads.enabled': z.boolean(),
  'ads.bannerEnabled': z.boolean(),
  'ads.bannerScreens': z.array(z.enum(BANNER_ALLOW_LIST)).max(BANNER_ALLOW_LIST.length),
  'ads.bannerMinCompletedReadings': int(0, 10),
  'ads.attPrepromptEnabled': z.boolean(),
  'store.enabled': z.boolean(),
  'store.packs': z.array(StorePackSchema).min(1).max(4),
  'store.verifyRetryWindowHours': int(24, 168),
  'store.pendingHoldMinutes': int(5, 240),
  'store.removeAdsEnabled': z.boolean(),
  'store.showBestValueBadge': z.boolean(),
  'store.showPerReadingPrice': z.boolean(),
  'ai.consentVersion': int(1, 1000),
  // 300 grapheme clusters by default (RC45); bounds chosen here.
  'ai.questionMaxChars': int(100, 1000),
  'app.minVersion.ios': semver,
  'app.minVersion.android': semver,
  'app.recommendedVersion.ios': semver,
  'app.recommendedVersion.android': semver,
  'balance.staleAfterSec': int(30, 3600),
  'balance.resumeSyncThrottleSec': int(0, 600),
  'review.promptAfterPositiveReadings': int(1, 20),
  'legal.termsUrl': httpsUrl,
  'legal.privacyUrl': httpsUrl,
  'support.email': z.email(),
};

/** `config:server` (never sent to clients), GLOSSARY §8.2. Bounds not in 03/04 are sanity limits. */
const serverShape = {
  version: z.int().min(0),
  'ai.model.paid': modelId,
  'ai.model.free': modelId,
  'ai.model.freeFallback': modelId,
  'ai.provider.paid': aiProvider,
  'ai.provider.free': aiProvider,
  'ai.provider.freeFallback': aiProvider,
  'ai.outageFallback.provider': aiProvider.nullable(),
  'ai.outageFallback.model': modelId.nullable(),
  'ai.moderation.provider': z.enum(AI_MODERATION_PROVIDERS),
  'ai.disclosedProviders': z.array(aiProvider).min(1).max(AI_PROVIDER_IDS.length),
  'ai.effort': z.enum(AI_EFFORTS),
  'ai.serviceTier': z.enum(AI_SERVICE_TIERS),
  'ai.promptVersion': z.string().regex(/^v\d+$/, 'expected v<n>'),
  'ai.maxTokensBySpread': MaxTokensBySpreadSchema,
  'ai.blockedCountries': z.array(z.string().regex(/^[A-Z]{2}$/, 'expected ISO 3166-1 alpha-2')),
  'ai.timeoutMs': int(5000, 60000),
  'ai.maxRetries': int(0, 3),
  'ai.refusalFallbacks': z.boolean(),
  'ai.deadlineMs': int(10000, 60000),
  'ai.budget.freeUsdPerDau': usd(10),
  'ai.budget.softFloorUsd': usd(100000),
  'ai.budget.freeStopFloorUsd': usd(100000),
  'ai.budget.dailyHardUsd': usd(100000),
  'readings.holdTtlSec': int(60, 3600),
  'rewarded.allowedAdUnitIds': nonEmptyStrings,
  'attest.allowedAppIds': nonEmptyStrings,
  'attest.requiredOnReadings': z.boolean(),
  'purchases.allowedBundleIds': nonEmptyStrings,
  'purchases.sandboxMaxCreditsPerInstallPerDay': int(0, 1000),
  'purchases.sandboxGlobalCreditsPerDay': int(0, 100000),
  'purchases.apple.sendConsumptionInfo': z.boolean(),
  'alerts.error5xxRatePct': z.number().min(0).max(100),
  'alerts.readingFailedRatePct': z.number().min(0).max(100),
  'alerts.webhookSigFailuresPer15m': int(1, 1000),
  'abuse.lowTrust.freeDaily': int(0, 5),
  'abuse.lowTrust.freePerIpPerDay': int(1, 100),
  'abuse.lowTrust.freePerCgnatPrefixPerDay': int(1, 1000),
  'abuse.lowTrust.cgnatAsns': z.array(int(1, 4294967295)),
  'abuse.lowTrust.powBits': int(8, 28),
  'abuse.lowTrust.registrationsPerPrefixPerDay': int(1, 100),
  'abuse.lowTrust.alertPerBucketPerDay': int(1, 1000000),
  'abuse.refundBlockThreshold': int(1, 20),
  'safety.maxDeclinedPerDay': int(1, 100),
  'rl.install.perMinute': int(1, 600),
  'rl.readings.perMinute': int(1, 60),
};

type PublicShape = typeof publicShape;
type ServerShape = typeof serverShape;

export type PublicConfig = z.infer<z.ZodObject<PublicShape>>;
export type ServerConfig = z.infer<z.ZodObject<ServerShape>>;

function duplicates(values: readonly unknown[]): unknown[] {
  return values.filter((value, index) => values.indexOf(value) !== index);
}

/** Cross-key rules JSON Schema cannot express: unique list items. */
function checkPublic(config: PublicConfig, ctx: z.RefinementCtx): void {
  const lists: [keyof PublicConfig, readonly unknown[]][] = [
    ['spreads.enabled', config['spreads.enabled']],
    ['ads.bannerScreens', config['ads.bannerScreens']],
    ['store.packs', config['store.packs'].map((p) => p.productId)],
  ];
  for (const [key, values] of lists) {
    for (const value of duplicates(values)) {
      ctx.addIssue({ code: 'custom', path: [key], message: `duplicate ${String(value)}` });
    }
  }
}

/**
 * AI routing (RC97): every routed provider (the three tiers, the outage
 * fallback, moderation) is in `ai.disclosedProviders`, each tier's model
 * belongs to its provider, and the outage fallback is fully set or off.
 */
function checkAiRouting(config: ServerConfig, ctx: z.RefinementCtx): void {
  const disclosed: readonly string[] = config['ai.disclosedProviders'];
  const tiers = [
    ['ai.provider.paid', 'ai.model.paid'],
    ['ai.provider.free', 'ai.model.free'],
    ['ai.provider.freeFallback', 'ai.model.freeFallback'],
  ] as const;
  const routed: [string, string | null][] = tiers.map(([key]) => [key, config[key]]);
  routed.push(['ai.outageFallback.provider', config['ai.outageFallback.provider']]);
  const moderation = config['ai.moderation.provider'];
  routed.push(['ai.moderation.provider', moderation === 'none' ? null : moderation]);
  for (const [key, provider] of routed) {
    if (provider !== null && !disclosed.includes(provider)) {
      ctx.addIssue({
        code: 'custom',
        path: [key],
        message: `provider ${provider} is not in ai.disclosedProviders`,
      });
    }
  }
  for (const [providerKey, modelKey] of tiers) {
    if (!MODEL_FAMILY[config[providerKey]].test(config[modelKey])) {
      ctx.addIssue({
        code: 'custom',
        path: [modelKey],
        message: `model ${config[modelKey]} is not a ${config[providerKey]} model`,
      });
    }
  }
  const fallbackProvider = config['ai.outageFallback.provider'];
  const fallbackModel = config['ai.outageFallback.model'];
  if ((fallbackProvider === null) !== (fallbackModel === null)) {
    ctx.addIssue({
      code: 'custom',
      path: ['ai.outageFallback.model'],
      message: 'ai.outageFallback.provider and ai.outageFallback.model are both set or both null',
    });
  } else if (
    fallbackProvider !== null &&
    fallbackModel !== null &&
    !MODEL_FAMILY[fallbackProvider].test(fallbackModel)
  ) {
    ctx.addIssue({
      code: 'custom',
      path: ['ai.outageFallback.model'],
      message: `model ${fallbackModel} is not a ${fallbackProvider} model`,
    });
  }
  for (const value of duplicates(disclosed)) {
    ctx.addIssue({
      code: 'custom',
      path: ['ai.disclosedProviders'],
      message: `duplicate ${String(value)}`,
    });
  }
}

/** Budget tiers must be ordered (03 §10.2), lists unique and AI routing disclosed (RC97). */
function checkServer(config: ServerConfig, ctx: z.RefinementCtx): void {
  checkAiRouting(config, ctx);
  const soft = config['ai.budget.softFloorUsd'];
  const freeStop = config['ai.budget.freeStopFloorUsd'];
  const hard = config['ai.budget.dailyHardUsd'];
  if (!(soft <= freeStop && freeStop <= hard)) {
    ctx.addIssue({
      code: 'custom',
      path: ['ai.budget.dailyHardUsd'],
      message: 'budget floors must satisfy softFloorUsd <= freeStopFloorUsd <= dailyHardUsd',
    });
  }
  for (const value of duplicates(config['ai.blockedCountries'])) {
    ctx.addIssue({
      code: 'custom',
      path: ['ai.blockedCountries'],
      message: `duplicate ${String(value)}`,
    });
  }
}

/** Push: complete, no unknown keys. */
export const PublicConfigSchema = z.strictObject(publicShape).superRefine(checkPublic);
export const ServerConfigSchema = z.strictObject(serverShape).superRefine(checkServer);

/** Read: unknown keys dropped (a rolled-back Worker keeps working after a newer push). */
export const PublicConfigReadSchema = z.object(publicShape).superRefine(checkPublic);
export const ServerConfigReadSchema = z.object(serverShape).superRefine(checkServer);

/** `config/remote_config.default.json`: both documents plus an optional `$schema` pointer. */
export const RemoteConfigFileSchema = z.strictObject({
  $schema: z.string().optional(),
  public: PublicConfigSchema,
  server: ServerConfigSchema,
});

export type RemoteConfigFile = z.infer<typeof RemoteConfigFileSchema>;

export const PUBLIC_CONFIG_KEYS = Object.keys(publicShape) as (keyof PublicConfig)[];
export const SERVER_CONFIG_KEYS = Object.keys(serverShape) as (keyof ServerConfig)[];

/** `CONFIG_KV` keys (03 §8.1, GLOSSARY §6.1). */
export const CONFIG_KV_KEYS = { public: 'config:public', server: 'config:server' } as const;
export type ConfigDocumentKind = keyof typeof CONFIG_KV_KEYS;

/**
 * The active config as the Worker reads it: public and server keys in one
 * flat object. `version` is the public document's (the `/v1/config` ETag);
 * `serverVersion` the server document's.
 */
export type RuntimeConfig = PublicConfig &
  Omit<ServerConfig, 'version'> & { readonly serverVersion: number };

export function mergeConfig(publicConfig: PublicConfig, serverConfig: ServerConfig): RuntimeConfig {
  const { version: serverVersion, ...server } = serverConfig;
  return { ...server, ...publicConfig, serverVersion };
}

/** The `config:public` document of an active config (key order of the schema). */
export function toPublicConfig(config: RuntimeConfig): PublicConfig {
  const out: Record<string, unknown> = {};
  for (const key of PUBLIC_CONFIG_KEYS) {
    out[key] = config[key];
  }
  return out as PublicConfig;
}
