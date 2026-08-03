import { HealthService } from './health.service';
import { Connection } from 'mongoose';

describe('HealthService', () => {
  it('reports the connection readyState as a human-readable label', () => {
    const fakeConnection = { readyState: 1 } as Connection;
    const service = new HealthService(fakeConnection);

    const result = service.check();

    expect(result.status).toBe('ok');
    expect(result.database).toBe('connected');
    expect(typeof result.timestamp).toBe('string');
  });
});
