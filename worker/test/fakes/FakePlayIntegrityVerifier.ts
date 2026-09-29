import type {
  PlayIntegrityInput,
  PlayIntegrityResult,
  PlayIntegrityVerifier,
} from '../../src/ports/PlayIntegrityVerifier';

/** Scripted Play Integrity (Standard API) verdicts for route tests (03 §15.3). */
export class FakePlayIntegrityVerifier implements PlayIntegrityVerifier {
  readonly calls: PlayIntegrityInput[] = [];
  private readonly queue: PlayIntegrityResult[] = [];

  defaultResult: PlayIntegrityResult = {
    ok: true,
    deviceVerdict: 'device',
    appRecognized: true,
    packageName: 'com.vshyrochuk.taro',
  };

  enqueue(...results: PlayIntegrityResult[]): this {
    this.queue.push(...results);
    return this;
  }

  verify(input: PlayIntegrityInput): Promise<PlayIntegrityResult> {
    this.calls.push(input);
    return Promise.resolve(this.queue.shift() ?? this.defaultResult);
  }
}
