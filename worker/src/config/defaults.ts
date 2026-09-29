import defaultsFile from '../../config/remote_config.default.json';
import {
  mergeConfig,
  RemoteConfigFileSchema,
  type PublicConfig,
  type RuntimeConfig,
  type ServerConfig,
} from './schema';

/**
 * The compiled defaults (03 §8.1, RC8): `config/remote_config.default.json`,
 * bundled at build time and parsed by the one schema when the module loads.
 * A defaults file that fails the schema stops the Worker at startup (and the
 * `config/defaults` test and `check_remote_config.py` fail in CI first).
 *
 * `abuse.lowTrust.cgnatAsns` (RC65, reviewed quarterly) holds mobile carriers
 * behind CGNAT: 21928 T-Mobile US, 22394 Verizon Wireless, 20057 AT&T
 * Mobility, 3209 Vodafone DE, 6805 Telefonica DE, 25135 Vodafone UK, 12576 EE,
 * 15557 SFR, 51207 Free Mobile, 28573 Claro BR, 26599 Vivo BR, 26615 TIM BR,
 * 28403 Telcel, 55836 Reliance Jio, 45609 Bharti Airtel, 16135 Turkcell,
 * 15895 Kyivstar, 34058 lifecell UA, 9605 NTT Docomo, 17676 SoftBank.
 */
export const DEFAULT_CONFIG_FILE = RemoteConfigFileSchema.parse(defaultsFile);

export const DEFAULT_PUBLIC_CONFIG: PublicConfig = DEFAULT_CONFIG_FILE.public;
export const DEFAULT_SERVER_CONFIG: ServerConfig = DEFAULT_CONFIG_FILE.server;

/** Public and server defaults as one flat active config. */
export const DEFAULT_RUNTIME_CONFIG: RuntimeConfig = mergeConfig(
  DEFAULT_PUBLIC_CONFIG,
  DEFAULT_SERVER_CONFIG,
);
