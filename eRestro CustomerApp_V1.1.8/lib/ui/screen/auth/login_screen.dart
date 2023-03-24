import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/auth/referAndEarnCubit.dart';
import 'package:erestro/cubit/auth/socialSignUpCubit.dart';
import 'package:erestro/cubit/cart/manageCartCubit.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/screen/auth/otp_verify_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/screen/settings/no_location_screen.dart';
import 'package:erestro/ui/widgets/buttomContainer.dart';
import 'package:erestro/ui/widgets/buttomWithImageContainer.dart';
import 'package:erestro/ui/widgets/keyboardOverlay.dart';
import 'package:erestro/ui/widgets/locationDialog.dart';
import 'package:erestro/utils/SqliteData.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/utils/string.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:erestro/utils/internetConnectivity.dart';
import 'dart:ui' as ui;

class LoginScreen extends StatefulWidget {
  final String? from;
  const LoginScreen({Key? key, this.from}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
  static Route<LoginScreen> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (_) => LoginScreen(
        from: arguments['from'] as String,
      ),
    );
  }
}

class LoginScreenState extends State<LoginScreen> {
  GlobalKey<ScaffoldState>? scaffoldKey;
  late double width, height;
  TextEditingController phoneNumberController = TextEditingController(text: "");
  TextEditingController passwordController = TextEditingController(text: "");
  String? countryCode = "+91";
  FocusNode numberFocusNode = FocusNode();
  FocusNode numberFocusNodeAndroid = FocusNode();
  bool obscure = true, status = false, iAccept = false;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  var db = DatabaseHelper();
  Random rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  String referCode = "", socialLoginType = "";
  @override
  void initState() {
    super.initState();
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    referCode = getRandomString(8);
    print("from:${widget.from}");
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    scaffoldKey = GlobalKey<ScaffoldState>();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    passwordController.dispose();
    numberFocusNode.dispose();
    numberFocusNodeAndroid.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  locationEnableDialog() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return LocationDialog(width: width, height: height, from: "skip");
        });
  }

  getUserLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      getUserLocation();
    } else if (permission == LocationPermission.denied) {
      print(permission.toString());
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        locationEnableDialog();
        //getUserLocation();
      } else {
        getUserLocation();
      }
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude,
            localeIdentifier: "en");
        String? location =
            "${placemarks[0].name},${placemarks[0].locality},${placemarks[0].postalCode},${placemarks[0].country}";
        if (await Permission.location.serviceStatus.isEnabled) {
          if (mounted) {
            setState(() async {
              if(context.read<SystemConfigCubit>().getDemoMode()=="0"){
                demoModeAddressDefault(context, "0");
              }else{
                
              setAddressForDisplayData(context, "0",placemarks[0].locality.toString(),position.latitude.toString(),position.longitude.toString(),location.toString());}
              if (context
                          .read<SettingsCubit>()
                          .state
                          .settingsModel!
                          .city
                          .toString() !=
                      "" &&
                  context
                          .read<SettingsCubit>()
                          .state
                          .settingsModel!
                          .city
                          .toString() !=
                      "null") {
                if (await Permission.location.serviceStatus.isEnabled) {
                  context.read<SettingsCubit>().changeShowSkip();
                  await Future.delayed(
                      Duration.zero,
                      () => Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.home,
                          (Route<dynamic> route) =>
                              false /* , arguments: {'id': 0} */));
                } else {
                  getUserLocation();
                }
              } else {
                getUserLocation();
              }
            });
          }
        } else {
          if (widget.from == "splash") {
            getUserLocation();
          } else {}
        }
      } catch (e) {
        if (widget.from == "splash") {
          getUserLocation();
        } else {
          context.read<SettingsCubit>().changeShowSkip();
          await Future.delayed(
              Duration.zero,
              () => Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.home,
                  (Route<dynamic> route) =>
                      false /* , arguments: {'id': 0} */));
        }
      }
    }
  }

  Future<void> offCartAdd() async {
    List cartOffList = await db.getOffCart();

    if (cartOffList.isNotEmpty) {
      for (int i = 0; i < cartOffList.length; i++) {
        if (!mounted) return;
        context.read<ManageCartCubit>().manageCartUser(
            userId: context.read<AuthCubit>().getId(),
            productVariantId: cartOffList[i]["VID"],
            isSavedForLater: "0",
            qty: cartOffList[i]["QTY"],
            addOnId: cartOffList[i]["ADDONID"].isNotEmpty
                ? cartOffList[i]["ADDONID"]
                : "",
            addOnQty: cartOffList[i]["ADDONQTY"].isNotEmpty
                ? cartOffList[i]["ADDONQTY"]
                : "");
      }
    }
  }

  navigationPageHome() async {
    if (widget.from == "splash") {
      if (context.read<SettingsCubit>().state.settingsModel!.city.toString() !=
              "" &&
          context.read<SettingsCubit>().state.settingsModel!.city.toString() !=
              "null") {
        await Future.delayed(
            Duration.zero,
            () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home,
                (Route<dynamic> route) => false ));
      } else {
        await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const NoLocationScreen(),
            ),
            (Route<dynamic> route) => false);
      }
    } else if (widget.from == "logout" || widget.from == "delete") {
      await Future.delayed(
          Duration.zero,
          () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home,
              (Route<dynamic> route) => false ));
    } else {
      await Future.delayed(
        const Duration(seconds: 1),
      );
      if (!mounted) return;

      Navigator.of(context).pop();
    }
  }

  Widget socialLogin() {
    return BlocConsumer<ReferAndEarnCubit,
                            ReferAndEarnState>(
                        bloc: context.read<ReferAndEarnCubit>(),
                        listener: (context, state) async {
                          //Exceuting only if authProvider is email
                          if (state is ReferAndEarnFailure) {
                            print(state.errorCode);
                            //UiUtils.setSnackBar(StringsRes.signUp, state.errorCode, context, false, type: "2");
                          }
                          if (state is ReferAndEarnSuccess) {
                            print("success");
                            if(socialLoginType == "apple"){
                              context.read<SocialSignUpCubit>().socialSocialSignUpUser(authProvider: AuthProvider.apple,
                                friendCode: "",
                                referCode: referCode);
                            }else if(socialLoginType == "facebook"){
                              context.read<SocialSignUpCubit>().socialSocialSignUpUser(authProvider: AuthProvider.facebook,
                                  friendCode: "",
                                  referCode: referCode);
                            }else if(socialLoginType == "google"){
                              context.read<SocialSignUpCubit>().socialSocialSignUpUser(authProvider: AuthProvider.google,
                                friendCode: "",
                                referCode: referCode);
                            }
                          }
                        },
                        builder: (context, state) {
                          return BlocConsumer<SocialSignUpCubit, SocialSignUpState>(
                              bloc: context.read<SocialSignUpCubit>(),
                              listener: (context, state) async {
                                //Exceuting only if authProvider is email
                                if (state is SocialSignUpFailure) {
                                  //print(state.errorMessage);
                                  if(state.errorMessage==defaultErrorMessage){}else {
                                    UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, loginLabel),
                                      state.errorMessage, context, false,
                                      type: "2");
                                  }
                                }
                                if (state is SocialSignUpSuccess) {
                                  context
                                      .read<AuthCubit>()
                                      .statusUpdateAuth(state.authModel);
                                  offCartAdd().then((value) {
                                    db.clearCart();
                                    navigationPageHome();
                                  });
                                }
                              },
                              builder: (context, state) {
                                return Column(mainAxisSize: MainAxisSize.min, children: [
                                  Platform.isIOS
                          ? SizedBox(
                              width: width,
                              child: ButtonImageContainer(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  height: height,
                                  width: width,
                                  text: UiUtils.getTranslatedLabel(context, continueWithAppleLabel),
                                  bottom: 0,
                                  start: width / 30.0,
                                  end: height / 50.0,
                                  top: height / 40.0,
                                  status: status,
                                  borderColor: Theme.of(context).colorScheme.onSecondary,
                                  textColor: white,
                                  onPressed: () {
                                    if (iAccept == true) {
                                      context
                                              .read<ReferAndEarnCubit>()
                                              .fetchReferAndEarn(referCode);
                                  status = false;
                                  socialLoginType = "apple";
                                    } else {
                                      UiUtils.setSnackBar(
                                          UiUtils.getTranslatedLabel(context, acceptTermConditionLabel),
                                          StringsRes.pleaseAcceptTermCondition,
                                          context,
                                          false,
                                          type: "2");
                                    }
                                  },
                                  widget: SvgPicture.asset(
                                      DesignConfig.setSvgPath("apple"))),
                            )
                          : const SizedBox(),
                      SizedBox(
                        width: width,
                        child: ButtonImageContainer(
                            color: facebookColor,
                            height: height,
                            width: width,
                            text: UiUtils.getTranslatedLabel(context, continueWithFacebookLabel),
                            bottom: 0,
                            start: width / 30.0,
                            end: height / 50.0,
                            top: height / 40.0,
                            status: status,
                            borderColor: facebookColor,
                            textColor: white,
                            onPressed: () {
                              if (iAccept == true) {
                                context
                                              .read<ReferAndEarnCubit>()
                                              .fetchReferAndEarn(referCode);
                                  status = false;
                                  setState(() {
                                    socialLoginType = "facebook";
                                  });
                              } else {
                                UiUtils.setSnackBar(
                                    UiUtils.getTranslatedLabel(context, acceptTermConditionLabel),
                                    StringsRes.pleaseAcceptTermCondition,
                                    context,
                                    false,
                                    type: "2");
                              }
                            },
                            widget: SvgPicture.asset(
                                DesignConfig.setSvgPath("facebook"))),
                      ),
                      SizedBox(
                        width: width,
                        child: ButtonImageContainer(
                            color: Theme.of(context).colorScheme.error,
                            height: height,
                            width: width,
                            text: UiUtils.getTranslatedLabel(context, continueWithGoogleLabel),
                            bottom: 0,
                            start: width / 30.0,
                            end: height / 50.0,
                            top: height / 40.0,
                            status: status,
                            borderColor: Theme.of(context).colorScheme.error,
                            textColor: white,
                            onPressed: () {
                              if (iAccept == true) {
                                  context
                                              .read<ReferAndEarnCubit>()
                                              .fetchReferAndEarn(referCode);
                                  status = false;
                                  setState(() {
                                    socialLoginType = "google";
                                  });
                              } else {
                                UiUtils.setSnackBar(
                                    UiUtils.getTranslatedLabel(context, acceptTermConditionLabel),
                                    StringsRes.pleaseAcceptTermCondition,
                                    context,
                                    false,
                                    type: "2");
                              }
                            },
                            widget: SvgPicture.asset(
                                DesignConfig.setSvgPath("google"))),
                      ),
                                ]);
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
      ),
      child: _connectionStatus == connectivityCheck
          ? const NoInternetScreen()
          : Scaffold(backgroundColor: Theme.of(context).colorScheme.onBackground,
              key: scaffoldKey,
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: greayLightColor,
                      ),
                      child: Checkbox(
                          value: iAccept,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (val) {
                            setState(() {
                              iAccept = val!;
                            });
                          },
                          checkColor: Theme.of(context).colorScheme.onBackground,
                          visualDensity:
                              const VisualDensity(horizontal: 0, vertical: -4)),
                    ),
                    Text(
                      UiUtils.getTranslatedLabel(context, byClickingYouAgreeToOurLabel),
                      style: const TextStyle(
                          color: greayLightColor, fontSize: 12.0),
                      textAlign: TextAlign.center,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.appSettings,
                            arguments: termsAndConditionsKey);
                      },
                      child: Text(
                        "  ${UiUtils.getTranslatedLabel(context, termAndConditionLabel)}",
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      " ${UiUtils.getTranslatedLabel(context, andLabel)} ",
                      style: const TextStyle(
                          color: greayLightColor,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.appSettings,
                            arguments: privacyPolicyKey);
                      },
                      child: Text(
                        UiUtils.getTranslatedLabel(context, privacyPolicyLabel),
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              body: CustomScrollView(physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                slivers: [
                  SliverAppBar(
                      expandedHeight: height / 3.2,
                      shadowColor: Colors.transparent,
                      backgroundColor: Theme.of(context).colorScheme.onBackground,
                      systemOverlayStyle: SystemUiOverlayStyle.light,
                      automaticallyImplyLeading: false,
                      iconTheme: IconThemeData(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      floating: false,
                      pinned: true,
                      title: Text(UiUtils.getTranslatedLabel(context, loginLabel),
                          style: const TextStyle(
                              fontSize: 18.0,
                              color: white,
                              fontWeight: FontWeight.w500)),
                      actions: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                              end: width / 20.0,
                              bottom: height / 80.0,
                              top: height / 80.0),
                          child: InkWell(
                            onTap: () {
                              getUserLocation();
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5.0),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  width: 42,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(5)),
                                      color: const Color(0xff000000)
                                          .withOpacity(0.50)),
                                  child: Center(
                                    child: Text(
                                      UiUtils.getTranslatedLabel(context, skipLabel),
                                      style: const TextStyle(
                                          color: white,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                      //automaticallyImplyLeading: _isVisible,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: false,
                        background: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0),
                          ),
                          child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    shaderColor,
                                    black
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.darken,
                              child: DesignConfig.imageWidgets(
                                  'login_banner', height / 3.2, width, "1")),
                        ),
                      )),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      //SvgPicture.asset(DesignConfig.setSvgPath("logo_white")),
                      SizedBox(height: height / 20.0),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: width / 20.0, end: height / 40.0),
                        child: Align(alignment: Alignment.topLeft,
                          child: Text(
                            UiUtils.getTranslatedLabel(context, weWillSendAVerificationCodeToThisNumberLabel),
                            style: const TextStyle(
                                decoration: TextDecoration.none,
                                color: greayLightColor,
                                fontSize: 14.0,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      SizedBox(height: height / 40.0),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: width / 20.0, end: height / 40.0),
                        child: IntlPhoneField(
                          controller: phoneNumberController,
                          textInputAction: TextInputAction.done,
                          dropdownIcon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                            contentPadding:
                                const EdgeInsets.only(top: 15, bottom: 15),
                            focusedBorder: DesignConfig.outlineInputBorder(
                                Theme.of(context).colorScheme.onBackground, 10.0),
                            focusedErrorBorder: DesignConfig.outlineInputBorder(
                                Theme.of(context).colorScheme.onBackground, 10.0),
                            errorBorder: DesignConfig.outlineInputBorder(
                                Theme.of(context).colorScheme.onBackground, 10.0),
                            enabledBorder: DesignConfig.outlineInputBorder(
                                Theme.of(context).colorScheme.onBackground, 10.0),
                            focusColor: white,
                            counterStyle: const TextStyle(
                                color: white, fontSize: 0),
                            border: InputBorder.none,
                            hintText: UiUtils.getTranslatedLabel(context, enterPhoneNumberLabel),
                            labelStyle: const TextStyle(
                              color: lightFont,
                              fontSize: 17.0,
                            ),
                            hintStyle: const TextStyle(
                              color: black,
                              fontSize: 17.0,
                            ),
                            //contentPadding: EdgeInsets.zero,
                          ),
                          flagsButtonMargin: EdgeInsets.all(width / 40.0),
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          focusNode: Platform.isIOS?numberFocusNode:numberFocusNodeAndroid,
                          dropdownIconPosition: IconPosition.trailing,
                          initialCountryCode: 'IN',
                          style: const TextStyle(
                            color: black,
                            fontSize: 17.0,
                          ),
                          textAlign:
                              Directionality.of(context) == ui.TextDirection.rtl
                                  ? TextAlign.right
                                  : TextAlign.left,
                          onChanged: (phone) {
                            setState(() {
                              //print(phone.completeNumber);
                              countryCode = phone.countryCode;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: ButtonContainer(
                          color: Theme.of(context).colorScheme.primary,
                          height: height,
                          width: width,
                          text: UiUtils.getTranslatedLabel(context, loginLabel),
                          bottom: height / 40.0,
                          start: width / 30.0,
                          end: height / 50.0,
                          top: height / 80.0,
                          status: status,
                          borderColor: Theme.of(context).colorScheme.primary,
                          textColor: white,
                          onPressed: () {
                            if (iAccept == true) {
                              /*if (phoneNumberController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                                        context.read<SignInCubit>().signInUser(mobile: phoneNumberController.text, password: passwordController.text);
                                        status = true;
                                      } else {*/
                              if (phoneNumberController.text.isEmpty) {
                                UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, phoneNumberLabel),
                                    UiUtils.getTranslatedLabel(context, enterPhoneNumberLabel), context, false,
                                    type: "2");
                                status = false;
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        OtpVerifyScreen(
                                      mobileNumber: phoneNumberController.text,
                                      countryCode: countryCode,
                                      from: widget.from,
                                    ),
                                  ),
                                );
                                status = false;
                              }
                              /*}*/
                            } else {
                              UiUtils.setSnackBar(
                                  UiUtils.getTranslatedLabel(context, acceptTermConditionLabel),
                                  StringsRes.pleaseAcceptTermCondition,
                                  context,
                                  false,
                                  type: "2");
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: width / 20.0, end: width / 20.0),
                        child: Row(children: [
                          Expanded(child: DesignConfig.divider()),
                          SizedBox(width: width / 40.0),
                          Text(
                            UiUtils.getTranslatedLabel(context, orLabel),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          SizedBox(width: width / 40.0),
                          Expanded(child: DesignConfig.divider()),
                        ]),
                      ),
                      socialLogin(),
                    ]),
                  ),
                ],
              )),
    );
  }
}
