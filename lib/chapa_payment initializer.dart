import 'package:flutter/material.dart';
import 'constants/common.dart';
import 'constants/requests.dart';
import 'constants/strings.dart';

class Chapa {
  BuildContext context;
  String publicKey;
  String amount;
  String currency;
  String email;
  String firstName;
  String lastName;
  String txRef;
  String title;
  String desc;
  String namedRouteFallBack;

  Chapa.paymentParameters({
    required this.context,
    required this.publicKey,
    required this.currency,
    required this.amount,
    required this.email,
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
    if (publicKey.trim().isEmpty) {
      showErrorToast(ChapaStrings.publicKeyRequired);
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
    if (email.trim().isEmpty) {
      showErrorToast(ChapaStrings.emailRequired);
      return false;
    }

    if (firstName.trim().isEmpty) {
      showErrorToast(ChapaStrings.firstNameRequired);
      return false;
    }
    if (lastName.trim().isEmpty) {
      showErrorToast(ChapaStrings.lastNameRequired);
      return false;
    }
    if (txRef.trim().isEmpty) {
      showErrorToast(ChapaStrings.transactionRefrenceRequired);
      return false;
    }

    return true;
  }

  void initatePayment() async {
    intilizeMyPayment(context, publicKey, email, amount, currency, firstName,
        lastName, txRef, title, desc, namedRouteFallBack);
  }
}
