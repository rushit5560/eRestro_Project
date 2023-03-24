import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/address/addressCubit.dart';
import 'package:erestro/cubit/address/cityDeliverableCubit.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/cart/getCartCubit.dart';
import 'package:erestro/cubit/favourite/favouriteProductsCubit.dart';
import 'package:erestro/cubit/favourite/favouriteRestaurantCubit.dart';
import 'package:erestro/cubit/home/restaurants/restaurantCubit.dart';
import 'package:erestro/cubit/home/restaurants/topRestaurantCubit.dart';
import 'package:erestro/cubit/home/sections/sectionsCubit.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/screen/cart/cart_screen.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

const String appName = "YOUR_APP_NAME";
const String packageName = "YOUR_ANDROID_PACKAGE_NAME";
const String androidLink = 'https://play.google.com/store/apps/details?id=';

const String iosPackage = 'YOUR_IOS_PACKAGE_NAME';
const String iosLink = 'https://apps.apple.com/id';
const String iosAppId = 'YOUR_IOS_APP_ID';

//Database related constants

//Add your database url
//make sure add '/app/v1/api/' at the end of baseurl

// const String databaseUrl = 'YOUR_DATABASE_URL';
const String databaseUrl = 'https://erestro.omdemo.co.in';
const String baseUrl = '$databaseUrl/app/v1/api/';
const String perPage = "10";

const String googleAPiKeyAndroid = "YOUR_ANDROID_MAP_API_KEY";
const String googleAPiKeyIos = "YOUR_IOS_MAP_API_KEY";
const String placeSearchApiKey = "YOUR_PLACE_SEARCH_API_KEY";

const String defaultErrorMessage = "Something went wrong!!";
const String connectivityCheck = "ConnectivityResult.none";
const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

//by default language of the app
const String defaultLanguageCode = "en";

getUserLocation() async {
  LocationPermission permission;

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openLocationSettings();

    getUserLocation();
  } else if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      await Geolocator.openLocationSettings();

      getUserLocation();
    } else {
      getUserLocation();
    }
  } else {}
}

appDataRefresh(BuildContext context) async {
  Future.delayed(Duration.zero, () async {
    await context
        .read<FavoriteRestaurantsCubit>()
        .getFavoriteRestaurants(context.read<AuthCubit>().getId(), partnersKey);
  });
  Future.delayed(Duration.zero, () async {
    await context
        .read<FavoriteProductsCubit>()
        .getFavoriteProducts(context.read<AuthCubit>().getId(), productsKey);
  });
  Future.delayed(Duration.zero, () async {
    context
        .read<SystemConfigCubit>()
        .getSystemConfig(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    await context.read<RestaurantCubit>().fetchRestaurant(
        perPage,
        "0",
        context.read<CityDeliverableCubit>().getCityId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<AuthCubit>().getId(),
        "");
  });
  Future.delayed(Duration.zero, () async {
    await context.read<TopRestaurantCubit>().fetchTopRestaurant(
        perPage,
        "1",
        context.read<CityDeliverableCubit>().getCityId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<AuthCubit>().getId(),
        "");
  });
  Future.delayed(Duration.zero, () async {
    await context.read<SectionsCubit>().fetchSections(
        perPage,
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<CityDeliverableCubit>().getCityId(),
        "");
  });

  Future.delayed(Duration.zero, () async {
    await context
        .read<GetCartCubit>()
        .getCartUser(userId: context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    await context
        .read<AddressCubit>()
        .fetchAddress(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    await context
        .read<SystemConfigCubit>()
        .getSystemConfig(context.read<AuthCubit>().getId());
  });
  Future.delayed(Duration.zero, () async {
    context
        .read<AddressCubit>()
        .fetchAddress(context.read<AuthCubit>().getId());
  });
}

//Clear OfflineCart Data
clearOffLineCart(BuildContext context) {
  context.read<SettingsCubit>().setCartCount("0");
  context.read<SettingsCubit>().setCartTotal("0");
  context.read<SettingsCubit>().setRestaurantId("");
}

//Predefined reason of order cancel
List<String> reasonList = [
  "Delay in delivery",
  "Order by mistake",
  "Other",
];

//When jwt key expire reLogin
reLogin(BuildContext context) {
  if (context.read<AuthCubit>().getType() == "google") {
    context.read<AuthCubit>().signOut(AuthProvider.google);
  } else if (context.read<AuthCubit>().getType() == "facebook") {
    context.read<AuthCubit>().signOut(AuthProvider.facebook);
  } else {
    context.read<AuthCubit>().signOut(AuthProvider.apple);
  }
  Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login, (Route<dynamic> route) => false,
      arguments: {'from': 'logout'});
}

/* //Globle bottombar hide show
myScroll(ScrollController scrollController, BuildContext context) async {
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (!context.read<NavigationBarCubit>().animationController.isAnimating) {
          context.read<NavigationBarCubit>().animationController.forward();
        }
      }
      if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!context.read<NavigationBarCubit>().animationController.isAnimating) {
          context.read<NavigationBarCubit>().animationController.reverse();
        }
      }
    });
  }

  //Globle bottombar reverse show
  myScrollRevers(ScrollController scrollController, BuildContext context) async {
    if (!context.read<NavigationBarCubit>().animationController.isAnimating) {
      context.read<NavigationBarCubit>().animationController.reverse();
    }
  } */

clearAll() {
  /*finalTotal = 0;
    subTotal = 0;*/
  taxPercentage = 0;
  deliveryCharge = 0;
  deliveryTip = 0;
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

bool getStoreOpenStatus(String openTime, String closeTime) {
  bool result = false;

  DateTime now = DateTime.now();
  int nowHour = now.hour;
  int nowMin = now.minute;

  print('Now: H$nowHour M$nowMin $now');

  var openTimes = openTime.split(":");
  int openHour = int.parse(openTimes[0]);
  int openMin = int.parse(openTimes[1]);

  print('OpenTimes: H$openHour M$openMin $openTime');

  var closeTimes = closeTime.split(":");
  int closeHour = int.parse(closeTimes[0]);
  int closeMin = int.parse(closeTimes[1]);

  print('CloseTimes: H$closeHour M$closeMin $closeTime');

  if (nowHour >= openHour && nowHour <= closeHour) {
    if (nowMin > openMin && nowMin < closeMin) result = true;
  }

  print('time: $result');

  return result;
}

demoModeAddressDefault(BuildContext context, String ifDelivery) {
  if (ifDelivery == "1") {
    context.read<CityDeliverableCubit>().fetchCityDeliverable("bhuj");
  }
  context.read<SettingsCubit>().setCity("bhuj");
  context.read<SettingsCubit>().setLatitude("23.230141065546604");
  context.read<SettingsCubit>().setLongitude("69.6622062844058");
  context.read<SettingsCubit>().setAddress("Bhuj, 370001");
}

setAddressForDisplayData(BuildContext context, String ifDelivery, String city, String latitude, String longitude, String address) {
  if (ifDelivery == "1") {
    context.read<CityDeliverableCubit>().fetchCityDeliverable(city.toString());
  }
  context.read<SettingsCubit>().setCity(city.toString());
  context.read<SettingsCubit>().setLatitude(latitude.toString());
  context.read<SettingsCubit>().setLongitude(longitude.toString());
  context.read<SettingsCubit>().setAddress(address.toString());
}

