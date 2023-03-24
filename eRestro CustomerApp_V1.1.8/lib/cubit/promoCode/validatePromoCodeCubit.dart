import 'package:erestro/utils/api.dart';
import 'package:erestro/data/repositories/promoCode/promoCodeRepository.dart';
import 'package:erestro/data/model/promoCodeValidateModel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ValidatePromoCodeState {}

class ValidatePromoCodeIntial extends ValidatePromoCodeState {}

class ValidatePromoCodeFetchInProgress extends ValidatePromoCodeState {}

class ValidatePromoCodeFetchSuccess extends ValidatePromoCodeState {
  final PromoCodeValidateModel? promoCodeValidateModel;

  ValidatePromoCodeFetchSuccess({this.promoCodeValidateModel});
}

class ValidatePromoCodeFetchFailure extends ValidatePromoCodeState {
  final String errorMessage, errorStatusCode;
  ValidatePromoCodeFetchFailure(this.errorMessage, this.errorStatusCode);
}

class ValidatePromoCodeCubit extends Cubit<ValidatePromoCodeState> {
  final PromoCodeRepository _validatePromoCodeRepository;
  ValidatePromoCodeCubit(this._validatePromoCodeRepository) : super(ValidatePromoCodeIntial());

  //to ValidatePromoCode
  void getValidatePromoCode(String? promoCode, String? userId, String? finalTotal) {
  
    //emitting ValidatePromoCodeFetchInProgress state
    emit(ValidatePromoCodeFetchInProgress());
    //ValidatePromoCode
    _validatePromoCodeRepository
        .validatePromoCodeData(promoCode: promoCode, userId: userId, finalTotal: finalTotal)
        .then((value) => emit(ValidatePromoCodeFetchSuccess(promoCodeValidateModel: value)))
        .catchError((e) {
        ApiMessageAndCodeException apiMessageAndCodeException = e;
        //print("validatePromoCodeError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(ValidatePromoCodeFetchFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}
