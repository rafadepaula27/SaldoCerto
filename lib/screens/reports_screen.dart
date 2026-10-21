import 'dart:io';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class ReportsScreen extends StatefulWidget {
  final List<FinanceTransaction> items;
  final DateTime month;
  const ReportsScreen({super.key, required this.items, required this.month});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool generating = false;
  List<FinanceTransaction> get items => widget.items;
  double get income => items.where((e)=>e.isIncome).fold(0,(s,e)=>s+e.amount);
  double get paidExpenses => items.where((e)=>!e.isIncome&&e.paid).fold(0,(s,e)=>s+e.amount.abs());
  double get pending => items.where((e)=>!e.isIncome&&!e.paid).fold(0,(s,e)=>s+e.amount.abs());
  double get totalExpenses => paidExpenses + pending;
  double get projected => income - totalExpenses;
  Map<String,double> get byCategory {
    final m=<String,double>{};
    for(final e in items.where((e)=>!e.isIncome)){m[e.category]=(m[e.category]??0)+e.amount.abs();}
    return m;
  }

  @override Widget build(BuildContext context) {
    final entries=byCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final total=entries.fold<double>(0,(s,e)=>s+e.value);
    return Scaffold(
      appBar: AppBar(title: Text('Relatórios • ${DateFormat('MMMM yyyy','pt_BR').format(widget.month)}')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16,8,16,32), children:[
        Row(children:[
          Expanded(child:_summary('Receitas',income,Icons.trending_up)), const SizedBox(width:8),
          Expanded(child:_summary('Despesas',totalExpenses,Icons.trending_down)),
        ]),
        const SizedBox(height:8),
        Row(children:[
          Expanded(child:_summary('Pendente',pending,Icons.schedule)), const SizedBox(width:8),
          Expanded(child:_summary('Saldo projetado',projected,Icons.account_balance_wallet_outlined)),
        ]),
        const SizedBox(height:16),
        Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Visão geral',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),
          const SizedBox(height:18),
          SizedBox(height:190,child:BarChart(BarChartData(
            maxY: math.max(income,totalExpenses)==0?1:math.max(income,totalExpenses)*1.2,
            gridData:const FlGridData(show:false), borderData:FlBorderData(show:false),
            titlesData:FlTitlesData(leftTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),rightTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),topTitles:const AxisTitles(sideTitles:SideTitles(showTitles:false)),bottomTitles:AxisTitles(sideTitles:SideTitles(showTitles:true,getTitlesWidget:(v,m)=>Padding(padding:const EdgeInsets.only(top:8),child:Text(v==0?'Receitas':'Despesas'))))),
            barGroups:[BarChartGroupData(x:0,barRods:[BarChartRodData(toY:income,width:38,borderRadius:BorderRadius.circular(8))]),BarChartGroupData(x:1,barRods:[BarChartRodData(toY:totalExpenses,width:38,borderRadius:BorderRadius.circular(8))])]
          ))),
        ]))),
        const SizedBox(height:16),
        Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
          Align(alignment:Alignment.centerLeft,child:Text('Despesas por categoria',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
          const SizedBox(height:18),
          if(entries.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Text('Sem despesas neste mês.')) else SizedBox(height:220,child:PieChart(PieChartData(centerSpaceRadius:48,sectionsSpace:3,sections:[for(final e in entries)PieChartSectionData(value:e.value,title:'${(e.value/total*100).round()}%',radius:70)]))),
        ]))),
        const SizedBox(height:12),
        ...entries.map((e)=>Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:const CircleAvatar(child:Icon(Icons.category_outlined)),title:Text(e.key),subtitle:LinearProgressIndicator(value:total==0?0:e.value/total),trailing:Text(money.format(e.value),style:const TextStyle(fontWeight:FontWeight.bold))))),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:generating?null:_sharePdf,icon:generating?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.picture_as_pdf_outlined),label:Text(generating?'Gerando PDF...':'Gerar e compartilhar PDF'),style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:16))),
        const SizedBox(height:8),
        const Text('O PDF é criado no aparelho e pode ser compartilhado pelo menu nativo do Android.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)),
      ]),
    );
  }

  Widget _summary(String label,double value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:20),const SizedBox(height:8),Text(label,style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:2),FittedBox(child:Text(money.format(value),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:17)))])));

  Future<void> _sharePdf() async {
    setState(()=>generating=true);
    try {
      final pdf=pw.Document();
      final monthTitle=DateFormat('MMMM yyyy','pt_BR').format(widget.month);
      final entries=byCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
      final ordered=[...items]..sort((a,b)=>a.date.compareTo(b.date));
      pdf.addPage(pw.MultiPage(
        pageFormat:PdfPageFormat.a4, margin:const pw.EdgeInsets.all(32),
        header:(c)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('SaldoCerto',style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold,color:PdfColors.teal700)),pw.Text('Relatório financeiro')]),
        footer:(c)=>pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('Página ${c.pageNumber} de ${c.pagesCount}',style:const pw.TextStyle(fontSize:9,color:PdfColors.grey700))),
        build:(c)=>[
          pw.SizedBox(height:12),pw.Text(toBeginningOfSentenceCase(monthTitle)??monthTitle,style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:16),
          pw.Table(columnWidths:{0:const pw.FlexColumnWidth(),1:const pw.FlexColumnWidth()},children:[
            _pdfMetric('Receitas',income),_pdfMetric('Despesas',totalExpenses),_pdfMetric('Pendente',pending),_pdfMetric('Saldo projetado',projected),
          ]),
          pw.SizedBox(height:22),pw.Text('Despesas por categoria',style:pw.TextStyle(fontSize:15,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:8),
          if(entries.isEmpty) pw.Text('Sem despesas no período.') else pw.TableHelper.fromTextArray(headers:['Categoria','Valor','%'],data:[for(final e in entries)[e.key,money.format(e.value),totalExpenses==0?'0%':'${(e.value/totalExpenses*100).toStringAsFixed(1)}%']],headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold),headerDecoration:const pw.BoxDecoration(color:PdfColors.grey300),cellPadding:const pw.EdgeInsets.all(6)),
          pw.SizedBox(height:22),pw.Text('Movimentações',style:pw.TextStyle(fontSize:15,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:8),
          pw.TableHelper.fromTextArray(headers:['Data','Descrição','Categoria','Status','Valor'],data:[for(final e in ordered)[DateFormat('dd/MM/yyyy').format(e.date),e.description,e.category,e.isIncome?'Receita':(e.paid?'Pago':'Pendente'),money.format(e.amount)]],headerStyle:pw.TextStyle(fontWeight:pw.FontWeight.bold),headerDecoration:const pw.BoxDecoration(color:PdfColors.grey300),cellStyle:const pw.TextStyle(fontSize:8),cellPadding:const pw.EdgeInsets.all(5)),
          pw.SizedBox(height:16),pw.Text('Gerado pelo SaldoCerto em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}.',style:const pw.TextStyle(fontSize:8,color:PdfColors.grey700)),
        ],
      ));
      final dir=await getTemporaryDirectory();
      final file=File('${dir.path}/SaldoCerto_${DateFormat('yyyy_MM').format(widget.month)}.pdf');
      await file.writeAsBytes(await pdf.save(),flush:true);
      await Share.shareXFiles([XFile(file.path,mimeType:'application/pdf')],subject:'Relatório SaldoCerto - $monthTitle',text:'Relatório financeiro do SaldoCerto - $monthTitle');
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Não foi possível gerar o PDF: $e')));
    } finally {if(mounted)setState(()=>generating=false);}
  }

  pw.TableRow _pdfMetric(String label,double value)=>pw.TableRow(children:[pw.Padding(padding:const pw.EdgeInsets.all(8),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(label,style:const pw.TextStyle(fontSize:9,color:PdfColors.grey700)),pw.SizedBox(height:3),pw.Text(money.format(value),style:pw.TextStyle(fontSize:14,fontWeight:pw.FontWeight.bold))])),pw.SizedBox()]);
}
