// api/_lib/bootstrap.ts
import { dataLoader } from './services/dataLoader';
import * as path from 'path';

let ready: Promise<void> | null = null;

export function ensureBoot() {
  if (!ready) {
    // DataLoader already knows its path from constructor
    ready = dataLoader.initialize();
  }
  return ready;
}
