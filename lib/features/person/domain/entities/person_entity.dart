class PersonEntity {
  final String agentName;
  final String agentId;
  final DateTime issuedDateFrom;
  final DateTime issuedDateTo;
  final double totalSumAssured;
  final double totalPremiumAssured;
  final int policyCount;

  const PersonEntity({
    required this.agentName,
    required this.agentId,
    required this.issuedDateFrom,
    required this.issuedDateTo,
    required this.totalSumAssured,
    required this.totalPremiumAssured,
    required this.policyCount,
  });

  PersonEntity copyWith({
    String? agentName,
    String? agentId,
    DateTime? issuedDateFrom,
    DateTime? issuedDateTo,
    double? totalSumAssured,
    double? totalPremiumAssured,
    int? policyCount,
  }) {
    return PersonEntity(
      agentName: agentName ?? this.agentName,
      agentId: agentId ?? this.agentId,
      issuedDateFrom: issuedDateFrom ?? this.issuedDateFrom,
      issuedDateTo: issuedDateTo ?? this.issuedDateTo,
      totalSumAssured: totalSumAssured ?? this.totalSumAssured,
      totalPremiumAssured: totalPremiumAssured ?? this.totalPremiumAssured,
      policyCount: policyCount ?? this.policyCount,
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
    );
  }
}
