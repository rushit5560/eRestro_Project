//State
import 'package:erestro/data/repositories/payment/paymentRepository.dart';
import 'package:erestro/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TransactionState {}

class TransactionIntial extends TransactionState {}

class TransactionFetchInProgress extends TransactionState {}

class TransactionFetchSuccess extends TransactionState {
  final String? userId, orderId, amount;

  TransactionFetchSuccess({this.userId, this.orderId, this.amount});
}

class TransactionFetchFailure extends TransactionState {
  final String errorCode, errorStatusCode;
  TransactionFetchFailure(this.errorCode, this.errorStatusCode);
}

class TransactionCubit extends Cubit<TransactionState> {
  final PaymentRepository _paymentRepository;
  TransactionCubit(this._paymentRepository) : super(TransactionIntial());

  //to getTransaction user
  void getTransaction(String? userId, String? orderId, String? amount) {
    //emitting GetTransactionProgress state
    emit(TransactionFetchInProgress());
    //GetTransaction details in api
    _paymentRepository
        .getPayment(userId, orderId, amount)
        .then((value) => emit(TransactionFetchSuccess(userId: userId, orderId: orderId, amount: amount)))
        .catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("transactionError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(TransactionFetchFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
