import 'package:erestro/utils/api.dart';
import 'package:erestro/data/model/deliveryBoyRatingModel.dart';
import 'package:erestro/data/repositories/rating/ratingRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SetRiderRatingState {}

class SetRiderRatingInitial extends SetRiderRatingState {}

class SetRiderRatingProgress extends SetRiderRatingState {}

class SetRiderRatingSuccess extends SetRiderRatingState {
  final RiderRatingModel riderRatingModel;

  SetRiderRatingSuccess(this.riderRatingModel);
}

class SetRiderRatingFailure extends SetRiderRatingState {
  final String errorCode, errorStatusCode;
  SetRiderRatingFailure(this.errorCode, this.errorStatusCode);
}

class SetRiderRatingCubit extends Cubit<SetRiderRatingState> {
  final RatingRepository _ratingRepository;

  SetRiderRatingCubit(this._ratingRepository) : super(SetRiderRatingInitial());

  void setRiderRating(String? userId, String? riderId, String? rating, String? comment) {
    emit(SetRiderRatingProgress());
    _ratingRepository.setRiderRating(userId,  riderId,  rating,  comment).then((value) => emit(SetRiderRatingSuccess(RiderRatingModel(/*data: userId,  RiderId: RiderId,  rating: rating,  comment: comment*/)))).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      //print("setRiderRatingError:${apiMessageAndCodeException.errorMessage.toString()}");
      emit(SetRiderRatingFailure(apiMessageAndCodeException.errorMessage.toString(), apiMessageAndCodeException.errorStatusCode.toString()));
    });
  }
}