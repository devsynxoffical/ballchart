/// Picks the first usable avatar path from common API field names.
String? pickAvatarUrl({
  String? profileImageUrl,
  String? profilePic,
  String? logoUrl,
  String? avatarUrl,
  Map? raw,
}) {
  String? firstNonEmpty(Iterable<String?> candidates) {
    for (final c in candidates) {
      final t = c?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  if (raw != null) {
    return firstNonEmpty([
      avatarUrl,
      profileImageUrl,
      profilePic,
      logoUrl,
      raw['avatarUrl']?.toString(),
      raw['profileImageUrl']?.toString(),
      raw['profilePic']?.toString(),
      raw['logoUrl']?.toString(),
    ]);
  }
  return firstNonEmpty([avatarUrl, profileImageUrl, profilePic, logoUrl]);
}
