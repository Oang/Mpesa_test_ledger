import 'package:mpesa_ledger_flutter/database/databaseProvider.dart';
import 'package:mpesa_ledger_flutter/models/transaction_category_model.dart';
import 'package:mpesa_ledger_flutter/repository/base_repository.dart';
import 'package:mpesa_ledger_flutter/utils/constants/database_constants.dart';
import 'package:sqflite/sqflite.dart';

class TransactionCategoryRepository extends BaseRepository {
  String tableName = transactionCategoryTable;

  @override
  Future<Database> get database async => await databaseProvider.database;

  Future<int> insert(TransactionCategoryModel transactionCategory) async {
    var db = await database;
    return await db.insert(tableName, transactionCategory.toMap());
  }

  Future<List<TransactionCategoryModel>> selectTransactions(
      {String query}) async {
    var db = await database;
    List<Map<String, dynamic>> result;
    if (query != null && query.isNotEmpty) {
      result = await db.query(
        tableName,
        where: "transactionId = ?",
        whereArgs: [query],
      );
    } else {
      result = await db.query(tableName);
    }
    List<TransactionCategoryModel> transactionCategory = result.isNotEmpty
        ? result.map((data) => TransactionCategoryModel.fromMap(data)).toList()
        : [];
    return transactionCategory;
  }

  Future<List<TransactionCategoryModel>> selectCategories(
      {String query}) async {
    var db = await database;
    List<Map<String, dynamic>> result;
    if (query != null && query.isNotEmpty) {
      result = await db.query(
        tableName,
        where: "categoryId = ?",
        whereArgs: [query],
      );
    } else {
      result = await db.query(tableName);
    }
    List<TransactionCategoryModel> transactionCategory = result.isNotEmpty
        ? result.map((data) => TransactionCategoryModel.fromMap(data)).toList()
        : [];
    return transactionCategory;
  }

  Future<void> delete(String id) async {
    var db = await database;
    db.delete(
      tableName,
      where: 'categoryId = ?',
      whereArgs: [id],
    );
  }
}
