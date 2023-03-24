import 'package:erestro/data/model/orderModel.dart';
import 'package:erestro/data/repositories/order/orderRepository.dart';
import 'package:erestro/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
abstract class OrderDetailState {}

class OrderDetailInitial extends OrderDetailState {}

class OrderDetail extends OrderDetailState {
  final List<OrderModel> orderDetailList;

  OrderDetail({required this.orderDetailList});
}

class OrderDetailProgress extends OrderDetailState {
  OrderDetailProgress();
}

class OrderDetailSuccess extends OrderDetailState {
  final String? status, orderId;
  OrderDetailSuccess(this.status, this.orderId);
}

class OrderDetailFailure extends OrderDetailState {
  final String errorMessage, errorStatusCode;
  OrderDetailFailure(this.errorMessage, this.errorStatusCode);
}

class OrderDetailCubit extends Cubit<OrderDetailState> {
  final OrderRepository _orderRepository;
  OrderDetailCubit(this._orderRepository) : super(OrderDetailInitial());

  //to getOrder user
  void getOrderDetail({
    String? status,
    String? orderId,
    String? reason,
  }) {
    //emitting GetOrderProgress state
    emit(OrderDetailProgress());
    //GetOrderDetail particular order details in api
    _orderRepository.getOrderData(status, orderId, reason).then((value) => emit(OrderDetailSuccess(status, orderId))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("orderDetailError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(OrderDetailFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
