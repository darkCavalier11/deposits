// ignore_for_file: public_member_api_docs, sort_constructors_first
enum PremiumFrequency { monthly, quarterly, halfYearly, annual, single }

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
  final DateTime? paidUntil;

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
    this.paidUntil,
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
      'paidUntil': paidUntil?.toIso8601String(),
    };
  }

  factory PolicyEntity.fromMap(Map<String, dynamic> map) {
    return PolicyEntity(
      policyNumber: map['policyNumber'] as String,
      insured: map['insured'] as String,
      sumAssured: map['sumAssured'] as double,
      premiumAmt: map['premiumAmt'] as double,
      premiumFrequency: PremiumFrequency.values.firstWhere(
        (e) => e.toString() == map['premiumFrequency'],
        orElse: () => PremiumFrequency.monthly,
      ),
      productName: map['productName'] as String,
      paymentMode: map['paymentMode'] as String,
      issueDate: DateTime.parse(map['issueDate'] as String),
      insuredDateOfBirth: DateTime.parse(map['insuredDateOfBirth'] as String),
      paidUntil: map['paidUntil'] != null
          ? DateTime.parse(map['paidUntil'] as String)
          : null,
    );
  }

  PolicyEntity copyWith({
    String? policyNumber,
    String? insured,
    double? sumAssured,
    double? premiumAmt,
    PremiumFrequency? premiumFrequency,
    String? productName,
    String? paymentMode,
    DateTime? issueDate,
    DateTime? insuredDateOfBirth,
    DateTime? paidUntil,
  }) {
    return PolicyEntity(
      policyNumber: policyNumber ?? this.policyNumber,
      insured: insured ?? this.insured,
      sumAssured: sumAssured ?? this.sumAssured,
      premiumAmt: premiumAmt ?? this.premiumAmt,
      premiumFrequency: premiumFrequency ?? this.premiumFrequency,
      productName: productName ?? this.productName,
      paymentMode: paymentMode ?? this.paymentMode,
      issueDate: issueDate ?? this.issueDate,
      insuredDateOfBirth: insuredDateOfBirth ?? this.insuredDateOfBirth,
      paidUntil: paidUntil ?? this.paidUntil,
    );
  }
}
