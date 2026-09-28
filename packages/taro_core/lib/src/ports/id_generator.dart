/// The ID source (RC41): reading IDs, idempotency keys and request IDs.
// A port is an interface with swappable adapters, even with one member.
// ignore: one_member_abstracts
abstract interface class IdGenerator {
  /// A new random UUIDv4 in canonical lowercase form.
  String uuidV4();
}
