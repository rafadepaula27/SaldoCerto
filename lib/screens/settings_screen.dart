import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/security_service.dart';
class SettingsScreen extends StatefulWidget{const SettingsScreen({super.key});@override State<SettingsScreen> createState()=>_S();}
class _S extends State<SettingsScreen>{final sec=SecurityService();bool bio=false,canBio=false,hasPin=false;@override void initState(){super.initState();_load();}Future<void>_load()async{bio=await sec.biometricEnabled();canBio=await sec.canBiometric();hasPin=await sec.hasPin();if(mounted)setState((){});}
@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Configurações')),body:ListView(padding:const EdgeInsets.all(16),children:[Text('Segurança',style:Theme.of(c).textTheme.titleMedium),ListTile(leading:const Icon(Icons.pin),title:Text(hasPin?'Alterar PIN':'Criar PIN'),subtitle:const Text('Protege a abertura do aplicativo'),onTap:_setPin),SwitchListTile(secondary:const Icon(Icons.fingerprint),title:const Text('Biometria'),subtitle:Text(canBio?'Desbloquear com biometria':'Não disponível neste aparelho'),value:bio,onChanged:canBio&&hasPin?(v)async{await sec.setBiometric(v);setState(()=>bio=v);}:null),const Divider(),Text('Backup',style:Theme.of(c).textTheme.titleMedium),ListTile(leading:const Icon(Icons.backup),title:const Text('Criar backup'),subtitle:const Text('Compartilhe uma cópia do banco de dados'),onTap:_backup),ListTile(leading:const Icon(Icons.restore),title:const Text('Restaurar backup'),subtitle:const Text('Substitui os dados atuais por um backup'),onTap:_restore)]));
Future<void>_setPin()async{final a=TextEditingController(),b=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Definir PIN'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:a,obscureText:true,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'PIN (4 a 6 números)')),TextField(controller:b,obscureText:true,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'Confirmar PIN'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Salvar'))]));if(ok==true&&RegExp(r'^\d{4,6}$').hasMatch(a.text)&&a.text==b.text){await sec.setPin(a.text);_load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('PIN atualizado.')));}else if(ok==true&&mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('PIN inválido ou confirmação diferente.')));}}
Future<void> _backup() async {
  try {
    final dir = await getTemporaryDirectory();

    final target = p.join(
      dir.path,
      'SaldoCerto_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    await DatabaseService.instance.backupTo(target);

    await Share.shareXFiles(
      [XFile(target)],
      text: 'Backup do SaldoCerto',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar backup: $e')),
      );
    }
  }
}
Future<void>_restore()async{final r=await FilePicker.platform.pickFiles(type:FileType.any);final path=r?.files.single.path;if(path==null)return;final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Restaurar backup?'),content:const Text('Os dados atuais serão substituídos.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Restaurar'))]));if(ok==true){await DatabaseService.instance.restoreFrom(path);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Backup restaurado. Reinicie a tela inicial para atualizar.')));}}
}
