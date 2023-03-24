import 'package:erestro/data/localDataStore/addressLocalDataSource.dart';
import 'package:erestro/data/repositories/address/addressRepository.dart';
import 'package:erestro/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class IsOrderDeliverableState {}

class IsOrderDeliverableInitial extends IsOrderDeliverableState {}

class IsOrderDeliverableProgress extends IsOrderDeliverableState {}

class IsOrderDeliverableSuccess extends IsOrderDeliverableState {
  final String? message;

  IsOrderDeliverableSuccess(this.message);
}

class IsOrderDeliverableFailure extends IsOrderDeliverableState {
  final String errorStatusCode, errorMessage;
  IsOrderDeliverableFailure(this.errorMessage, this.errorStatusCode);
}

class IsOrderDeliverableCubit extends Cubit<IsOrderDeliverableState> {
  final AddressRepository _addressRepository;
  final AddressLocalDataSource _addressLocalDataSource;

  IsOrderDeliverableCubit(this._addressRepository, this._addressLocalDataSource) : super(IsOrderDeliverableInitial());

  fetchIsOrderDeliverable(String? partnerId, String? latitude, String? longitude, String? addressId) {
    emit(IsOrderDeliverableProgress());
    _addressRepository.getIsOrderDeliverable(partnerId, latitude, longitude, addressId).then((value) => emit(IsOrderDeliverableSuccess(value))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("IsOrderDeliverableError:${apiMessageAndCodeException.errorMessage}");
      emit(IsOrderDeliverableFailure(apiMessageAndCodeException.errorMessage, apiMessageAndCodeException.errorStatusCode!));
    });
  }

  String getCityId() {
    if (state is IsOrderDeliverableSuccess) {
      //print("check City Id :"+(state as isOrderDeliverableSuccess).cityId!);
      return (state as IsOrderDeliverableSuccess).message!;
    } else if (state is IsOrderDeliverableFailure) {
      //print("city..!!");
    }
    return "";
  }
}
