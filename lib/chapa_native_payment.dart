import 'package:flutter/material.dart';

class ChapaNativePayment extends StatefulWidget {
  final String title;
  final String txRef;
  final double amount;
  final Function(String, String, double)? onPaymentFinished;

  const ChapaNativePayment({
    Key? key,
    required this.title,
    required this.txRef,
    required this.amount,
    this.onPaymentFinished,
  }) : super(key: key);

  @override
  _ChapaNativePaymentState createState() => _ChapaNativePaymentState();
}

class _ChapaNativePaymentState extends State<ChapaNativePayment> {
  bool _isPaymentCompleted = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.onPaymentFinished != null && _isPaymentCompleted) {
          widget.onPaymentFinished!('Payment completed', widget.txRef, widget.amount);
          return true;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onPaymentFinished != null && _isPaymentCompleted) {
                widget.onPaymentFinished!('Payment completed', widget.txRef, widget.amount);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(widget.title),
        ),
        body: Center(
          child: Text('Payment Page Content'),
        ),
      ),
    );
  }
} 