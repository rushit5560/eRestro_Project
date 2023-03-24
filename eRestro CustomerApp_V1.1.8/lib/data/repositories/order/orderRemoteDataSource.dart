import 'package:erestro/data/model/orderLiveTrackingModel.dart';
import 'package:erestro/data/model/orderModel.dart';
import 'package:erestro/utils/api.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';


class OrderRemoteDataSource {
  //to getUserOrder
  Future<OrderModel> getOrder({String? status, String? orderId, String? reason}) async {
    try {
      //body of post request
      final body = {statusKey: status, orderIdKey: orderId, reasonKey: reason ?? ""};
      final result = await Api.post(body: body, url: Api.updateOrderStatusUrl, token: true, errorCode: true);
      return OrderModel.fromJson(result);
    } catch (e) {
      //print(e.toString());
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  //to getUserOrderLiveTracking
  Future<OrderLiveTrackingModel> getOrderLiveTracing({String? orderId}) async {
    try {
      //body of post request
      final body = {orderIdKey: orderId};
      final result = await Api.post(body: body, url: Api.getLiveTrackingDetailsUrl, token: true, errorCode: true);
      return OrderLiveTrackingModel.fromJson(result['data'][0]);
    } catch (e) {
      //print(e.toString());
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
