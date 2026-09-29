import { PREV_APPLIED } from './batchGuard';
import { blobToBytes } from '../crypto/encoding';
import type { Platform, Trust } from '../domain/types';

/** `installs` (03 §4, §3.3; RC37, RC53, RC54, RC67). */
export type InstallStatus = 'active' | 'blocked' | 'deleted';
export type AttestEnv = 'production' | 'development';

export interface InstallRow {
  readonly id: string;
  readonly platform: Platform;
  readonly status: InstallStatus;
  readonly trust: Trust;
  readonly tokenGeneration: number;
  /** `BalanceDto.ledgerVersion` (RC67). */
  readonly stateVersion: number;
  readonly installSecretHash: string | null;
  readonly deviceKeyHash: string | null;
  readonly deviceReused: boolean;
  readonly appVersion: string | null;
  readonly locale: string | null;
  readonly timezone: string | null;
  readonly tzChangedAt: string | null;
  readonly attestKeyId: string | null;
  readonly attestPublicKey: Uint8Array | null;
  readonly attestCounter: number | null;
  readonly attestEnv: AttestEnv | null;
  readonly integrityVerdict: string | null;
  readonly appleAccountToken: string | null;
  readonly playAccountHash: string | null;
  readonly refundCount: number;
  readonly reregisterCountDay: string | null;
  readonly createdAt: string;
  readonly lastSeenAt: string;
}

/** Columns set at registration; the rest take their DDL defaults. */
export interface NewInstall {
  readonly id: string;
  readonly platform: Platform;
  readonly trust: Trust;
  readonly installSecretHash: string;
  readonly deviceKeyHash?: string | null;
  readonly deviceReused?: boolean;
  readonly appVersion?: string | null;
  readonly locale?: string | null;
  readonly timezone?: string | null;
  readonly attestKeyId?: string | null;
  readonly attestPublicKey?: Uint8Array | null;
  readonly attestCounter?: number | null;
  readonly attestEnv?: AttestEnv | null;
  readonly integrityVerdict?: string | null;
  readonly appleAccountToken?: string | null;
  readonly playAccountHash?: string | null;
  readonly now: string;
}

/** Columns written by a proven re-registration (03 §3.3). */
export interface Reregistration {
  readonly id: string;
  /** `token_generation` read before the proof; the update is a compare-and-set on it. */
  readonly expectedGeneration: number;
  readonly trust: Trust;
  readonly appVersion: string;
  readonly locale: string;
  /** Applied only when the stored timezone is null (a pseudonymised row). */
  readonly timezone: string;
  /** Android: the new device-key hash; null keeps the stored one. */
  readonly deviceKeyHash: string | null;
  readonly attestKeyId: string | null;
  readonly attestPublicKey: Uint8Array | null;
  readonly attestCounter: number | null;
  readonly attestEnv: AttestEnv | null;
  readonly integrityVerdict: string | null;
  /** Applied only when the stored binding is null. */
  readonly appleAccountToken: string | null;
  readonly playAccountHash: string | null;
  /** `'yyyy-mm-dd:n'` (UTC day and count, 5 per day). */
  readonly reregisterCountDay: string;
  readonly now: string;
}

interface RawInstall {
  id: string;
  platform: Platform;
  status: InstallStatus;
  trust: Trust;
  token_generation: number;
  state_version: number;
  install_secret_hash: string | null;
  device_key_hash: string | null;
  device_reused: number;
  app_version: string | null;
  locale: string | null;
  timezone: string | null;
  tz_changed_at: string | null;
  attest_key_id: string | null;
  attest_public_key: unknown;
  attest_counter: number | null;
  attest_env: AttestEnv | null;
  integrity_verdict: string | null;
  apple_account_token: string | null;
  play_account_hash: string | null;
  refund_count: number;
  reregister_count_day: string | null;
  created_at: string;
  last_seen_at: string;
}

export class InstallRepo {
  constructor(private readonly db: D1Database) {}

  /** Inserts a new install; false when the ID (or a binding column) already exists. */
  async insert(input: NewInstall): Promise<boolean> {
    const result = await this.db
      .prepare(
        `INSERT INTO installs
           (id, platform, trust, install_secret_hash, device_key_hash, device_reused,
            app_version, locale, timezone, attest_key_id, attest_public_key, attest_counter,
            attest_env, integrity_verdict, apple_account_token, play_account_hash,
            created_at, last_seen_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?17)
         ON CONFLICT DO NOTHING`,
      )
      .bind(
        input.id,
        input.platform,
        input.trust,
        input.installSecretHash,
        input.deviceKeyHash ?? null,
        input.deviceReused === true ? 1 : 0,
        input.appVersion ?? null,
        input.locale ?? null,
        input.timezone ?? null,
        input.attestKeyId ?? null,
        input.attestPublicKey ?? null,
        input.attestCounter ?? null,
        input.attestEnv ?? null,
        input.integrityVerdict ?? null,
        input.appleAccountToken ?? null,
        input.playAccountHash ?? null,
        input.now,
      )
      .run();
    return result.meta.changes === 1;
  }

  async findById(id: string): Promise<InstallRow | null> {
    return this.first('id = ?1', id);
  }

  /** `findById` as a batch statement; map the row with `InstallRepo.parse`. */
  findByIdStmt(id: string): D1PreparedStatement {
    return this.db.prepare(`SELECT * FROM installs WHERE id = ?1`).bind(id);
  }

  /** Maps a raw `installs` row (from a batch result) to an `InstallRow`. */
  static parse(raw: unknown): InstallRow {
    return toInstall(raw as RawInstall);
  }

  /** The install bound to a StoreKit `appAccountToken` (03 §6.1, RC85). */
  async findByAppleAccountToken(token: string): Promise<InstallRow | null> {
    return this.first('apple_account_token = ?1', token);
  }

  /** The install bound to a Play `obfuscatedAccountId` (03 §6.1). */
  async findByPlayAccountHash(hash: string): Promise<InstallRow | null> {
    return this.first('play_account_hash = ?1', hash);
  }

  /** `last_seen_at` and `app_version` on a balance sync (at most hourly, 03 §5.1). */
  async touch(id: string, now: string, appVersion: string | null): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE installs SET last_seen_at = ?2, app_version = COALESCE(?3, app_version)
          WHERE id = ?1`,
      )
      .bind(id, now, appVersion)
      .run();
    return result.meta.changes === 1;
  }

  /** Sets the IANA timezone (03 §3.5); the cooldown check belongs to the caller. */
  async updateTimezone(id: string, timezone: string, changedAt: string): Promise<boolean> {
    const result = await this.db
      .prepare(`UPDATE installs SET timezone = ?2, tz_changed_at = ?3 WHERE id = ?1`)
      .bind(id, timezone, changedAt)
      .run();
    return result.meta.changes === 1;
  }

  /**
   * Timezone change as a compare-and-set on `tz_changed_at` (03 §3.5): applies
   * only if nobody changed the zone since `expectedChangedAt` was read, and
   * bumps `state_version` because the free-day boundary moves (RC67).
   */
  async changeTimezone(input: {
    readonly id: string;
    readonly timezone: string;
    readonly changedAt: string;
    readonly expectedChangedAt: string | null;
  }): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE installs SET timezone = ?2, tz_changed_at = ?3, state_version = state_version + 1
          WHERE id = ?1 AND tz_changed_at IS ?4`,
      )
      .bind(input.id, input.timezone, input.changedAt, input.expectedChangedAt)
      .run();
    return result.meta.changes === 1;
  }

  async setStatus(id: string, status: InstallStatus): Promise<boolean> {
    const result = await this.db
      .prepare(`UPDATE installs SET status = ?2 WHERE id = ?1`)
      .bind(id, status)
      .run();
    return result.meta.changes === 1;
  }

  /** Revokes every issued token by bumping `token_generation` (re-registration, 03 §3.3). */
  async bumpTokenGeneration(id: string): Promise<number | null> {
    const row = await this.db
      .prepare(
        `UPDATE installs SET token_generation = token_generation + 1 WHERE id = ?1
         RETURNING token_generation`,
      )
      .bind(id)
      .first<{ token_generation: number }>();
    return row?.token_generation ?? null;
  }

  /** `state_version + 1`; part of every batch that changes the install's balance state (RC67). */
  bumpStateVersionStmt(id: string): D1PreparedStatement {
    return this.db
      .prepare(`UPDATE installs SET state_version = state_version + 1 WHERE id = ?1`)
      .bind(id);
  }

  /** `state_version + 1` chained after a gate (`PREV_APPLIED`, `batchGuard`). */
  bumpStateVersionAfterStmt(id: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE installs SET state_version = state_version + 1 WHERE id = ?1 AND ${PREV_APPLIED}`,
      )
      .bind(id);
  }

  /** `refund_count + 1` (03 §6.5); returns the new count. */
  async incrementRefundCount(id: string): Promise<number | null> {
    const row = await this.db
      .prepare(
        `UPDATE installs SET refund_count = refund_count + 1 WHERE id = ?1 RETURNING refund_count`,
      )
      .bind(id)
      .first<{ refund_count: number }>();
    return row?.refund_count ?? null;
  }

  /**
   * A refund clawback's install update chained after it (`PREV_APPLIED`,
   * 03 §6.5, RC66): `refund_count + 1`, `state_version + 1`, and an `active`
   * install whose new count reaches `blockThreshold` becomes `blocked`
   * (SET expressions read the old row, so `refund_count + 1` is the new count).
   */
  recordRefundAfterStmt(id: string, blockThreshold: number): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE installs
            SET refund_count = refund_count + 1,
                state_version = state_version + 1,
                status = CASE WHEN status = 'active' AND refund_count + 1 >= ?2
                              THEN 'blocked' ELSE status END
          WHERE id = ?1 AND ${PREV_APPLIED}`,
      )
      .bind(id, blockThreshold);
  }

  /** Erasure keeps the row and nulls `locale` only (03 §3.6, RC37). */
  eraseLocaleStmt(id: string): D1PreparedStatement {
    return this.db.prepare(`UPDATE installs SET locale = NULL WHERE id = ?1`).bind(id);
  }

  /**
   * A proven re-registration (03 §3.3, RC54): replaces the attestation,
   * bumps `token_generation` (revoking every older token), reactivates a
   * `deleted` row (a `blocked` row stays blocked), sets locale and app
   * version, restores a nulled timezone or binding, and keeps the balance.
   * Compare-and-set on `token_generation`: null when another re-registration
   * won the race.
   */
  async reregister(input: Reregistration): Promise<number | null> {
    const row = await this.db
      .prepare(
        `UPDATE installs SET
           status = CASE WHEN status = 'deleted' THEN 'active' ELSE status END,
           trust = ?3,
           token_generation = token_generation + 1,
           app_version = ?4,
           locale = ?5,
           timezone = COALESCE(timezone, ?6),
           device_key_hash = COALESCE(?7, device_key_hash),
           attest_key_id = ?8,
           attest_public_key = ?9,
           attest_counter = ?10,
           attest_env = ?11,
           integrity_verdict = ?12,
           apple_account_token = COALESCE(apple_account_token, ?13),
           play_account_hash = COALESCE(play_account_hash, ?14),
           reregister_count_day = ?15,
           last_seen_at = ?16
         WHERE id = ?1 AND token_generation = ?2
         RETURNING token_generation`,
      )
      .bind(
        input.id,
        input.expectedGeneration,
        input.trust,
        input.appVersion,
        input.locale,
        input.timezone,
        input.deviceKeyHash,
        input.attestKeyId,
        input.attestPublicKey,
        input.attestCounter,
        input.attestEnv,
        input.integrityVerdict,
        input.appleAccountToken,
        input.playAccountHash,
        input.reregisterCountDay,
        input.now,
      )
      .first<{ token_generation: number }>();
    return row?.token_generation ?? null;
  }

  /**
   * Stores a newer App Attest assertion counter (03 §3.4); false when the
   * stored counter is already at or above it (a replayed or cloned key).
   */
  async advanceAttestCounter(id: string, counter: number): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE installs SET attest_counter = ?2
          WHERE id = ?1 AND (attest_counter IS NULL OR attest_counter < ?2)`,
      )
      .bind(id, counter)
      .run();
    return result.meta.changes === 1;
  }

  private async first(where: string, value: string): Promise<InstallRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM installs WHERE ${where}`)
      .bind(value)
      .first<RawInstall>();
    return raw === null ? null : toInstall(raw);
  }
}

function toInstall(raw: RawInstall): InstallRow {
  return {
    id: raw.id,
    platform: raw.platform,
    status: raw.status,
    trust: raw.trust,
    tokenGeneration: raw.token_generation,
    stateVersion: raw.state_version,
    installSecretHash: raw.install_secret_hash,
    deviceKeyHash: raw.device_key_hash,
    deviceReused: raw.device_reused === 1,
    appVersion: raw.app_version,
    locale: raw.locale,
    timezone: raw.timezone,
    tzChangedAt: raw.tz_changed_at,
    attestKeyId: raw.attest_key_id,
    attestPublicKey: blobToBytes(raw.attest_public_key),
    attestCounter: raw.attest_counter,
    attestEnv: raw.attest_env,
    integrityVerdict: raw.integrity_verdict,
    appleAccountToken: raw.apple_account_token,
    playAccountHash: raw.play_account_hash,
    refundCount: raw.refund_count,
    reregisterCountDay: raw.reregister_count_day,
    createdAt: raw.created_at,
    lastSeenAt: raw.last_seen_at,
  };
}
