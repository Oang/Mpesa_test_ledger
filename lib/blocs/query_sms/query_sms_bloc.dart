import 'dart:async';

import 'package:mpesa_ledger_flutter/blocs/base_bloc.dart';
import 'package:mpesa_ledger_flutter/blocs/shared_preferences/shared_preferences_bloc.dart';
import 'package:mpesa_ledger_flutter/database/databaseProvider.dart';
import 'package:mpesa_ledger_flutter/models/shared_preferences_model.dart';
import 'package:mpesa_ledger_flutter/services/sms_filter/index.dart';
import 'package:mpesa_ledger_flutter/utils/method_channel/methodChannel.dart';

class QuerySMSBloc extends BaseBloc {
  var methodChannel = MethodChannelClass();
  SMSFilter smsFilter = SMSFilter();

  StreamController<void> _retrieveSMSController = StreamController<void>();
  Stream<void> get retrieveSMSStream => _retrieveSMSController.stream;
  StreamSink<void> get retrieveSMSSink => _retrieveSMSController.sink;

  StreamController<bool> _retrieveSMSCompleteController =
      StreamController<bool>();
  Stream<bool> get retrieveSMSCompleteStream =>
      _retrieveSMSCompleteController.stream;
  StreamSink<bool> get retrieveSMSCompleteSink =>
      _retrieveSMSCompleteController.sink;

  QuerySMSBloc() {
    retrieveSMSStream.listen((void data) async {
      var result =
          await smsFilter.addSMSTodatabase(await _retrieveSMSMessages());
      if (result.containsKey("success")) {
        sharedPreferencesBloc.changeSharedPreferencesEventSink
            .add(SharedPreferencesModel.fromMap({"isDBCreated": true}));
        retrieveSMSCompleteSink.add(true);
      } else {
        databaseProvider.deleteDB();
        retrieveSMSCompleteSink.add(false);
      }
    });
  }

  Future<List<dynamic>> _retrieveSMSMessages() async {
    return await methodChannel.invokeMethod("retrieveSMSMessages");
  }

  @override
  void dispose() {
    _retrieveSMSController.close();
    _retrieveSMSCompleteController.close();
  }
}
