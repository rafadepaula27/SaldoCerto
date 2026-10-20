import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';

class DatabaseService {
  DatabaseService._(); static final instance=DatabaseService._(); Database? _db;
  Future<String> get dbPath async=>join(await getDatabasesPath(),'controle_financeiro.db');
  Future<Database> get database async {
    if(_db!=null)return _db!;
    _db=await openDatabase(await dbPath,version:2,onCreate:(db,v)async{await _create(db);await _seed(db);},onUpgrade:(db,old,v)async{
      if(old<2){await db.execute('ALTER TABLE transactions ADD COLUMN recurring INTEGER NOT NULL DEFAULT 0');await db.execute('ALTER TABLE transactions ADD COLUMN recurring_day INTEGER');}
    }); return _db!;
  }
  Future<void> _create(Database db)=>db.execute('''CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT,description TEXT NOT NULL,category TEXT NOT NULL,amount REAL NOT NULL,date TEXT NOT NULL,paid INTEGER NOT NULL,fortnight INTEGER NOT NULL,recurring INTEGER NOT NULL DEFAULT 0,recurring_day INTEGER)''');
  Future<void> _seed(Database db) async { final rows=<FinanceTransaction>[
    FinanceTransaction(description:'SALÁRIO DIA 10',category:'Receita',amount:10000,date:DateTime(2026,10,10),paid:true,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'PARCELA CASA',category:'Habitação',amount:-1918.55,date:DateTime(2026,10,10),paid:true,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'ESCOLA MATHEUS',category:'Educação',amount:-1533,date:DateTime(2026,10,10),paid:true,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'CONVÊNIO MÉDICO',category:'Saúde',amount:-1675.74,date:DateTime(2026,10,10),paid:true,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'AGUA CASA',category:'Habitação',amount:-119.84,date:DateTime(2026,10,10),paid:false,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'LUZ CASA',category:'Habitação',amount:-200.04,date:DateTime(2026,10,10),paid:false,fortnight:1,recurring:true,recurringDay:10),
    FinanceTransaction(description:'VALE DIA 20',category:'Receita',amount:10000,date:DateTime(2026,10,20),paid:true,fortnight:2,recurring:true,recurringDay:20),
    FinanceTransaction(description:'PARCELA APTO',category:'Habitação',amount:-2850,date:DateTime(2026,10,20),paid:true,fortnight:2,recurring:true,recurringDay:20),
    FinanceTransaction(description:'CONDOMÍNIO',category:'Habitação',amount:-885,date:DateTime(2026,10,20),paid:true,fortnight:2,recurring:true,recurringDay:20),
    FinanceTransaction(description:'FACULDADE',category:'Educação',amount:-581.85,date:DateTime(2026,10,20),paid:true,fortnight:2,recurring:true,recurringDay:20),
    FinanceTransaction(description:'MERCADO',category:'Alimentação',amount:-1200,date:DateTime(2026,10,25),paid:false,fortnight:2),
  ]; for(final x in rows){final m=x.toMap()..remove('id');await db.insert('transactions',m);} }
  Future<List<FinanceTransaction>> listMonth(DateTime m) async {await ensureRecurringForMonth(m);final db=await database;final s=DateTime(m.year,m.month,1),e=DateTime(m.year,m.month+1,1);final r=await db.query('transactions',where:'date >= ? AND date < ?',whereArgs:[s.toIso8601String(),e.toIso8601String()],orderBy:'date ASC,id ASC');return r.map(FinanceTransaction.fromMap).toList();}
  Future<List<FinanceTransaction>> listPending() async {final db=await database;final r=await db.query('transactions',where:'amount < 0 AND paid=0',orderBy:'date ASC,id ASC');return r.map(FinanceTransaction.fromMap).toList();}
  Future<int> insert(FinanceTransaction x) async {final db=await database;final m=x.toMap()..remove('id');return db.insert('transactions',m);}
  Future<void> update(FinanceTransaction x) async {final db=await database;final m=x.toMap()..remove('id');await db.update('transactions',m,where:'id=?',whereArgs:[x.id]);}
  Future<void> setPaid(FinanceTransaction x,bool v)=>update(x.copyWith(paid:v));
  Future<void> delete(int id) async {(await database).delete('transactions',where:'id=?',whereArgs:[id]);}
  Future<void> ensureRecurringForMonth(DateTime month) async {final db=await database;final templates=await db.query('transactions',where:'recurring=1',orderBy:'date ASC');final seen=<String>{};for(final row in templates){final x=FinanceTransaction.fromMap(row);final key='${x.description}|${x.amount}|${x.recurringDay}';if(seen.contains(key))continue;seen.add(key);final day=x.recurringDay??x.date.day;final last=DateTime(month.year,month.month+1,0).day;final target=DateTime(month.year,month.month,day>last?last:day);final exists=Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions WHERE description=? AND amount=? AND date>=? AND date<?',[x.description,x.amount,DateTime(month.year,month.month,1).toIso8601String(),DateTime(month.year,month.month+1,1).toIso8601String()]))??0;if(exists==0){final m=x.copyWith(id:null,date:target,paid:false,fortnight:target.day<=15?1:2).toMap()..remove('id');await db.insert('transactions',m);}}}
  Future<String> backupTo(String targetPath) async {final db=await database;await db.close();_db=null;await File(await dbPath).copy(targetPath);await database;return targetPath;}
  Future<void> restoreFrom(String sourcePath) async {if(_db!=null){await _db!.close();_db=null;}final target=await dbPath;await File(sourcePath).copy(target);await database;}
}
