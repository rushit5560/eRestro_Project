import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/address/cityDeliverableCubit.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/data/model/addressModel.dart';
import 'package:erestro/ui/screen/home/home_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/widgets/locationDialog.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:erestro/utils/internetConnectivity.dart';

class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({Key? key}) : super(key: key);

  @override
  SearchLocationScreenState createState() => SearchLocationScreenState();
}

class SearchLocationScreenState extends State<SearchLocationScreen> {
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  TextEditingController locationSearchController =
      TextEditingController(text: "");
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  double? width, height;
  String? currentAddress = "";
  
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
    loadSearchAddressData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  placesAutoCompleteTextField() {
    return Container(
      margin: EdgeInsets.only(top: height! / 25.0, bottom: height! / 45.0),
      decoration: DesignConfig.boxDecorationContainerBorder(
          lightFont, textFieldBackground, 10.0),
      child: GooglePlaceAutoCompleteTextField(
          textEditingController: locationSearchController,
          googleAPIKey: placeSearchApiKey,
          inputDecoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: height! / 55.0),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              hintText: UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
              hintStyle:
                  const TextStyle(fontSize: 12.0, color: lightFont)),
          debounceTime: 600,
          //countries: ["in", "fr"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (p) async {
            PlacesDetailsResponse detail =
                await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                context
                    .read<CityDeliverableCubit>()
                    .fetchCityDeliverable(localities.join("").toString());
                context
                    .read<SettingsCubit>()
                    .setCity(localities.join("").toString());
                context.read<SettingsCubit>().setLatitude(
                    detail.result.geometry!.location.lat.toString());
                context.read<SettingsCubit>().setLongitude(
                    detail.result.geometry!.location.lng.toString());
                context
                    .read<SettingsCubit>()
                    .setAddress(detail.result.formattedAddress!.toString());
              });
            }
          },
          itmClick: (p) async {
            locationSearchController.text = p.description!;
            PlacesDetailsResponse detail =
                await _places.getDetailsByPlaceId(p.placeId!);
            if (mounted) {
              setState(() {
                List<dynamic> localities = detail.result.addressComponents
                    .where((entry) => entry.types.contains('locality'))
                    .toList()
                    .map((entry) => entry.longName)
                    .toList();
                context
                    .read<CityDeliverableCubit>()
                    .fetchCityDeliverable(localities.join("").toString());
                context
                    .read<SettingsCubit>()
                    .setCity(localities.join("").toString());
                context.read<SettingsCubit>().setLatitude(
                    detail.result.geometry!.location.lat.toString());
                context.read<SettingsCubit>().setLongitude(
                    detail.result.geometry!.location.lng.toString());
                context
                    .read<SettingsCubit>()
                    .setAddress(detail.result.formattedAddress!.toString());
                addSearchAddress({
                  "city": localities.join("").toString(),
                  "latitude": detail.result.geometry!.location.lat.toString(),
                  "longitude": detail.result.geometry!.location.lng.toString(),
                  "address": detail.result.formattedAddress!.toString()
                }).then((value) => Navigator.pop(context));
              });
            }
            locationSearchController.selection = TextSelection.fromPosition(
                TextPosition(offset: p.description!.length));
            locationSearchController.clear();
          },
          textStyle: const TextStyle(
              color: black,
              fontSize: 15,
              fontWeight: FontWeight.w400)),
    );
  }
  
  // Get all items from the database
  void loadSearchAddressData() {
    final data = searchAddressBoxData.keys.map((key) {
      final value = searchAddressBoxData.get(key);
      return {
        "key": key,
        "city": value["city"],
        "latitude": value['latitude'],
        "longitude": value['longitude'],
        "address": value['address']
      };
    }).toList();

    setState(() {
      searchAddressData = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
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

    locationEnableDialog() async {
    if (context.read<SettingsCubit>().state.settingsModel!.city.toString() ==
            "" &&
        context.read<SettingsCubit>().state.settingsModel!.city.toString() ==
            "null") {
      // Use location.
      getUserLocation();
    } else {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return LocationDialog(width: width, height: height);
          }).whenComplete(() async {
        if (context
            .read<SettingsCubit>()
            .state
            .settingsModel!
            .city
            .toString()
            .isNotEmpty) {
          await context.read<CityDeliverableCubit>().fetchCityDeliverable(
              context
                  .read<SettingsCubit>()
                  .state
                  .settingsModel!
                  .city
                  .toString());
        }
      });
    }
  }

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
        locationEnableDialog();
        //await Geolocator.openLocationSettings();
        //getUserLocation();
      } else {
        getUserLocation();
      }
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        //print("heading---${position.heading}");

        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude,
            localeIdentifier: "en");
        // print(placemarks[0]);

        String? address =
            "${placemarks[0].name},${placemarks[0].thoroughfare},${placemarks[0].locality},${placemarks[0].postalCode},${placemarks[0].country}";

        String? location =
            "${placemarks[0].name},${placemarks[0].locality},${placemarks[0].postalCode},${placemarks[0].country}";

        if (await Permission.location.serviceStatus.isEnabled) {
          if (mounted) {
            setState(() async {
              if (placemarks[0].subLocality == "" ||
                  placemarks[0].subLocality!.isEmpty) {
                currentAddress = "${placemarks[0].locality}";
              } else {
                currentAddress =
                    "${placemarks[0].subLocality}, ${placemarks[0].locality}";
              }
              context
                  .read<SettingsCubit>()
                  .setCity(placemarks[0].locality.toString());
              context
                  .read<SettingsCubit>()
                  .setLatitude(position.latitude.toString());
              context
                  .read<SettingsCubit>()
                  .setLongitude(position.longitude.toString());
              context.read<SettingsCubit>().setAddress(location.toString());

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
                  if (mounted) {
                    context
                        .read<CityDeliverableCubit>()
                        .fetchCityDeliverable(placemarks[0].locality);
                  }
                } else {
                  context.read<CityDeliverableCubit>().fetchCityDeliverable(
                      context
                          .read<SettingsCubit>()
                          .state
                          .settingsModel!
                          .city
                          .toString());
                }
              } else {
                getUserLocation();
              }
            });
          }
        } else {
          setState(() {
            context.read<CityDeliverableCubit>().fetchCityDeliverable(context
                .read<SettingsCubit>()
                .state
                .settingsModel!
                .city
                .toString());
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            context.read<CityDeliverableCubit>().fetchCityDeliverable(context
                .read<SettingsCubit>()
                .state
                .settingsModel!
                .city
                .toString());
            print(context
                .read<SettingsCubit>()
                .state
                .settingsModel!
                .address
                .toString());
          });
        }
      }
      //print("curadd-$address");
    }
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
                context
                    .read<CityDeliverableCubit>()
                    .fetchCityDeliverable(currentItem['city'].toString());
                context
                    .read<SettingsCubit>()
                    .setCity(currentItem['city'].toString());
                context
                    .read<SettingsCubit>()
                    .setLatitude(currentItem['latitude'].toString());
                context
                    .read<SettingsCubit>()
                    .setLongitude(currentItem['longitude'].toString());
                context
                    .read<SettingsCubit>()
                    .setAddress(currentItem['address'].toString());
              });
            }
            Navigator.pop(context);
          });
    });
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
              appBar: DesignConfig.appBar(context, width, UiUtils.getTranslatedLabel(context, selectALocationLabel), const PreferredSize(
                                preferredSize: Size.zero,child:SizedBox())),
              body: Container(height: height!,
                margin: EdgeInsetsDirectional.only(top: height! / 80.0), padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0, top: height! / 99.0),
                decoration: DesignConfig.boxDecorationContainerHalf(Theme.of(context).colorScheme.onBackground),
                width: width,
                child: SingleChildScrollView(
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  placesAutoCompleteTextField(),
                            ListTile(
                              visualDensity: const VisualDensity(vertical: -4),
                              minLeadingWidth: 0,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.gps_fixed,
                                  color: Theme.of(context).colorScheme.primary),
                              trailing: Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  size: 18.0),
                              title: Text(UiUtils.getTranslatedLabel(context, useCurrentLocationLabel),
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: Text(
                                  currentAddress.toString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: lightFontColor),
                                ),
                              ),
                              onTap: () async {
                                if (await Permission
                                    .location.serviceStatus.isEnabled) {
                                  Navigator.pop(context);
                                  Navigator.of(context).pushNamed(
                                      Routes.address,
                                      arguments: {'from': 'change', 'addressModel': AddressModel()});
                                } else {
                                  getUserLocation();
                                  Navigator.pop(context);
                                  //Navigator.of(context).pushNamed(Routes.changeAddress, arguments: {'from': 'change'});
                                }
                              },),
                              Padding(
                              padding: EdgeInsetsDirectional.only(
                                  bottom: height! / 99.0),
                              child: const Divider(
                                color: textFieldBorder,
                                height: 0.0,
                              ),
                            ),
                            searchAddressData.isNotEmpty
                                ? Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        top: height! / 80.0,
                                        bottom: 5.0,
                                        start: width! / 60.0),
                                    child: Text(
                                      UiUtils.getTranslatedLabel(context, recentSearchesLabel),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : const SizedBox(),
                            Column(
                                mainAxisSize: MainAxisSize.min,
                                children: searchAddress()),
                  ]),
                ),
              )),
    );
  }
}
