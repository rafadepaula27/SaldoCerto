import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class PendingScreen extends StatefulWidget { const PendingScreen({super.key}); @override State<PendingScreen> createState()=>_PendingScreenState(); }
class _PendingScreenState extends State<PendingScreen> {
  List<FinanceTransaction> items=[]; bool loading=true; final money=NumberFormat.currency(locale:'pt_BR',symbol:'R\$');
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { items=await DatabaseService.instance.listPending(); if(mounted)setState(()=>loading=false); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Contas pendentes')),body:loading?const Center(child:CircularProgressIndicator()):items.isEmpty?const Center(child:Text('Tudo em dia!')):ListView.separated(padding:const EdgeInsets.all(16),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final e=items[i];return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.schedule)),title:Text(e.description),subtitle:Text('${e.category} • ${DateFormat('dd/MM/yyyy').format(e.date)}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money.format(e.amount.abs()),style:const TextStyle(fontWeight:FontWeight.bold)),TextButton(onPressed:()async{await DatabaseService.instance.setPaid(e,true);await _load();},child:const Text('Marcar pago'))]))); }));
}
