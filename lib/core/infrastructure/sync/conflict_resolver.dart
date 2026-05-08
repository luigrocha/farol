/// Last-Write-Wins conflict resolution.
/// When a local and remote record differ, the one with the newer `updated_at` wins.
class ConflictResolver {
  const ConflictResolver();

  /// Returns the record that should be kept.
  /// Both records must have an `updated_at` DateTime field.
  Map<String, dynamic> resolve(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTs = _parseTs(local['updated_at']);
    final remoteTs = _parseTs(remote['updated_at']);
    // Remote wins on tie — Supabase is the source of truth
    return (localTs != null &&
            remoteTs != null &&
            localTs.isAfter(remoteTs))
        ? local
        : remote;
  }

  DateTime? _parseTs(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
