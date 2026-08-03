import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';

const READY_STATE_LABELS: Record<number, string> = {
  0: 'disconnected',
  1: 'connected',
  2: 'connecting',
  3: 'disconnecting',
};

@Injectable()
export class HealthService {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: READY_STATE_LABELS[this.connection.readyState] ?? 'unknown',
    };
  }
}
