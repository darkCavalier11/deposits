class PersonEntity {
  final String agentName;
  final String agentId;
  final DateTime issuedDateFrom;
  final DateTime issuedDateTo;
  final double totalSumAssured;
  final double totalPremiumAssured;
  final int policyCount;
  final Map<String, double> monthlyCollections; // Format: {'YYYY-MM': amount}

  const PersonEntity({
    required this.agentName,
    required this.agentId,
    required this.issuedDateFrom,
    required this.issuedDateTo,
    required this.totalSumAssured,
    required this.totalPremiumAssured,
    required this.policyCount,
    Map<String, double>? monthlyCollections,
  }) : monthlyCollections = monthlyCollections ?? const {};

  PersonEntity copyWith({
    String? agentName,
    String? agentId,
    DateTime? issuedDateFrom,
    DateTime? issuedDateTo,
    double? totalSumAssured,
    double? totalPremiumAssured,
    int? policyCount,
    Map<String, double>? monthlyCollections,
  }) {
    return PersonEntity(
      agentName: agentName ?? this.agentName,
      agentId: agentId ?? this.agentId,
      issuedDateFrom: issuedDateFrom ?? this.issuedDateFrom,
      issuedDateTo: issuedDateTo ?? this.issuedDateTo,
      totalSumAssured: totalSumAssured ?? this.totalSumAssured,
      totalPremiumAssured: totalPremiumAssured ?? this.totalPremiumAssured,
policyCount: policyCount ?? this.policyCount,
      monthlyCollections: monthlyCollections ?? this.monthlyCollections,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agentName': agentName,
      'agentId': agentId,
      'issuedDateFrom': issuedDateFrom.toIso8601String(),
      'issuedDateTo': issuedDateTo.toIso8601String(),
'totalSumAssured': totalSumAssured,
      'totalPremiumAssured': totalPremiumAssured,
      'policyCount': policyCount,
      'monthlyCollections': monthlyCollections.map(
        (key, value) => MapEntry(key, value),
      ),
    };
  }

  factory PersonEntity.fromMap(Map<String, dynamic> map) {
    return PersonEntity(
      agentName: map['agentName'] as String,
      agentId: map['agentId'] as String,
      issuedDateFrom: DateTime.parse(map['issuedDateFrom'] as String),
      issuedDateTo: DateTime.parse(map['issuedDateTo'] as String),
totalSumAssured: (map['totalSumAssured'] as num).toDouble(),
      totalPremiumAssured: (map['totalPremiumAssured'] as num).toDouble(),
      policyCount: map['policyCount'] as int,
      monthlyCollections: (map['monthlyCollections'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
    );
  }
}
