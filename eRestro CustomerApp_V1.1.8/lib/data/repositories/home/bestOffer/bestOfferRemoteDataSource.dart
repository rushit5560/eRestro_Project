import 'package:erestro/data/model/bestOfferModel.dart';
import 'package:erestro/utils/api.dart';


class BestOfferRemoteDataSource {
  Future<List<BestOfferModel>> getBestOffer() async {
    try {
      final body = {};
      final result = await Api.post(body: body, url: Api.getOfferImagesUrl, token: true, errorCode: false);
      return (result['data'] as List).map((e) => BestOfferModel.fromJson(Map.from(e))).toList();
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
