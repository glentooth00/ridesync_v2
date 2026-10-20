
class RideRecord {
  const RideRecord({
    required this.id,
    required this.motorcycleId,
    required this.date,
    required this.distanceKm,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    this.note = '',
  });

  final int id;
  final int motorcycleId;
  final DateTime date;
  final double distanceKm;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'motorcycleId': motorcycleId,
        'date': date.toIso8601String(),
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'note': note,
      };

  factory RideRecord.fromJson(Map<String, dynamic> json) {
    return RideRecord(
      id: (json['id'] as num?)?.toInt() ??
          DateTime.now().microsecondsSinceEpoch,
      motorcycleId: (json['motorcycleId'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.now(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes:
          (json['durationMinutes'] as num?)?.toInt() ?? 0,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? ''),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? ''),
      note: json['note'] as String? ?? '',
    );
  }
}
