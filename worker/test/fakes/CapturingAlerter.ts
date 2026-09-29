import type { Alert, Alerter } from '../../src/ports/Alerter';

export class CapturingAlerter implements Alerter {
  readonly alerts: Alert[] = [];

  send(alert: Alert): Promise<void> {
    this.alerts.push(alert);
    return Promise.resolve();
  }
}
