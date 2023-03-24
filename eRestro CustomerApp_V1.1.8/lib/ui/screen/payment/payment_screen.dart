import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/cubit/address/addressCubit.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/data/model/cartModel.dart';
import 'package:erestro/cubit/cart/getCartCubit.dart';
import 'package:erestro/cubit/home/search/filterCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/screen/payment/Stripe_Service.dart';
import 'package:erestro/ui/screen/payment/payment_radio.dart';
import 'package:erestro/ui/screen/payment/paypal_webview_screen.dart';
import 'package:erestro/ui/screen/cart/cart_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/screen/order/thank_you_for_order.dart';
import 'package:erestro/ui/widgets/buttomContainer.dart';
import 'package:erestro/ui/widgets/simmer/cartSimmer.dart';
import 'package:erestro/utils/api.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/internetConnectivity.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/utils/string.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:http/http.dart';
import 'package:paytm/paytm.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final CartModel? cartModel;
  final String? addNote;
  const PaymentScreen({Key? key, this.cartModel, this.addNote}) : super(key: key);

  @override
  PaymentScreenState createState() => PaymentScreenState();
  static Route<dynamic> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
        builder: (_) => BlocProvider<FilterCubit>(
              create: (_) => FilterCubit(),
              child: PaymentScreen(cartModel: arguments['cartModel'] as CartModel, addNote: arguments['addNote']),
            ));
  }
}

bool codAllowed = true;
String? bankName, bankNo, acName, acNo, exDetails;

class PaymentScreenState extends State<PaymentScreen> {
  double? width, height;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  int? addressIndex;
  bool _isLoading = true;
  String? startingDate;
  CartModel cartModel = CartModel();

  late bool cod = false,
      paypal = false,
      razorpay = false,
      paumoney = false,
      paystack = false,
      flutterwave = false,
      stripe = false,
      paytm = true,
      gpay = false;
  List<RadioModel> paymentModel = [];

  List<String?> paymentMethodList = [];
  List<String> paymentIconList = [
    'cash_delivery',
    'paypal',
    'rozerpay',
    'paystack',
    'flutterwave',
    'stripe',
    'paytm',
  ];

  Razorpay? _razorpay;
  final payStackPlugin = PaystackPlugin();
  bool _placeOrder = false;
  final plugin = PaystackPlugin();
  String addressId = "";
  List<String> codAllowedList = [];

  @override
  void initState() {
    super.initState();
    context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
    getDateTime();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    Future.delayed(Duration.zero, () {
      paymentMethodList = [
        UiUtils.getTranslatedLabel(context, caseOnDeliveryLblLabel),
        UiUtils.getTranslatedLabel(context, payPalLblLabel),
        UiUtils.getTranslatedLabel(context, razorpayLblLabel),
        UiUtils.getTranslatedLabel(context, payStackLblLabel),
        UiUtils.getTranslatedLabel(context, flutterWaveLblLabel),
        UiUtils.getTranslatedLabel(context, stripeLblLabel),
        UiUtils.getTranslatedLabel(context, paytmLblLabel),
      ];
    });
    if (context.read<GetCartCubit>().getCartModel().variantId!.isEmpty) {
      Future.delayed(Duration.zero, () async {
        await context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId());
      }).then((value) => codeMethodCheck());
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    //print("payment success" + response.toString());
    placeOrder(response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    //print("payment error" + response.toString());
    var getdata = json.decode(response.message!);
    String errorMsg = getdata["error"]["description"];
    UiUtils.setSnackBar(errorMsg, errorMsg, context, false, type: "2");

    if (mounted) {
      setState(() {
        _placeOrder = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> getDateTime() async {
    try {
      var parameter = {typeKey: paymentMethodKey, userIdKey: context.read<AuthCubit>().getId()};
      Response response = await post(Uri.parse(Api.getSettingsUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        if (!error) {
          var data = getdata["data"];
          //codAllowed = data["is_cod_allowed"] == 1 ? true : false;

          var payment = data["payment_method"];
          print("payment:$payment");

          //cod = codAllowed? payment["cod_method"] == "1"? true: false: false;
          paypal = payment["paypal_payment_method"] == "1" ? true : false;
          paumoney = payment["payumoney_payment_method"] == "1" ? true : false;
          flutterwave = payment["flutterwave_payment_method"] == "1" ? true : false;
          razorpay = payment["razorpay_payment_method"] == "1" ? true : false;
          paystack = payment["paystack_payment_method"] == "1" ? true : false;
          stripe = payment["stripe_payment_method"] == "1" ? true : false;
          paytm = payment["paytm_payment_method"] == "1" ? true : false;

          for (int i = 0; i < cartModel.data!.length; i++) {
            codAllowedList.add(cartModel.data![i].productDetails![0].codAllowed!);
            print("codData$codAllowedList");
          }
          if(codAllowedList.contains("0")){
              cod = false;
              codAllowed = false;
          }else{
            codAllowed = data["is_cod_allowed"] == 1 ? true : false;
              cod = codAllowed? payment["cod_method"] == "1"? true: false: false;
          }

          if (razorpay) razorpayId = payment["razorpay_key_id"];
          if (paystack) {
            paystackId = payment["paystack_key_id"];

            await plugin.initialize(publicKey: paystackId!);
          }
          if (stripe) {
            stripeId = payment['stripe_publishable_key'];
            stripeSecret = payment['stripe_secret_key'];
            stripeCurCode = payment['stripe_currency_code'];
            stripeMode = payment['stripe_mode'] ?? 'test';
            StripeService.secret = stripeSecret;
            //print("stripe$stripeId--$stripeMode");
            StripeService.init(stripeId, stripeMode);
          }
          if (paytm) {
            paytmMerId = payment['paytm_merchant_id'];
            paytmMerKey = payment['paytm_merchant_key'];
            payTesting = payment['paytm_payment_mode'] == 'sandbox' ? true : false;
          }

          for (int i = 0; i < paymentMethodList.length; i++) {
            paymentModel.add(RadioModel(isSelected: i == selectedMethod ? true : false, name: paymentMethodList[i], img: paymentIconList[i]));
          }
        } else {}
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on TimeoutException catch (_) {}
  }

  doPayment() {
    if (paymentMethod == UiUtils.getTranslatedLabel(context, payPalLblLabel)) {
      placeOrder('');
    } else if (paymentMethod == UiUtils.getTranslatedLabel(context, razorpayLblLabel)) {
      razorpayPayment();
    } else if (paymentMethod == UiUtils.getTranslatedLabel(context, payStackLblLabel)) {
      payStackPayment(context);
    } else if (paymentMethod == UiUtils.getTranslatedLabel(context, flutterWaveLblLabel)) {
      flutterWavePayment();
    } else if (paymentMethod == UiUtils.getTranslatedLabel(context, stripeLblLabel)) {
      stripePayment();
    } else if (paymentMethod == UiUtils.getTranslatedLabel(context, paytmLblLabel)) {
      paytmPayment();
    } else {
      placeOrder('');}
  }

  void paytmPayment() async {
    String? paymentResponse;

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    String callBackUrl = '${payTesting ? 'https://securegw-stage.paytm.in' : 'https://securegw.paytm.in'}/theia/paytmCallback?ORDER_ID=$orderId';
    //print(callBackUrl);
    var parameter = {amountKey: finalTotal.toString(), userIdKey: context.read<AuthCubit>().getId(), orderIdKey: orderId};
    //print(parameter);

    try {
      final response = await post(
        Uri.parse(Api.generatePaytmTxnTokenUrl),
        body: parameter,
        headers: Api.getHeaders(),
      );

      var getdata = json.decode(response.body);

      bool error = getdata["error"];

      if (!error) {
        String txnToken = getdata["txn_token"];
        //print("isvar--${txnToken}");

        setState(() {
          paymentResponse = txnToken;
        });
        // orderId, mId, txnToken, txnAmount, callback

        var paytmResponse = Paytm.payWithPaytm(
            callBackUrl: callBackUrl, mId: paytmMerId!, orderId: orderId, txnToken: txnToken, txnAmount: finalTotal.toString(), staging: payTesting);
        paytmResponse.then((value) {
          _placeOrder = false;
          setState(() {});
          if (value['error']) {
            paymentResponse = value['errorMessage'];

            if (value['response'] != "") {
              addTransaction(value['response']['TXNID'], orderId, value['response']['STATUS'] ?? '', paymentResponse, false);
            }
          } else {
            if (value['response'] != "") {
              paymentResponse = value['response']['STATUS'];
              if (paymentResponse == "TXN_SUCCESS") {
                placeOrder(value['response']['TXNID']);
              } else {
                addTransaction(value['response']['TXNID'], orderId, value['response']['STATUS'], value['errorMessage'] ?? '', false);
              }
            }
          }
          UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), paymentResponse!, context, false, type: "1");
        });
      } else {
        if(getdata["status_code"].toString() == "102"){
            reLogin(context);
          }
        if (mounted) {
          setState(() {
            _placeOrder = false;
          });
        }
        if (!mounted) return;
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), getdata["message"], context, false, type: "2");
      }
    } catch (e) {
      print(e);
    }
  }

  razorpayPayment() async {
    String? contact = context.read<AuthCubit>().getMobile();
    String? email = context.read<AuthCubit>().getEmail();
    String? name = context.read<AuthCubit>().getName();

    String? amt = ((finalTotal) * 100).toStringAsFixed(2);
    //print(contact + "" + email + "" + amt + "" + razorpayId.toString() + "" + context.read<SystemConfigCubit>().getName().toString());
    if (contact != '' && email != '') {
      var options = {
        key: razorpayId,
        amountKey: amt,
        nameKey: name,
        'prefill': {contactKey: contact, emailKey: email},
      };

      try {
        _razorpay!.open(options);
      } catch (e) {
        if (mounted) {
          setState(() {
            _placeOrder = false;
          });
        }
        debugPrint(e.toString());
      }
    } else {
      if (mounted) {
        setState(() {
          _placeOrder = false;
        });
      }
      if (email == '') {
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, emailLabel), StringsRes.emailWarning, context, false, type: "2");
      } else if (contact == '') {
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, phoneNumberLabel), StringsRes.phoneWarning, context, false, type: "2");
      }
    }
  }

  payStackPayment(BuildContext context) async {
    await payStackPlugin.initialize(publicKey: paystackId!);
    if (!mounted) return;
    String? email = context.read<AuthCubit>().getEmail();

    Charge charge = Charge()
      ..amount = finalTotal.toInt()
      ..reference = _getReference()
      ..email = email;

    try {
      CheckoutResponse response = await payStackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );
      if (response.status) {
        placeOrder(response.reference);
      } else {
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), response.message, context, false, type: "2");
        if (mounted) {
          setState(() {
            _placeOrder = false;
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }

    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> placeOrder(String? tranId) async {
    try {
      String? mob = context.read<SystemConfigCubit>().getMobile();
      String? varientId, quantity;
      //CartModel? cartModel = context.read<GetCartCubit>().getCartModel();
      print("cartMdel:${cartModel.variantId}----${(context.read<GetCartCubit>().getCartModel().variantId)}");
      varientId = cartModel.variantId!.join(",");
      for (int i = 0; i < cartModel.data!.length; i++) {
        quantity = quantity != null ? "$quantity,${cartModel.data![i].qty!}" : cartModel.data![i].qty!;
      }

      String? payVia;
      if (paymentMethod == UiUtils.getTranslatedLabel(context, caseOnDeliveryLblLabel)) {
        payVia = "COD";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, payPalLblLabel)) {
        payVia = "PayPal";
      }else if (paymentMethod == UiUtils.getTranslatedLabel(context, razorpayLblLabel)) {
        payVia = "RazorPay";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, payStackLblLabel)) {
        payVia = "Paystack";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, flutterWaveLblLabel)) {
        payVia = "Flutterwave";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, stripeLblLabel)) {
        payVia = "Stripe";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, paytmLblLabel)) {
        payVia = "Paytm";
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, walletLabel)) {
        payVia = "Wallet";
      }

      var parameter = {
        userIdKey: context.read<AuthCubit>().getId(),
        mobileKey: context.read<AddressCubit>().gerCurrentAddress().mobile.toString(), //context.read<SystemConfigCubit>().getMobile(),
        productVariantIdKey: varientId,
        quantityKey: quantity,
        totalKey: subTotal.toString(),
        finalTotalKey: finalTotal.toString(),
        deliveryChargeKey: orderTypeIndex.toString() == "0" ? deliveryCharge.toString() : "0",
        taxAmountKey: taxAmount.toString(),
        promoCodeKey: promoCode ?? "",
        taxPercentageKey: taxPercentage.toString(),
        latitudeKey: latitude.toString(),
        longitudeKey: longitude.toString(),
        paymentMethodKey: payVia,
        addressIdKey: orderTypeIndex.toString() == "0" ? selAddress : "",
        isWalletUsedKey: isUseWallet! ? "1" : "0",
        walletBalanceUsedKey: walletBalanceUsed.toString(),
        orderNoteKey: widget.addNote,
        deliveryTipKey: deliveryTip.toString(),
        isSelfPickUpKey: orderTypeIndex.toString(),
      };

      print("body:$parameter");

      if (isPromoValid!) {
        parameter[promoCodeKey] = promoCode;
      }
      if (orderTypeIndex.toString() == "0") {
        parameter[addressIdKey] = selAddress;
      }

      if (paymentMethod == UiUtils.getTranslatedLabel(context, payPalLblLabel)) {
        parameter["active_status"] = waitingKey;
      } else if (paymentMethod == UiUtils.getTranslatedLabel(context, stripeLblLabel)) {
        parameter["active_status"] = waitingKey;
      }

      Response response = await post(Uri.parse(Api.placeOrderUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));
      if (mounted) {
        setState(() {
          _placeOrder = false;
        });
      }
      print(response.statusCode);
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);
        print(getdata);
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          String orderId = getdata["order_id"].toString();
          //print("orderId:" + orderId);
          if (paymentMethod == UiUtils.getTranslatedLabel(context, razorpayLblLabel)) {
            addTransaction(tranId, orderId, "Success", msg, true);
          } else if (paymentMethod == UiUtils.getTranslatedLabel(context, payPalLblLabel)) {
            paypalPayment(orderId);
          } else if (paymentMethod == UiUtils.getTranslatedLabel(context, stripeLblLabel)) {
            addTransaction(stripePayId, orderId, tranId == "succeeded" ? placedKey : waitingKey, msg, true);
          } else if (paymentMethod == UiUtils.getTranslatedLabel(context, payStackLblLabel)) {
            addTransaction(tranId, orderId, "Success", msg, true);
          } else if (paymentMethod == UiUtils.getTranslatedLabel(context, paytmLblLabel)) {
            addTransaction(tranId, orderId, "Success", msg, true);
          } else {
            clearAll();
            //Navigator.of(context).popUntil((route) => route.isFirst);
            await Navigator.push(context, MaterialPageRoute(builder: (context) => ThankYouForOrderScreen(orderId: orderId.toString())));
            context.read<GetCartCubit>().clearCartModel();

            /*await Future.delayed(
                Duration.zero,
                () => Navigator.pushAndRemoveUntil(
                    context, CupertinoPageRoute(builder: (BuildContext context) => const ThankYouForOrderScreen()), ModalRoute.withName('/home')));*/
          }
        } else {
          if(getdata["status_code"].toString() == "102"){
            reLogin(context);
          }
          if (!mounted) return;
          UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), msg!, context, false, type: "2");
          if (mounted) {
            setState(() {
              _placeOrder = false;
            });
          }
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _placeOrder = false;
        });
      }
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.somethingMsg, context, false, type: "2");
    } catch (e) {
      if (mounted) {
        setState(() {
          _placeOrder = false;
        });
      }
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), e.toString(), context, false, type: "2");
    }
  }

  Future<void> paypalPayment(String orderId) async {
    try {
      var parameter = {userIdKey: context.read<AuthCubit>().getId(), orderIdKey: orderId, amountKey: finalTotal.toString()};
      Response response =
          await post(Uri.parse(Api.getPaypalLinkUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));

      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg = getdata["message"];
      if (!error) {
        String? data = getdata["data"];
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (BuildContext context) => PaypalWebView(
                      url: data,
                      from: "order",
                      orderId: orderId,
                      addNote: widget.addNote,
                    )));
      } else {
        if(getdata["status_code"].toString() == "102"){
          reLogin(context);
        }
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), msg!, context, false, type: "2");
      }
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  clearAll() {
    finalTotal = 0;
    subTotal = 0;
    taxPercentage = 0;
    deliveryCharge = 0;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {});

    promoAmt = 0;
    remWalBal = 0;
    walletBalanceUsed = 0;
    paymentMethod = '';
    promoCode = '';
    isPromoValid = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
    orderTypeIndex = 0;
  }

  stripePayment() async {
    var response = await StripeService.payWithPaymentSheet(
        amount: (finalTotal.toInt() * 100).toString(), currency: stripeCurCode, from: "order", context: context);

    if (response.message == "Transaction successful") {
      placeOrder(response.status);
    } else if (response.status == 'pending' || response.status == "captured") {
      placeOrder(response.status);
    } else {
      if (mounted) {
        setState(() {
          _placeOrder = false;
        });
      }
    }
    if (response.status == 'succeeded') {
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), response.message!, context, false, type: "1");
    } else {
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), response.message!, context, false, type: "2");
    }
  }

  Future<void> addTransaction(String? tranId, String orderID, String? status, String? msg, bool redirect) async {
    print("stripe");
    try {
      var parameter = {
        userIdKey: context.read<AuthCubit>().getMobile(),
        orderIdKey: orderID,
        typeKey: paymentMethod,
        txnIdKey: tranId,
        amountKey: finalTotal.toString(),
        statusKey: status,
        messageKey: msg
      };
      Response response =
          await post(Uri.parse(Api.addTransactionUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));

      var getdata = json.decode(response.body);
      print("data:$getdata-----$parameter");

      bool error = getdata["error"];
      String? msg1 = getdata["message"];
      if (!error) {
        if (redirect) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ThankYouForOrderScreen(orderId: orderID.toString())),
          );
          context.read<GetCartCubit>().clearCartModel();
          /*await Future.delayed(
              Duration.zero,
              () => Navigator.pushAndRemoveUntil(
                  context, CupertinoPageRoute(builder: (BuildContext context) => const ThankYouForOrderScreen()), ModalRoute.withName('/home')));*/
        }
      } else {
        if(getdata["status_code"].toString() == "102"){
          reLogin(context);
        }
        if (!mounted) return;
        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), msg!, context, false, type: "2");
      }
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  Future<void> flutterWavePayment() async {
    try {
      var parameter = {
        amountKey: finalTotal.toString(),
        userIdKey: context.read<AuthCubit>().getId(),
      };
      //print(parameter.toString());
      Response response =
          await post(Uri.parse(Api.flutterwaveWebviewUrl), body: parameter, headers: Api.getHeaders()).timeout(const Duration(seconds: 50));
      //print("payment" + response.body.toString());
      if (response.statusCode == 200) {
        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["link"];
          if (!mounted) return;
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (BuildContext context) => PaypalWebView(
                        url: data,
                        from: "order",
                        addNote: widget.addNote,
                      )));
        } else {
          if(getdata["status_code"].toString() == "102"){
            reLogin(context);
          }
          if (!mounted) return;
          UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), msg!, context, false, type: "2");
        }
      }
    } on TimeoutException catch (_) {
      UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.somethingMsg, context, false, type: "2");
    }
  }

  /* Widget deliveryLocation() {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: height! / 40.0),
      child: BlocProvider<UpdateAddressCubit>(
        create: (_) => UpdateAddressCubit(AddressRepository()),
        child: Builder(builder: (context) {
          return BlocConsumer<AddressCubit, AddressState>(
              bloc: context.read<AddressCubit>(),
              listener: (context, state) {},
              builder: (context, state) {
                if (state is AddressProgress || state is AddressInitial) {
                  return AddressSimmer(width: width!, height: height!);
                }
                if (state is AddressFailure) {
                  return Center(
                      child: Text(
                    state.errorMessage.toString(),
                    textAlign: TextAlign.center,
                  ));
                }
                final addressList = (state as AddressSuccess).addressList;
                return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: addressList.length,
                    itemBuilder: (BuildContext context, i) {
                      if (addressList[i].isDefault == "1") {
                        addressIndex = i;
                        addressId = addressList[i].id!;
                      }
                      return addressList[i].isDefault == "0"
                          ? Container()
                          : Container(decoration: DesignConfig.boxDecorationContainer(white, 10.0),
                              margin: const EdgeInsetsDirectional.only(top: 5),
                              padding: EdgeInsetsDirectional.only(bottom: height! / 40.0, start: width! / 40.0, end: width! / 40.0, top: height!/ 40.0),
                              child: Column(children: [
                                Row(children: [
                                  addressList[i].type == StringsRes.home
                                      ? SvgPicture.asset(
                                          DesignConfig.setSvgPath("home_address"), fit: BoxFit.scaleDown, height: 20, width: 20,
                                        )
                                      : addressList[i].type == StringsRes.office
                                          ? SvgPicture.asset(DesignConfig.setSvgPath("work_address"), fit: BoxFit.scaleDown, height: 20, width: 20,)
                                          : SvgPicture.asset(DesignConfig.setSvgPath("other_address"), fit: BoxFit.scaleDown, height: 20, width: 20,),
                                  SizedBox(width: height! / 99.0),
                                  Text(
                                    addressList[i].type == StringsRes.home
                                        ? StringsRes.home
                                        : addressList[i].type == StringsRes.office
                                            ? StringsRes.office
                                            : StringsRes.other,
                                    style: const TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ]),
                                SizedBox(width: height! / 99.0),
                                Row(
                                  children: [
                                    SizedBox(width: width! / 11.0),
                                    Expanded(
                                      child: Text(
                                        "${addressList[i].address!},${addressList[i].area!},${addressList[i].city},${addressList[i].state!},${addressList[i].pincode!}",
                                        style: const TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                )
                              ]),
                            );
                    });
              });
        }),
      ),
    );
  } */

  codeMethodCheck(){
    for (int i = 0; i < cartModel.data!.length; i++) {
      codAllowedList.add(cartModel.data![i].productDetails![0].codAllowed!);
      print("codData$codAllowedList");
    }
    if(codAllowedList.contains("0")){
      if(paymentMethod == UiUtils.getTranslatedLabel(context, caseOnDeliveryLblLabel)){
        cod = false;
        codAllowed = false;
        //UiUtils.setSnackBar(StringsRes.payment, StringsRes.selectAnotherPaymentMethod, context, false, type: "2");
      }
    }
  }

  @override
  void dispose() {
    if (_razorpay != null) _razorpay!.clear();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
        ),
        child: _connectionStatus == connectivityCheck
            ? const NoInternetScreen()
            : Scaffold(
                appBar: DesignConfig.appBar(context, width!, UiUtils.getTranslatedLabel(context, paymentLabel), const PreferredSize(
                                preferredSize: Size.zero,child:SizedBox())),
                bottomNavigationBar: ButtonContainer(color: Theme.of(context).colorScheme.secondary, height: height, width: width, text: UiUtils.getTranslatedLabel(context, placeOrderLabel), start: width! / 40.0, end: width! / 40.0, bottom: height! / 55.0, top: 0, status: _placeOrder,borderColor: Theme.of(context).colorScheme.secondary, textColor: white, onPressed: (){
                                      if (paymentMethod == null || paymentMethod!.isEmpty) {
                        setState(() {
                          _placeOrder = false;
                        });
                        //codeMethodCheck();
                        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.selectPaymentMethod, context, false, type: "2");
                      } else {
                        if(paymentMethod == UiUtils.getTranslatedLabel(context, caseOnDeliveryLblLabel)){
                          if(codAllowedList.contains("0")){
                            UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, paymentLabel), StringsRes.selectAnotherPaymentMethod, context, false, type: "2");
                          }else{
                            if (mounted) {
                                setState(() {//
                                  _placeOrder = true;
                                });
                              }
                            doPayment();
                          }
                        }else{
                          if (mounted) {
                          setState(() {//
                            _placeOrder = true;
                          });
                        }
                          doPayment();
                        }
                      }
                    },)/* TextButton(
                    style: ButtonStyle(
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                    ),
                    onPressed: () {
                      if (paymentMethod == null || paymentMethod!.isEmpty) {
                        setState(() {
                          _placeOrder = true;
                        });
                        UiUtils.setSnackBar(StringsRes.payment, StringsRes.selectPaymentMethod, context, false, type: "2");
                      } else {
                        if (mounted) {
                          setState(() {
                            _placeOrder = false;
                          });
                        }
                        doPayment();
                      }
                    },
                    child: Container(
                        height: height! / 15.0,
                        margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 55.0),
                        width: width,
                        padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0, start: width! / 20.0, end: width! / 20.0),
                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onSecondary, 100.0),
                        child: _placeOrder
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(StringsRes.placeOrder,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: const TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500)),
                                  Text(
                                      "${StringsRes.totalPay} : ${context.read<SystemConfigCubit>().getCurrency()}${(finalTotal + deliveryTip).toStringAsFixed(2)}",
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: const TextStyle(color: white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ],
                              )
                            : /*SizedBox(height: height! / 15.0, child: const Center(child: */ const Center(
                                child: CircularProgressIndicator(color: white),
                              ) /*))*/)) */,
                body: BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                  return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
                      ? Container()
                      : BlocConsumer<GetCartCubit, GetCartState>(
                          bloc: context.read<GetCartCubit>(),
                          listener: (context, state) {
                            /* if(state is GetCartSuccess){
                                codeMethodCheck();
                              } */
                          },
                          builder: (context, state) {
                            if (state is GetCartProgress || state is GetCartInitial) {
                              return CartSimmer(width: width!, height: height!);
                            }
                            if (state is GetCartFailure) {
                              return Center(
                                  child: Text(
                                state.errorMessage.toString(),
                                textAlign: TextAlign.center,
                              ));
                            }
                            final cartList = (state as GetCartSuccess).cartModel;
                            cartModel = cartList;

                            return Container(height: height!,
                              margin: EdgeInsetsDirectional.only(top: height! / 80.0), padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
                              width: width,
                              child: SingleChildScrollView(
                                child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  Container(padding: EdgeInsetsDirectional.only(start: width!/30.0, end: width!/30.0, top: height!/40.0, bottom: height!/40.0),
                                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0), child: Row(children: [
                                    Text(
                                      UiUtils.getTranslatedLabel(context, totalBillLabel),
                                      style: TextStyle(
                                          color:  Theme.of(context).colorScheme.onSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:  FontStyle.normal,
                                          fontSize: 12.0
                                      )),
                                      const Spacer(),
                                      Text(
                                        "${context.read<SystemConfigCubit>().getCurrency()}${(finalTotal + deliveryTip).toStringAsFixed(2)}",
                                        style: TextStyle(
                                            color:  Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:  FontStyle.normal,
                                            fontSize: 14.0
                                        ))
                                  ])),
                                  Container(margin: EdgeInsetsDirectional.only(top: height!/80.0), decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                                    child: context.read<SystemConfigCubit>().getWallet() != "0" &&
                                            context.read<SystemConfigCubit>().getWallet().isNotEmpty &&
                                            context.read<SystemConfigCubit>().getWallet() != ""
                                        ? Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(top: height! / 60.0, start: width! / 30.0),
                                              child: Text(
                                                UiUtils.getTranslatedLabel(context, walletLabel),
                                                style: 
                                                  TextStyle(
                                                  color:  Theme.of(context).colorScheme.onSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle:  FontStyle.normal,
                                                  fontSize: 14.0
                                              ),
                                              ),
                                            ),
                                          Padding(
                                            padding: EdgeInsetsDirectional.only(top: height! / 80.0),
                                            child: Divider(
                                              color: lightFont.withOpacity(0.50),
                                              height: 1.0,
                                            ),
                                          ),
                                            Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                child: CheckboxListTile(checkboxShape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                                  dense: true,
                                                  activeColor: Theme.of(context).colorScheme.primary,
                                                  contentPadding: const EdgeInsets.all(0),
                                                  value: isUseWallet,
                                                  onChanged: (bool? value) {
                                                    if (mounted) {
                                                      setState(() {
                                                        isUseWallet = value;
                                                        if (value!) {
                                                          if (finalTotal <= double.parse(context.read<SystemConfigCubit>().getWallet())) {
                                                            remWalBal = (double.parse(context.read<SystemConfigCubit>().getWallet()) - finalTotal);
                                                            walletBalanceUsed = finalTotal;
                                                            paymentMethod = "Wallet";

                                                            isPayLayShow = false;
                                                          } else {
                                                            remWalBal = 0;
                                                            walletBalanceUsed = double.parse(context.read<SystemConfigCubit>().getWallet());
                                                            isPayLayShow = true;
                                                          }

                                                          finalTotal = finalTotal - walletBalanceUsed;
                                                        } else {
                                                          finalTotal = finalTotal + walletBalanceUsed;
                                                          remWalBal = double.parse(context.read<SystemConfigCubit>().getWallet());
                                                          paymentMethod = null;
                                                          selectedMethod = null;
                                                          walletBalanceUsed = 0;
                                                          isPayLayShow = true;
                                                        }
                                                      });
                                                    }
                                                  },
                                                  title: Text(
                                                          isUseWallet!
                                                              ? UiUtils.getTranslatedLabel(context, remainingBalanceLabel)
                                                              : UiUtils.getTranslatedLabel(context, balanceLabel),
                                                          style:
                                                              TextStyle(
                                                              color:  Theme.of(context).colorScheme.onSecondary,
                                                              fontWeight: FontWeight.w400,
                                                              fontStyle:  FontStyle.normal,
                                                              fontSize: 12.0
                                                          ),
                                                        ),
                                                  subtitle: Text(
                                                    isUseWallet!
                                                        ? "${context.read<SystemConfigCubit>().getCurrency()} ${remWalBal.toStringAsFixed(2)}"
                                                        : "${context.read<SystemConfigCubit>().getCurrency()} ${double.parse(context.read<SystemConfigCubit>().getWallet()).toStringAsFixed(2)}",
                                                    style:
                                                        TextStyle(
                                                      color:  Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                      fontStyle:  FontStyle.normal,
                                                      fontSize: 16.0
                                                  ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                        : Container(),
                                  ),
                                  isPayLayShow!
                                      ? Container(decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0), margin: EdgeInsetsDirectional.only(top: height!/80.0),
                                        child: Column(
                                          children: [
                                          Row(children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(top: height! / 60.0, start: width! / 30.0),
                                              child: Text(
                                                UiUtils.getTranslatedLabel(context, paymentMethodLabel),
                                                style: TextStyle(
                                                color:  Theme.of(context).colorScheme.onSecondary,
                                                fontWeight: FontWeight.w600,
                                                fontStyle:  FontStyle.normal,
                                                fontSize: 14.0
                                            ),
                                              ),
                                            ),
                                            const Spacer(),
                                          ]),
                                          Padding(
                                            padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                                            child: Divider(
                                              color: lightFont.withOpacity(0.50),
                                              height: 1.0,
                                            ),
                                          ),
                                            ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: paymentMethodList.length,
                                                itemBuilder: (context, index) {
                                                  //print(paymentMethodList.length);
                                                  if (index == 0 && cod) {
                                                    return paymentItem(index);
                                                  } else if (index == 1 && paypal) {
                                                    return paymentItem(index);
                                                  }else if (index == 2 && razorpay) {
                                                    return paymentItem(index);
                                                  } else if (index == 3 && paystack) {
                                                    return paymentItem(index);
                                                  } else if (index == 4 && flutterwave) {
                                                    return paymentItem(index);
                                                  } else if (index == 5 && stripe) {
                                                    return paymentItem(index);
                                                  } else if (index == 6 && paytm) {
                                                    return paymentItem(index);
                                                  }else {
                                                    return Container();
                                                  }
                                                }),
                                          ],
                                        ),
                                      )
                                      : Container(),
                                  /* orderTypeIndex == 1
                                      ? const SizedBox()
                                      : Row(children: [
                                          Text(
                                            StringsRes.deliveryLocation,
                                            style: const TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                                          ),
                                          const Spacer(),
                                        ]),
                                  orderTypeIndex == 1
                                      ? const SizedBox()
                                      : Padding(
                                          padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 50.0),
                                          child: Divider(
                                            color: lightFont.withOpacity(0.50),
                                            height: 1.0,
                                          ),
                                        ),
                                  orderTypeIndex == 1 ? const SizedBox() : deliveryLocation(), */
                                  /* Row(children: [
                                    Text(
                                      StringsRes.payUsing,
                                      style: const TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(3.0),
                                      decoration: DesignConfig.boxDecorationContainer(textFieldBackground, 4.0),
                                      child: Text(
                                        paymentMethod ?? "",
                                        style: const TextStyle(fontSize: 12, color: red),
                                      ),
                                    ),
                                  ]),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                                    child: Divider(
                                      color: lightFont.withOpacity(0.50),
                                      height: 1.0,
                                    ),
                                  ), */
                                ]),
                              ),
                            );
                          });
                })));
  }

  Widget paymentItem(int index) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            selectedMethod = index;
            paymentMethod = paymentMethodList[selectedMethod!]!;
            print("${paymentMethod}Payment");

            for (var element in paymentModel) {
              element.isSelected = false;
            }
            paymentModel[index].isSelected = true;
            //codeMethodCheck();
          });
        }
      },
      child: paymentModel.isNotEmpty ? RadioItem(paymentModel[index]) : Container(),
    );
  }
}
