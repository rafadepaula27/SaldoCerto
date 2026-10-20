class FinanceTransaction {
  final int? id;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final bool paid;
  final int fortnight;
  final bool recurring;
  final int? recurringDay;

  const FinanceTransaction({this.id, required this.description, required this.category, required this.amount, required this.date, required this.paid, required this.fortnight, this.recurring=false, this.recurringDay});
  bool get isIncome => amount >= 0;

  FinanceTransaction copyWith({int? id,String? description,String? category,double? amount,DateTime? date,bool? paid,int? fortnight,bool? recurring,int? recurringDay}) => FinanceTransaction(
    id:id??this.id, description:description??this.description, category:category??this.category, amount:amount??this.amount,
    date:date??this.date, paid:paid??this.paid, fortnight:fortnight??this.fortnight, recurring:recurring??this.recurring, recurringDay:recurringDay??this.recurringDay);

  Map<String,Object?> toMap()=>{'id':id,'description':description,'category':category,'amount':amount,'date':date.toIso8601String(),'paid':paid?1:0,'fortnight':fortnight,'recurring':recurring?1:0,'recurring_day':recurringDay};
  factory FinanceTransaction.fromMap(Map<String,Object?> m)=>FinanceTransaction(id:m['id'] as int?,description:m['description'] as String,category:m['category'] as String,amount:(m['amount'] as num).toDouble(),date:DateTime.parse(m['date'] as String),paid:(m['paid'] as int)==1,fortnight:m['fortnight'] as int,recurring:((m['recurring'] as int?)??0)==1,recurringDay:m['recurring_day'] as int?);
}
