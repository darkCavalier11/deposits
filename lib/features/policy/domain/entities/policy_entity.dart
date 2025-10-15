enum PremiumFrequency {
  monthly,
  quarterly,
  halfYearly,
  annual,
  single,
}

class PolicyEntity {
  final String policyNumber;
  final String insured;
  final double sumAssured;
  final double premiumAmt;
  final PremiumFrequency premiumFrequency;
  final String productName;
  final String paymentMode;
  final DateTime issueDate;
  final DateTime insuredDateOfBirth;

  const PolicyEntity({
    required this.policyNumber,
    required this.insured,
    required this.sumAssured,
    required this.premiumAmt,
    required this.premiumFrequency,
    required this.productName,
    required this.paymentMode,
    required this.issueDate,
    required this.insuredDateOfBirth,
  });

  Map<String, dynamic> toMap() {
    return {
      'policyNumber': policyNumber,
      'insured': insured,
      'sumAssured': sumAssured,
      'premiumAmt': premiumAmt,
      'premiumFrequency': premiumFrequency.toString(),
      'productName': productName,
      'paymentMode': paymentMode,
      'issueDate': issueDate.toIso8601String(),
      'insuredDateOfBirth': insuredDateOfBirth.toIso8601String(),
    };
  }

  factory PolicyEntity.fromMap(Map<String, dynamic> map) {
    return PolicyEntity(
      policyNumber: map['policyNumber'] as String,
      insured: map['insured'] as String,
      sumAssured: (map['sumAssured'] as num).toDouble(),
      premiumAmt: (map['premiumAmt'] as num).toDouble(),
      premiumFrequency: PremiumFrequency.values.firstWhere(
        (e) => e.toString() == map['premiumFrequency'],
        orElse: () => PremiumFrequency.annual,
      ),
      productName: map['productName'] as String,
      paymentMode: map['paymentMode'] as String,
      issueDate: DateTime.parse(map['issueDate'] as String),
      insuredDateOfBirth: DateTime.parse(map['insuredDateOfBirth'] as String),
    );
  }
}
