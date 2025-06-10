import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:chapasdk/domain/constants/app_colors.dart';
import 'package:chapasdk/domain/constants/app_images.dart';
import 'package:chapasdk/domain/constants/enums.dart';
import 'package:chapasdk/domain/constants/extentions.dart';
import 'package:chapasdk/domain/constants/requests.dart';
import 'package:chapasdk/domain/custom-widget/contact_us.dart';
import 'package:chapasdk/domain/custom-widget/custom_button.dart';
import 'package:chapasdk/data/model/request/direct_charge_request.dart';
import 'package:chapasdk/data/services/payment_service.dart';
import 'package:chapasdk/domain/custom-widget/custom_textform.dart';
import 'package:chapasdk/domain/custom-widget/no_connection.dart';
import 'package:chapasdk/features/native-checkout/bloc/chapa_native_checkout_bloc.dart';
import 'package:chapasdk/features/network/bloc/network_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget for performing Chapa native payment checkout.
// ignore: must_be_immutable
class ChapaNativePayment extends StatefulWidget {
  /// BuildContext
  final BuildContext context;

  /// The public API key from Chapa for processing payments for Authenticating Merchant.
  final String publicKey;

  /// The email of the customer making the payment.
  final String email;

  /// The phone number of the customer making the payment.
  final String phone;

  /// The payment amount to be charged.
  final String amount;

  /// The currency for the payment, e.g., "ETB".
  final String currency;

  /// The first name of the customer.
  final String firstName;

  /// The last name of the customer.
  final String lastName;

  ///The unique transaction reference for the payment.
  final String txRef;

  ///The title of the payment.
  final String title;

  /// The description of the payment request.
  final String desc;

  ///The route to navigate after payment is made.
  final String namedRouteFallBack;

  /// Custom button color for the checkout.
  final Color? buttonColor;

  /// Option to show payment methods in a grid view.
  final bool? showPaymentMethodsOnGridView;

  /// List of available payment methods. If null, all methods are enabled.
  List<String> availablePaymentMethods;

  /// Return the transaction status, reference, and response as arguments.
  Function(String, String, String)? onPaymentFinished;

  /// Constructor
  ChapaNativePayment({
    super.key,
    required this.context,
    required this.publicKey,
    required this.email,
    required this.phone,
    required this.amount,
    required this.firstName,
    required this.lastName,
    required this.txRef,
    required this.title,
    required this.desc,
    required this.namedRouteFallBack,
    required this.currency,
    this.buttonColor,
    this.showPaymentMethodsOnGridView,
    this.availablePaymentMethods = const [
      "telebirr",
      "cbebirr",
      "ebirr",
      "mpesa",
    ],
    this.onPaymentFinished,
  });

  @override
  State<ChapaNativePayment> createState() => _ChapaNativePaymentState();
}

class _ChapaNativePaymentState extends State<ChapaNativePayment> {
  PaymentService paymentService = PaymentService();
  LocalPaymentMethods? selectedLocalPaymentMethods;
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneNumberController = TextEditingController();
  late ChapaNativeCheckoutBloc _chapaNativeCheckoutBloc;
  late NetworkBloc _networkBloc;
  bool chapasButtonIsClicked = false;
  bool showPaymentMethodError = false;
  bool _isDialogShowing = false;
  List<LocalPaymentMethods> paymentMethods = [];

  @override
  void initState() {
    phoneNumberController = TextEditingController(
      text: widget.phone,
    );

    _chapaNativeCheckoutBloc =
        ChapaNativeCheckoutBloc(paymentService: PaymentService());
    _networkBloc = NetworkBloc();

    setState(() {
      if (widget.availablePaymentMethods.isNotEmpty) {
        paymentMethods = getFilteredPaymentMethods(
          widget.availablePaymentMethods,
        );
      } else {
        paymentMethods = LocalPaymentMethods.values;
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _chapaNativeCheckoutBloc.close();
    phoneNumberController.dispose();
    super.dispose();
  }

  exitPaymentPage(
    String message,
    String? chapaTransactionRef,
  ) {
    if (widget.namedRouteFallBack.isEmpty) {
      widget.onPaymentFinished!(
        message,
        chapaTransactionRef ?? widget.txRef,
        widget.amount,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        widget.namedRouteFallBack,
        (Route<dynamic> route) => false,
        arguments: {
          'message': message,
          'transactionReference': chapaTransactionRef ?? widget.txRef,
          'paidAmount': widget.amount
        },
      );
    }
  }

  Future<void> _showProcessingDialog() async {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Processing Payment'),
              SizedBox(height: 12),
              Text('Please wait while we process your payment.'),
              SizedBox(height: 12),
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _hideDialog() {
    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isDialogShowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              final state = _chapaNativeCheckoutBloc.state;
              if (state is ChapaNativeCheckoutPaymentValidateSuccessState) {
                exitPaymentPage(
                  state.directChargeValidateResponse.message ??
                      "Payment is Failed",
                  state.directChargeValidateResponse.trxRef,
                );
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.shadowColor
                  : AppColors.darkShadowColor,
            )),
        title: Text(
          "Checkout",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.shadowColor
                    : AppColors.darkShadowColor),
              ),
        ),
      ),
      body: StreamBuilder<NetworkState>(
        stream: _networkBloc.stream,
        initialData: NetworkInitial(),
        builder: (context, netSnapshot) {
          if (netSnapshot.hasData) {
            final netState = netSnapshot.data;
            if (netState is OnNetworkNotConnected) {
              return const NoConnection();
            } else {
              return StreamBuilder<ChapaNativeCheckoutState>(
                stream: _chapaNativeCheckoutBloc.stream,
                initialData: ChapaNativeCheckoutInitial(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final state = snapshot.data;
                    return _buildStreamState(state, deviceSize);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              );
            }
          } else {
            return const NoConnection();
          }
        },
      ),
    );
  }

  Widget _buildStreamState(ChapaNativeCheckoutState? state, Size deviceSize) {
    if (state is ChapaNativeCheckoutLoadingState) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (state is ChapaNativeCheckoutValidationOngoingState) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showProcessingDialog(),
      );
    }
    if (state is ChapaNativeCheckoutPaymentInitiateSuccessState) {
      return _buildPaymentInitiateSuccessError(state, deviceSize);
    }
    if (state is ChapaNativeCheckoutPaymentValidateSuccessState) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _hideDialog(),
      );
      return _buildPaymentValidateSuccessResult(state, deviceSize);
    }

    if (state is ChapaNativeCheckoutPaymentInitiateApiError) {
      return _buildPaymentInitiateError(state, deviceSize);
    }
    if (state is ChapaNativeCheckoutPaymentValidateApiError) {
      return _buildPaymentValidateError(state);
    }
    if (state is ChapaNativeCheckoutNetworkError) {
      return NoConnection();
    }

    if (state is ChapaNativeCheckoutUnknownError) {
      return ContactUs();
    }

    return _buildPaymentForm(state, deviceSize);
  }

  Widget _buildPaymentForm(ChapaNativeCheckoutState? state, Size deviceSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: deviceSize.width * 0.064),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: state is ChapaNativeCheckoutValidationOngoingState ? 5.0 : 0,
          sigmaY: state is ChapaNativeCheckoutValidationOngoingState ? 5.0 : 0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment Method",
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SizedBox(
                height: deviceSize.height * 0.012,
              ),
              PaymentMethodsCustomBuilderView(
                showPaymentMethodsOnGridView:
                    widget.showPaymentMethodsOnGridView,
                availablePaymentMethods: paymentMethods,
                onPressed: (val) {
                  setState(() {
                    selectedLocalPaymentMethods = val;
                    showPaymentMethodError = false;
                  });
                },
                selectedPaymentMethod: selectedLocalPaymentMethods,
              ),
              Visibility(
                visible: showPaymentMethodError,
                child: Text(
                  "Please Select Payment Method",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.red),
                ),
              ),
              SizedBox(
                height: deviceSize.height * 0.02,
              ),
              Text(
                "Phone Number",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              SizedBox(
                height: deviceSize.height * 0.006,
              ),
              CustomTextForm(
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppImages.ethiopiaLogo,
                        width: deviceSize.width * 0.064,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                    ],
                  ),
                ),
                textStyle: Theme.of(context).textTheme.bodyMedium,
                controller: phoneNumberController,
                hintText: "0911121314",
                readOnly: true,
                keyboardType: TextInputType.number,
                inputFormatter: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10)
                ],
                hintTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color.fromARGB(255, 156, 145, 145),
                    ),
                labelText: "",
                filled: false,
                filledColor: Colors.transparent,
                obscureText: false,
                onTap: () {},
                validator: (phone) {
                  if (phone == null || phone.isEmpty) {
                    return 'Phone number can\'t be empty';
                  }

                  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                    return 'Phone number must be a 10-digit number';
                  }

                  if (!RegExp(r'^(09|07|011)').hasMatch(phone)) {
                    return 'Enter a valid phone no.';
                  }
                  return null;
                },
                onChanged: (val) {},
              ),
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    if (!chapasButtonIsClicked) {
                      String transactionRef = generateTransactionRef();
                      await initializeMyPayment(
                        widget.context,
                        widget.email,
                        widget.phone,
                        widget.amount,
                        widget.currency,
                        widget.firstName,
                        widget.lastName,
                        transactionRef,
                        widget.title,
                        widget.desc,
                        widget.namedRouteFallBack,
                        widget.publicKey,
                        widget.onPaymentFinished,
                      ).then((String result) {
                        if (result.isNotEmpty) {
                          setState(() {
                            chapasButtonIsClicked = true;
                          });
                        }
                      });
                    }
                  },
                  child: Text(
                    "Pay with Chapa",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.chapaPrimaryColor,
                          color: AppColors.chapaPrimaryColor,
                        ),
                  ),
                ),
              ),
              SizedBox(
                height: deviceSize.height * 0.064,
              ),
              CustomButton(
                title: "Pay ${widget.amount} ${widget.currency.toUpperCase()}",
                backgroundColor: widget.buttonColor,
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      selectedLocalPaymentMethods != null) {
                    DirectChargeRequest request = DirectChargeRequest(
                      amount: widget.amount,
                      mobile: phoneNumberController.text,
                      currency: widget.currency,
                      firstName: widget.firstName,
                      lastName: widget.lastName,
                      email: widget.email,
                      txRef: widget.txRef,
                      paymentMethod: selectedLocalPaymentMethods!.value(),
                    );
                    _chapaNativeCheckoutBloc.add(InitiatePayment(
                      directChargeRequest: request,
                      publicKey: widget.publicKey,
                    ));
                  }
                  if (selectedLocalPaymentMethods == null) {
                    setState(() {
                      showPaymentMethodError = true;
                    });
                  }
                },
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentValidateSuccessResult(
      ChapaNativeCheckoutPaymentValidateSuccessState state, Size deviceSize) {
    if (state.isPaymentFailed) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: deviceSize.width * 0.08,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: deviceSize.height * 0.064,
            ),
            CircleAvatar(
              backgroundColor: Colors.red,
              radius: deviceSize.height * 0.028,
              child: Icon(
                Icons.close,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            SizedBox(
              height: deviceSize.height * 0.016,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Payment Failed",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            SizedBox(
              height: deviceSize.height * 0.012,
            ),
            Text(
              "Payment is failed. Please try again. \n The transaction is canceled or third party time is out.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: deviceSize.height * 0.04,
            ),
            SizedBox(
              width: deviceSize.width * 0.64,
              child: CustomButton(
                backgroundColor: Colors.red,
                onPressed: () {
                  exitPaymentPage(
                    state.directChargeValidateResponse.message ??
                        "Payment is Failed",
                    state.directChargeValidateResponse.trxRef,
                  );
                },
                title: "Retry Again",
              ),
            )
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: deviceSize.width * 0.04,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: deviceSize.height * 0.054,
            ),
            Image.asset(
              AppImages.successIcon,
              width: deviceSize.width * 0.2,
            ),
            SizedBox(
              height: deviceSize.height * 0.012,
            ),
            Text(
              "${state.directChargeValidateResponse.data!.amount?.formattedBirr()}",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 60),
              child: Divider(),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                state.directChargeValidateResponse.message ?? "Successful",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.chapaPrimaryColor),
              ),
            ),
            SizedBox(
              height: deviceSize.height * 0.012,
            ),
            Row(
              children: [
                Text(
                  "Order ID",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Colors.grey),
                ),
                Spacer(),
                Text(
                  state.directChargeValidateResponse.processorId ?? "",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            Divider(),
            Row(
              children: [
                Text(
                  "Amount: ",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Colors.grey),
                ),
                Spacer(),
                Text(
                  state.directChargeValidateResponse.data?.amount
                          ?.formattedBirr() ??
                      "",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ],
            ),
            Divider(),
            Row(
              children: [
                Text(
                  "Charge: ",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Colors.grey),
                ),
                Spacer(),
                Text(
                  state.directChargeValidateResponse.data?.charge
                          ?.formattedBirr() ??
                      "",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ],
            ),
            Divider(),
            Row(
              children: [
                Text(
                  "Reference ID: ",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Colors.grey),
                ),
                Spacer(),
                Text(
                  state.directChargeValidateResponse.trxRef ?? "",
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ],
            ),
            Divider(),
            Row(
              children: [
                Text(
                  "Paid At: ",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: Colors.grey),
                ),
                Spacer(),
                Text(
                  state.directChargeValidateResponse
                      .getCreatedAtTime()
                      .format(),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              ],
            ),
            Divider(),
            SizedBox(
              height: deviceSize.height * 0.048,
            ),
            SizedBox(
              width: deviceSize.width * 0.72,
              child: CustomButton(
                onPressed: () {
                  exitPaymentPage(
                    'paymentSuccessful',
                    state.directChargeValidateResponse.trxRef,
                  );
                },
                title: "Finish",
              ),
            ),
            Spacer(),
            Image.asset(
              AppImages.chapaFullLogo,
              width: deviceSize.width * 0.28,
            ),
            SizedBox(
              height: deviceSize.height * 0.008,
            ),
            Text(
              "Thank you for using chapa",
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: Colors.grey, fontWeight: FontWeight.w400),
            ),
            SizedBox(
              height: deviceSize.height * 0.048,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPaymentInitiateError(
      ChapaNativeCheckoutPaymentInitiateApiError? state, Size deviceSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: deviceSize.width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: deviceSize.height * 0.064,
          ),
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: deviceSize.height * 0.028,
            child: Icon(
              Icons.close,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          SizedBox(
            height: deviceSize.height * 0.016,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              state?.directChargeApiError?.status?.toUpperCase() ??
                  "Payment Failed",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          SizedBox(
            height: deviceSize.height * 0.012,
          ),
          Text(
            state?.directChargeApiError?.data?.message ??
                state?.directChargeApiError?.message ??
                "Something went wrong",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: deviceSize.height * 0.04,
          ),
          SizedBox(
            width: deviceSize.width * 0.64,
            child: CustomButton(
              backgroundColor: Colors.red,
              onPressed: () {
                exitPaymentPage(
                  state?.directChargeApiError?.message ?? "Payment is Failed",
                  null,
                );
              },
              title: "Retry Again",
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentInitiateSuccessError(
      ChapaNativeCheckoutPaymentInitiateSuccessState? state, Size deviceSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: deviceSize.width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: deviceSize.height * 0.064,
          ),
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: deviceSize.height * 0.028,
            child: Icon(
              Icons.close,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          SizedBox(
            height: deviceSize.height * 0.016,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              state?.directChargeSuccessResponse.status?.toUpperCase() ??
                  "Payment Failed",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          SizedBox(
            height: deviceSize.height * 0.012,
          ),
          Text(
            state?.directChargeSuccessResponse.data?.meta?.message ??
                "Charge failed to initiate",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: deviceSize.height * 0.04,
          ),
          SizedBox(
            width: deviceSize.width * 0.64,
            child: CustomButton(
              backgroundColor: Colors.red,
              onPressed: () {
                exitPaymentPage(
                  state?.directChargeSuccessResponse.data?.meta?.message ??
                      "Charge failed to initiate",
                  null,
                );
              },
              title: "Retry Again",
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentValidateError(
      ChapaNativeCheckoutPaymentValidateApiError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state.apiErrorResponse?.status ?? "Error occurred"),
          const SizedBox(height: 8),
          Text(
            state.apiErrorResponse?.message ?? "Something went wrong",
          ),
        ],
      ),
    );
  }
}

/// A custom widget for displaying payment methods in a grid or horizontal list.
// ignore: must_be_immutable
class PaymentMethodsCustomBuilderView extends StatefulWidget {
  /// A flag to determine whether the payment methods
  final bool? showPaymentMethodsOnGridView;

  /// A list of available payment methods to be displayed.
  final List<LocalPaymentMethods> availablePaymentMethods;

  /// The currently selected payment method. Used to highlight
  LocalPaymentMethods? selectedPaymentMethod;

  /// A callback function that is triggered when a payment method is selected
  Function(LocalPaymentMethods) onPressed;

  /// Constructor
  PaymentMethodsCustomBuilderView({
    super.key,
    required this.showPaymentMethodsOnGridView,
    required this.availablePaymentMethods,
    required this.onPressed,
    required this.selectedPaymentMethod,
  });

  @override
  State<PaymentMethodsCustomBuilderView> createState() =>
      _PaymentMethodsCustomBuilderViewState();
}

class _PaymentMethodsCustomBuilderViewState
    extends State<PaymentMethodsCustomBuilderView> {
  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return widget.showPaymentMethodsOnGridView ?? true
        ? Container(
            width: deviceSize.width,
            color: isDarkMode()
                ? AppColors.darkShadowColor
                : AppColors.shadowColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 1.0,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: widget.availablePaymentMethods.map((method) {
                return InkWell(
                  onTap: () {
                    widget.onPressed(method);
                  },
                  child: paymentMethodItem(
                    method,
                    deviceSize,
                    method == widget.selectedPaymentMethod,
                  ),
                );
              }).toList(),
            ),
          )
        : Container(
            color: isDarkMode()
                ? AppColors.darkShadowColor
                : AppColors.shadowColor,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
            ),
            height: deviceSize.height * 0.16,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availablePaymentMethods.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final paymentMethod = widget.availablePaymentMethods[index];
                return InkWell(
                  onTap: () {
                    widget.onPressed(paymentMethod);
                  },
                  child: paymentMethodItem(paymentMethod, deviceSize,
                      paymentMethod == widget.selectedPaymentMethod),
                );
              },
            ),
          );
  }

  Widget paymentMethodItem(
      LocalPaymentMethods paymentMethod, Size deviceSize, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 6, left: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: deviceSize.width * 0.22,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.green : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(24),
                  blurRadius: 2,
                  spreadRadius: 2.0,
                  offset: Offset(0, 4), // Controls the position of the shadow
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: isSelected
                        ? Color(0xff7DC400)
                        : Theme.of(context).scaffoldBackgroundColor,
                    child: Icon(
                      Icons.done,
                      size: 8,
                      color: isSelected
                          ? Colors.black
                          : Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: 6,
                  ),
                  width: deviceSize.width * 0.16,
                  height: deviceSize.width * 0.072,
                  child: Image.asset(
                    paymentMethod.iconPath(),
                    fit: BoxFit.contain,
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            paymentMethod.displayName(),
            style: Theme.of(context)
                .textTheme
                .labelSmall!
                .copyWith(fontSize: deviceSize.width * 0.028),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 4,
          ),
        ],
      ),
    );
  }

  bool isDarkMode() {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
