// ignore_for_file: public_member_api_docs, sort_constructors_first
enum PremiumFrequency { Monthly, Quarterly, SemiAnnual, Annual }

class PolicyEntry {
  final String policyNumber;
  final String insured;
  final double sumAssured;
  final double premiumAmt;
  final PremiumFrequency premiumFrequency;
  final String productName;
  final String paymentMode;
  final DateTime issueDate;
  final DateTime insuredDateOfBirth;

  PolicyEntry({
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

  factory PolicyEntry.fromJson(Map<String, dynamic> json) {
    return PolicyEntry(
      policyNumber: json['policyNumber'] as String,
      insured: json['insured'] as String,
      sumAssured: (json['sumAssured'] as num).toDouble(),
      premiumAmt: (json['premiumAmt'] as num).toDouble(),
      premiumFrequency: PremiumFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == json['premiumFrequency'],
        orElse: () => PremiumFrequency.Annual,
      ),
      productName: json['productName'] as String,
      paymentMode: json['paymentMode'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      insuredDateOfBirth: DateTime.parse(json['insuredDateOfBirth'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyNumber': policyNumber,
      'insured': insured,
      'sumAssured': sumAssured,
      'premiumAmt': premiumAmt,
      'premiumFrequency': premiumFrequency.toString().split('.').last,
      'productName': productName,
      'paymentMode': paymentMode,
      'issueDate': issueDate.toIso8601String(),
      'insuredDateOfBirth': insuredDateOfBirth.toIso8601String(),
    };
  }

  PolicyEntry copyWith({
    String? policyNumber,
    String? insured,
    double? sumAssured,
    double? premiumAmt,
    PremiumFrequency? premiumFrequency,
    String? productName,
    String? paymentMode,
    DateTime? issueDate,
    DateTime? insuredDateOfBirth,
  }) {
    return PolicyEntry(
      policyNumber: policyNumber ?? this.policyNumber,
      insured: insured ?? this.insured,
      sumAssured: sumAssured ?? this.sumAssured,
      premiumAmt: premiumAmt ?? this.premiumAmt,
      premiumFrequency: premiumFrequency ?? this.premiumFrequency,
      productName: productName ?? this.productName,
      paymentMode: paymentMode ?? this.paymentMode,
      issueDate: issueDate ?? this.issueDate,
      insuredDateOfBirth: insuredDateOfBirth ?? this.insuredDateOfBirth,
    );
  }
}
