import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/ui/screen/cart/cart_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/screen/favourite/favourite_screen.dart';
import 'package:erestro/ui/screen/settings/settings_screen.dart';
import 'package:erestro/ui/widgets/customDialog.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:erestro/utils/internetConnectivity.dart';

class AccountScreen extends StatefulWidget {
  final Function? bottomStatus;
  const AccountScreen({Key? key, this.bottomStatus}) : super(key: key);

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> with TickerProviderStateMixin {
  double? width, height;
  var size;
  //final ScrollController _scrollBottomBarController = ScrollController(); // set controller on scrolling
  bool isScrollingDown = false;
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
    //getUserLocation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    //myScroll(_scrollBottomBarController, context);
  }

  bottomStatusUpdate() {
    setState(() {
      widget.bottomStatus!(0);
    });
  }

  circle(Size size, String? image) {
    return Container(
      alignment: Alignment.topCenter,
      margin: EdgeInsetsDirectional.only(top: height! / 99),
      child: CircleAvatar(
        radius: 45,
        backgroundColor: Theme.of(context).colorScheme.onBackground,
        child: Container(
          alignment: Alignment.center,
          child: ClipOval(
              child: image!=""?DesignConfig.imageWidgets(image, 80, 80,"2"):DesignConfig.imageWidgets(
                                  'profile_pic', 80, 80, "1")),
        ),
      ),
    );
  }

  Widget arrowTile({String? title, String? subTitle, VoidCallback? onPressed, String? image}) {
    return InkWell(
      onTap: onPressed,
      child: Row(children: [
        CircleAvatar(
            radius: 18.0,
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            child: image != null && image != ""
                ? SvgPicture.asset(DesignConfig.setSvgPath(image), width: 16.0, height: 16.0, color: Theme.of(context).colorScheme.onBackground)
                : Icon(Icons.power_settings_new, color: Theme.of(context).colorScheme.onBackground)),
        SizedBox(width: width! / 30.0),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title!,
                textAlign: TextAlign.start, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(
              subTitle!,
              textAlign: TextAlign.start,
              style: const TextStyle(color: lightFont, fontSize: 10, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
              maxLines: 2,
            ),
          ]),
        ),
      ]),
    );
  }

  Widget profile() {
    return Container(
        margin: EdgeInsetsDirectional.only(top: height! / 15.0),
        decoration: DesignConfig.boxCurveShadow(Theme.of(context).colorScheme.background),
        width: width,
        height: height!,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsetsDirectional.only(top: height! / 45.0),
                child: BlocBuilder<AuthCubit, AuthState>(
                    bloc: context.read<AuthCubit>(),
                    builder: (context, state) {
                      if (state is Authenticated) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: height! / 20.0),
                              child: Text(state.authModel.username!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 20, fontWeight: FontWeight.w500)),
                            ),
                            SizedBox(height: height! / 99.0),
                            Text(state.authModel.email!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: greayLightColor, fontSize: 12, fontWeight: FontWeight.normal)),
                          ],
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.only(top: height! / 20.0),
                            child: Text(UiUtils.getTranslatedLabel(context, yourProfileLabel),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 20, fontWeight: FontWeight.w500)),
                          ),
                          SizedBox(height: height! / 99.0),
                          Text(UiUtils.getTranslatedLabel(context, loginOrSignUpToViewYourCompleteProfileLabel),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: greayLightColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      );
                    }),
              ),
              SizedBox(height: height! / 40.0),
              Padding(
                padding: EdgeInsetsDirectional.only(top: height! / 80.0, start: width! / 20.0),
                child: Text(UiUtils.getTranslatedLabel(context, profileLabel),
                    textAlign: TextAlign.center, style: const TextStyle(color: greayLightColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                padding: const EdgeInsetsDirectional.all(10.0),
                margin: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0, start: width! / 20.0, end: width! / 20.0),
                child: Column(children: [
                  BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                    return arrowTile(
                      onPressed: () {
                        if (state is AuthInitial || state is Unauthenticated) {
                          //  Navigator.of(context).pushReplacementNamed(Routes.login);
                          Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'profile'}).then((value) {
                            appDataRefresh(context);
                          });
                          return;
                        } else {
                          Navigator.of(context).pushNamed(Routes.profile, arguments: false);
                        }
                      },
                      image: "profile_icon",
                      title: UiUtils.getTranslatedLabel(context, myProfileLabel),
                      subTitle: UiUtils.getTranslatedLabel(context, myProfileSubTitleLabel),
                    );
                  }),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                    child: Divider(
                      color: lightFont.withOpacity(0.50),
                      height: 1.0,
                    ),
                  ),
                  arrowTile(
                    onPressed: () {
                      Navigator.of(context).pushNamed(Routes.notification);
                    },
                    image: "notification",
                    title: UiUtils.getTranslatedLabel(context, notificationLabel),//StringsRes.notification,
                    subTitle: UiUtils.getTranslatedLabel(context, notificationSubTitleLabel), //StringsRes.notificationSubTitle,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                    child: Divider(
                      color: lightFont.withOpacity(0.50),
                      height: 1.0,
                    ),
                  ),
                  arrowTile(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const FavouriteScreen(),
                        ),
                      );
                    },
                    image: "favourite_icon",
                    title: UiUtils.getTranslatedLabel(context, favouriteLabel),
                    subTitle: UiUtils.getTranslatedLabel(context, favouriteSubTitleLabel),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                    child: Divider(
                      color: lightFont.withOpacity(0.50),
                      height: 1.0,
                    ),
                  ),
                  arrowTile(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const CartScreen(from: "account"),
                        ),
                      );
                    },
                    image: "cart_icon",
                    title: UiUtils.getTranslatedLabel(context, cartLabel),
                    subTitle: UiUtils.getTranslatedLabel(context, cartSubTitleLabel),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                    child: Divider(
                      color: lightFont.withOpacity(0.50),
                      height: 1.0,
                    ),
                  ),
                  BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                    return arrowTile(
                      onPressed: () {
                        if (state is AuthInitial || state is Unauthenticated) {
                          //Navigator.of(context).pushReplacementNamed(Routes.login);
                          Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'order'}).then((value) {
                            appDataRefresh(context);
                          });
                          return;
                        } else {
                          Navigator.of(context).pushNamed(Routes.order, arguments: false);
                        }
                      },
                      image: "my_order_icon",
                      title: UiUtils.getTranslatedLabel(context, myOrderLabel),
                      subTitle: UiUtils.getTranslatedLabel(context, myOrderSubTitleLabel),
                    );
                  }),
                ]),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(top: height! / 80.0, start: width! / 20.0),
                child: Text(UiUtils.getTranslatedLabel(context, addressLabel),
                    textAlign: TextAlign.center, style: const TextStyle(color: greayLightColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                  padding: const EdgeInsetsDirectional.all(10.0),
                  margin: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0, start: width! / 20.0, end: width! / 20.0),
                  child: Column(children: [
                    BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                      return arrowTile(
                        onPressed: () {
                          if (state is AuthInitial || state is Unauthenticated) {
                            //Navigator.of(context).pushReplacementNamed(Routes.login);
                            Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'address'}).then((value) {
                              appDataRefresh(context);
                            });
                            return;
                          } else {
                            Navigator.of(context).pushNamed(Routes.deliveryAddress, arguments: false);
                          }
                        },
                        image: "address_icon",
                        title: UiUtils.getTranslatedLabel(context, deliveryLocationLabel),
                        subTitle: UiUtils.getTranslatedLabel(context, deliveryLocationSubTitleLabel),
                      );
                    }),
                  ])),
              Padding(
                padding: EdgeInsetsDirectional.only(top: height! / 80.0, start: width! / 20.0),
                child: Text(UiUtils.getTranslatedLabel(context, settingsLabel),
                    textAlign: TextAlign.center, style: const TextStyle(color: greayLightColor, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                  decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                  padding: const EdgeInsetsDirectional.all(10.0),
                  margin: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0, start: width! / 20.0, end: width! / 20.0),
                  child: Column(children: [
                    arrowTile(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                        
                      },
                      image: "setting_icon",
                      title: UiUtils.getTranslatedLabel(context, settingsLabel),
                      subTitle: UiUtils.getTranslatedLabel(context, settingsSubTitleLabel),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: height! / 80.0),
                      child: Divider(
                        color: lightFont.withOpacity(0.50),
                        height: 1.0,
                      ),
                    ),
                    BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
                      return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
                          ? arrowTile(
                              onPressed: () {
                                Navigator.of(context).pushNamed(Routes.login, arguments: {'from': 'profile'}).then((value) {
                                  appDataRefresh(context);
                                });
                              },
                              image: "",
                              title: UiUtils.getTranslatedLabel(context, loginLabel),
                              subTitle: UiUtils.getTranslatedLabel(context, areYouSureYouWantToLoginLabel),
                            )
                          : arrowTile(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomDialog(
                                          title: UiUtils.getTranslatedLabel(context, logoutLabel),
                                          subtitle: UiUtils.getTranslatedLabel(context, areYouSureYouWantToLogoutLabel),
                                          width: width!,
                                          height: height!,
                                          from: UiUtils.getTranslatedLabel(context, logoutLabel));
                                    });
                              },
                              image: "",
                              title: UiUtils.getTranslatedLabel(context, logoutLabel),
                              subTitle: UiUtils.getTranslatedLabel(context, logoutSubTitleLabel),
                            );
                    }),
                  ])),
              SizedBox(height: height! / 10.0),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    //_scrollBottomBarController.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : Scaffold(
              appBar: AppBar(leadingWidth: width!/8.5,
                leading: GestureDetector(
                  onTap: () {
                          Navigator.pop(context);
                        },
                  child: Padding(
                      padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                      child: CircleAvatar(radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.onBackground,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8.0),
                            child: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary, size: 15.0),
                          ))),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shadowColor: Theme.of(context).colorScheme.onBackground,
                elevation: 0,
                centerTitle: true,
                title: Text(UiUtils.getTranslatedLabel(context, accountLabel),
                    textAlign: TextAlign.center, style: const TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              backgroundColor: Theme.of(context).colorScheme.background,
              body: _connectionStatus == connectivityCheck
                  ? const NoInternetScreen()
                  : Stack(
                      children: [
                        Container(
                          color: Theme.of(context).colorScheme.primary,
                          width: width,
                          height: height!/9.0),
                        profile(),
                        BlocBuilder<AuthCubit, AuthState>(
                            bloc: context.read<AuthCubit>(),
                            builder: (context, state) {
                              if (state is Authenticated) {
                                return circle(size, state.authModel.image!);
                              }
                              return circle(size, "");
                            }),
                      ],
                    ),
            ),
    );
  }
}
