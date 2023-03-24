import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/widgets/buttomContainer.dart';
import 'package:erestro/ui/widgets/noDataContainer.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erestro/utils/internetConnectivity.dart';

class ThankYouForOrderScreen extends StatefulWidget {
  final String? orderId;
  const ThankYouForOrderScreen({Key? key, this.orderId}) : super(key: key);

  @override
  ThankYouForOrderScreenState createState() => ThankYouForOrderScreenState();
}

class ThankYouForOrderScreenState extends State<ThankYouForOrderScreen> {
  double? width , height;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  navigationPage() async {
    Future.delayed(Duration.zero, () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Widget orderSuccessData(){
    return NoDataContainer(
                image: "empty_order",
                title: UiUtils.getTranslatedLabel(context, thankYouLabel),
                subTitle: UiUtils.getTranslatedLabel(context, forYourOrderSubTitleLabel),
                width: width!,
                height: height!);
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
          : WillPopScope(onWillPop: (){
            navigationPage();
            return Future.value(true);
          },
            child: Scaffold(
              bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.onBackground,
                      child: SizedBox(width: width,
                        child: ButtonContainer(
                                            color: Theme.of(context).colorScheme.secondary,
                                            height: height,
                                            width: width,
                                            text: UiUtils.getTranslatedLabel(context, trackMyOrderLabel),
                                            top: 0,
                                            bottom: 0,
                                            start: width! / 40.0,
                                            end: width! / 40.0,
                                            status: false,
                                            borderColor: Theme.of(context).colorScheme.secondary,
                                            textColor: white,
                                            onPressed: () {
                                              Navigator.of(context)
                                                .pushNamed(Routes.orderDetail, arguments: {
                                                'id': widget.orderId.toString(),
                                                'riderId': "",
                                                'riderName': "",
                                                'riderRating': "",
                                                'riderImage': "",
                                                'riderMobile': "",
                                                'riderNoOfRating': "",
                                                'isSelfPickup': "",
                                                'from': 'orderSuccess'
                                              });
                                            },
                                          ),
                      ),
                    ),
                    Container(
                      color: Theme.of(context).colorScheme.onBackground,
                      width: width,
                      margin: EdgeInsetsDirectional.only(
                          bottom: height! / 50.0, top: height! / 99.0),
                      child: ButtonContainer(
                        color: Theme.of(context).colorScheme.onBackground,
                        height: height,
                        width: width,
                        text: UiUtils.getTranslatedLabel(context, backToHomeLabel),
                        top: 0,
                        bottom: 0,
                        start: width! / 40.0,
                        end: width! / 40.0,
                        status: false,
                        borderColor: Theme.of(context).colorScheme.secondary,
                        textColor: Theme.of(context).colorScheme.secondary,
                        onPressed: () async{
                          navigationPage();
                          },
                      ),
                    ),
                  ],
                ),
                body: SizedBox(
                  // /margin: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 5.0),
                  width: width,
                  child: orderSuccessData(),
                )),
          ),
    );
  }
}
