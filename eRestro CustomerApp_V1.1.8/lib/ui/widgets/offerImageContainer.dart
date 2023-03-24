import 'package:erestro/data/model/bestOfferModel.dart';
import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:flutter/material.dart';

class OfferImageContainer extends StatelessWidget {
  final List<BestOfferModel> bestOfferList;
  final double? width, height;
  final int index;
  const OfferImageContainer(
      {Key? key,
      required this.bestOfferList,
      this.width,
      this.height,
      required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsetsDirectional.only(
            top: height! / 88.0, start: width! / 20.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [shaderColor, black],
              ).createShader(bounds);
            },
            blendMode: BlendMode.darken,
            child: DesignConfig.imageWidgets(bestOfferList[index].image!, height! / 4, width! / 1.1,"2"),
          ),
        ));
  }
}
