import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/screen/settings/no_location_screen.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:erestro/ui/styles/color.dart';

import 'package:erestro/utils/internetConnectivity.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  late double width, height;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  @override
  initState() {
    CheckInternet.initConnectivity().then((value) => setState(() {
          _connectionStatus = value;
        }));
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      CheckInternet.updateConnectionStatus(result).then((value) => setState(() {
            _connectionStatus = value;
          }));
    });
    /*Future.delayed(Duration.zero, () {
      if (context.read<AuthCubit>().state is Authenticated) {
        context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
      } else {*/

      /* if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" && context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
        } else {
              context
                  .read<SettingsCubit>()
                  .setCity("bhuj");
              context
                  .read<SettingsCubit>()
                  .setLatitude("23.230141065546604");
              context
                  .read<SettingsCubit>()
                  .setLongitude("69.6622062844058");
                  context.read<SettingsCubit>().setAddress("Bhuj, 370001");
            
        } */
    /* Future.delayed(const Duration(seconds: 2), () {
      navigateToNextScreen();
    }); */
    /*}
    });*/
    context
            .read<SystemConfigCubit>()
            .getSystemConfig(context.read<AuthCubit>().getId());
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    super.initState();
  }

  void navigateToNextScreen() async {
    //Reading from settingsCubit means we are just reading current value of settingsCubit
    //if settingsCubit will change in future it will not rebuild it's child
    final currentSettings = context.read<SettingsCubit>().state.settingsModel;
    final currentAuthState = context.read<AuthCubit>().state;
    if (currentSettings!.showIntroSlider) {
      Navigator.of(context).pushReplacementNamed(Routes.introSlider);
    } else {
      if (currentSettings.skip) {
        Navigator.of(context).pushReplacementNamed(Routes.login, arguments: {'from': "splash"});
      } else {
        if (currentSettings.city.toString() != "" && currentSettings.city.toString() != "null") {
          Navigator.of(context).pushReplacementNamed(Routes.home/* , arguments: {'id': 0} */);
        } else {
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const NoLocationScreen(),
            ),
            (Route<dynamic> route) => false);
            
        }
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
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
            : BlocConsumer<SystemConfigCubit, SystemConfigState>(
              bloc: context.read<SystemConfigCubit>(),
              listener: (context, state) {
                print("systemSetting:${state.toString()}");
                if (state is SystemConfigFetchSuccess) {
                  //if animation is running then navigate to next screen
                  //after animation completed
                  //print("Success");
                  //navigateToNextScreen();
                  //Future.delayed(const Duration(seconds: 2), () {
                    navigateToNextScreen();
                  //});
                }
                if (state is SystemConfigFetchFailure) {
                  print(state.errorCode);
                  //animationController.stop();
                }
              },
              builder: (context, state) {
                Widget child = const Center(
                  key: Key("splashAnimation"),
                  //child: _buildSplashAnimation(),
                );
                if (state is SystemConfigFetchFailure) {
                  child = Center(
                    key: const Key("errorContainer"),
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                  );
                }

                return
            Scaffold(
                backgroundColor: splasBackgroundColor,
                bottomNavigationBar: Container(
                  height: height / 9.0,
                  //color: splasBackgroundColor,
                  alignment: Alignment.center,
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(UiUtils.getTranslatedLabel(context, madeByLabel), style: const TextStyle(color: lightFontColor, fontSize: 10.0, fontWeight: FontWeight.w800)),
                      SizedBox(height: height / 60.0),
                      SvgPicture.asset(DesignConfig.setSvgPath("made_by")),
                    ],
                  ) //Container(),
                      ),
                ),
                body: Container(
                  //color: splasBackgroundColor,
                  alignment: Alignment.center,
                  child: Center(
                    child: SvgPicture.asset(DesignConfig.setSvgPath("logo_red")),
                  ),
                )) ;
              }),
        );
  }
}
