class MoneySumModel {
  MoneySumModel({required this.date, required this.sum});

  /// JSON → モデル
  factory MoneySumModel.fromJson(Map<String, dynamic> json) {
    return MoneySumModel(date: json['date'] as String, sum: json['sum'] as int);
  }

  final String date;
  final int sum;

  /// モデル → JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'date': date, 'sum': sum};
  }
}
