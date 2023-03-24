import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:erestro/cubit/auth/authCubit.dart';
import 'package:erestro/cubit/promoCode/promoCodeCubit.dart';
import 'package:erestro/cubit/promoCode/validatePromoCodeCubit.dart';
import 'package:erestro/data/repositories/promoCode/promoCodeRepository.dart';
import 'package:erestro/cubit/systemConfig/systemConfigCubit.dart';
import 'package:erestro/ui/styles/dotted_border.dart';
import 'package:erestro/ui/screen/cart/cart_screen.dart';
import 'package:erestro/ui/screen/settings/no_internet_screen.dart';
import 'package:erestro/ui/widgets/noDataContainer.dart';
import 'package:erestro/ui/widgets/simmer/promoCodeSimmer.dart';
import 'package:erestro/utils/constants.dart';
import 'package:erestro/utils/labelKeys.dart';
import 'package:erestro/utils/uiUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:erestro/utils/string.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:erestro/utils/internetConnectivity.dart';
import 'package:intl/intl.dart';

class OfferCouponsScreen extends StatefulWidget {
  const OfferCouponsScreen({Key? key}) : super(key: key);

  @override
  OfferCouponsScreenState createState() => OfferCouponsScreenState();
}

class OfferCouponsScreenState extends State<OfferCouponsScreen> {
  double? width, height;
  ScrollController promoCodeController = ScrollController();
  String _connectionStatus = 'unKnown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String? promoCodeData = "", finalTotalData = "";
  TextEditingController addCouponsController = TextEditingController(text: "");
  bool checkStatusOfMessage = true;
  var inputFormat = DateFormat('yyyy-MM-dd');
  var outputFormat = DateFormat('dd,MMMM yyyy');

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
    promoCodeController.addListener(promoCodeScrollListener);
    Future.delayed(Duration.zero, () {
      context.read<PromoCodeCubit>().fetchPromoCode(perPage);
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  promoCodeScrollListener() {
    if (promoCodeController.position.maxScrollExtent == promoCodeController.offset) {
      if (context.read<PromoCodeCubit>().hasMoreData()) {
        context.read<PromoCodeCubit>().fetchMorePromoCodeData(perPage);
      }
    }
  }

  Widget noCoupnData() {
    return NoDataContainer(
        image: "coupon_applied",
        title: UiUtils.getTranslatedLabel(context, noCouponYetLabel),
        subTitle: UiUtils.getTranslatedLabel(context, noCouponYetSubTitleLabel),
        width: width!,
        height: height!);
  }

  Widget offerCoupons() {
    return BlocConsumer<PromoCodeCubit, PromoCodeState>(
        bloc: context.read<PromoCodeCubit>(),
        listener: (context, state) {},
        builder: (context, state) {
          if (state is PromoCodeProgress || state is PromoCodeInitial) {
            return PromoCodeSimmer(length: 8, width: width!, height: height!);
          }
          if (state is PromoCodeFailure) {
            print(state.errorMessage.toString());
            return SizedBox(
            height: height! / 1.3,
            child: noCoupnData());
            /* return Center(
                child: Text(
              state.errorMessage.toString(),
              textAlign: TextAlign.center,
            )); */
          }
          final promoCodeList = (state as PromoCodeSuccess).promoCodeList;
          final hasMore = state.hasMore;
          return SizedBox(
            height: height! / 1.3,
            child: promoCodeList.isEmpty?noCoupnData():ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: promoCodeList.length,
                    itemBuilder: (BuildContext context, index) {
                    var inputDate = inputFormat.parse(promoCodeList[index].endDate!);
                    var outputDate = outputFormat.format(inputDate);
                  return hasMore && index == (promoCodeList.length - 1)
                      ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                      : BlocProvider<ValidatePromoCodeCubit>(
                          create: (context) => ValidatePromoCodeCubit(PromoCodeRepository()),
                          child: Builder(builder: (context) {
                            return BlocConsumer<ValidatePromoCodeCubit, ValidatePromoCodeState>(
                                bloc: context.read<ValidatePromoCodeCubit>(),
                                listener: (context, state) {
                                  if (state is ValidatePromoCodeFetchFailure) {
                                    UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, promoCodeLabel), state.errorMessage, context, false, type: "2");
                                    if(state.errorStatusCode.toString() == "102"){
                                      reLogin(context);
                                    }
                                  }
                                  if (state is ValidatePromoCodeFetchSuccess) {
                                    //print("success:"+state.promoCodeValidateModel!.promoCode!);
                                    promoCode = state.promoCodeValidateModel!.promoCode!.toString();
                                    promoAmt = double.parse(state.promoCodeValidateModel!.finalDiscount!);

                                    coupons(context, promoCode!, promoAmt, double.parse(state.promoCodeValidateModel!.finalTotal!));
                                  }
                                },
                                builder: (context, state) {
                                  return Stack(
                                    children: [
                                      Container(padding: EdgeInsetsDirectional.only(start: width!/80.0, top: height!/80.0, end: width!/80.0, bottom: height!/80.0),
                                          margin: EdgeInsetsDirectional.only(start: width! / 40.0, end: width! / 40.0),
                                          child: Row(
                                            children: [
                                              Container(alignment: Alignment.center,
                                                width: 52,
                                                height: 144,
                                                decoration: DesignConfig.boxDecorationContainerRoundHalf(Theme.of(context).colorScheme.primary, 10, 10, 0, 0,), child: RotatedBox(quarterTurns: -1,
                                                child: Text(
                                                    UiUtils.getTranslatedLabel(context, discountLabel),
                                                    style: const TextStyle(
                                                        color:  Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontStyle:  FontStyle.normal,
                                                        fontSize: 14.0, letterSpacing: 6.3
                                                    ),
                                                    textAlign: TextAlign.center                
                                                    ),
                                              )
                                              ),
                                              Expanded(
                                                child: Container(
                                                  width: width!,
                                                  height: height!/ 5.15,
                                                  decoration: DesignConfig.boxDecorationContainerRoundHalf(Theme.of(context).colorScheme.onBackground, 0, 0, 10, 10,),
                                                  padding: EdgeInsetsDirectional.only(start: width!/40.0, top: height!/80.0, bottom: height!/80.0, end: width!/40.0),
                                                  child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(5.0)), child: DesignConfig.imageWidgets(
                                                              promoCodeList[index].image!, 40.0, 40.0, "2")),
                                                            Container(color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                                                              margin: EdgeInsetsDirectional.only(start: width!/60.0),
                                                              child: DottedBorder(color: Theme.of(context).colorScheme.primary,
                                                                dashPattern: const [8, 4],padding: const EdgeInsets.all(5),
                                                                strokeWidth: 1,
                                                                strokeCap: StrokeCap.round,
                                                                borderType: BorderType.RRect,
                                                                radius: const Radius.circular(5.0),
                                                                child: Text("${StringsRes.coupon} ${promoCodeList[index].promoCode!}",
                                                                    textAlign: TextAlign.center,
                                                                    style: TextStyle(
                                                                      color: Theme.of(context).colorScheme.onSecondary,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.w500,
                                                                      fontStyle:  FontStyle.normal,
                                                                    )),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: height!/80.0),
                                                        Text("${promoCodeList[index].discount!}${StringsRes.percentSymbol} ${StringsRes.off} ${StringsRes.upTo} ${context.read<SystemConfigCubit>().getCurrency() + promoCodeList[index].maxDiscountAmt!}",
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                  color: Theme.of(context).colorScheme.onSecondary,
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w600,
                                                                  fontStyle:  FontStyle.normal)),
                                                                  const SizedBox(height: 5.0),
                                                        Text(
                                                          promoCodeList[index].message!,
                                                          style: const TextStyle(
                                                              color:  greayLightColor,
                                                              fontWeight: FontWeight.w500,
                                                              fontStyle:  FontStyle.normal,
                                                              fontSize: 10.0
                                                          ),
                                                          textAlign: TextAlign.left                
                                                          ),
                                                          SizedBox(height: height!/80.0),
                                                          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                                            Expanded(
                                                              child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Text(
                                                                  UiUtils.getTranslatedLabel(context, expiresLabel),
                                                                  style: const TextStyle(
                                                                      color:  greayLightColor,
                                                                      fontWeight: FontWeight.w500,
                                                                      fontStyle:  FontStyle.normal,
                                                                      fontSize: 10.0
                                                                  ),
                                                                  textAlign: TextAlign.left                
                                                                  ),
                                                                  Text(
                                                                  outputDate.toString(),
                                                                  style: const TextStyle(
                                                                      color:  greayLightColor,
                                                                      fontWeight: FontWeight.w600,
                                                                      fontStyle:  FontStyle.normal,
                                                                      fontSize: 10.0
                                                                  ),
                                                                  textAlign: TextAlign.left                
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap:(){
                                                                promoCodeData = promoCodeList[index].promoCode!;
                                                                  finalTotalData = subTotal.toString();
                                                                  context
                                                                      .read<ValidatePromoCodeCubit>()
                                                                      .getValidatePromoCode(promoCodeData, context.read<AuthCubit>().getId(), finalTotalData);
                                                              },
                                                              child: Text(
                                                                UiUtils.getTranslatedLabel(context, applyLabel),
                                                                style: TextStyle(
                                                                    color:  Theme.of(context).colorScheme.primary,
                                                                    fontWeight: FontWeight.w700,
                                                                    fontStyle:  FontStyle.normal,
                                                                    fontSize: 10.0
                                                                ),
                                                                textAlign: TextAlign.left                
                                                                ),
                                                            )
                                                          ]),         
                                                      ]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(top: 10, bottom: 10,
                                          child: Container(alignment: Alignment.centerLeft,
                                                  width: 21,
                                                  height: 21,
                                                  decoration: DesignConfig.circle(Theme.of(context).colorScheme.background)
                                                ),
                                        ),
                                        Positioned(top: 10, bottom: 10, right: 0,
                                          child: Container(alignment: Alignment.centerLeft,
                                                  width: 21,
                                                  height: 21,
                                                  decoration: DesignConfig.circle(Theme.of(context).colorScheme.background)
                                                ),
                                        )
                                    ],
                                  );
                                });
                          }),
                        );
                })
          );
        });
  }

  void coupons(BuildContext context, String code, double price, double finalAmount) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            shape: DesignConfig.setRounded(25.0),
            //title: Text('Not in stock'),
            content: SizedBox(
              height: height! / 2.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(DesignConfig.setSvgPath("coupon_applied")),
                  Text(" ' ${StringsRes.use} $code ' ${StringsRes.applie}",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5.0),
                  Text("${StringsRes.youSaved} ",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 28, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5.0),
                  Text(context.read<SystemConfigCubit>().getCurrency() + price.toString(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 28, fontWeight: FontWeight.w500)),
                ],
              ),
            ));
      },
    );
    await Future.delayed(
      const Duration(seconds: 1),
    );
    Navigator.of(context).pop();

    Navigator.of(context).pop({"code": code, "amount": price, "finalAmount": finalAmount});
  }

  Widget addCoupons() {
    return Container(
        decoration: DesignConfig.boxDecorationContainerBorder(commentBoxBorderColor, textFieldBackground, 10.0),
        alignment: Alignment.centerLeft,
        margin: EdgeInsetsDirectional.only(
          start: width! / 40.0,
          end: width! / 40.0,
        ),
        padding: EdgeInsetsDirectional.only(start: width! / 20.0),
        child: TextField(onChanged: (value){
          if(value.isEmpty){
            checkStatusOfMessage = true;
          }
          else{
            checkStatusOfMessage=false;
          }
          setState(() {
            
          });
        },
          controller: addCouponsController,
          cursorColor: lightFont,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: UiUtils.getTranslatedLabel(context, addCouponLabel),
            hintStyle: const TextStyle(
              color: lightFont,
              fontSize: 14.0,
            ),
            suffixIcon: checkStatusOfMessage==false?BlocProvider<ValidatePromoCodeCubit>(
              create: (context) => ValidatePromoCodeCubit(PromoCodeRepository()),
              child: Builder(builder: (context) {
                return BlocConsumer<ValidatePromoCodeCubit, ValidatePromoCodeState>(
                    bloc: context.read<ValidatePromoCodeCubit>(),
                    listener: (context, state) {
                      if (state is ValidatePromoCodeFetchFailure) {
                        print("promocode${state.errorMessage}");
                        UiUtils.setSnackBar(UiUtils.getTranslatedLabel(context, promoCodeLabel), state.errorMessage, context, false, type: "2");
                        checkStatusOfMessage = false;
                        if(state.errorStatusCode.toString() == "102"){
                          reLogin(context);
                        }
                      }
                      if (state is ValidatePromoCodeFetchSuccess) {
                        //print("success:"+state.promoCodeValidateModel!.promoCode!);
                        promoCode = state.promoCodeValidateModel!.promoCode!.toString();
                        promoAmt = double.parse(state.promoCodeValidateModel!.finalDiscount!);

                        coupons(context, promoCode!, promoAmt, double.parse(state.promoCodeValidateModel!.finalTotal!));
                      }
                    },
                    builder: (context, state) {
                      return InkWell(
                          onTap: () {
                            if(addCouponsController.text.trim().isNotEmpty){
                            //setState(() {
                              checkStatusOfMessage = true;
                            //});
                            promoCodeData = addCouponsController.text.trim();
                            finalTotalData = subTotal.toString();
                            context
                                .read<ValidatePromoCodeCubit>()
                                .getValidatePromoCode(promoCodeData, context.read<AuthCubit>().getId(), finalTotalData);
                                }
                          },
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(top: height! / 50.0),
                            child: Text(UiUtils.getTranslatedLabel(context, applyLabel), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ));
                    });
              }),
            ):const SizedBox(),
          ),
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: lightFont,
            fontSize: 14.0,
          ),
        ));
  }

  @override
  void dispose() {
    promoCodeController.dispose();
    addCouponsController.dispose();
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
              appBar: DesignConfig.appBar(context, width!, UiUtils.getTranslatedLabel(context, offerCouponsLabel), const PreferredSize(
                                preferredSize: Size.zero,child:SizedBox())),
              body: Container(height: height!,
                  margin: EdgeInsetsDirectional.only(top: height! / 80.0), //padding: EdgeInsetsDirectional.only(end: width! / 40.0, start: width! / 40.0),
                  width: width,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(decoration: DesignConfig.boxDecorationContainer(Theme.of(context).colorScheme.onBackground, 10.0), padding: EdgeInsetsDirectional.only(top: height!/80, bottom: height!/80.0),child: addCoupons()),
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: width! / 20.0, top: height! / 80.0),
                          child: Text(UiUtils.getTranslatedLabel(context, availableCouponsLabel),
                              textAlign: TextAlign.start,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        offerCoupons(),
                      ],
                    ),
                  )),
            ),
    );
  }
}
