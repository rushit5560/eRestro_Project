import 'package:erestro/ui/styles/color.dart';
import 'package:erestro/ui/styles/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RadioItem extends StatelessWidget {
  final RadioModel _item;

  RadioItem(this._item, {Key? key}) : super(key: key);

  double? height;
  double? width;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Container(
      //decoration: DesignConfig.boxDecorationContainerCardShadow(ColorsRes.textFieldBackground, ColorsRes.shadowTextField, 10, 0, 3, 10, 0),
      //margin: EdgeInsetsDirectional.only(bottom: height! / 50.0),
      padding: EdgeInsetsDirectional.only(start: height! / 40.0, end: height! / 40.0, bottom: height!/60.0, top: height!/60.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _item.img != ""
                ? Container(padding: const EdgeInsetsDirectional.all(5.0), decoration: DesignConfig.boxDecorationContainerBorderCustom(Theme.of(context).colorScheme.onSecondary.withOpacity(0.50), Theme.of(context).colorScheme.onBackground, 5.0),
                  child: SvgPicture.asset(
                      DesignConfig.setSvgPath(_item.img!), height: 20, width: 20,
                    ),
                )
                : Container(),
            SizedBox(width: height! / 99.0),
            Text(
              _item.name!,
              style: TextStyle(
              color:  Theme.of(context).colorScheme.onSecondary,
              fontWeight: FontWeight.w400,
              fontStyle:  FontStyle.normal,
              fontSize: 14.0
          ),
            )
          ]),
          Icon(
            Icons.radio_button_checked,
            color: _item.isSelected! ? Theme.of(context).colorScheme.primary : lightFont,
          ),
        ],
      ),
    );
  }
}

class RadioModel {
  bool? isSelected;
  final String? img;
  final String? name;

  RadioModel({this.isSelected, this.name, this.img});
}
