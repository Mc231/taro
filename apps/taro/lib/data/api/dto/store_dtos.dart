import 'package:json_annotation/json_annotation.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro_core/taro_core.dart';

part 'store_dtos.g.dart';

/// `POST /v1/purchases/verify` body (03 §6.2 iOS / §6.3 Android). The
/// purchase token and signed transaction are never logged.
@JsonSerializable(createFactory: false, includeIfNull: false)
final class VerifyPurchaseRequestDto {
  /// Creates the DTO.
  const VerifyPurchaseRequestDto({
    required this.platform,
    required this.productId,
    this.transactionId,
    this.signedTransaction,
    this.purchaseToken,
    this.orderId,
    this.transferToken,
  });

  /// The body for [purchase]: only the fields of its platform are sent.
  factory VerifyPurchaseRequestDto.fromDomain(
    StorePurchase purchase, {
    String? transferToken,
  }) {
    final ios = purchase.platform == StorePlatform.ios;
    return VerifyPurchaseRequestDto(
      platform: purchase.platform.name,
      productId: purchase.productId.value,
      transactionId: ios ? purchase.transactionId : null,
      signedTransaction: ios ? purchase.signedTransaction : null,
      purchaseToken: ios ? null : purchase.purchaseToken,
      orderId: ios ? null : purchase.orderId,
      transferToken: transferToken,
    );
  }

  /// `ios | android` (must equal `X-Taro-Platform`).
  final String platform;

  /// The fully qualified product ID.
  final String productId;

  /// iOS transaction ID.
  final String? transactionId;

  /// iOS JWS.
  final String? signedTransaction;

  /// Android purchase token.
  final String? purchaseToken;

  /// Android order ID.
  final String? orderId;

  /// A support transfer token (RC84).
  final String? transferToken;

  /// The wire JSON.
  JsonObject toJson() => _$VerifyPurchaseRequestDtoToJson(this);

  @override
  String toString() => 'VerifyPurchaseRequestDto($platform, $productId)';
}

/// `POST /v1/purchases/verify` `200 {granted | already_granted}` or
/// `202 {pending}` (03 §6.2); maps to [GrantResult].
@JsonSerializable(createToJson: false, checked: true)
final class VerifyPurchaseResponseDto {
  /// Creates the DTO.
  const VerifyPurchaseResponseDto({
    required this.status,
    this.purchaseId,
    this.productId,
    this.creditsGranted = 0,
    this.isFirstPurchase = false,
    this.balance,
  });

  /// Decodes the wire JSON.
  factory VerifyPurchaseResponseDto.fromJson(JsonObject json) =>
      _$VerifyPurchaseResponseDtoFromJson(json);

  /// `granted | already_granted | pending`.
  final String status;

  /// The Worker purchase ID.
  final String? purchaseId;

  /// The product the store says was bought.
  final String? productId;

  /// Credits granted.
  final int creditsGranted;

  /// The first purchase of the install.
  final bool isFirstPurchase;

  /// The balance after a grant.
  final BalanceDto? balance;

  /// The domain result, received at device time [syncedAt]. A granted
  /// response without a balance is malformed ([FormatException]).
  GrantResult toDomain({required DateTime syncedAt}) {
    final grant = wireEnum(
      {for (final s in GrantStatus.values) s.wire: s},
      status,
      'status',
    );
    if (grant != GrantStatus.pending && balance == null) {
      throw const FormatException('"balance" is required for a grant');
    }
    return GrantResult(
      status: grant,
      creditsGranted: creditsGranted,
      isFirstPurchase: isFirstPurchase,
      purchaseId: purchaseId,
      productId: productId == null ? null : ProductId(productId!),
      balance: balance?.toDomain(syncedAt: syncedAt),
    );
  }
}

/// `POST /v1/rewards/intents` body (03 §7.1).
@JsonSerializable(createFactory: false)
final class RewardIntentRequestDto {
  /// Creates the DTO.
  const RewardIntentRequestDto({required this.adUnitId});

  /// The rewarded ad unit.
  final String adUnitId;

  /// The wire JSON.
  JsonObject toJson() => _$RewardIntentRequestDtoToJson(this);
}

/// `POST /v1/rewards/intents` 201 response (03 §7.1).
@JsonSerializable(createToJson: false, checked: true)
final class RewardIntentDto {
  /// Creates the DTO.
  const RewardIntentDto({
    required this.intentId,
    required this.amount,
    required this.expiresAt,
    this.customData,
    this.userId,
  });

  /// Decodes the wire JSON.
  factory RewardIntentDto.fromJson(JsonObject json) =>
      _$RewardIntentDtoFromJson(json);

  /// The intent ID.
  final String intentId;

  /// SSV `customData` (= [intentId], RC56).
  final String? customData;

  /// SSV `userId` (= [intentId], never the install ID).
  final String? userId;

  /// Bonus readings on a verified view.
  final int amount;

  /// When the intent lapses.
  @UtcInstantConverter()
  final DateTime expiresAt;

  /// The domain intent.
  RewardIntent toDomain() => RewardIntent(
    intentId: IntentId(intentId),
    amount: amount,
    expiresAt: expiresAt,
  );
}

/// `GET /v1/rewards/intents/{intentId}` response (03 §7.3).
@JsonSerializable(createToJson: false, checked: true)
final class RewardIntentStatusDto {
  /// Creates the DTO.
  const RewardIntentStatusDto({
    required this.status,
    required this.amount,
    this.balance,
  });

  /// Decodes the wire JSON.
  factory RewardIntentStatusDto.fromJson(JsonObject json) =>
      _$RewardIntentStatusDtoFromJson(json);

  /// `issued | granted | cancelled | expired | rejected`.
  final String status;

  /// The intent amount.
  final int amount;

  /// The balance after a grant.
  final BalanceDto? balance;

  /// The domain status, received at device time [syncedAt].
  RewardStatus toDomain({required DateTime syncedAt}) => RewardStatus(
    state: wireEnum(RewardIntentState.values.asNameMap(), status, 'status'),
    amount: amount,
    balance: balance?.toDomain(syncedAt: syncedAt),
  );
}
