import 'package:erestro/data/model/orderModel.dart';
import 'package:erestro/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erestro/utils/apiBodyParameterLabels.dart';

@immutable
abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderProgress extends OrderState {}

class OrderSuccess extends OrderState {
  final List<OrderModel> orderList;
  final int totalData;
  final bool hasMore;
  OrderSuccess(this.orderList, this.totalData, this.hasMore);
}

class OrderFailure extends OrderState {
  final String errorMessage, errorStatusCode;
  OrderFailure(this.errorMessage, this.errorStatusCode);
}

String? totalHasMore;

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(OrderInitial());
  Future<List<OrderModel>> _fetchData({
    required String limit,
    String? offset,
    required String? userId,
    String? id,
  }) async {
    try {
      //
      //body of post request
      final body = {
        limitKey: limit,
        offsetKey: offset ?? "",
        userIdKey: userId,
        idKey: id ?? "",
      };

      if (offset == null) {
        body.remove(offset);
      }
      final result = await Api.post(body: body, url: Api.getOrdersUrl, token: true, errorCode: true);
      totalHasMore = result['total'].toString();
      return (result['data'] as List).map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      //print("orderError:${e.toString()}");
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  void fetchOrder(String limit, String userId, String id) {
    emit(OrderProgress());
    _fetchData(limit: limit, userId: userId, id: id).then((value) {
      final List<OrderModel> usersDetails = value;
      final total =  int.parse(totalHasMore!);
      emit(OrderSuccess(
        usersDetails,
        total,
        total > usersDetails.length,
      ));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("orderError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(OrderFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  void fetchMoreOrderData(String limit, String? userId, String? id) {
    _fetchData(limit: limit, offset: (state as OrderSuccess).orderList.length.toString(), userId: userId, id: id).then((value) {
      //
      final oldState = (state as OrderSuccess);
      final List<OrderModel> usersDetails = value;
      final List<OrderModel> updatedUserDetails = List.from(oldState.orderList);
      updatedUserDetails.addAll(usersDetails);
      emit(OrderSuccess(updatedUserDetails, oldState.totalData, oldState.totalData > updatedUserDetails.length));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("orderLoadMoreError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(OrderFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }

  bool hasMoreData() {
    if (state is OrderSuccess) {
      return (state as OrderSuccess).hasMore;
    } else {
      return false;
    }
  }
}
