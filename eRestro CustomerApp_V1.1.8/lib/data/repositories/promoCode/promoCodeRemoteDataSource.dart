import 'package:erestro/data/model/promoCodeValidateModel.dart';
import 'package:erestro/utils/api.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';


class PromoCodeRemoteDataSource {
//to promoCode
  Future<PromoCodeValidateModel> validatePromoCode({String? promoCode, String? userId, String? finalTotal}) async {
    try {
      //body of post request
      final body = {promoCodeKey: promoCode, userIdKey: userId, finalTotalKey: finalTotal};
      final result = await Api.post(body: body, url: Api.validatePromoCodeUrl, token: true, errorCode: true);
      return PromoCodeValidateModel.fromJson(result['data'][0]);
    } catch (e) {
      print(e.toString());
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
