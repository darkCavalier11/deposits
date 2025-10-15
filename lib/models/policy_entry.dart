enum PremiumFrequency {
  monthly,
  quarterly,
  halfYearly,
  annual,
  single,
}

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

  const PolicyEntry({
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
}
