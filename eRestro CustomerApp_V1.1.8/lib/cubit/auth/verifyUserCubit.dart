/*import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erestro/data/repositories/auth/authRepository.dart';


//State
@immutable
abstract class VerifyUserState {}

class VerifyUserInitial extends VerifyUserState {}

class VerifyUserProgress extends VerifyUserState {
  VerifyUserProgress();
}

class VerifyUserSuccess extends VerifyUserState {

  VerifyUserSuccess();
}

class VerifyUserFailure extends VerifyUserState {
  final String errorMessage;
  VerifyUserFailure(this.errorMessage);
}

class VerifyUserCubit extends Cubit<VerifyUserState> {
  final AuthRepository _authRepository;
  VerifyUserCubit(this._authRepository) : super(VerifyUserInitial());

  //to signIn user
  void verifyUser({
    String? mobile}) {
    //emitting signInProgress state
      emit(VerifyUserProgress());
    //signIn user with given provider and also add user detials in api
    _authRepository
        .verify(mobile: mobile
    )
        .then((result) {
      //success
       emit(VerifyUserSuccess());
    }).catchError((e) {
      //failure
      //print("verifyUserError:${e.toString()}");
      emit(VerifyUserFailure(e.toString()));
    });
  }

}*/
