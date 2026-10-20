import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'add_transaction_screen.dart';
import 'pending_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  DateTime month=DateTime(2026,10,1); List<FinanceTransaction> items=[]; bool loading=true;
  final money=NumberFormat.currency(locale:'pt_BR',symbol:'R\$'); final monthFmt=DateFormat('MMMM yyyy','pt_BR');
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {setState(()=>loading=true);items=await DatabaseService.instance.listMonth(month);if(mounted)setState(()=>loading=false);}
  double get income=>items.where((e)=>e.isIncome).fold(0,(s,e)=>s+e.amount);
  double get paidExpenses=>items.where((e)=>!e.isIncome&&e.paid).fold(0,(s,e)=>s+e.amount.abs());
  double get pending=>items.where((e)=>!e.isIncome&&!e.paid).fold(0,(s,e)=>s+e.amount.abs());
  double get balance=>income-paidExpenses;
  double get projectedBalance=>income-paidExpenses-pending;
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Row(children:[CircleAvatar(radius:18,backgroundColor:Color(0xFFD8EEE9),child:Icon(Icons.account_balance_wallet_rounded,color:Color(0xFF006B5F),size:20)),SizedBox(width:10),Text('SaldoCerto',style:TextStyle(fontWeight:FontWeight.w800))]),actions:[IconButton(tooltip:'Configurações',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())).then((_)=>_load()),icon:const Icon(Icons.settings_outlined)),IconButton(tooltip:'Atualizar',onPressed:_load,icon:const Icon(Icons.refresh))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:_add,icon:const Icon(Icons.add_rounded),label:const Text('Novo lançamento',style:TextStyle(fontWeight:FontWeight.w700))),
    bottomNavigationBar:NavigationBar(selectedIndex:0,onDestinationSelected:(i){if(i==1)Navigator.push(context,MaterialPageRoute(builder:(_)=>const PendingScreen())).then((_)=>_load());if(i==2)Navigator.push(context,MaterialPageRoute(builder:(_)=>ReportsScreen(items:items,month:month)));},destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Início'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'Contas'),NavigationDestination(icon:Icon(Icons.pie_chart_outline),label:'Relatórios')]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[IconButton(onPressed:(){month=DateTime(month.year,month.month-1);_load();},icon:const Icon(Icons.chevron_left)),Text(toBeginningOfSentenceCase(monthFmt.format(month))??'',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w700)),IconButton(onPressed:(){month=DateTime(month.year,month.month+1);_load();},icon:const Icon(Icons.chevron_right))]),
      const SizedBox(height:10),
      Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Saldo realizado',style:TextStyle(color:Color(0xFF60706C),fontWeight:FontWeight.w600)),const SizedBox(height:4),Text(money.format(balance),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:18),Row(children:[Expanded(child:_metric('Receitas',income,Icons.trending_up)),Expanded(child:_metric('Despesas pagas',paidExpenses,Icons.trending_down))]),const SizedBox(height:12),_metric('Pendente',pending,Icons.schedule),const Divider(height:28),_metric('Saldo projetado no fim do mês',projectedBalance,Icons.insights)]))),
      const SizedBox(height:12),
      Row(children:[Expanded(child:_quick('Contas pendentes',Icons.receipt_long,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const PendingScreen())).then((_)=>_load()))),const SizedBox(width:10),Expanded(child:_quick('Ver relatório',Icons.pie_chart,()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReportsScreen(items:items,month:month)))))]),
      const SizedBox(height:18),Text('Lançamentos',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:8),...[1,2].map(_fortnight),
    ])));
  Future<void> _add() async {final ok=await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(month:month)));if(ok==true)_load();}
  Widget _quick(String label,IconData icon,VoidCallback onTap)=>Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:onTap,child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Icon(icon),const SizedBox(width:10),Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w600)))]))));
  Widget _metric(String label,double value,IconData icon)=>Row(children:[Icon(icon,size:20),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:Theme.of(context).textTheme.bodySmall),Text(money.format(value),style:const TextStyle(fontWeight:FontWeight.w700))]))]);
  Widget _fortnight(int q){final list=items.where((e)=>e.fortnight==q).toList();return Card(margin:const EdgeInsets.only(bottom:12),child:ExpansionTile(initiallyExpanded:true,title:Text('$qª quinzena',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${list.length} lançamentos'),children:list.map(_tile).toList()));}
  Widget _tile(FinanceTransaction e)=>Dismissible(key:ValueKey(e.id),direction:DismissDirection.endToStart,background:Container(alignment:Alignment.centerRight,padding:const EdgeInsets.only(right:20),child:const Icon(Icons.delete)),confirmDismiss:(_)=>showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Excluir lançamento?'),content:Text(e.description),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Excluir'))])),onDismissed:(_)async{await DatabaseService.instance.delete(e.id!);_load();},child:ListTile(onTap:()async{final ok=await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(month:month,item:e)));if(ok==true)_load();},leading:CircleAvatar(child:Icon(e.isIncome?Icons.add:Icons.remove)),title:Text(e.description),subtitle:Text('${e.category} • ${e.paid?'Pago':'Pendente'}${e.recurring?' • Mensal':''}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money.format(e.amount),style:const TextStyle(fontWeight:FontWeight.bold)),if(!e.isIncome)SizedBox(height:28,child:Switch(value:e.paid,onChanged:(v)async{await DatabaseService.instance.setPaid(e,v);_load();}))])));
}
