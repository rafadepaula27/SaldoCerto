import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatelessWidget {
  final List<FinanceTransaction> items;
  final DateTime month;
  const ReportsScreen({super.key, required this.items, required this.month});

  @override
  Widget build(BuildContext context) {
    final expenses = items.where((e) => !e.isIncome).toList();
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount.abs();
    }
    final entries = byCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s,e)=>s+e.value);
    final money = NumberFormat.currency(locale:'pt_BR', symbol:'R\$');
    return Scaffold(
      appBar: AppBar(title: Text('Relatório • ${DateFormat('MMMM yyyy','pt_BR').format(month)}')),
      body: entries.isEmpty ? const Center(child: Text('Sem despesas neste mês.')) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children:[
            Text('Despesas por categoria', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height:20),
            SizedBox(height:220, child: PieChart(PieChartData(centerSpaceRadius:48, sectionsSpace:3, sections: [
              for (var i=0;i<entries.length;i++) PieChartSectionData(value:entries[i].value, title:'${(entries[i].value/total*100).round()}%', radius:70)
            ]))),
          ]))),
          const SizedBox(height:16),
          ...entries.map((e)=>Card(margin:const EdgeInsets.only(bottom:8), child:ListTile(
            leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
            title: Text(e.key),
            subtitle: LinearProgressIndicator(value: total == 0 ? 0 : e.value/total),
            trailing: Text(money.format(e.value), style: const TextStyle(fontWeight:FontWeight.bold)),
          ))),
        ],
      ),
    );
  }
}
