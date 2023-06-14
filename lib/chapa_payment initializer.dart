import 'package:flutter/material.dart';
import 'constants/common.dart';
import 'constants/requests.dart';
import 'constants/strings.dart';

class Chapa {
  BuildContext context;
  String privateKey;
  String amount;
  String currency;
  String email;
  String phone;
  String firstName;
  String lastName;
  String txRef;
  String title;
  String desc;
  String namedRouteFallBack;

  Chapa.paymentParameters({
    required this.context,
    required this.privateKey,
    required this.currency,
    required this.amount,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.txRef,
    required this.title,
    required this.desc,
    required this.namedRouteFallBack,
  }) {
    _validateKeys();
    currency = currency.toUpperCase();
    if (_validateKeys()) {
      initatePayment();
    }
  }

  bool _validateKeys() {
    if (privateKey.trim().isEmpty) {
      showErrorToast(ChapaStrings.privateKeyRequired);
      return false;
    }
    if (currency.trim().isEmpty) {
      showErrorToast(ChapaStrings.currencyRequired);
      return false;
    }
    if (amount.trim().isEmpty) {
      showErrorToast(ChapaStrings.amountRequired);
      return false;
    }

    if (txRef.trim().isEmpty) {
      showErrorToast(ChapaStrings.transactionRefrenceRequired);
      return false;
    }

    return true;
  }

  void initatePayment() async {
    intilizeMyPayment(context, privateKey, email, phone, amount, currency,
        firstName, lastName, txRef, title, desc, namedRouteFallBack);
  }
}
