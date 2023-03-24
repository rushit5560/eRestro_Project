import 'package:erestro/data/model/productModel.dart';
import 'package:erestro/data/model/sectionsModel.dart';
import 'package:erestro/data/repositories/product/productRemoteDataSource.dart';
import 'package:erestro/utils/api.dart';

class ProductRepository {
  static final ProductRepository _productRepository = ProductRepository._internal();
  late ProductRemoteDataSource _productRemoteDataSource;

  factory ProductRepository() {
    _productRepository._productRemoteDataSource = ProductRemoteDataSource();
    return _productRepository;
  }
  ProductRepository._internal();

  //to getProduct
  Future<ProductModel> getProductData(
      String? partnerId, String? latitude, String? longitude, String? userId, String? cityId, String? vegetarian) async {
    try {
      ProductModel result = await _productRemoteDataSource.getProduct(
          partnerId: partnerId, latitude: latitude ?? "", longitude: longitude ?? "", userId: userId, cityId: cityId, vegetarian: vegetarian);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  //to getOfflineCartData
  Future/* <ProductModel> */<List<ProductDetails>> getOfflineCartData(String? latitude, String? longitude, String? cityId, String? productVariantIds) async {
    try {
      /* ProductModel */List<ProductDetails> result = await _productRemoteDataSource.getOfflineCart(
          latitude: latitude ?? "", longitude: longitude ?? "", cityId: cityId, productVariantIds: productVariantIds);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  //to manageOfflineCartData
  Future<ProductModel> manageOfflineCartData(String? latitude, String? longitude, String? cityId, String? productVariantIds) async {
    try {
      ProductModel result = await _productRemoteDataSource.manageOfflineCart(
          latitude: latitude ?? "", longitude: longitude ?? "", cityId: cityId, productVariantIds: productVariantIds);
      print("result:${result.total}-${result.offset}-${result.data!.length}");
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }
}
