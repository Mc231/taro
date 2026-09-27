import { version } from '../package.json';

/** `worker/package.json` version, exposed at `GET /v1/health` (06 §10.1). */
export const WORKER_VERSION: string = version;
