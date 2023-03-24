import 'dart:io';
import 'package:erestro/app/appLocalization.dart';
import 'package:erestro/cubit/address/isOrderDeliverableCubit.dart';
import 'package:erestro/cubit/auth/socialSignUpCubit.dart';
import 'package:erestro/cubit/helpAndSupport/ticketCubit.dart';
import 'package:erestro/cubit/home/cuisine/restaurantCuisineCubit.dart';
import 'package:erestro/cubit/home/sections/sectionsDetailCubit.dart';
import 'package:erestro/cubit/localization/appLocalizationCubit.dart';
import 'package:erestro/cubit/notificatiion/notificationCubit.dart';
import 'package:erestro/cubit/product/ProductViewAllCubit.dart';
import 'package:erestro/cubit/product/productLoadCubit.dart';
import 'package:erestro/cubit/product/restaurantCategoryCubit.dart';
import 'package:erestro/data/localDataStore/addressLocalDataSource.dart';
import 'package:erestro/data/repositories/address/addressRepository.dart';
import 'package:erestro/cubit/address/addAddressCubit.dart';
import 'package:erestro/cubit/address/addressCubit.dart';
import 'package:erestro/cubit/address/cityDeliverableCubit.dart';
import 'package:erestro/cubit/address/deliveryChargeCubit.dart';
import 'package:erestro/cubit/address/updateAddressCubit.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/auth/deleteMyAccountCubit.dart';
import 'package:erestro/cubit/auth/referAndEarnCubit.dart';
import 'package:erestro/cubit/auth/signInCubit.dart';
import 'package:erestro/cubit/auth/signUpCubit.dart';
import 'package:erestro/cubit/bottomNavigationBar/navicationBarCubit.dart';
import 'package:erestro/data/repositories/cart/cartRepository.dart';
import 'package:erestro/cubit/cart/clearCartCubit.dart';
import 'package:erestro/cubit/cart/getCartCubit.dart';
import 'package:erestro/cubit/cart/manageCartCubit.dart';
import 'package:erestro/cubit/cart/placeOrder.dart';
import 'package:erestro/cubit/cart/removeFromCartCubit.dart';
import 'package:erestro/cubit/favourite/favouriteProductsCubit.dart';
import 'package:erestro/cubit/favourite/favouriteRestaurantCubit.dart';
import 'package:erestro/cubit/favourite/updateFavouriteRestaurant.dart';
import 'package:erestro/cubit/favourite/updateFavouriteProduct.dart';
import 'package:erestro/data/repositories/home/bestOffer/bestOfferRepository.dart';
import 'package:erestro/cubit/home/bestOffer/bestOfferCubit.dart';
import 'package:erestro/cubit/home/cuisine/cuisineCubit.dart';
import 'package:erestro/cubit/home/restaurants/restaurantCubit.dart';
import 'package:erestro/cubit/home/restaurants/topRestaurantCubit.dart';
import 'package:erestro/cubit/home/search/searchCubit.dart';
import 'package:erestro/cubit/home/sections/sectionsCubit.dart';
import 'package:erestro/cubit/home/slider/sliderOfferCubit.dart';
import 'package:erestro/data/repositories/home/slider/sliderRepository.dart';
import 'package:erestro/cubit/order/orderCubit.dart';
import 'package:erestro/cubit/order/orderDetailCubit.dart';
import 'package:erestro/cubit/order/orderLiveTrackingCubit.dart';
import 'package:erestro/data/repositories/order/orderRepository.dart';
import 'package:erestro/cubit/payment/GetWithdrawRequestCubit.dart';
import 'package:erestro/cubit/payment/sendWithdrawRequestCubit.dart';
import 'package:erestro/cubit/product/manageOfflineCartCubit.dart';
import 'package:erestro/cubit/product/offlineCartCubit.dart';
import 'package:erestro/cubit/product/productCubit.dart';
import 'package:erestro/data/repositories/payment/paymentRepository.dart';
import 'package:erestro/data/repositories/product/productRepository.dart';
import 'package:erestro/cubit/promoCode/promoCodeCubit.dart';
import 'package:erestro/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:erestro/data/repositories/promoCode/promoCodeRepository.dart';
import 'package:erestro/cubit/rating/setRiderRatingCubit.dart';
import 'package:erestro/data/repositories/rating/ratingRepository.dart';
import 'package:erestro/cubit/settings/settingsCubit.dart';
import 'package:erestro/data/repositories/settings/settingsRepository.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/data/repositories/systemConfig/systemConfigRepository.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/utils/appLanguages.dart';
import 'package:erestro/utils/hiveBoxKey.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erestro/app/routes.dart';
import 'package:erestro/data/repositories/auth/authRepository.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<Widget> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.dark));
    initializedDownload();
    await Firebase.initializeApp();

    if (defaultTargetPlatform == TargetPlatform.android) {}
  }

  await Hive.initFlutter();
  await Hive.openBox(authBox); //auth box for storing all authentication related details
  await Hive.openBox(settingsBox); //settings box for storing all settings details
  await Hive.openBox(userdetailsBox); //userDetails box for storing all userDetails details
  await Hive.openBox(addressBox); //address box for storing all address details
  await Hive.openBox(searchAddressBox); //searchAddress box for storing all searchAddress details

  return const MyApp();
}

Future<void> initializedDownload() async {
  await FlutterDownloader.initialize(debug: false);
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      //providing global providers
      providers: [
        //Creating cubit/bloc that will be use in whole app or
        //will be use in multiple screens
        BlocProvider<AppLocalizationCubit>(
            create: (_) => AppLocalizationCubit(SettingsRepository())),
        BlocProvider<NavigationBarCubit>(create: (_) => NavigationBarCubit()),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider<SignUpCubit>(create: (_) => SignUpCubit(AuthRepository())),
        BlocProvider<ReferAndEarnCubit>(create: (_) => ReferAndEarnCubit(AuthRepository())),
        BlocProvider<SignInCubit>(create: (_) => SignInCubit(AuthRepository())),
        //BlocProvider<VerifyUserCubit>(create: (_) => VerifyUserCubit(AuthRepository())),
        BlocProvider<SocialSignUpCubit>(create: (_) => SocialSignUpCubit(AuthRepository())),
        BlocProvider<RestaurantCubit>(create: (_) => RestaurantCubit()),
        BlocProvider<TopRestaurantCubit>(create: (_) => TopRestaurantCubit()),
        BlocProvider<CuisineCubit>(create: (_) => CuisineCubit()),
        BlocProvider<RestaurantCuisineCubit>(create: (_) => RestaurantCuisineCubit()),
        BlocProvider<BestOfferCubit>(create: (_) => BestOfferCubit(BestOfferRepository())),
        BlocProvider<SliderCubit>(create: (_) => SliderCubit(SliderRepository())),
        BlocProvider<SectionsCubit>(create: (_) => SectionsCubit()),
        BlocProvider<SectionsDetailCubit>(create: (_) => SectionsDetailCubit()),
        BlocProvider<AddressCubit>(create: (_) => AddressCubit(AddressRepository())),
        BlocProvider<AddAddressCubit>(create: (_) => AddAddressCubit(AddressRepository())),
        BlocProvider<CityDeliverableCubit>(create: (_) => CityDeliverableCubit(AddressRepository(), AddressLocalDataSource())),
        BlocProvider<IsOrderDeliverableCubit>(create: (_) => IsOrderDeliverableCubit(AddressRepository(), AddressLocalDataSource())),
        BlocProvider<PromoCodeCubit>(create: (_) => PromoCodeCubit()),
        BlocProvider<ValidatePromoCodeCubit>(create: (_) => ValidatePromoCodeCubit(PromoCodeRepository())),
        BlocProvider<GetCartCubit>(create: (_) => GetCartCubit(CartRepository())),
        BlocProvider<ProductCubit>(create: (_) => ProductCubit(ProductRepository())),
        BlocProvider<ProductViewAllCubit>(create: (_) => ProductViewAllCubit()),
        BlocProvider<ManageCartCubit>(create: (_) => ManageCartCubit(CartRepository())),
        BlocProvider<RemoveFromCartCubit>(create: (_) => RemoveFromCartCubit(CartRepository())),
        BlocProvider<OrderCubit>(create: (_) => OrderCubit()),
        BlocProvider<PlaceOrderCubit>(create: (_) => PlaceOrderCubit(CartRepository())),
        BlocProvider<SearchCubit>(create: (_) => SearchCubit()),
        BlocProvider<SystemConfigCubit>(create: (_) => SystemConfigCubit(SystemConfigRepository())),
        BlocProvider<OrderDetailCubit>(create: (_) => OrderDetailCubit(OrderRepository())),
        BlocProvider<OrderLiveTrackingCubit>(create: (_) => OrderLiveTrackingCubit(OrderRepository())),
        BlocProvider<UpdateAddressCubit>(create: (_) => UpdateAddressCubit(AddressRepository())),
        BlocProvider<DeliveryChargeCubit>(create: (_) => DeliveryChargeCubit(AddressRepository())),
        BlocProvider<SettingsCubit>(create: (_) => SettingsCubit(SettingsRepository())),
        BlocProvider<SetRiderRatingCubit>(create: (_) => SetRiderRatingCubit(RatingRepository())),
        BlocProvider<FavoriteRestaurantsCubit>(create: (_) => FavoriteRestaurantsCubit()),
        BlocProvider<UpdateRestaurantFavoriteStatusCubit>(create: (_) => UpdateRestaurantFavoriteStatusCubit()),
        BlocProvider<FavoriteProductsCubit>(create: (_) => FavoriteProductsCubit()),
        BlocProvider<UpdateProductFavoriteStatusCubit>(create: (_) => UpdateProductFavoriteStatusCubit()),
        BlocProvider<DeleteMyAccountCubit>(create: (_) => DeleteMyAccountCubit(AuthRepository())),
        BlocProvider<ClearCartCubit>(create: (_) => ClearCartCubit(CartRepository())),
        BlocProvider<OfflineCartCubit>(create: (_) => OfflineCartCubit(ProductRepository())),
        BlocProvider<ManageOfflineCartCubit>(create: (_) => ManageOfflineCartCubit(ProductRepository())),
        BlocProvider<SendWithdrawRequestCubit>(create: (_) => SendWithdrawRequestCubit(PaymentRepository())),
        BlocProvider<GetWithdrawRequestCubit>(create: (_) => GetWithdrawRequestCubit()),
        BlocProvider<TicketCubit>(create: (_) => TicketCubit()),
        BlocProvider<RestaurantCategoryCubit>(create: (_) => RestaurantCategoryCubit()),
        BlocProvider<ProductLoadCubit>(create: (_) => ProductLoadCubit()),
        BlocProvider<NotificationCubit>(
          create: (_) => NotificationCubit(),
        )
      ],
      child: Builder(
        builder: (context) {
          final currentLanguage = context.watch<AppLocalizationCubit>().state.language;
          return MaterialApp(
            builder: (context, widget) {
              return ScrollConfiguration(behavior: GlobalScrollBehavior(), child: widget!);
            },
            theme: ThemeData(scaffoldBackgroundColor: backgroundColor,
              fontFamily: 'Quicksand',
              iconTheme: const IconThemeData(
                color: black,
              ),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: primaryColor,
                    secondary: secondaryColor,
                    background: backgroundColor,
                    error: errorColor,
                    onPrimary: onPrimaryColor,
                    onSecondary: onSecondaryColor,
                    onBackground: onBackgroundColor,
                  )
              //visualDensity: VisualDensity.adaptivePlatformDensity, colorScheme: ColorScheme.fromSwatch(primarySwatch: ColorsRes.appColor_material).copyWith(secondary: ColorsRes.yellow),
            ),
            locale: currentLanguage,
          localizationsDelegates: const [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: appLanguages.map((appLanguage) {
            return UiUtils.getLocaleFromLanguageCode(appLanguage.languageCode);
          }).toList(),
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.onGenerateRouted,
          );
        },
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
