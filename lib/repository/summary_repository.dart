import 'package:mpesa_ledger_flutter/database/databaseProvider.dart';
import 'package:mpesa_ledger_flutter/models/summary_model.dart';
import 'package:mpesa_ledger_flutter/repository/base_repository.dart';
import 'package:mpesa_ledger_flutter/utils/constants/database_constants.dart';
import 'package:sqflite/sqflite.dart';

class SummaryRepository extends BaseRepository {
  String tableName = summaryTable;

  @override
  Future<Database> get database async => await databaseProvider.database;

  Future<int> insert(SummaryModel summary) async {
    var db = await database;
    List<SummaryModel> result =
        await select(columns: ["id", "monthInt", "year"], query: summary.id);
    if (result.isEmpty) {
      return await db.insert(tableName, summary.toMap());
    }
    return await update(summary);
  }

  Future<int> update(SummaryModel summary) async {
    var db = await database;
    return await db.rawUpdate(
      """
        UPDATE $tableName SET
        deposits = deposits + ?,
        withdrawals = withdrawals + ?,
        transactionCost = transactionCost + ?
        WHERE id = ?;
      """,
      [
        summary.deposits,
        summary.withdrawals,
        summary.transactionCost,
        summary.id
      ],
    );
  }

  Future<List<SummaryModel>> select(
      {List<String> columns, String query}) async {
    var db = await database;
    List<Map<String, dynamic>> result;
    if (query != null && query.isNotEmpty) {
      result = await db.query(
        tableName,
        columns: columns,
        where: "id = ?",
        whereArgs: [query],
      );
    } else {
      result = await db.rawQuery('''
        SELECT * FROM $tableName
        ORDER BY id DESC
      ''');
    }
    List<SummaryModel> summaries;
    summaries = result.isNotEmpty
        ? result.map((data) => SummaryModel.fromMap(data)).toList()
        : [];
    return summaries;
  }
}
