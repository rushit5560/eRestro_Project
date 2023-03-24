import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/address/addressCubit.dart';
import 'package:erestro/cubit/address/cityDeliverableCubit.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/cart/getCartCubit.dart';
import 'package:erestro/cubit/favourite/favouriteProductsCubit.dart';
import 'package:erestro/cubit/favourite/favouriteRestaurantCubit.dart';
import 'package:erestro/cubit/home/bestOffer/bestOfferCubit.dart';
import 'package:erestro/cubit/home/cuisine/cuisineCubit.dart';
import 'package:erestro/cubit/home/restaurants/restaurantCubit.dart';
import 'package:erestro/cubit/home/restaurants/topRestaurantCubit.dart';
import 'package:erestro/cubit/home/slider/sliderOfferCubit.dart';
import 'package:erestro/data/model/addressModel.dart';
import 'package:erestro/data/model/cuisineModel.dart';
import 'package:erestro/data/model/restaurantModel.dart';
import 'package:erestro/cubit/home/sections/sectionsCubit.dart';
import 'package:erestro/data/model/sectionsModel.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/screen/cart/cart_screen.dart';
import 'package:erestro/ui/widgets/offerImageContainer.dart';
import 'package:erestro/ui/widgets/productUnavailableDialog.dart';
import 'package:erestro/ui/widgets/searchBarContainer.dart';
import 'package:erestro/ui/widgets/topBrandContainer.dart';
import 'package:erestro/ui/widgets/voiceSearchContainer.dart';
import 'package:erestro/utils/SqliteData.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/ui/screen/auth/login_screen.dart';
import 'package:erestro/ui/screen/home/topBrand/top_brand_screen.dart';
import 'package:erestro/ui/screen/settings/maintenance_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/widgets/bottomSheetContainer.dart';
import 'package:erestro/ui/widgets/simmer/cuicineSimmer.dart';
import 'package:erestro/ui/widgets/cuisineContainer.dart';
import 'package:erestro/ui/widgets/forceUpdateDialog.dart';
import 'package:erestro/ui/widgets/simmer/homeSimmer.dart';
import 'package:erestro/ui/widgets/locationDialog.dart';
import 'package:erestro/ui/widgets/productContainer.dart';
import 'package:erestro/ui/widgets/restaurantCloseDialog.dart';
import 'package:erestro/ui/widgets/restaurantContainer.dart';
import 'package:erestro/ui/widgets/simmer/restaurantNearBySimmer.dart';
import 'package:erestro/ui/widgets/simmer/sectionSimmer.dart';
import 'package:erestro/ui/widgets/simmer/sliderSimmer.dart';
import 'package:erestro/ui/widgets/simmer/topBrandSimmer.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/notificationUtility.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:erestro/utils/internetConnectivity.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:erestro/utils/hiveBoxKey.dart';
import '../settings/no_location_screen.dart';

class HomeScreen extends StatefulWidget {
  //final AnimationController animationController;
  const HomeScreen({Key? key /* , required this.animationController */}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

List<Map<String, dynamic>> searchAddressData = [];

final searchAddressBoxData = Hive.box(searchAddressBox);

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  //TextEditingController searchController = TextEditingController(text: "");
  TextEditingController locationSearchController = TextEditingController(text: "");
  TextEditingController enableLocationController = TextEditingController(text: "");
  String searchText = '';
  double? width, height;
  final PageController _pageController = PageController(
    initialPage: 0,
  );
  int _currentPage = 0;
  ScrollController restaurantController = ScrollController();
  ScrollController topRestaurantController = ScrollController();
  ScrollController cuisineController = ScrollController();
  final ScrollController _scrollBottomBarController = ScrollController(); // set controller on scrolling
  ScrollController sectionController = ScrollController();
  bool isScrollingDown = false;
  final bool _show = true;
  double bottomBarHeight = 75; // set bottom bar height
  final Geolocator geolocator = Geolocator();
  Position? _currentPosition;
  String? currentAddress = "";
  String showMessage = "";
  List<String> variance = [];
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<RestaurantModel> restaurantList = [];
  List<RestaurantModel> topRestaurantList = [];
  List<ProductDetails> productList = [];
  List<CuisineModel> cuisineList = [];
  RegExp regex = RegExp(r'([^\d]00)(?=[^\d]|$)');
  bool? showBottom = false;
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  var db = DatabaseHelper();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

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
    apiCall();
    if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" &&
        context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
      locationDialog();
    } else {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) => const NoLocationScreen(),
            ),
            (Route<dynamic> route) => false);
      });
    }
    //_initLocalNotification();
    //getUserLocation();
    //setupInteractedMessage();
    //myScroll();

    //Check for Force Update
    _initPackageInfo().then((value) {
      forceUpdateDialog();
    });

    //Check if Currently in Maintenance or Not
    print("MiantanaceMode:${context.read<SystemConfigCubit>().getDemoMode()}");
    isMaintenance();

    //Check User Active Deactive Status
    userStatus();

    //search Address Data Load
    loadSearchAddressData();

    final pushNotificationService = NotificationUtility(context: context);
    pushNotificationService.initLocalNotification();
    pushNotificationService.setupInteractedMessage();

  }

  apiCall() {
    Future.delayed(Duration.zero, () {
      if (context.read<AuthCubit>().state is AuthInitial ||
        context.read<AuthCubit>().state is Unauthenticated) {}else{
          context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
        }
      //context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
      if (context.read<SystemConfigCubit>().state is! SystemConfigFetchSuccess) {
        context.read<SystemConfigCubit>().getSystemConfig(context.read<AuthCubit>().getId());
      }
    });
    context.read<SliderCubit>().fetchSlider();
    if (context.read<AuthCubit>().state is AuthInitial ||
        context.read<AuthCubit>().state is Unauthenticated) {}else{
      context
          .read<GetCartCubit>()
          .getCartUser(userId: context.read<AuthCubit>().getId());
    }
    //context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId());
    //context.read<CuisineCubit>().fetchCuisine(perPage, popularCategoriesKey, "");
    context.read<CuisineCubit>().fetchCuisine(perPage, "", "");
    //context.read<BestOfferCubit>().fetchBestOffer();
    if (context.read<AuthCubit>().state is AuthInitial ||
        context.read<AuthCubit>().state is Unauthenticated) {}else{
      Future.delayed(Duration.zero, () async {
      if (mounted) {
        context.read<FavoriteRestaurantsCubit>().getFavoriteRestaurants(context.read<AuthCubit>().getId(), partnersKey);
        context.read<FavoriteProductsCubit>().getFavoriteProducts(context.read<AuthCubit>().getId(), productsKey);
      }
    });
    }
    /* Future.delayed(Duration.zero, () async {
      if (mounted) {
        context.read<FavoriteRestaurantsCubit>().getFavoriteRestaurants(context.read<AuthCubit>().getId(), partnersKey);
        context.read<FavoriteProductsCubit>().getFavoriteProducts(context.read<AuthCubit>().getId(), productsKey);
      }
    }); */
  }

// Get all items from the database
  void loadSearchAddressData() {
    final data = searchAddressBoxData.keys.map((key) {
      final value = searchAddressBoxData.get(key);
      return {"key": key, "city": value["city"], "latitude": value['latitude'], "longitude": value['longitude'], "address": value['address']};
    }).toList();

    setState(() {
      searchAddressData = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
    print(searchAddressData.length);
  }

  // add Search Address in Database
  Future<void> addSearchAddress(Map<String, dynamic> newItem) async {
    await searchAddressBoxData.add(newItem);
    loadSearchAddressData(); // update the UI
  }

  // Retrieve a single item from the database by using its key
  // Our app won't use this function but I put it here for your reference
  Map<String, dynamic> getSearchAddress(int key) {
    final item = searchAddressBoxData.get(key);
    return item;
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  isMaintenance() {
    if (context.read<SystemConfigCubit>().isAppMaintenance() == "1") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const MaintenanceScreen(),
        ),
      );
    } else {}
  }

  userStatus() {
    if (context.read<AuthCubit>().getActive() == "0") {
      Future.delayed(Duration.zero, () {
        userActiveStatus(context);
      });
    } else {}
  }

  forceUpdateDialog() async {
    if (context.read<SystemConfigCubit>().isForceUpdateEnable() == "1") {
      if (Platform.isIOS) {
        if (context.read<SystemConfigCubit>().getCurrentVersionIos() == _packageInfo.version) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return ForceUpdateDialog(width: width!, height: height!);
              });
        }
      } else {
        if (context.read<SystemConfigCubit>().getCurrentVersionAndroid() == _packageInfo.version) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return ForceUpdateDialog(width: width!, height: height!);
              });
        }
      }
    } else {}
  }

  locationDialog() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      // Use location.
      getUserLocation();
    } else {
      // Use location.
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: DesignConfig.setRounded(25.0),
              backgroundColor: Colors.transparent,
              child: contentBox(context),
            );
          });
    }
  }

  Future userActiveStatus(BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(UiUtils.getTranslatedLabel(context, userNotActiveLabel),
              textAlign: TextAlign.start,
              maxLines: 2,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Text(UiUtils.getTranslatedLabel(context, okLabel), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
              onPressed: () {
                if (context.read<AuthCubit>().getType() == "google") {
                  context.read<AuthCubit>().signOut(AuthProvider.google);
                } else if (context.read<AuthCubit>().getType() == "facebook") {
                  context.read<AuthCubit>().signOut(AuthProvider.facebook);
                } else {
                  context.read<AuthCubit>().signOut(AuthProvider.apple);
                }
                Navigator.of(context)
                    .pushAndRemoveUntil(CupertinoPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
              },
            )
          ],
        );
      },
    );
  }

  locationEnableDialog() async {
    if (context.read<SettingsCubit>().state.settingsModel!.city.toString() == "" &&
        context.read<SettingsCubit>().state.settingsModel!.city.toString() == "null") {
      // Use location.
      getUserLocation();
    } else {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return LocationDialog(width: width, height: height);
          }).whenComplete(() async {
        if (context.read<SettingsCubit>().state.settingsModel!.city.toString().isNotEmpty) {
          await context.read<CityDeliverableCubit>().fetchCityDeliverable(context.read<SettingsCubit>().state.settingsModel!.city.toString());
        }
      });
    }
  }

  getUserLocation() async {
    /* LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      getUserLocation();
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        locationEnableDialog();
        //await Geolocator.openLocationSettings();
        //getUserLocation();
      } else {
        getUserLocation();
      }
    } else { */
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        //print("heading---${position.heading}");

        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: "en");
        // print(placemarks[0]);

        String? address =
            "${placemarks[0].name},${placemarks[0].thoroughfare},${placemarks[0].locality},${placemarks[0].postalCode},${placemarks[0].country}";

        String? location = "${placemarks[0].name},${placemarks[0].locality},${placemarks[0].postalCode},${placemarks[0].country}";

        if (await Permission.location.serviceStatus.isEnabled) {
          if (mounted) {
            setState(() async {
              if (placemarks[0].subLocality == "" || placemarks[0].subLocality!.isEmpty) {
                currentAddress = "${placemarks[0].locality}";
              } else {
                currentAddress = "${placemarks[0].subLocality}, ${placemarks[0].locality}";
              }
              if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                demoModeAddressDefault(context, "0");
              } else {
                setAddressForDisplayData(context, "0", placemarks[0].locality.toString(), position.latitude.toString(), position.longitude.toString(),
                    location.toString());
              }

              if (searchAddressData.isNotEmpty) {
              } else {
                if (searchAddressData.contains(location.toString())) {
                } else {
                  addSearchAddress({
                    "city": placemarks[0].locality.toString(),
                    "latitude": position.latitude.toString(),
                    "longitude": position.longitude.toString(),
                    "address": location.toString()
                  });
                }
              }
              if (context.read<SettingsCubit>().state.settingsModel!.city.toString() != "" &&
                  context.read<SettingsCubit>().state.settingsModel!.city.toString() != "null") {
                if (await Permission.location.serviceStatus.isEnabled) {
                  if (mounted) {
                    if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                      context.read<CityDeliverableCubit>().fetchCityDeliverable("Bhuj");
                    }else{
                      context.read<CityDeliverableCubit>().fetchCityDeliverable(placemarks[0].locality);
                    }
                  }
                } else {
                  if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                      context.read<CityDeliverableCubit>().fetchCityDeliverable("Bhuj");
                    }else{
                  context.read<CityDeliverableCubit>().fetchCityDeliverable(context.read<SettingsCubit>().state.settingsModel!.city.toString());
                    }
                }
              } else {
                getUserLocation();
              }
            });
          }
        } else {
          setState(() {
            if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                      context.read<CityDeliverableCubit>().fetchCityDeliverable("Bhuj");
                    }else{
            context.read<CityDeliverableCubit>().fetchCityDeliverable(context.read<SettingsCubit>().state.settingsModel!.city.toString());
                    }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                      context.read<CityDeliverableCubit>().fetchCityDeliverable("Bhuj");
                    }else{
            context.read<CityDeliverableCubit>().fetchCityDeliverable(context.read<SettingsCubit>().state.settingsModel!.city.toString());
                    }
            print(context.read<SettingsCubit>().state.settingsModel!.address.toString());
          });
        }
      }
      //print("curadd-$address");
    /* } */
  }

  

  /* restaurantScrollListener() {
    if (restaurantController.position.maxScrollExtent == restaurantController.offset) {
      if (context.read<RestaurantCubit>().hasMoreData()) {
        context.read<RestaurantCubit>().fetchMoreRestaurantData(
            perPage,
            "0",
            context.read<CityDeliverableCubit>().getCityId(),
            context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
            context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
            context.read<AuthCubit>().getId(),
            "");
      }
    }
  }

  topRestaurantScrollListener() {
    if (topRestaurantController.position.maxScrollExtent == topRestaurantController.offset) {
      if (context.read<TopRestaurantCubit>().hasMoreData()) {
        context.read<TopRestaurantCubit>().fetchMoreTopRestaurantData(
            perPage,
            "1",
            context.read<CityDeliverableCubit>().getCityId(),
            context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
            context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
            context.read<AuthCubit>().getId(),
            "");
      }
    }
  }

  cuisineScrollListener() {
    if (cuisineController.position.maxScrollExtent == cuisineController.offset) {
      if (context.read<CuisineCubit>().hasMoreData()) {
        context.read<CuisineCubit>().fetchMoreCuisineData(perPage, categoryKey);
      }
    }
  } */

  /* void myScroll() async {
    _scrollBottomBarController.addListener(() {
      if (_scrollBottomBarController.position.userScrollDirection == ScrollDirection.reverse) {
        if (!context.read<NavigationBarCubit>().animationController.isAnimating) {
          context.read<NavigationBarCubit>().animationController.forward();
          setState(() {
            _show = false;
          });
        }
      }
      if (_scrollBottomBarController.position.userScrollDirection == ScrollDirection.forward) {
        if (!context.read<NavigationBarCubit>().animationController.isAnimating) {
          context.read<NavigationBarCubit>().animationController.reverse();
          setState(() {
            _show = true;
          });
        }
      }
    });
  } */

  Widget deliveryLocation() {
    return SizedBox(
      height: height! / 20.0,
      child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 3.0),
          child: Text(
            context.read<SettingsCubit>().state.settingsModel!.city.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: height! / 99.0),
        Expanded(
          child: SizedBox(
            width: width! / 1.5,
            child: Text(
              context.read<SettingsCubit>().state.settingsModel!.address.toString(),
              style: const TextStyle(color: lightFont, fontSize: 12, overflow: TextOverflow.ellipsis),
              maxLines: 1,
            ),
          ),
        )
      ]),
    );
  }

  placesAutoCompleteTextField() {
    return Container(
      margin: EdgeInsets.only(top: height! / 25.0, bottom: height! / 45.0),
      decoration: DesignConfig.boxDecorationContainerBorder(lightFont, textFieldBackground, 10.0),
      child: GooglePlaceAutoCompleteTextField(
          textEditingController: locationSearchController,
          googleAPIKey: placeSearchApiKey,
          inputDecoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: height! / 55.0),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              hintText: UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
              hintStyle: const TextStyle(fontSize: 12.0, color: lightFont)),
          debounceTime: 600,
          //countries: ["in", "fr"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (p) async {
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                }
              });
            }
          },
          itmClick: (p) async {
            locationSearchController.text = p.description!;
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                }
                addSearchAddress({
                  "city": localities.join("").toString(),
                  "latitude": detail.result.geometry!.location.lat.toString(),
                  "longitude": detail.result.geometry!.location.lng.toString(),
                  "address": detail.result.formattedAddress!.toString()
                }).then((value) => Navigator.pop(context));
              });
            }
            locationSearchController.selection = TextSelection.fromPosition(TextPosition(offset: p.description!.length));
            locationSearchController.clear();
          },
          textStyle: const TextStyle(color: black, fontSize: 15, fontWeight: FontWeight.w400)),
    );
  }

  bottomModelSheetShowLocation() {
    showModalBottomSheet(
        isDismissible: false,
        backgroundColor: Colors.transparent,
        shape: DesignConfig.setRoundedBorderCard(20.0, 0.0, 20.0, 0.0),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                  height: (MediaQuery.of(context).size.height) / 1.14,
                  padding: EdgeInsets.only(top: height! / 15.0),
                  child: Container(
                    decoration: DesignConfig.boxDecorationContainerRoundHalf(Theme.of(context).colorScheme.onBackground, 25, 0, 25, 0),
                    child: Container(
                      padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0, top: height! / 25.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              UiUtils.getTranslatedLabel(context, selectALocationLabel),
                              style: TextStyle(fontSize: 28, color: Theme.of(context).colorScheme.onSecondary),
                            ),
                            //locationSearchBar(),
                            placesAutoCompleteTextField(),
                            ListTile(
                              visualDensity: const VisualDensity(vertical: -4),
                              minLeadingWidth: 0,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                              trailing: Icon(Icons.arrow_forward_ios_outlined, color: Theme.of(context).colorScheme.onSecondary, size: 18.0),
                              title: Text(UiUtils.getTranslatedLabel(context, useCurrentLocationLabel),
                                  style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding: const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  currentAddress.toString(),
                                  style: const TextStyle(fontSize: 12, color: lightFontColor),
                                ),
                              ),
                              onTap: () async {
                                if (await Permission.location.serviceStatus.isEnabled) {
                                  Navigator.pop(context);
                                  Navigator.of(context).pushNamed(Routes.address, arguments: {'from': 'change', 'addressModel': AddressModel()});
                                } else {
                                  getUserLocation();
                                  Navigator.pop(context);
                                  //Navigator.of(context).pushNamed(Routes.changeAddress, arguments: {'from': 'change'});
                                }
                              },
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(bottom: height! / 99.0),
                              child: const Divider(
                                color: textFieldBorder,
                                height: 0.0,
                              ),
                            ),
                            searchAddressData.isNotEmpty
                                ? Padding(
                                    padding: EdgeInsetsDirectional.only(top: height! / 80.0, bottom: 5.0, start: width! / 9.4),
                                    child: Text(
                                      UiUtils.getTranslatedLabel(context, recentSearchesLabel),
                                      style: const TextStyle(fontSize: 14, color: lightFontColor, fontWeight: FontWeight.normal),
                                    ),
                                  )
                                : const SizedBox(),
                            Column(mainAxisSize: MainAxisSize.min, children: searchAddress()),
                            /*  searchCityData(),*/
                          ],
                        ),
                      ),
                    ),
                  )),
              InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: SvgPicture.asset(DesignConfig.setSvgPath("cancel_icon"), width: 32, height: 32)),
            ],
          );
        });
  }

  searchAddress() {
    return List.generate(
        // the list of items
        searchAddressData.length, (index) {
      final currentItem = searchAddressData[index];
      return ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          dense: true,
          visualDensity: VisualDensity.comfortable,
          horizontalTitleGap: 0.0,
          title: Text(currentItem['city']),
          subtitle: Text(currentItem['address'].toString()),
          leading: const Icon(Icons.history_sharp),
          onTap: () {
            if (mounted) {
              setState(() {
                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                  demoModeAddressDefault(context, "1");
                } else {
                  setAddressForDisplayData(context, "1", currentItem['city'].toString(), currentItem['latitude'].toString(),
                      currentItem['longitude'].toString(), currentItem['address'].toString());
                }
              });
            }
            Navigator.pop(context);
          });
    });
  }

  bottomModelSheetShow(List<ProductDetails> productList, int index) async {
    ProductDetails productDetailsModel = productList[index];
    Map<String, int> qtyData = {};
    int currentIndex = 0, qty = 0;
    List<bool> isChecked = List<bool>.filled(productDetailsModel.productAddOns!.length, false);
    String? productVariantId = productDetailsModel.variants![currentIndex].id;

    List<String> addOnIds = [];
    List<String> addOnQty = [];
    List<double> addOnPrice = [];
    List<String> productAddOnIds = [];
    List<String> productAddOnId = [];
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      productAddOnId = (await db.getVariantItemData(productDetailsModel.id!, productVariantId!))!;
      productAddOnIds = productAddOnId;
    } else {
      for (int i = 0; i < productDetailsModel.variants![currentIndex].addOnsData!.length; i++) {
        productAddOnIds.add(productDetailsModel.variants![currentIndex].addOnsData![i].id!);
      }
    }
    if (context.read<AuthCubit>().getId().isEmpty || context.read<AuthCubit>().getId() == "") {
      qty = int.parse((await db.checkCartItemExists(productDetailsModel.id!, productVariantId!))!);
      if (qty == 0) {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      } else {
        print(qty);
        int data = int.parse(productDetailsModel.variants![currentIndex].cartCount!);
        data = qty;
        qtyData[productVariantId] = qty;
      }
    } else {
      if (productDetailsModel.variants![currentIndex].cartCount != "0") {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);//qty = int.parse(productDetailsModel.variants![currentIndex].cartCount!);
      } else {
        qty = int.parse(productDetailsModel.minimumOrderQuantity!);
      }
    }
    qtyData[productVariantId!] = qty;
    bool descTextShowFlag = false;

    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        shape: DesignConfig.setRoundedBorderCard(20.0, 0.0, 20.0, 0.0),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return BottomSheetContainer(
              productDetailsModel: productDetailsModel,
              isChecked: isChecked,
              height: height!,
              width: width!,
              productVariantId: productVariantId,
              addOnIds: addOnIds,
              addOnPrice: addOnPrice,
              addOnQty: addOnQty,
              productAddOnIds: productAddOnIds,
              qtyData: qtyData,
              currentIndex: currentIndex,
              descTextShowFlag: descTextShowFlag,
              qty: qty,
              from: "home");
        });
  }

  Widget homeList() {
    return Container(margin: EdgeInsetsDirectional.only(top: height! / 80.0),
      color: Theme.of(context).colorScheme.background,
      child:
          Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        slider(),
        topCuisine(),
        topBrand(),
        restaurantsNearby(),
        SizedBox(height: height! / 50.0),
        topDeal(),
        SizedBox(height: height! / 99.0),
      ]),
    );
  }

  Widget searchBar() {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(Routes.search);
      },
      child: SearchBarContainer(width: width!, height: height!, title: UiUtils.getTranslatedLabel(context, searchTitleLabel)),
    );
  }

  Widget topCuisine() {
    return BlocConsumer<CuisineCubit, CuisineState>(
        bloc: context.read<CuisineCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is CuisineProgress || state is CuisineInitial) {
            return CuisineSimmer(length: 3, height: height! / 4.9, width: width!);
          }
          if (state is CuisineFailure) {
            return const SizedBox() /* Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            )) */
                ;
          }
          cuisineList = (state as CuisineSuccess).cuisineList;
          final hasMore = state.hasMore;
          return Container(
            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10),
            padding: EdgeInsetsDirectional.only(bottom: height! / 70.0),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(UiUtils.getTranslatedLabel(context, deliciousCuisineLabel),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(UiUtils.getTranslatedLabel(context, discoverAndGetBestFoodLabel),
                            textAlign: TextAlign.center, style: const TextStyle(color: lightFont, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(Routes.cuisine);
                    },
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: width! / 20.0, top: height! / 40.0),
                      child: Text(UiUtils.getTranslatedLabel(context, showAllLabel), textAlign: TextAlign.center, style: const TextStyle(color: lightFont, fontSize: 12)),
                    ),
                  ),
                ]),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: width! / 20.0, top: height! / 80.0, start: width! / 20.0,),
                  child: DesignConfig.divider(),
                ),
                cuisineList.isEmpty
                    ? const SizedBox()
                    : Container(
                        alignment: Alignment.topLeft,
                        height: height! / 6.15,
                        decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
                        child: SizedBox(
                          height: height! / 4.9,
                          child: ListView.builder(
                              shrinkWrap: true,
                              //controller: topRestaurantController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: cuisineList.length > 6 ? 6 : cuisineList.length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (BuildContext buildContext, index) {
                                return /* hasMore && index == (cuisineList.length - 1)
                                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                                    :  */GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pushNamed(Routes.cuisineDetail,
                                              arguments: {'categoryId': cuisineList[index].id!, 'name': cuisineList[index].text!});
                                        },
                                        child: CuisineContainer(cuisineList: cuisineList, index: index, width: width!, height: height!),
                                      );
                              }),
                        ),
                      ),
              ],
            ),
          );
        });
  }

  Widget topDeal() {
    return BlocConsumer<SectionsCubit, SectionsState>(
        bloc: context.read<SectionsCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is SectionsProgress || state is SectionsInitial) {
            return SectionSimmer(length: 5, width: width!, height: height!);
          }
          if (state is SectionsFailure) {
            return const SizedBox() /* Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            )) */
                ;
          }
          final sectionsList = (state as SectionsSuccess).sectionsList;
          final hasMore = state.hasMore;
          return sectionsList.isEmpty
              ? const SizedBox()
              :Column(
                    children: List.generate(sectionsList.length, (index) {
                    productList = sectionsList[index].productDetails!;
                    return hasMore && index == (sectionsList.length - 1)
                        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                        : sectionsList[index].productDetails!.isEmpty
                            ? const SizedBox()
                            : Container(
                                decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10),
                                padding: EdgeInsetsDirectional.only(bottom: height! / 70.0, top: height! / 80.0),
                                margin: EdgeInsetsDirectional.only(top: height! / 70.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionsList[index].productDetails!.isEmpty
                                        ? Container()
                                        : Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                            Padding(
                                              padding: EdgeInsetsDirectional.only(start: width! / 20.0 /*, top: height! / 60.0*/),
                                              child: Text(sectionsList[index].title!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
                                            ),
                                            const Spacer(),
                                               GestureDetector(onTap:(){
                                                Navigator.of(context)
                              .pushNamed(Routes.section, arguments: {'title': sectionsList[index].title!, 'sectionId': sectionsList[index].id!});
                                               },
                                                 child: Padding(
                                                                                         padding: EdgeInsetsDirectional.only(end: width!/20.0, top: height!/40.0),
                                                                                         child: Text(UiUtils.getTranslatedLabel(context, showAllLabel), textAlign: TextAlign.center, style: const TextStyle(color: lightFont, fontSize: 12)),
                                                                                       ),
                                               ),
                                          ]),
                                          Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      end: width! / 20.0,
                                      top: height! / 80.0,
                                      start: width! / 20.0,
                                    ),
                                    child: DesignConfig.divider(),
                                  ),
                                    sectionsList[index].productDetails!.isEmpty
                                        ? Container()
                                        : (index.isEven)
                                            ? SizedBox(
                                                height: height! / 3.9,width: width!,
                                                child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                                                  child: Row(children: List.generate(sectionsList[index].productDetails!.length, (i) { 
                                                        double price = double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!);
                                                        if (price == 0) {
                                                          price = double.parse(sectionsList[index].productDetails![i].variants![0].price!);
                                                        }
                                                
                                                        double off = 0;
                                                        if (sectionsList[index].productDetails![i].variants![0].specialPrice! != "0") {
                                                          off = (double.parse(sectionsList[index].productDetails![i].variants![0].price!) -
                                                                  double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!))
                                                              .toDouble();
                                                          off = off *
                                                              100 /
                                                              double.parse(sectionsList[index].productDetails![i].variants![0].price!).toDouble();
                                                        }
                                                
                                                        return GestureDetector(
                                                          onTap: () {
                                                            if (sectionsList[index].productDetails![i].partnerDetails![0].isRestroOpen == "1") {
                                                              bool check = getStoreOpenStatus(sectionsList[index].productDetails![i].startTime!,
                                                                  sectionsList[index].productDetails![i].endTime!);
                                                              if (sectionsList[index].productDetails![i].availableTime == "1") {
                                                                if (check == true) {
                                                                  bottomModelSheetShow(sectionsList[index].productDetails!, i);
                                                                } else {
                                                                  showDialog(
                                                                      context: context,
                                                                      builder: (_) => ProductUnavailableDialog(
                                                                          startTime: sectionsList[index].productDetails![i].startTime,
                                                                          endTime: sectionsList[index].productDetails![i].endTime));
                                                                }
                                                              } else {
                                                                bottomModelSheetShow(sectionsList[index].productDetails!, i);
                                                              }
                                                            } else {
                                                              showDialog(
                                                                  context: context,
                                                                  builder: (_) => const RestaurantCloseDialog(hours: "", minute: "", status: false));
                                                            }
                                                          },
                                                          child: ProductContainer(
                                                              productDetails: sectionsList[index].productDetails![i],
                                                              height: height!,
                                                              width: width,
                                                              productDetailsList: sectionsList[index].productDetails!,
                                                              price: price,
                                                              off: off,
                                                              from: "home",
                                                              axis: "horizontal"),
                                                        );
                                                      }),
                                                                                              ),
                                                ))
                                            : SingleChildScrollView(scrollDirection: Axis.vertical,
                                              child: Column(
                                                children: List.generate(sectionsList[index].productDetails!.length, (i) { 
                                                    double price = double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!);
                                                    if (price == 0) {
                                                      price = double.parse(sectionsList[index].productDetails![i].variants![0].price!);
                                                    }
                                            
                                                    double off = 0;
                                                    if (sectionsList[index].productDetails![i].variants![0].specialPrice! != "0") {
                                                      off = (double.parse(sectionsList[index].productDetails![i].variants![0].price!) -
                                                              double.parse(sectionsList[index].productDetails![i].variants![0].specialPrice!))
                                                          .toDouble();
                                                      off = off *
                                                          100 /
                                                          double.parse(sectionsList[index].productDetails![i].variants![0].price!).toDouble();
                                                    }
                                            
                                                    return GestureDetector(
                                                      onTap: () {
                                                        if (sectionsList[index].productDetails![i].partnerDetails![0].isRestroOpen == "1") {
                                                          bool check = getStoreOpenStatus(sectionsList[index].productDetails![i].startTime!,
                                                              sectionsList[index].productDetails![i].endTime!);
                                                          if (sectionsList[index].productDetails![i].availableTime == "1") {
                                                            if (check == true) {
                                                              bottomModelSheetShow(sectionsList[index].productDetails!, i);
                                                            } else {
                                                              showDialog(
                                                                  context: context,
                                                                  builder: (_) => ProductUnavailableDialog(
                                                                      startTime: sectionsList[index].productDetails![i].startTime,
                                                                      endTime: sectionsList[index].productDetails![i].endTime));
                                                            }
                                                          } else {
                                                            bottomModelSheetShow(sectionsList[index].productDetails!, i);
                                                          }
                                                        } else {
                                                          showDialog(
                                                              context: context,
                                                              builder: (_) => const RestaurantCloseDialog(hours: "", minute: "", status: false));
                                                        }
                                                      },
                                                      child: ProductContainer(
                                                          productDetails: sectionsList[index].productDetails![i],
                                                          height: height!,
                                                          width: width,
                                                          productDetailsList: sectionsList[index].productDetails!,
                                                          price: price,
                                                          off: off,
                                                          from: "home",
                                                          axis: "vertical"),
                                                    );
                                                  })),
                                            ),
                                  ],
                                ),
                              );
                  }));
        } /*);
        }*/
        );
  }

  Widget bestOffer() {
    return BlocConsumer<BestOfferCubit, BestOfferState>(
        bloc: context.read<BestOfferCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is BestOfferProgress || state is BestOfferInitial) {
            return SliderSimmer(width: width!, height: height!);
          }
          if (state is BestOfferFailure) {
            return Center(
                child: Text(
              state.errorCode.toString(),
              textAlign: TextAlign.center,
            ));
          }
          final bestOfferList = (state as BestOfferSuccess).bestOfferList;
          return SizedBox(
              height: height! / 4.0,
              child: Column(
                children: [
                  SizedBox(
                    height: height! / 4.0,
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: topRestaurantController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: bestOfferList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext buildContext, index) {
                        return /*hasMore && index == (topRestaurantList.length - 1)
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: red,
                              ))
                            : */
                            InkWell(
                          onTap: () {},
                          child: OfferImageContainer(index: index, bestOfferList: bestOfferList, height: height!, width: width!),
                        );
                      },
                    ),
                  ),
                ],
              ));
        });
  }

  Widget slider() {
    return BlocConsumer<SliderCubit, SliderState>(
        bloc: context.read<SliderCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is SliderProgress || state is SliderInitial) {
            return SliderSimmer(width: width!, height: height!);
          }
          if (state is SliderFailure) {
            return const SizedBox() /* Center(
                child: Text(
              state.errorCode.toString(),
              textAlign: TextAlign.center,
            )) */
                ;
          }
          final sliderList = (state as SliderSuccess).sliderList;
          return sliderList.isEmpty
              ? const SizedBox()
              : Column(
                  children: [
                    CarouselSlider(
                        items: sliderList
                            .map((item) => GestureDetector(
                                  onTap: () {
                                    if (item.type == "default") {
                                    } else if (item.type == "categories") {
                                      Navigator.of(context)
                                          .pushNamed(Routes.cuisineDetail, arguments: {'categoryId': item.data![0].id!, 'name': item.data![0].text!});
                                    } else if (item.type == "products") {
                                      /*  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) => RestaurantDetailScreen(
                                      restaurant: item.data![0].partnerDetails![0],
                                    ),
                                  ),
                                );*/
                                      Navigator.of(context)
                                          .pushNamed(Routes.restaurantDetail, arguments: {'restaurant': item.data![0].partnerDetails![0]});
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsetsDirectional.only(/*start: width!/20.0, end: width!/20.0, */ top: 10.0),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                                      child: DesignConfig.imageWidgets(item.image!, height! / 5.0, width!, "2"),
                                    ),
                                  ),
                                ))
                            .toList(),
                        options: CarouselOptions(
                          autoPlay: true,
                          enlargeCenterPage: true,
                          reverse: false,
                          autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                          aspectRatio: 2.3,
                          initialPage: 0,
                          onPageChanged: (index, reason) {
                            
                      setState(() {
                        _currentPage = index;
                      });
                   
                          },
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sliderList
                          .map((item) => Container(
                                width: _currentPage == sliderList.indexOf(item) ? 15.0 : 6.0,
                                height: 6.0,
                                margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(3.0)),
                                    color: _currentPage == sliderList.indexOf(item) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary),
                              ))
                          .toList(),
                    ),
                  ],
                );
        });
  }

  Widget topBrand() {
    return BlocConsumer<TopRestaurantCubit, TopRestaurantState>(
        bloc: context.read<TopRestaurantCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is TopRestaurantProgress || state is TopRestaurantInitial) {
            return TopBrandSimmer(width: width!, height: height! / 5.0, length: 2);
          }
          if (state is TopRestaurantFailure) {
            return const SizedBox() /* Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            )) */
                ;
          }
          topRestaurantList = (state as TopRestaurantSuccess).topRestaurantList;
          final hasMore = state.hasMore;
          return Container(
            decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10),
            margin: EdgeInsetsDirectional.only(top: height! / 60.0),
            padding: EdgeInsetsDirectional.only(bottom: height! / 70.0),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 40.0),
                    child: Text(UiUtils.getTranslatedLabel(context, topBrandsNearYouLabel),
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const TopBrandScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: width! / 20.0, top: height! / 40.0),
                      child: Text(UiUtils.getTranslatedLabel(context, showAllLabel), textAlign: TextAlign.center, style: const TextStyle(color: lightFont, fontSize: 12)),
                    ),
                  ),
                ]),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: width! / 20.0, top: height! / 80.0, start: width! / 20.0,),
                  child: DesignConfig.divider(),
                ),
                SizedBox(height: height! / 99.0),
                topRestaurantList.isEmpty
                    ? const SizedBox()
                    : SizedBox(
                        height: height! / 4.0,
                        child: ListView.builder(
                          shrinkWrap: true,
                          controller: topRestaurantController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: topRestaurantList.length > 5 ? 5 : topRestaurantList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (BuildContext buildContext, index) {
                            return /*hasMore && index == (topRestaurantList.length - 1)
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: red,
                            ))
                          : */
                                InkWell(
                              onTap: () {
                                /*Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => RestaurantDetailScreen(
                                          restaurant: topRestaurantList[index],
                                        ),
                                      ),
                                    );*/
                                Navigator.of(context).pushNamed(Routes.restaurantDetail, arguments: {'restaurant': topRestaurantList[index]});
                              },
                              child:
                                  TopBrandContainer(index: index, topRestaurantList: topRestaurantList, height: height!, width: width!, from: "home"),
                            );
                          },
                        ),
                      ),
              ],
            ),
          );
        });
  }

  Widget restaurantsNearby() {
    return BlocConsumer<RestaurantCubit, RestaurantState>(
        bloc: context.read<RestaurantCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is RestaurantProgress || state is RestaurantInitial) {
            return RestaurantNearBySimmer(length: 5, width: width!, height: height!);
          }
          if (state is RestaurantFailure) {
            return const SizedBox() /* Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            )) */
                ;
          }
          restaurantList = (state as RestaurantSuccess).restaurantList;
          final hasMore = state.hasMore;
          return /*Container(height: height!/0.9, color: white,
          child:*/
              restaurantList.isEmpty
                  ? const SizedBox()
                  : Container(
                      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10),
                      padding: EdgeInsetsDirectional.only(bottom: height! / 70.0),
                      margin: EdgeInsetsDirectional.only(top: height! / 70.0),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 60.0),
                              child: Text(UiUtils.getTranslatedLabel(context, restaurantsNearbyLabel),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pushNamed(Routes.restaurantNearBy, arguments: {'from': 'restaurantsNearBy'});
                              },
                              child: Padding(
                                padding: EdgeInsetsDirectional.only(end: width! / 20.0),
                                child: Text(UiUtils.getTranslatedLabel(context, showAllLabel),
                                    textAlign: TextAlign.center, style: const TextStyle(color: lightFont, fontSize: 12)),
                              ),
                            ),
                          ]),
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: width! / 20.0,
                              top: height! / 80.0,
                              start: width! / 20.0,
                            ),
                            child: DesignConfig.divider(),
                          ),
                          restaurantList.isEmpty
                              ? const SizedBox()
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  controller: restaurantController,
                                  //physics: const BouncingScrollPhysics(),
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: restaurantList.length > 5 ? 5 : restaurantList.length,
                                  itemBuilder: (BuildContext context, index) {
                                    return hasMore && restaurantList.isEmpty && index == (restaurantList.length - 1)
                                        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                                        : RestaurantContainer(restaurant: restaurantList[index], height: height!, width: width!);
                                  }),
                        ],
                      ),
                    );
        });
  }

  Future<void> refreshList() async {
    context.read<RestaurantCubit>().fetchRestaurant(
        perPage,
        "0",
        context.read<CityDeliverableCubit>().getCityId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<AuthCubit>().getId(),
        "");
    context.read<TopRestaurantCubit>().fetchTopRestaurant(
        perPage,
        "1",
        context.read<CityDeliverableCubit>().getCityId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<AuthCubit>().getId(),
        "");
    context.read<SectionsCubit>().fetchSections(
        perPage,
        context.read<AuthCubit>().getId(),
        context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
        context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
        context.read<CityDeliverableCubit>().getCityId(),
        "");
    context.read<SliderCubit>().fetchSlider();
    context.read<GetCartCubit>().getCartUser(userId: context.read<AuthCubit>().getId());
    context.read<CuisineCubit>().fetchCuisine(perPage, popularCategoriesKey, "");
    //context.read<BestOfferCubit>().fetchBestOffer();
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        context.read<FavoriteRestaurantsCubit>().getFavoriteRestaurants(context.read<AuthCubit>().getId(), partnersKey);
        context.read<FavoriteProductsCubit>().getFavoriteProducts(context.read<AuthCubit>().getId(), productsKey);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollBottomBarController.removeListener(() {});
    //searchController.dispose();
    locationSearchController.dispose();
    restaurantController.dispose();
    topRestaurantController.dispose();
    cuisineController.dispose();
    _scrollBottomBarController.dispose();
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Widget enterLocationSearch() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        bottomModelSheetShowLocation();
        //Navigator.of(context).pushNamed(Routes.searchLocation);
      },
      child: Container(
        margin: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 45.0, start: width! / 20.0, end: width! / 20.0),
        decoration: DesignConfig.boxDecorationContainerBorder(lightFont, textFieldBackground, 10.0),
        child: TextField(
            enabled: false,
            maxLines: 1,
            keyboardType: TextInputType.text,
            //controller: locationSearchController,
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: height! / 55.0),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                hintText: UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
                hintStyle: const TextStyle(fontSize: 12.0, color: lightFont)),
            cursorColor: black,
            textAlign: TextAlign.start,
            style: const TextStyle(color: black, fontSize: 15, fontWeight: FontWeight.w400)),
      ),
    );
  }

  contentBox(context) {
    return Container(
      margin: EdgeInsets.only(top: height! / 18.0),
      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsetsDirectional.only(start: width! / 20.0),
              decoration: DesignConfig.boxDecorationContainerHalf(Theme.of(context).colorScheme.secondary),
              height: height! / 15.0,
              width: width!,
              child: Text(UiUtils.getTranslatedLabel(context, deviceLocationIsOffLabel),
                  style: const TextStyle(color: white, fontWeight: FontWeight.w400, fontStyle: FontStyle.normal, fontSize: 14.0),
                  textAlign: TextAlign.left)),
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
            child: Text(UiUtils.getTranslatedLabel(context, deviceLocationIsOffSubTitleLabel),
                textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 12)),
          ),
          const SizedBox(
            height: 22,
          ),
          enterLocationSearch(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              getUserLocation();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: width! / 99.0),
                Text(UiUtils.getTranslatedLabel(context, enableDeviceLocationLabel), style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(height: height! / 40.0),
        ],
      ),
    );
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
                extendBody: true,
                backgroundColor: Theme.of(context).colorScheme.onBackground,
                bottomNavigationBar: _show
                    ? (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated)
                        ? BlocConsumer<SettingsCubit, SettingsState>(
                            bloc: context.read<SettingsCubit>(),
                            listener: (context, state) {},
                            builder: (context, state) {
                              return (context.read<AuthCubit>().state is AuthInitial || context.read<AuthCubit>().state is Unauthenticated) &&
                                      (state.settingsModel!.cartCount == "0" ||
                                          state.settingsModel!.cartCount == "" ||
                                          state.settingsModel!.cartCount == "0.0") &&
                                      (state.settingsModel!.cartTotal == "0" ||
                                          state.settingsModel!.cartTotal == "" ||
                                          state.settingsModel!.cartTotal == "0.0" ||
                                          state.settingsModel!.cartTotal == "0.00")
                                  ? Container(
                                      height: 0.0,
                                    )
                                  : Container(
                                      //height: height! / 9.8,
                                      margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                      width: width,
                                      padding: EdgeInsetsDirectional.only(
                                          top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 100.0),
                                      child: Row(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text("${state.settingsModel!.cartCount} ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w500)),
                                              Text(
                                                  context.read<SystemConfigCubit>().getCurrency() + state.settingsModel!.cartTotal.toString() == ""
                                                      ? "0"
                                                      : double.parse(state.settingsModel!.cartTotal.toString()).toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: const TextStyle(color: white, fontSize: 13, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                              onTap: () {
                                                clearAll();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (BuildContext context) => const CartScreen(),
                                                  ),
                                                );
                                              },
                                              child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  style: const TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    );
                            })
                        : BlocConsumer<GetCartCubit, GetCartState>(
                            bloc: context.read<GetCartCubit>(),
                            listener: (context, state) {
                              if (state is GetCartSuccess) {}
                            },
                            builder: (context, state) {
                              if (state is GetCartProgress) {
                                //return BottomCartSimmer(show: _show, width: width!, height: height!);
                                return const SizedBox();
                              }
                              if (state is GetCartInitial) {
                                //return BottomCartSimmer(show: _show, width: width!, height: height!);
                                return const SizedBox();
                              }
                              if (state is GetCartFailure) {
                                return const Text(
                                  "",
                                  textAlign: TextAlign.center,
                                );
                              }
                              final cartList = (state as GetCartSuccess).cartModel;
                              var sum = 0;
                              final currentCartModel = context.read<GetCartCubit>().getCartModel();
                              for (int i = 0; i < currentCartModel.data!.length; i++) {
                                sum += int.parse(currentCartModel.data![i].qty!);
                              }
                              return cartList.data!.isEmpty
                                  ? Container()
                                  : Container(
                                      //height: height! / 9.8,
                                      margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0, bottom: height! / 40.0),
                                      width: width,
                                      padding: EdgeInsetsDirectional.only(
                                          top: height! / 55.0, bottom: height! / 55.0, start: width! / 20.0, end: width! / 20.0),
                                      decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 100.0),
                                      child: Row(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text("$sum ${UiUtils.getTranslatedLabel(context, itemTagLabel)} | ",
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  style: const TextStyle(color: white, fontSize: 14, fontWeight: FontWeight.w500)),
                                              Text(context.read<SystemConfigCubit>().getCurrency() + (double.parse(cartList.overallAmount.toString())-double.parse(cartList.taxAmount.toString())).toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: const TextStyle(color: white, fontSize: 13, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                              onTap: () {
                                                clearAll();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (BuildContext context) => const CartScreen(),
                                                  ),
                                                );
                                              },
                                              child: Text(UiUtils.getTranslatedLabel(context, viewCartLabel),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  style: const TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    );
                            })
                    : Container(height: 0),
                body: SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                      onRefresh: refreshList,
                      color: Theme.of(context).colorScheme.primary,
                      child: CustomScrollView(
                        //controller: _scrollBottomBarController,
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: Container(
                              color: Theme.of(context).colorScheme.onBackground,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                          onTap: () {
                                            //  Navigator.of(context).pushNamed(Routes.selectAddress, arguments: false);
                                            bottomModelSheetShowLocation();
                                            /* Navigator.of(context)
                                            .pushNamed(Routes.searchLocation); */
                                          },
                                          child: Container(
                                              width: 32.0,
                                              height: 32.0,
                                              margin: EdgeInsetsDirectional.only(
                                                  start: width! / 20.0, top: height! / 60.0, bottom: height! / 99.0, end: width! / 40.0),
                                              //decoration:DesignConfig.boxDecorationContainerCardShadow(red, shadowCard, 5, 0, 3, 6, 0),
                                              child: SvgPicture.asset(
                                                DesignConfig.setSvgPath("location_pin"),
                                              ))),
                                      InkWell(
                                        onTap: () {
                                          //Navigator.of(context).pushNamed(Routes.selectAddress, arguments: false);
                                          bottomModelSheetShowLocation();
                                          /* Navigator.of(context)
                                            .pushNamed(Routes.searchLocation); */
                                        },
                                        child: deliveryLocation(),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  BlocBuilder<AuthCubit, AuthState>(
                                      bloc: context.read<AuthCubit>(),
                                      builder: (context, state) {
                                        if (state is Authenticated) {
                                          return InkWell(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(Routes.account);
                                            },
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Theme.of(context).colorScheme.onBackground,
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: ClipOval(child: DesignConfig.imageWidgets(state.authModel.image!, 30, 30, "2")),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return InkWell(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(Routes.account);
                                            },
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Theme.of(context).colorScheme.onBackground,
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: ClipOval(child: DesignConfig.imageWidgets(
                                  'profile_pic', 30, 30, "1")),
                                              ),
                                            ),
                                          );
                                        }
                                      }),
                                ],
                              ),
                            ),
                          ),
                          SliverAppBar(
                            automaticallyImplyLeading: false,
                            shadowColor: Colors.transparent,
                            backgroundColor: Theme.of(context).colorScheme.onBackground,
                            systemOverlayStyle: SystemUiOverlayStyle.dark,
                            iconTheme: const IconThemeData(
                              color: black,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            floating: false,
                            pinned: true,
                            title: Padding(
                              padding: EdgeInsetsDirectional.only(bottom: height! / 99, top: height! / 99),
                              child: Row(
                                children: [
                                  Expanded(child: searchBar()),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushNamed(Routes.search);
                                    },
                                    child: VoiceSearchContainer(
                                      width: width!,
                                      height: height!,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return BlocConsumer<CityDeliverableCubit, CityDeliverableState>(
                                    bloc: context.read<CityDeliverableCubit>(),
                                    listener: (context, state) {
                                      if (state is CityDeliverableSuccess) {
                                        context.read<SettingsCubit>().setCityId(state.cityId.toString());
                                        context.read<RestaurantCubit>().fetchRestaurant(
                                            perPage,
                                            "0",
                                            context.read<CityDeliverableCubit>().getCityId(),
                                            context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                                            context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
                                            context.read<AuthCubit>().getId(),
                                            "");
                                        context.read<TopRestaurantCubit>().fetchTopRestaurant(
                                            perPage,
                                            "1",
                                            context.read<CityDeliverableCubit>().getCityId(),
                                            context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                                            context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
                                            context.read<AuthCubit>().getId(),
                                            "");
                                        context.read<SectionsCubit>().fetchSections(
                                            perPage,
                                            context.read<AuthCubit>().getId(),
                                            context.read<SettingsCubit>().state.settingsModel!.latitude.toString(),
                                            context.read<SettingsCubit>().state.settingsModel!.longitude.toString(),
                                            context.read<CityDeliverableCubit>().getCityId(),
                                            "");
                                      }
                                    },
                                    builder: (context, state) {
                                      if (state is CityDeliverableProgress || state is CityDeliverableInitial) {
                                        return HomeSimmer(
                                          width: width,
                                          height: height,
                                        );
                                      }
                                      if (state is CityDeliverableFailure) {
                                        //return Center(child: Text(state.errorCode));
                                        return SingleChildScrollView(
                                          child: Column(children: [
                                            SizedBox(height: height! / 40.0),
                                            Image.asset(
                                              DesignConfig.setPngPath("location"),
                                              height: height! / 3.0,
                                              width: height! / 3.0,
                                              fit: BoxFit.scaleDown,
                                            ),
                                            SizedBox(height: height! / 20.0),
                                            Text(
                                              UiUtils.getTranslatedLabel(context, whoopsLabel),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color:Theme.of(context).colorScheme.error, fontSize: 26, fontWeight: FontWeight.w700),
                                              maxLines: 2,
                                            ),
                                            const SizedBox(height: 5.0),
                                            Padding(
                                              padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0),
                                              child: Text(UiUtils.getTranslatedLabel(context, sorryWeAreNotDeliveryFoodOnCurrentLocationLabel),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14)),
                                            ),
                                            const SizedBox(height: 5.0),
                                            Padding(
                                              padding: EdgeInsets.only(left: width! / 15.0, right: width! / 15.0),
                                              child: Text(UiUtils.getTranslatedLabel(context, currentlyRestaurantAvailableOnBhujLocationLabel),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14, fontWeight: FontWeight.w700)),
                                            ),
                                            GestureDetector(
                                                onTap: () {
                                                  bottomModelSheetShowLocation();
                                                  /*   Navigator.of(context)
                                            .pushNamed(Routes.searchLocation); */
                                                },
                                                child: Container(
                                                    margin: EdgeInsetsDirectional.only(top: height! / 12.0),
                                                    padding: EdgeInsetsDirectional.only(
                                                        top: height! / 70.0, bottom: 10.0, start: width! / 20.0, end: width! / 20.0),
                                                    decoration: DesignConfig.boxDecorationContainerBorder(Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.onBackground, 0.0),
                                                    child: Text(UiUtils.getTranslatedLabel(context, tryDifferentLocationLabel),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.w500)))),
                                          ]),
                                        );
                                      }
                                      return homeList();
                                    });
                              },
                              childCount: 1,
                            ),
                          ),
                        ],
                      )),
                ),
              ));
  }
}
