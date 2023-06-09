import 'package:erestro/data/model/bestOfferModel.dart';
import 'package:erestro/data/repositories/home/bestOffer/bestOfferRemoteDataSource.dart';
import 'package:erestro/utils/api.dart';

class BestOfferRepository {
  static final BestOfferRepository _bestOfferRepository = BestOfferRepository._internal();
  late BestOfferRemoteDataSource _bestOfferRemoteDataSource;

  factory BestOfferRepository() {
    _bestOfferRepository._bestOfferRemoteDataSource = BestOfferRemoteDataSource();
    return _bestOfferRepository;
  }

  BestOfferRepository._internal();

  Future<List<BestOfferModel>> getBestOffer() async {
    try {
      List<BestOfferModel> result = await _bestOfferRemoteDataSource.getBestOffer();
      return result/*.map((e) => BestOfferModel.fromJson(Map.from(e))).toList()*/;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

}
