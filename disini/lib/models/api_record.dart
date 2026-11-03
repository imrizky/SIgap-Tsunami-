class ApiRecord {
  const ApiRecord(this.json);
  final Map<String, dynamic> json;

  String get id => json['id']?.toString() ?? '';

  String get title =>
      (json['title'] ??
              json['name'] ??
              json['report_code'] ??
              json['incident_type'] ??
              json['status'] ??
              'Informasi')
          .toString();

  String get description =>
      (json['description'] ??
              json['message'] ??
              json['address'] ??
              json['location'] ??
              '')
          .toString();

  String get address => (json['address'] ?? json['location'] ?? '').toString();

  String get status => (json['status'] ?? '').toString();

  String get type => (json['type'] ?? json['incident_type'] ?? '').toString();

  String get severity => (json['severity'] ?? '').toString();

  String get reportCode => (json['report_code'] ?? '').toString();

  double? get latitude => double.tryParse(json['latitude']?.toString() ?? '');

  double? get longitude => double.tryParse(json['longitude']?.toString() ?? '');

  int? get capacity => int.tryParse(json['capacity']?.toString() ?? '');

  String get affectedArea => (json['affected_area'] ?? '').toString();

  String get source => (json['source'] ?? '').toString();

  String get userName {
    if (json['user'] is Map) {
      return json['user']['name']?.toString() ?? 'Warga';
    }
    return '';
  }

  String get createdAt => (json['created_at'] ?? '').toString();

  String get subtitle => [
    if (severity.isNotEmpty) severity.toUpperCase(),
    if (type.isNotEmpty) type.replaceAll('_', ' '),
    if (status.isNotEmpty) status.toUpperCase(),
    if (affectedArea.isNotEmpty) affectedArea,
  ].join(' • ');

  factory ApiRecord.fromJson(dynamic value) =>
      ApiRecord(value is Map<String, dynamic> ? value : <String, dynamic>{});
}

List<ApiRecord> recordsFrom(dynamic value) {
  dynamic list = value;
  if (value is Map) {
    list = value['data'] ?? value['results'] ?? value;
    if (list is Map) list = list['data'] ?? list['items'] ?? const [];
  }
  if (list is! List) return const [];
  return list.map(ApiRecord.fromJson).toList();
}
