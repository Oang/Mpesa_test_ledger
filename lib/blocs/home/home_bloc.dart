import 'dart:async';
import "package:collection/collection.dart";

import 'package:mpesa_ledger_flutter/blocs/base_bloc.dart';
import 'package:mpesa_ledger_flutter/models/category_model.dart';
import 'package:mpesa_ledger_flutter/models/transaction_category_model.dart';
import 'package:mpesa_ledger_flutter/models/transaction_model.dart';
import 'package:mpesa_ledger_flutter/repository/category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/mpesa_balance_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_repository.dart';
import 'package:mpesa_ledger_flutter/utils/date_format/date_format.dart';

class HomeBloc extends BaseBloc {
  MpesaBalanceRepository _mpesaBalanceRepository = MpesaBalanceRepository();
  TransactionRepository _transactionRepository = TransactionRepository();
  TransactionCategoryRepository _transactionCategoryRepository =
      TransactionCategoryRepository();
  CategoryRepository _categoryRepository = CategoryRepository();

  DateFormatUtil dateFormatUtil = DateFormatUtil();
  Map<String, dynamic> _homeTransactionMap = {};
  int limit = 10;

  StreamController<Map<String, dynamic>> _homeController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get homeStream => _homeController.stream;
  StreamSink<Map<String, dynamic>> get homeSink => _homeController.sink;

  // EVENTS

  StreamController<int> _getSMSDataEventController = StreamController<int>();
  Stream<int> get getSMSDataEventStream => _getSMSDataEventController.stream;
  StreamSink<int> get getSMSDataEventSink => _getSMSDataEventController.sink;

  HomeBloc() {
    getSMSDataEventStream.listen((data) {
      limit = data;
      _getHomeData();
    });
  }

  Future<void> _getHomeData() async {
    var transactions = await getTransactions();
    var mpesaBalance = await _getMpesaBalance();
    _homeTransactionMap["headerData"] = {
      "mpesaBalance": mpesaBalance,
    };
    _homeTransactionMap["transactions"] = transactions;
    homeSink.add(_homeTransactionMap);
  }

  Future<double> _getMpesaBalance() async {
    var result = await _mpesaBalanceRepository.select();
    return result.mpesaBalance;
  }

  Future<List<Map<String, dynamic>>> getTransactions(
      {List<TransactionModel> transactions}) async {
    List<Map<String, dynamic>> transactionByDayList = [];
    List<TransactionModel> result = [];
    if (transactions != null && transactions.isNotEmpty) {
      result = transactions;
    } else {
      // result = await _transactionRepository.select();
      result = await _transactionRepository.selectPagination(limit);
    }
    List<Map<String, dynamic>> transactionList = [];
    for (var i = 0; i < result.length; i++) {
      var datetime =
          await dateFormatUtil.getDateTime(result[i].timestamp.toString());
      var categories = await _getCategory(result[i].id.toString());
      Map<String, dynamic> transactionMap = {};
      transactionMap.addAll(result[i].toMap());
      transactionMap["isDeposit"] = result[i].isDeposit;
      transactionMap["day"] = datetime["dayInt"];
      transactionMap["dateTime"] = datetime["dateTime"];
      transactionMap["time"] = datetime["time"];
      transactionMap["categories"] = categories;
      transactionList.add(transactionMap);
    }
    var transactionByDayMap = groupBy(transactionList, (key) => key["day"]);
    transactionByDayMap.forEach((key, value) async {
      var dateTime =
          await dateFormatUtil.getDateTime(value[0]["timestamp"].toString());
      Map<String, dynamic> map = {};
      map["dateTime"] = {
        "dayInt": key,
        "dayString": dateTime["dayString"],
        "month": dateTime["month"],
        "year": dateTime["year"],
      };
      map["transactions"] = value;
      transactionByDayList.add(map);
    });
    return transactionByDayList;
  }

  Future<List<String>> _getCategory(String id) async {
    List<String> categoryList = [];
    List<TransactionCategoryModel> transactionCategory =
        await _transactionCategoryRepository.selectTransactions(query: id);
    for (var i = 0; i < transactionCategory.length; i++) {
      List<CategoryModel> category = await _categoryRepository.select(
          columns: ["title"],
          query: transactionCategory[i].categoryId.toString());
      categoryList.add(category[0].title);
    }
    return categoryList;
  }

  @override
  void dispose() {
    _homeController.close();
    _getSMSDataEventController.close();
  }
}

HomeBloc homeBloc = HomeBloc();
