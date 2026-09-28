export function register(app: any): void {
  app.post('/v1/readings/:clientReadingId/ack', () => null);
  app.get('/v1/credits', () => null);
}
