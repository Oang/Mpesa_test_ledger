import 'dart:core';

import 'package:mpesa_ledger_flutter/blocs/counter/counter_bloc.dart';
import 'package:mpesa_ledger_flutter/models/category_model.dart';
import 'package:mpesa_ledger_flutter/models/mpesa_balance_model.dart';
import 'package:mpesa_ledger_flutter/models/summary_model.dart';
import 'package:mpesa_ledger_flutter/models/transaction_category_model.dart';
import 'package:mpesa_ledger_flutter/models/transaction_model.dart';
import 'package:mpesa_ledger_flutter/repository/category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/mpesa_balance_repository.dart';
import 'package:mpesa_ledger_flutter/repository/summary_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_category_repository.dart';
import 'package:mpesa_ledger_flutter/repository/transaction_repository.dart';
import 'package:mpesa_ledger_flutter/services/sms_filter/check_sms_category.dart';
import 'package:mpesa_ledger_flutter/services/sms_filter/check_sms_type.dart';
import 'package:mpesa_ledger_flutter/utils/date_format/date_format.dart';

class SMSFilter {
  CheckSMSType smsFilters;
  TransactionRepository transactionRepo = TransactionRepository();
  CategoryRepository categoryRepo = CategoryRepository();
  TransactionCategoryRepository transactionCategoryRepo =
      TransactionCategoryRepository();
  SummaryRepository summaryRepo = SummaryRepository();
  DateFormatUtil dateFormatUtil = DateFormatUtil();
  MpesaBalanceRepository mpesaBalanceRepository = MpesaBalanceRepository();

  Future<Map<String, String>> addSMSTodatabase(List<dynamic> bodies) async {
    try {
      List<dynamic> reversedBodies = bodies.reversed.toList();
      var categoryObject = await categoryRepo.select(columns: ["id", "keywords"]);
      int bodyLength = reversedBodies.length;
      for (var i = 0; i < bodyLength; i++) {
        Map<String, dynamic> obj = await _getSMSObject(reversedBodies[i]);
        if (obj.isNotEmpty && !obj["data"].containsKey("unknown")) {
          int id = await transactionRepo.insert(
            TransactionModel.fromMap(Map<String, dynamic>.from(obj["data"])),
          );
          var transactionCategoryObjectList =
              await CheckSMSCategory(categoryObject, obj["data"]["body"], id)
                  .addCategeoryToTransaction();
          for (var j = 0; j < transactionCategoryObjectList.length; j++) {
            await transactionCategoryRepo.insert(
              TransactionCategoryModel.fromMap(
                  transactionCategoryObjectList[j]),
            );
            await categoryRepo.incrementNumOfTransactions(CategoryModel.fromMap(
                {"id": transactionCategoryObjectList[j]["categoryId"]}));
          }
          Map<dynamic, dynamic> dateTime = await dateFormatUtil.getDateTime(
              reversedBodies[i]["timestamp"].toString() ??
                  obj["data"]["timestamp"].toString());
          await summaryRepo.insert(SummaryModel.fromMap({
            "month": dateTime["month"],
            "monthInt": dateTime["monthInt"],
            "year": int.parse(dateTime["year"]),
            "deposits":
                obj["data"]["isDeposit"] == 1 ? obj["data"]["amount"] : 0.0,
            "withdrawals":
                obj["data"]["isDeposit"] == 0 ? obj["data"]["amount"] : 0.0,
            "transactionCost": obj["data"]["transactionCost"]
          }));
        }
        if (obj.isNotEmpty && obj["data"]["mpesaBalance"] != null) {
            await mpesaBalanceRepository.update(MpesaBalanceModel.fromMap(
                {"mpesaBalance": obj["data"]["mpesaBalance"]}));
          }
        counter.counterSink
            .add(((i / bodyLength) * 100).round());
      }
      return {"success": "Data successfully added to database"};
    } catch (e) {
      return {"error": "There was an error", "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getSMSObject(Map<dynamic, dynamic> map) async {
    Map<String, dynamic> smsObject = {};
    smsFilters = CheckSMSType(map["body"], map["timestamp"].toString());
    var coreValuesObject = await smsFilters.getCoreValues();
    if (!coreValuesObject.containsKey("error")) {
      smsObject.addAll(coreValuesObject);
      await smsObject["data"].addAll(smsFilters.checkTypeOfSMS());
    }
    return Future.value(smsObject);
  }
}
