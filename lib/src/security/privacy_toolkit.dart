/// Privacy Toolkit: tagging + purge APIs (skeleton)
class PrivacyTag {
  final String key; // e.g. pii.email
  final String category; // pii | sensitive | telemetry
  final Map<String, dynamic>? meta;
  PrivacyTag(this.key, this.category, {this.meta});
}

class TaggedRecord<T> {
  final T data;
  final List<PrivacyTag> tags;
  TaggedRecord(this.data, this.tags);
}

class PrivacyToolkit {
  PrivacyToolkit._();
  static PrivacyToolkit? _instance;
  static PrivacyToolkit get instance => _instance ??= PrivacyToolkit._();

  final List<TaggedRecord> _records = [];

  void register<T>(T data, List<PrivacyTag> tags) {
    _records.add(TaggedRecord<T>(data, tags));
  }

  List<TaggedRecord> queryByTag(String tagKey) =>
      _records.where((r) => r.tags.any((t) => t.key == tagKey)).toList();

  int purgeByCategory(String category) {
    final before = _records.length;
    _records.removeWhere((r) => r.tags.any((t) => t.category == category));
    return before - _records.length;
  }

  Map<String, int> categoryStats() {
    final map = <String, int>{};
    for (final r in _records) {
      for (final t in r.tags) {
        map[t.category] = (map[t.category] ?? 0) + 1;
      }
    }
    return map;
  }
}
