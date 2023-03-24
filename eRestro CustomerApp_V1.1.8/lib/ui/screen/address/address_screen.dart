import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/cubit/address/updateAddressCubit.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/data/model/addressModel.dart';
import 'package:erestro/data/repositories/address/addressRepository.dart';
import 'package:erestro/cubit/address/addAddressCubit.dart';
import 'package:erestro/cubit/address/addressCubit.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/ui/screen/home/home_screen.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/ui/widgets/buttomContainer.dart';
import 'package:erestro/ui/widgets/keyboardOverlay.dart';
import 'package:erestro/ui/widgets/pinAnimation.dart';
import 'package:erestro/ui/widgets/simmer/mapLoadSimmer.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/string.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/widgets/locationDialog.dart';
import 'package:erestro/utils/internetConnectivity.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:ui' as ui;

class AddressScreen extends StatefulWidget {
  final AddressModel? addressModel;
  final String? from;
  const AddressScreen({Key? key, this.addressModel, this.from}) : super(key: key);

  @override
  _AddressScreenState createState() => _AddressScreenState();
  static Route<AddressScreen> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
      builder: (context) => MultiBlocProvider(providers: [
        BlocProvider<AddAddressCubit>(
          create: (_) => AddAddressCubit(
            AddressRepository(),
          ),
        ),
        BlocProvider<UpdateAddressCubit>(
          create: (_) => UpdateAddressCubit(
            AddressRepository(),
          ),
        )
      ], child: AddressScreen(addressModel: arguments['addressModel'], from: arguments['from'])),
    );
  }
}

class _AddressScreenState extends State<AddressScreen> {
  LatLng? latlong;
  late CameraPosition _cameraPosition;
  GoogleMapController? _controller;
  TextEditingController locationController = TextEditingController();
  final Set<Marker> _markers = {};
  double? width, height;
  String? locationStatus = officeKey;
  late Position position;
  TextEditingController areaRoadApartmentNameController = TextEditingController(text: "");
  TextEditingController addressController = TextEditingController(text: "");
  TextEditingController alternateMobileNumberController = TextEditingController(text: "");
  TextEditingController phoneNumberController = TextEditingController(text: "");
  TextEditingController landmarkController = TextEditingController(text: "");
  TextEditingController cityController = TextEditingController(text: "");
  TextEditingController pinCodeController = TextEditingController(text: "");
  final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: placeSearchApiKey);
  TextEditingController locationSearchController = TextEditingController(text: "");
  String? states, country, pincode, latitude, longitude, address, city, area;
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String? checkStatusFirstTime = "1";
  bool markerMove = false;
  String? countryCode = "+91", alternetNumbercountryCode = "+91";
  FocusNode numberFocusNode = FocusNode();
  FocusNode numberFocusNodeAndroid = FocusNode();
  FocusNode alternetNumberFocusNode = FocusNode();
  FocusNode alternetNumberFocusNodeAndroid = FocusNode();
  locationEnableDialog() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return LocationDialog(width: width, height: height);
        });
  }

  getUserLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();

      getUserLocation();
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        locationEnableDialog();
      } else {
        getUserLocation();
      }
    } else {
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: "en");
        //List<Placemark> placemark = await GeocodingPlatform.instance.placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: "en");

        if (mounted) {
          if (widget.from == "updateAddress") {
            setState(() {
              latlong = LatLng(double.parse(widget.addressModel!.latitude!), double.parse(widget.addressModel!.longitude!));

              _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
              if (_controller != null) {
                _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
              }
              states = widget.addressModel!.state!;
              country = widget.addressModel!.country!;
              pincode = widget.addressModel!.pincode!;
              latitude = widget.addressModel!.latitude!.toString();
              longitude = widget.addressModel!.longitude!.toString();
              area = widget.addressModel!.area!;
              areaRoadApartmentNameController.text = widget.addressModel!.area!;
              cityController.text = widget.addressModel!.city!;
              addressController = TextEditingController(text: widget.addressModel!.address.toString());
              if (areaRoadApartmentNameController.text.trim().isEmpty) {
                areaRoadApartmentNameController.text = widget.addressModel!.area!;
                areaRoadApartmentNameController.selection =
                    TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              if (cityController.text.trim().isEmpty) {
                cityController.text = widget.addressModel!.city!;
                cityController.selection = TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              address = widget.addressModel!.address!;
              city = widget.addressModel!.city!;

              locationController.text =
                  "${widget.addressModel!.address!},${widget.addressModel!.area!},${widget.addressModel!.city},${widget.addressModel!.state!},${widget.addressModel!.pincode!}";
              _markers.add(Marker(
                markerId: const MarkerId("Marker"),
                position: LatLng(double.parse(widget.addressModel!.latitude!), double.parse(widget.addressModel!.longitude!)),
              ));
            });
          } else {
            setState(() {
              latlong = LatLng(position.latitude, position.longitude);

              _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
              if (_controller != null) {
                _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
              }
              List<String> addressData = [];
              var address1, addressComplete;

              address1 = placemark[0].name;
              address1 = address1 + "," + placemark[0].subLocality;
              address1 = address1 + "," + placemark[0].locality;
              address1 = address1 + "," + placemark[0].administrativeArea;
              address1 = address1 + "," + placemark[0].country;
              address1 = address1 + "," + placemark[0].postalCode;

              addressComplete = placemark[0].name;

              if (placemark[0].subLocality!.isNotEmpty) {
                addressComplete = addressComplete + "," + placemark[0].subLocality;
              }
              if (placemark[0].locality!.isNotEmpty) {
                addressComplete = addressComplete + "," + placemark[0].locality;
              }
              if (placemark[0].administrativeArea!.isNotEmpty) {
                addressComplete = addressComplete + "," + placemark[0].administrativeArea;
              }

              addressData.add(addressComplete);
              print("addres${addressData.join(",")}-${addressData.join(",")}");

              states = placemark[0].administrativeArea;
              country = placemark[0].country;
              pincode = placemark[0].postalCode;
              latitude = position.latitude.toString();
              longitude = position.longitude.toString();
              if (areaRoadApartmentNameController.text.trim().isEmpty) {
                areaRoadApartmentNameController.text = placemark[0].subLocality!;
                areaRoadApartmentNameController.selection =
                    TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
              }
              if (cityController.text.trim().isEmpty) {
                cityController.text = placemark[0].locality!;
                cityController.selection = TextSelection.fromPosition(TextPosition(offset: cityController.text.length));
              }
              //address = "${placemark[0].name!},${placemark[0].subLocality!},${placemark[0].locality!},${placemark[0].administrativeArea!}";
              address = addressData.join(",").toString();
              addressController = TextEditingController(text: addressData.join(",").toString());
              city = placemark[0].locality;
              //cityController.text = placemark[0].locality!;
              print("states:$states,country:$country,pincode:$pincode,latitude:$latitude,longitude:${longitude}city:$city");
              //locationController.text = address1;
              locationController.text = addressData.join(",").toString();
              _markers.add(Marker(
                markerId: const MarkerId("Marker"),
                position: LatLng(position.latitude, position.longitude),
              ));
            });
          }
        }
      } catch (e) {
        getUserLocation();
      }
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cityController.clear();
    });
    _cameraPosition = const CameraPosition(target: LatLng(0, 0), zoom: 14.4746);
    getUserLocation();
    if (widget.from == "updateAddress") {
      locationStatus = widget.addressModel!.type!; //locationStatus
      alternateMobileNumberController = TextEditingController(text: widget.addressModel!.alternateMobile!);
      phoneNumberController = TextEditingController(text: widget.addressModel!.mobile);
      countryCode = widget.addressModel!.countryCode;
      areaRoadApartmentNameController = TextEditingController(text: widget.addressModel!.area!);
      addressController = TextEditingController(text: widget.addressModel!.address!);
      cityController = TextEditingController(text: widget.addressModel!.city!);
      landmarkController = TextEditingController(text: widget.addressModel!.landmark!);
      pinCodeController = TextEditingController(text: widget.addressModel!.pincode!);
    }
    numberFocusNode.addListener(() {
      bool hasFocus = numberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    alternetNumberFocusNode.addListener(() {
      bool hasFocus = alternetNumberFocusNode.hasFocus;
      if (hasFocus) {
        KeyboardOverlay.showOverlay(context);
      } else {
        KeyboardOverlay.removeOverlay();
      }
    });
    loadSearchAddressData();
  }

  // Get all items from the database
  loadSearchAddressData() {
    final data = searchAddressBoxData.keys.map((key) {
      final value = searchAddressBoxData.get(key);
      return {"key": key, "city": value["city"], "latitude": value['latitude'], "longitude": value['longitude'], "address": value['address']};
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

  completeAddressShow() {
    showModalBottomSheet(
        isDismissible: false,
        backgroundColor: Colors.transparent,
        shape: DesignConfig.setRoundedBorderCard(20.0, 0.0, 20.0, 0.0),
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context, void Function(void Function()) setState) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                    //height: (MediaQuery.of(context).size.height) / 1.22,
                    padding: EdgeInsets.only(top: height! / 15.0),
                    child: Container(
                      decoration: DesignConfig.boxDecorationContainerRoundHalf(Theme.of(context).colorScheme.onBackground, 25, 0, 25, 0),
                      child: Container(
                        padding: EdgeInsets.only(
                            //left: width! / 15.0,
                            //right: width! / 15.0,
                            top: height! / 25.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              addressField(),
                              areaRoadApartmentNameField(),
                              mobileNumberField(),
                              alternateMobileNumberField(),
                              landmarkField(),
                              cityField(),
                              pincode == "" ? pinCodeField() : Container(),
                              // additionalInstructions(),
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                child: Text(UiUtils.getTranslatedLabel(context, tagThisLocationForLaterLabel),
                                    style: const TextStyle(fontSize: 14.0, color: greayLightColor, fontWeight: FontWeight.w500)),
                              ),
                              tagLocation(setState),
                              widget.from == "updateAddress"
                                  ? BlocConsumer<UpdateAddressCubit, UpdateAddressState>(
                                      bloc: context.read<UpdateAddressCubit>(),
                                      listener: (context, state) {
                                        if (state is UpdateAddressSuccess) {
                                          context.read<AddressCubit>().editAddress(state.addressModel);
                                          Navigator.pop(context);
                                          Future.delayed(const Duration(microseconds: 1000)).then((value) {
                                            Navigator.pop(context);
                                          });
                                        }
                                        if (state is UpdateAddressFailure) {
                                          if (state.errorStatusCode.toString() == "102") {
                                            reLogin(context);
                                          }
                                          Navigator.pop(context);
                                          UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, addressLabel), state.errorMessage, context, false,
                                              type: "2");
                                        }
                                      },
                                      builder: (context, state) {
                                        return SizedBox(
                                          width: width!,
                                          child: ButtonContainer(
                                            color: Theme.of(context).colorScheme.secondary,
                                            height: height,
                                            width: width,
                                            text: state is UpdateAddressProgress
                                                ? UiUtils.getTranslatedLabel(context, updateIngLocationLabel)
                                                : UiUtils.getTranslatedLabel(context, updateLocationLabel),
                                            start: width! / 40.0,
                                            end: width! / 40.0,
                                            bottom: height! / 55.0,
                                            top: 0,
                                            status: false,
                                            borderColor: Theme.of(context).colorScheme.secondary,
                                            textColor: white,
                                            onPressed: () {
                                              context.read<UpdateAddressCubit>().fetchUpdateAddress(
                                                    widget.addressModel!.id!,
                                                    context.read<AuthCubit>().getId(),
                                                    phoneNumberController.text.toString(),
                                                    addressController.text,
                                                    cityController.text,
                                                    latitude ?? "",
                                                    longitude ?? "",
                                                    areaRoadApartmentNameController.text,
                                                    locationStatus,
                                                    context.read<AuthCubit>().getName(),
                                                    countryCode.toString().replaceAll("+", ""),
                                                    alternetNumbercountryCode.toString().replaceAll("+", ""),
                                                    alternateMobileNumberController.text.toString(),
                                                    landmarkController.text,
                                                    pincode == "" ? cityController.text : pincode!,
                                                    states ?? "",
                                                    country ?? "",
                                                    "0",
                                                  );
                                            },
                                          ),
                                        );
                                      })
                                  : BlocConsumer<AddAddressCubit, AddAddressState>(
                                      bloc: context.read<AddAddressCubit>(),
                                      listener: (context, state) {
                                        if (state is AddAddressSuccess) {
                                          context.read<AddressCubit>().addAddress(state.addressModel);
                                          if (widget.from == "login") {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (BuildContext context) => const HomeScreen(),
                                              ),
                                            );
                                          } else {
                                            AddressModel addressModel = context.read<AddressCubit>().gerCurrentAddress();
                                            /*if (addressModel.id == "" || addressModel.id!.isEmpty) {
                                      context.read<AddressCubit>().fetchAddress(context.read<AuthCubit>().getId());
                                      Navigator.pop(context);
                                    } else {*/
                                            Navigator.pop(context);
                                            Future.delayed(const Duration(microseconds: 1000)).then((value) {
                                              Navigator.pop(context);
                                            });
                                            /*}*/
                                          }
                                        }
                                        if (state is AddAddressFailure) {
                                          if (state.errorStatusCode.toString() == "102") {
                                            reLogin(context);
                                          }
                                          Navigator.pop(context);
                                          /* if ((context.read<AuthCubit>().getType() == "google") ||
                                              (context.read<AuthCubit>().getType() == "facebook")) {
                                            if (context.read<AuthCubit>().getMobile().isEmpty) {
                                              Navigator.of(context).pushNamed(Routes.profile, arguments: false);
                                            }
                                          } */
                                          UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, addressLabel), state.errorMessage, context, false,
                                              type: "2");
                                        }
                                      },
                                      builder: (context, state) {
                                        return SizedBox(
                                          width: width!,
                                          child: ButtonContainer(
                                            color: Theme.of(context).colorScheme.secondary,
                                            height: height,
                                            width: width,
                                            text: state is AddAddressProgress
                                                ? UiUtils.getTranslatedLabel(context, addingLocationLabel)
                                                : UiUtils.getTranslatedLabel(context, confirmLocationLabel),
                                            start: width! / 40.0,
                                            end: width! / 40.0,
                                            bottom: height! / 55.0,
                                            top: 0,
                                            status: false,
                                            borderColor: Theme.of(context).colorScheme.secondary,
                                            textColor: white,
                                            onPressed: () {
                                              context.read<AddAddressCubit>().fetchAddAddress(
                                                    context.read<AuthCubit>().getId(),
                                                    phoneNumberController.text.toString(),
                                                    addressController.text,
                                                    cityController.text,
                                                    latitude ?? "",
                                                    longitude ?? "",
                                                    areaRoadApartmentNameController.text,
                                                    locationStatus,
                                                    context.read<AuthCubit>().getName(),
                                                    countryCode.toString(),
                                                    alternetNumbercountryCode.toString(),
                                                    alternateMobileNumberController.text,
                                                    landmarkController.text,
                                                    pincode == "" ? pinCodeController.text : pincode!,
                                                    states ?? "",
                                                    country ?? "",
                                                    widget.from == "login" ? "1" : "0",
                                                  );
                                            },
                                          ),
                                        );
                                      }),
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
        });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    locationController.clear();
    areaRoadApartmentNameController.clear();
    addressController.clear();
    cityController.clear();
    landmarkController.clear();
    pinCodeController.clear();
    alternateMobileNumberController.clear();
    _controller!.dispose();
    locationController.dispose();
    areaRoadApartmentNameController.dispose();
    addressController.dispose();
    cityController.dispose();
    alternateMobileNumberController.dispose();
    pinCodeController.dispose();
    landmarkController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Widget cityField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          controller: cityController,
          cursorColor: lightFont,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, cityLabel), UiUtils.getTranslatedLabel(context, enterCityLabel), width!, context),
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: greayLightColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget pinCodeField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextFormField(
          controller: pinCodeController,
          cursorColor: lightFont,
          textInputAction: TextInputAction.done,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, pinCodeLabel), UiUtils.getTranslatedLabel(context, enterpinCodeLabel), width!, context),
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: greayLightColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget addressField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextField(
          controller: addressController,
          cursorColor: greayLightColor,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, addressLabel), UiUtils.getTranslatedLabel(context, enterAddressLabel), width!, context),
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: greayLightColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget areaRoadApartmentNameField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextField(
          controller: areaRoadApartmentNameController,
          cursorColor: greayLightColor,
          decoration: DesignConfig.inputDecorationextField(UiUtils.getTranslatedLabel(context, areaRoadApartmentNameLabel),
              UiUtils.getTranslatedLabel(context, enterAreaRoadApartmentNameLabel), width!, context),
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: greayLightColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget alternateMobileNumberField() {
    return Container(
        padding: EdgeInsetsDirectional.only(
            start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 80.0,
          end: width! / 20.0,
        ),
        child: IntlPhoneField(
          controller: alternateMobileNumberController,
          textInputAction: TextInputAction.done,
          dropdownIcon:
              const Icon(Icons.keyboard_arrow_down_rounded, color: black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 15),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: greayLightColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.0, color: Theme.of(context).colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.0, color: Theme.of(context).colorScheme.primary),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: greayLightColor),
            ),
            focusColor: white,
            counterStyle: const TextStyle(color: white, fontSize: 0),
            border: InputBorder.none,
            hintText:
                UiUtils.getTranslatedLabel(context, enterAlternateMobileNumberLabel),
            labelStyle: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
            //contentPadding: EdgeInsets.zero,
          ),
          flagsButtonMargin: EdgeInsets.all(width! / 40.0),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          focusNode: Platform.isIOS ? alternetNumberFocusNode : alternetNumberFocusNodeAndroid,
          dropdownIconPosition: IconPosition.trailing,
          initialCountryCode: 'IN',
          style: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          textAlign: Directionality.of(context) == ui.TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          onChanged: (phone) {
            setState(() {
              //print(phone.completeNumber);
              alternetNumbercountryCode = phone.countryCode;
            });
          },
        ));
  }

  Widget mobileNumberField() {
    return Container(
        padding: EdgeInsetsDirectional.only(
            start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 80.0,
          end: width! / 20.0,
        ),
        child: IntlPhoneField(
          controller: phoneNumberController,
          textInputAction: TextInputAction.done,
          dropdownIcon:
              const Icon(Icons.keyboard_arrow_down_rounded, color: black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
            contentPadding: const EdgeInsets.only(top: 15, bottom: 15),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: greayLightColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.0, color: Theme.of(context).colorScheme.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 1.0, color: Theme.of(context).colorScheme.primary),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(width: 1.0, color: greayLightColor),
            ),
            focusColor: white,
            counterStyle: const TextStyle(color: white, fontSize: 0),
            border: InputBorder.none,
            hintText:
                UiUtils.getTranslatedLabel(context, enterPhoneNumberLabel),
            labelStyle: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
            //contentPadding: EdgeInsets.zero,
          ),
          flagsButtonMargin: EdgeInsets.all(width! / 40.0),
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          focusNode: Platform.isIOS ? numberFocusNode : numberFocusNodeAndroid,
          dropdownIconPosition: IconPosition.trailing,
          initialCountryCode: 'IN',
          style: const TextStyle(
              color: greayLightColor,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          textAlign: Directionality.of(context) == ui.TextDirection.rtl
              ? TextAlign.right
              : TextAlign.left,
          onChanged: (phone) {
            setState(() {
              //print(phone.completeNumber);
              countryCode = phone.countryCode;
            });
          },
        ));
  }

  Widget landmarkField() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 99.0),
        margin: EdgeInsetsDirectional.only(
          bottom: height! / 40.0,
          end: width! / 20.0,
        ),
        child: TextField(
          controller: landmarkController,
          cursorColor: greayLightColor,
          decoration: DesignConfig.inputDecorationextField(
              UiUtils.getTranslatedLabel(context, landmarkLabel), UiUtils.getTranslatedLabel(context, enterLandmarkLabel), width!, context),
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: greayLightColor,
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ));
  }

  Widget tagLocation(StateSetter setState) {
    return Padding(
      padding: EdgeInsetsDirectional.only(end: width! / 40.0, top: height! / 99.0, start: width! / 40.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = homeKey;
                });
              },
              child: Container(
                  width: width,
                  padding: EdgeInsetsDirectional.only(
                    top: height! / 99.0,
                    bottom: height! / 99.0,
                  ),
                  decoration: locationStatus == homeKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 5.0)
                      : DesignConfig.boxDecorationContainerBorder(lightFont, Theme.of(context).colorScheme.onBackground, 5.0),
                  child: Text(UiUtils.getTranslatedLabel(context, homeLabel),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: locationStatus == homeKey ? white : lightFont, fontSize: 14, fontWeight: FontWeight.w500)))),
        ),
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = officeKey;
                });
              },
              child: Container(
                  width: width!,
                  padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                  decoration: locationStatus == officeKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 5.0)
                      : DesignConfig.boxDecorationContainerBorder(lightFont, Theme.of(context).colorScheme.onBackground, 5.0),
                  child: Text(UiUtils.getTranslatedLabel(context, officeLabel),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: locationStatus == officeKey ? white : lightFont, fontSize: 14, fontWeight: FontWeight.w500)))),
        ),
        Expanded(
          child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () {
                setState(() {
                  locationStatus = otherKey;
                });
              },
              child: Container(
                  width: width!,
                  padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 99.0),
                  decoration: locationStatus == otherKey
                      ? DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.secondary, 5.0)
                      : DesignConfig.boxDecorationContainerBorder(lightFont, Theme.of(context).colorScheme.onBackground, 5.0),
                  child: Text(UiUtils.getTranslatedLabel(context, otherLabel),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: locationStatus == otherKey ? white : lightFont, fontSize: 14, fontWeight: FontWeight.w500)))),
        ),
      ]),
    );
  }

  Widget locationChange() {
    return Container(
        margin: const EdgeInsetsDirectional.only(bottom: 10.0),
        padding: EdgeInsetsDirectional.only(start: width! / 20.0, end: width! / 20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          SvgPicture.asset(DesignConfig.setSvgPath("other_address")),
          SizedBox(width: height! / 99.0),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city!,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  addressController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          )
        ]));
  }

  placesAutoCompleteTextField() {
    return Container(
      margin: EdgeInsetsDirectional.only(top: height! / 20.0, bottom: height! / 45.0, end: width! / 25.0, start: width! / 40.0),
      decoration: DesignConfig.boxDecorationContainerBorder(lightFont, textFieldBackground, 10.0),
      child: GooglePlaceAutoCompleteTextField(
          textEditingController: locationSearchController,
          googleAPIKey: placeSearchApiKey,
          inputDecoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: height! / 62.0),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              hintText: UiUtils.getTranslatedLabel(context, enterLocationAreaCityEtcLabel),
              hintStyle: const TextStyle(fontSize: 12.0, color: lightFont)),
          debounceTime: 600,
          //countries: ["in", "fr"],
          isLatLngRequired: true,
          getPlaceDetailWithLatLng: (p) async {
          },
          itmClick: (p) async {
            print("itmClick");
            locationSearchController.text = p.description!;
            PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
            print("address:${detail.result.formattedAddress!.toString()}");
            //
            List<dynamic> localities =
                detail.result.addressComponents.where((entry) => entry.types.contains('locality')).toList().map((entry) => entry.longName).toList();
            latlong =
                LatLng(double.parse(detail.result.geometry!.location.lat.toString()), double.parse(detail.result.geometry!.location.lng.toString()));
            List<Placemark> placemark = await placemarkFromCoordinates(latlong!.latitude, latlong!.longitude, localeIdentifier: "en");
            //
            if (mounted) {
              setState(() {
                if (widget.from == "location" || widget.from == "change") {
                  List<dynamic> localities = detail.result.addressComponents
                      .where((entry) => entry.types.contains('locality'))
                      .toList()
                      .map((entry) => entry.longName)
                      .toList();
                  setAddressForDisplayData(context, "1", localities.join("").toString(), detail.result.geometry!.location.lat.toString(),
                      detail.result.geometry!.location.lng.toString(), detail.result.formattedAddress!.toString());
                  addSearchAddress({
                    "city": localities.join("").toString(),
                    "latitude": detail.result.geometry!.location.lat.toString(),
                    "longitude": detail.result.geometry!.location.lng.toString(),
                    "address": detail.result.formattedAddress!.toString()
                  }).then((value) => Navigator.pop(context));
                } else {
                  _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
                  if (_controller != null) {
                    _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                  }
                  states = placemark[0].administrativeArea;
                  country = placemark[0].country;
                  pincode = placemark[0].postalCode;
                  latitude = detail.result.geometry!.location.lat.toString();
                  longitude = detail.result.geometry!.location.lng.toString();
                  area = placemark[0].subLocality!;
                  areaRoadApartmentNameController.text = placemark[0].subLocality!;
                  cityController.text = localities.join("").toString();
                  setState(() {
                    addressController.text = detail.result.formattedAddress!.toString();
                  });
                  print("address::${addressController.text}--${detail.result.formattedAddress!.toString()}");
                  addressController = TextEditingController(text: detail.result.formattedAddress!.toString());
                  if (areaRoadApartmentNameController.text.trim().isEmpty) {
                    areaRoadApartmentNameController.text = placemark[0].subLocality!;
                    areaRoadApartmentNameController.selection =
                        TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
                  }
                  if (cityController.text.trim().isEmpty) {
                    cityController.text = localities.join("").toString();
                    cityController.selection = TextSelection.fromPosition(TextPosition(offset: cityController.text.length));
                  }
                  address = detail.result.formattedAddress!.toString();
                  city = localities.join("").toString();
                  FocusScope.of(context).unfocus();
                  locationController.text = detail.result.formattedAddress!.toString();
                }
              });
            }
            locationSearchController.clear();
            setState(() {
              markerMove = true;
            });
          },
          textStyle: const TextStyle(color: black, fontSize: 15, fontWeight: FontWeight.w400)),
    );
  }

  void _checkPermission(Function callback, BuildContext context) async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => locationEnableDialog());
    } else {
      callback();
      List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude, localeIdentifier: "en");
      latlong = LatLng(position.latitude, position.longitude);

      _cameraPosition = CameraPosition(target: latlong!, zoom: 14.4746, bearing: 0);
      if (_controller != null) {
        _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
      }
      setState(() {
        markerMove = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return _connectionStatus == connectivityCheck
        ? const NoInternetScreen()
        : WillPopScope(
            onWillPop: () {
              Future.delayed(const Duration(microseconds: 1000)).then((value) {
                Navigator.pop(context);
              });
              return Future.value(false);
            },
            child: Scaffold(
                resizeToAvoidBottomInset: true,
                body: Stack(children: [
                  SizedBox(
                    height: height! / 1.27,
                    child: (latlong != null)
                        ? Stack(
                            children: [
                              SafeArea(
                                child: GoogleMap(
                                    onCameraMove: (position) {
                                      _cameraPosition = position;
                                    },
                                    onCameraIdle: () {
                                      if(markerMove ==false){
                                        getLocation();
                                      }
                                    },//markers: myMarker(),
                                    zoomControlsEnabled: false,
                                    minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                                    compassEnabled: false,
                                    indoorViewEnabled: true,
                                    mapToolbarEnabled: true,myLocationButtonEnabled: false,
                                    mapType: MapType.normal,
                                    initialCameraPosition: _cameraPosition,
                                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{}
                                          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()..onUpdate = (dragUpdateDetails) {
                                          }))
                                          ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()..onStart = (dragUpdateDetails) {
                                          }))
                                          ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
                                          ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()..onDown = (dragUpdateDetails) {
                                            setState(() {
                                              markerMove = false;
                                            });
                                          })),
                                    onMapCreated: (GoogleMapController controller) {
                                      Future.delayed(const Duration(milliseconds: 500)).then((value) {
                                        _controller = (controller);
                                        _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                                      });
                                    },
                                    onTap: (latLng) {
                                      _controller!.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                                      setState(() {
                                        markerMove = false;
                                      });
                                    }),
                              ),
                              PinAnimation(color: Theme.of(context).colorScheme.primary),
                              Center(child: SvgPicture.asset(DesignConfig.setSvgPath('other_address'), width: 35, height: 35)),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: width! / 90.0,
                                top: height! / 1.6,
                                child: InkWell(
                                  onTap: () => _checkPermission(() async {
                                  }, context),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    margin: const EdgeInsetsDirectional.only(end: 10),
                                    decoration:
                                        DesignConfig.boxDecorationContainerBorder(lightFont, Theme.of(context).colorScheme.onBackground, 10.0),
                                    child: Icon(
                                      Icons.my_location,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 35,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : MapLoadSimmer(width: width!, height: height!),
                  ),
                  // : Container(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsetsDirectional.only(top: height! / 1.45),
                      decoration: DesignConfig.boxCurveShadow(Theme.of(context).colorScheme.onBackground),
                      width: width,
                      child: Container(
                        margin: EdgeInsetsDirectional.only(top: height! / 30.0),
                        child: SingleChildScrollView(
                          child: latlong != null
                              ? Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(start: width! / 20.0),
                                    child: Text(UiUtils.getTranslatedLabel(context, selectDeliveryLocationLabel),
                                        style:
                                            TextStyle(fontSize: 16.0, color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500)),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(top: height! / 60.0, bottom: height! / 40.0),
                                    child: Divider(
                                      color: lightFont.withOpacity(0.10),
                                      height: 0.2,
                                      thickness: 0.2,
                                      endIndent: width! / 20.0,
                                      indent: width! / 20.0,
                                    ),
                                  ),
                                  locationChange(),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(top: height! / 99.0, bottom: height! / 40.0),
                                    child: Divider(
                                      color: lightFont.withOpacity(0.10),
                                      height: 0.2,
                                      thickness: 0.2,
                                      endIndent: width! / 20.0,
                                      indent: width! / 20.0,
                                    ),
                                  ),
                                  SizedBox(
                                    width: width!,
                                    child: ButtonContainer(
                                      color: Theme.of(context).colorScheme.secondary,
                                      height: height,
                                      width: width,
                                      text: (widget.from == "location" || widget.from == "change")
                                          ? UiUtils.getTranslatedLabel(context, confirmLocationLabel)
                                          : UiUtils.getTranslatedLabel(context, enterCompleteAddressLocationLabel),
                                      start: width! / 40.0,
                                      end: width! / 40.0,
                                      bottom: height! / 55.0,
                                      top: 0,
                                      status: false,
                                      borderColor: Theme.of(context).colorScheme.secondary,
                                      textColor: white,
                                      onPressed: () {
                                        if (widget.from == "location" || widget.from == "change") {
                                          if (city == "") {
                                            UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, addressLabel),
                                                StringsRes.sorryWeAreNotDeliveryFoodOnCurrentLocation, context, false,
                                                type: "2");
                                          } else {
                                            if (mounted) {
                                              setState(() {
                                                if (context.read<SystemConfigCubit>().getDemoMode() == "0") {
                                                  demoModeAddressDefault(context, "1");
                                                } else {
                                                  setAddressForDisplayData(context, "1", city.toString(), latitude!.toString(),
                                                    longitude!.toString(), address.toString());
                                                }
                                                //if (widget.from == "location") {
                                                  //context.read<SettingsCubit>().changeShowSkip();
                                                  Future.delayed(Duration.zero, () {
                                                    addSearchAddress({
                                                      "city": city.toString(),
                                                      "latitude": latitude.toString(),
                                                      "longitude": longitude.toString(),
                                                      "address": address.toString()
                                                    }).then((value) { if (widget.from == "location") {
                                                      context.read<SettingsCubit>().changeShowSkip();
                                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                                        Routes.home, (Route<dynamic> route) => false /* , arguments: {'id': 0} */);}else{
                                                          Navigator.pop(context);
                                                        }});
                                                  });
                                                /* } else {
                                                  addSearchAddress({
                                                    "city": city.toString(),
                                                    "latitude": latitude.toString(),
                                                    "longitude": longitude.toString(),
                                                    "address": address.toString()
                                                  }).then((value) => Navigator.pop(context));
                                                } */
                                              });
                                            }
                                          }
                                        } else {
                                          completeAddressShow();
                                        }
                                      },
                                    ),
                                  ),
                                ])
                              : MapDataLoadSimmer(width: width!, height: height!),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                          onTap: () {
                            Future.delayed(const Duration(microseconds: 1000)).then((value) {
                              Navigator.pop(context);
                            });
                          },
                          child: Padding(
                              padding: EdgeInsetsDirectional.only(start: width! / 40.0, top: height! / 32.0),
                              child: SvgPicture.asset(
                                DesignConfig.setSvgPath("back_icon"),
                                width: 32,
                                height: 32,
                                fit: BoxFit.scaleDown,
                              ))),
                      Expanded(child: placesAutoCompleteTextField())
                    ],
                  ),
                ])),
          );
  }

  Set<Marker> myMarker() {
    _markers.clear();
    _markers.add(Marker(onDrag: (value) {
      print("on:Drag");
    },onDragStart: (value) {
      print("on:DragStart");
    },onDragEnd: (value) {
      print("onDragEnd");
    },
      markerId: MarkerId(Random().nextInt(10000).toString()),
      visible: false,
      position: LatLng(latlong!.latitude, latlong!.longitude),
      draggable: true,
    ));
    return _markers;
  }

  Future<void> getLocation() async {
    print("center:${latlong!.latitude}-${latlong!.longitude}");
    latlong = LatLng(_cameraPosition.target.latitude, _cameraPosition.target.longitude);
    //List<Placemark> placemark = await placemarkFromCoordinates(latlong!.latitude, latlong!.longitude);
    List<Placemark> placemark =
        await GeocodingPlatform.instance.placemarkFromCoordinates(latlong!.latitude, latlong!.longitude, localeIdentifier: "en");

    var address1, addressComplete;
    List<String> addressData = [];

    address1 = placemark[0].name;

    if (placemark[0].subLocality!.isNotEmpty) {
      address1 = address1 + "," + placemark[0].subLocality;
    }
    if (placemark[0].locality!.isNotEmpty) {
      address1 = address1 + "," + placemark[0].locality;
    }
    if (placemark[0].administrativeArea!.isNotEmpty) {
      address1 = address1 + "," + placemark[0].administrativeArea;
    }
    if (placemark[0].country!.isNotEmpty) {
      address1 = address1 + "," + placemark[0].country;
    }
    if (placemark[0].postalCode!.isNotEmpty) {
      address1 = address1 + "," + placemark[0].postalCode;
    }

    addressComplete = placemark[0].name;

    if (placemark[0].subLocality!.isNotEmpty) {
      addressComplete = addressComplete + "," + placemark[0].subLocality;
    }
    if (placemark[0].locality!.isNotEmpty) {
      addressComplete = addressComplete + "," + placemark[0].locality;
    }
    if (placemark[0].administrativeArea!.isNotEmpty) {
      addressComplete = addressComplete + "," + placemark[0].administrativeArea;
    }

    addressData.add(addressComplete);
    print("addres${addressData.join(",")}-${addressData.join(",")}");

    states = placemark[0].administrativeArea;
    country = placemark[0].country;
    pincode = placemark[0].postalCode;
    latitude = latlong!.latitude.toString();
    longitude = latlong!.longitude.toString();
    area = placemark[0].subLocality;
    if (areaRoadApartmentNameController.text.trim().isEmpty) {
      areaRoadApartmentNameController.text = placemark[0].subLocality!;
      areaRoadApartmentNameController.selection = TextSelection.fromPosition(TextPosition(offset: areaRoadApartmentNameController.text.length));
    }
    address = placemark[0].name;
    addressController = TextEditingController(text: addressData.join(",").toString());
    city = placemark[0].locality;
    cityController.text = placemark[0].locality!;
    if (cityController.text.trim().isEmpty) {
      cityController.text = placemark[0].locality!;
      cityController.selection = TextSelection.fromPosition(TextPosition(offset: cityController.text.length));
    }

    //locationController.text = address1;
    if (locationController.text.trim().isEmpty) {
      locationController.text = addressData.join(",").toString();
      locationController.selection = TextSelection.fromPosition(TextPosition(offset: locationController.text.length));
    }
    if (mounted) setState(() {});
  }
}
