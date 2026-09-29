import { InstallRepo, type NewInstall } from '../../src/repos/InstallRepo';
import { ReadingRepo, type NewReading } from '../../src/repos/ReadingRepo';
import { bindings, uniqueId } from '../fakes/testDeps';

export const db = bindings.DB;
export const NOW = '2026-09-26T10:00:00.000Z';

/** Inserts an install (unique ID unless given) and returns its ID. */
export async function seedInstall(overrides: Partial<NewInstall> = {}): Promise<string> {
  const id = overrides.id ?? uniqueId('inst');
  const ok = await new InstallRepo(db).insert({
    id,
    platform: 'ios',
    trust: 'high',
    installSecretHash: `hash-${id}`,
    now: NOW,
    ...overrides,
  });
  if (!ok) {
    throw new Error(`seedInstall: ${id} already exists`);
  }
  return id;
}

/** Inserts a `held`-ready reading row for `installId` and returns it. */
export async function seedReading(
  installId: string,
  overrides: Partial<NewReading> = {},
): Promise<NewReading> {
  const reading: NewReading = {
    id: uniqueId('read'),
    installId,
    clientReadingId: uniqueId('crid'),
    spreadId: 'single',
    cardCount: 1,
    hasQuestion: true,
    locale: 'en',
    localDate: '2026-09-26',
    status: 'held',
    chargeSource: 'none',
    createdAt: NOW,
    ...overrides,
  };
  await new ReadingRepo(db).insert(reading);
  return reading;
}

/** The D1 error message of a rejected statement. */
export async function rejection(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (err) {
    return (err as Error).message;
  }
  throw new Error('expected the statement to be rejected');
}
