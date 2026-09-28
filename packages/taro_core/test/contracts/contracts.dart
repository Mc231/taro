/// Shared port contract suites (QA16): each `runXContract` runs against its
/// fake here and against the real adapter in `apps/taro/test/data/` and
/// `apps/taro/test/services/` (Phases 11–12), imported by relative path.
library;

export 'ads_service_contract.dart';
export 'balance_repository_contract.dart';
export 'consent_contracts.dart';
export 'consent_store_contract.dart';
export 'content_contracts.dart';
export 'contract_support.dart';
export 'daily_card_repository_contract.dart';
export 'data_deletion_gateway_contract.dart';
export 'determinism_contracts.dart';
export 'device_contracts.dart';
export 'entitlement_cache_contract.dart';
export 'iap_service_contract.dart';
export 'install_repository_contract.dart';
export 'journal_repository_contract.dart';
export 'purchase_outbox_contract.dart';
export 'purchase_verifier_contract.dart';
export 'reading_repository_contract.dart';
export 'remote_config_repository_contract.dart';
export 'report_gateway_contract.dart';
export 'reward_gateway_contract.dart';
export 'secure_store_contract.dart';
export 'session_token_store_contract.dart';
export 'settings_repository_contract.dart';
export 'telemetry_contracts.dart';
