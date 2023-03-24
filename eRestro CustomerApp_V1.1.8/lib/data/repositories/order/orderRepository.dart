import 'package:erestro/data/model/orderLiveTrackingModel.dart';
import 'package:erestro/data/model/orderModel.dart';
import 'package:erestro/data/repositories/order/orderRemoteDataSource.dart';
import 'package:erestro/utils/api.dart';

class OrderRepository {
  static final OrderRepository _orderRepository = OrderRepository._internal();
  late OrderRemoteDataSource _orderRemoteDataSource;

  factory OrderRepository() {
    _orderRepository._orderRemoteDataSource = OrderRemoteDataSource();
    return _orderRepository;
  }
  OrderRepository._internal();

  //to getOrder
  Future<OrderModel> getOrderData(String? status, String? orderId, String? reason) async {
    try {
      OrderModel result = await _orderRemoteDataSource.getOrder(status: status, orderId: orderId, reason: reason);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    }  catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  //to getOrderLiveTracking
  Future<OrderLiveTrackingModel> getOrderLiveTrackingData(String? orderId) async {
    try {
      OrderLiveTrackingModel result = await _orderRemoteDataSource.getOrderLiveTracing(orderId: orderId);
      return result;
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    }  catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
