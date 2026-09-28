/// Port interfaces (02 §5): every external service the domain talks to,
/// plus their value types and the two in-core production adapters
/// (`SystemClock`, `SecureRandomSource`).
library;

export 'ads_service.dart';
export 'analytics_service.dart';
export 'app_info.dart';
export 'attestation_service.dart';
export 'balance_repository.dart';
export 'clock.dart';
export 'connectivity_monitor.dart';
export 'consent_service.dart';
export 'consent_store.dart';
export 'content_repository.dart';
export 'crash_reporter.dart';
export 'crisis_resources_repository.dart';
export 'daily_card_repository.dart';
export 'data_deletion_gateway.dart';
export 'entitlement_cache.dart';
export 'file_transfer.dart';
export 'iap_event.dart';
export 'iap_service.dart';
export 'id_generator.dart';
export 'install_repository.dart';
export 'journal_repository.dart';
export 'logger.dart';
export 'purchase_outbox.dart';
export 'purchase_outcome.dart';
export 'purchase_verifier.dart';
export 'random_source.dart';
export 'reading_repository.dart';
export 'reminder_scheduler.dart';
export 'remote_config_repository.dart';
export 'report_gateway.dart';
export 'review_prompter.dart';
export 'reward_gateway.dart';
export 'rewarded_show_result.dart';
export 'secure_random_source.dart';
export 'secure_store.dart';
export 'session_token_store.dart';
export 'settings_repository.dart';
export 'store_product.dart';
export 'store_purchase.dart';
export 'sync_reason.dart';
export 'sync_status.dart';
export 'system_clock.dart';
export 'timezone_provider.dart';
export 'tracking_authorization.dart';
