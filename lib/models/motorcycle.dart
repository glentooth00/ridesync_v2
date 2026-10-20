class Motorcycle {
  const Motorcycle({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.odometerKm,
    this.engineCc = '',
    this.plateNumber = '',
  });

  final int id;
  final String name;
  final String make;
  final String model;
  final int year;
  final double odometerKm;
  final String engineCc;
  final String plateNumber;

  String get displayName => '$make $model'.trim().isEmpty ? name : '$make $model';

  Motorcycle copyWith({
    String? name,
    String? make,
    String? model,
    int? year,
    double? odometerKm,
    String? engineCc,
    String? plateNumber,
  }) {
    return Motorcycle(
      id: id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      odometerKm: odometerKm ?? this.odometerKm,
      engineCc: engineCc ?? this.engineCc,
      plateNumber: plateNumber ?? this.plateNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'make': make,
        'model': model,
        'year': year,
        'odometerKm': odometerKm,
        'engineCc': engineCc,
        'plateNumber': plateNumber,
      };

  factory Motorcycle.fromJson(Map<String, dynamic> json) => Motorcycle(
        id: (json['id'] as num?)?.toInt() ?? DateTime.now().microsecondsSinceEpoch,
        name: json['name'] as String? ?? 'My Motorcycle',
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
        odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0,
        engineCc: json['engineCc'] as String? ?? '',
        plateNumber: json['plateNumber'] as String? ?? '',
      );
}
