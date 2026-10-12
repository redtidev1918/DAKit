final class Redactor {
  const Redactor();

  static const Set<String> _sensitiveNames = <String>{
    'access_token',
    'authorization',
    'client_secret',
    'code',
    'code_verifier',
    'cookie',
    'refresh_token',
    'set-cookie',
    'state',
    'id_token',
    'csrf_token',
    'signature',
    'sig',
    'token',
  };

  Map<String, Object?> fields(Map<String, Object?> values) => <String, Object?>{
    for (final entry in values.entries)
      entry.key: _sensitiveNames.contains(entry.key.toLowerCase())
          ? '<redacted>'
          : entry.value is String
          ? text(entry.value! as String)
          : entry.value,
  };

  /// Redacts credential query assignments without decoding diagnostic text.
  ///
  /// Nested redirect URLs can encode `&state=` as `%26state%3D` or
  /// `%2526state%253D`. Preserve their delimiters and encoding depth instead
  /// of decoding a whole log line (which can reveal otherwise hidden values).
  String text(String value) {
    var result = value;
    final names = _sensitiveNames.map(RegExp.escape).join('|');
    for (var depth = 0; depth <= 4; depth++) {
      final percent = depth == 0 ? '' : '%${'25' * (depth - 1)}';
      final equals = depth == 0 ? '=' : '${percent}3d';
      final separators = depth == 0
          ? r'[\s&,;#]'
          : '(?:$percent(?:26|23)|[\\s&,;#])';
      final pattern = RegExp(
        '(${depth == 0 ? r'\b' : '(?:\\b|$percent(?:26|3f))'})((?:$names)$equals)(?:(?!$separators)[^\\s&,;#])+',
        caseSensitive: false,
      );
      var replacement = '<redacted>';
      for (var i = 0; i < depth; i++) {
        replacement = Uri.encodeComponent(replacement);
      }
      result = result.replaceAllMapped(
        pattern,
        (match) => '${match[1]}${match[2]}$replacement',
      );
    }
    return result;
  }

  Uri uri(Uri value) {
    if (!value.hasQuery) return value;
    return value.replace(
      queryParameters: <String, List<String>>{
        for (final entry in value.queryParametersAll.entries)
          entry.key: _sensitiveNames.contains(entry.key.toLowerCase())
              ? [for (final _ in entry.value) '<redacted>']
              : [for (final item in entry.value) text(item)],
      },
    );
  }
}
