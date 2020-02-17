import 'dart:async';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import 'package:mpesa_ledger_flutter/blocs/base_bloc.dart';
import 'package:mpesa_ledger_flutter/blocs/categories/categories_bloc.dart';
import 'package:mpesa_ledger_flutter/blocs/counter/counter_bloc.dart';
import 'package:mpesa_ledger_flutter/models/category_model.dart';
import 'package:mpesa_ledger_flutter/models/transaction_category_model.dart';
import 'package:mpesa_ledger_flutter/repository/category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_repository.dart';

class NewCategoryBloc extends BaseBloc {
  TransactionRepository _transactionRepository = TransactionRepository();
  CategoryRepository _categoryRepository = CategoryRepository();
  TransactionCategoryRepository _transactionCategoryRepository =
      TransactionCategoryRepository();

  List<String> keywordList = [];
  List<int> transactionIdList = [];

  StreamController<List<String>> _keyWordChipController =
      StreamController<List<String>>();
  Stream<List<String>> get keyWordChipStream => _keyWordChipController.stream;
  StreamSink<List<String>> get keyWordChipSink => _keyWordChipController.sink;

  StreamController _totalTransactionsController = StreamController();
  Stream get totalTransactionsStream => _totalTransactionsController.stream;
  StreamSink get totalTransactionsSink => _totalTransactionsController.sink;

  // EVENTS

  StreamController<Map<String, dynamic>> _addCategoryEventController =
      StreamController<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get addCategoryEventStream =>
      _addCategoryEventController.stream;
  StreamSink<Map<String, dynamic>> get addCategoryEventSink =>
      _addCategoryEventController.sink;

  StreamController<String> _addKeywordEventController =
      StreamController<String>();
  Stream<String> get addKeywordEventStream => _addKeywordEventController.stream;
  StreamSink<String> get addKeywordEventSink => _addKeywordEventController.sink;

  StreamController<int> _deleteKeywordEventController = StreamController<int>();
  Stream<int> get deleteKeywordEventStream =>
      _deleteKeywordEventController.stream;
  StreamSink<int> get deleteKeywordEventSink =>
      _deleteKeywordEventController.sink;

  NewCategoryBloc() {
    addCategoryEventStream.listen((data) {
      _addCategory(data);
    });
    addKeywordEventStream.listen((data) {
      _addKeyword(data);
      _getTransactions();
    });
    deleteKeywordEventStream.listen((data) {
      _deleteKeyword(data);
      _getTransactions();
    });
  }

  _addCategory(Map<String, dynamic> map) async {
    if (keywordList.isEmpty) {
      Flushbar(
        duration: Duration(seconds: 3),
        message: "Please add keywords",
      )..show(map["context"]);
    } else {
      map["keywords"] = keywordList.toString();
      int id = await _categoryRepository.insert(CategoryModel.fromMap(map));
      for (var i = 0; i < transactionIdList.length; i++) {
        map["transactionId"] = transactionIdList[i];
        map["categoryId"] = id;
        await _transactionCategoryRepository
            .insert(TransactionCategoryModel.fromMap(map));
        await _categoryRepository
            .incrementNumOfTransactions(CategoryModel.fromMap({"id": id}));
      }
      categoriesBloc.getCategoriesEventSink.add(null);
      Navigator.pop(map["context"]);
    }
  }

  _getTransactions() async {
    String schema = _generateSchema();
    transactionIdList = [];
    if (schema.isNotEmpty) {
      var result =
          await _transactionRepository.selectByKeyword(_generateSchema());
      counter.counterSink.add(result.length);
      for (var i = 0; i < result.length; i++) {
        transactionIdList.add(result[i].id);
      }
    } else {
      counter.counterSink.add(0);
    }
  }

  String _generateSchema() {
    if (keywordList.isNotEmpty) {
      String s = "";
      for (var i = 0; i < keywordList.length; i++) {
        var index = keywordList[i];
        s += "body LIKE '%$index%' OR ";
      }
      return s.replaceRange(s.length - 4, s.length, "");
    }
    return "";
  }

  _addKeyword(String keyword) {
    if (!keywordList.contains(keyword)) {
      keywordList.add(keyword);
      keyWordChipSink.add(keywordList);
    }
  }

  _deleteKeyword(int index) {
    keywordList.removeAt(index);
    keyWordChipSink.add(keywordList);
  }

  @override
  void dispose() {
    _keyWordChipController.close();
    _totalTransactionsController.close();
    _addCategoryEventController.close();
    _addKeywordEventController.close();
    _deleteKeywordEventController.close();
  }
}
