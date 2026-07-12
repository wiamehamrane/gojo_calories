import 'dart:io';

import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

Future<void> presentAppleCodeRedemptionSheet() async {
  if (Platform.isIOS) {
    await SKPaymentQueueWrapper().presentCodeRedemptionSheet();
  }
}
