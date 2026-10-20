import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/transaction.dart';
class NotificationService {
  static final instance=NotificationService._(); NotificationService._(); final _p=FlutterLocalNotificationsPlugin();
  Future<void> init() async {tz.initializeTimeZones();const a=AndroidInitializationSettings('@mipmap/ic_launcher');await _p.initialize(const InitializationSettings(android:a));await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();}
  Future<void> schedule(FinanceTransaction x) async {if(x.id==null||x.isIncome||x.paid)return;final when=DateTime(x.date.year,x.date.month,x.date.day).subtract(const Duration(days:1)).add(const Duration(hours:9));if(when.isBefore(DateTime.now()))return;await _p.zonedSchedule(x.id!,'Conta vence amanhã',x.description,tz.TZDateTime.from(when,tz.local),const NotificationDetails(android:AndroidNotificationDetails('vencimentos','Vencimentos',channelDescription:'Lembretes de contas a vencer',importance:Importance.high,priority:Priority.high)),androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle,uiLocalNotificationDateInterpretation:UILocalNotificationDateInterpretation.absoluteTime);}
  Future<void> cancel(int id)=>_p.cancel(id);
}
