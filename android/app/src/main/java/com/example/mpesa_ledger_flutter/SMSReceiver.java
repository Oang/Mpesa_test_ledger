package com.example.mpesa_ledger_flutter;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.provider.Telephony;
import android.telephony.SmsMessage;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SMSReceiver extends BroadcastReceiver {

  @Override
  public void onReceive(Context context, Intent intent) {
    if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION.equals(intent.getAction())) {
      List<Map<String, String>> mapList = new ArrayList<>();
      String body = "";
      String timestamp = "";
      String address = "";
      for (SmsMessage smsMessage : Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
        body += smsMessage.getMessageBody();
        address = smsMessage.getOriginatingAddress();
        timestamp = String.valueOf(smsMessage.getTimestampMillis());
      }
      Map<String, String> map = new HashMap<>();
      if (address.equals("MPESA")) {
        map.put("body", body);
        map.put("timestamp", timestamp);
        mapList.add(map);
      }
      if (!mapList.isEmpty()) {
        DatabaseHelper databaseHelper = new DatabaseHelper(context);
        databaseHelper.insertUnrecordedTransactions(mapList);
      }
    }
  }
}
