import 'package:erestro/data/model/authModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erestro/data/repositories/auth/authRepository.dart';

//State
@immutable
abstract class SignInState {}

class SignInInitial extends SignInState {}

class SignIn extends SignInState {
  //to store authDetials
  final AuthModel authModel;

  SignIn({required this.authModel});
}

class SignInProgress extends SignInState {
  SignInProgress();
}

class SignInSuccess extends SignInState {
  final AuthModel authModel;
  SignInSuccess(this.authModel);
}

class SignInFailure extends SignInState {
  final String errorMessage;
  SignInFailure(this.errorMessage);
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;
  SignInCubit(this._authRepository) : super(SignInInitial());

  //to signIn user
  void signInUser({
    // AuthModel? authModel,
    String? mobile,
    //String? password,
  }) {
    //emitting signInProgress state
    emit(SignInProgress());
    //signIn user with given provider and also add user detials in api
    _authRepository
        .login(
      mobile: mobile,
      /*password: password,*/
    )
        .then((result) {
      //success
      print(AuthModel.fromJson(result).id);
      emit(SignInSuccess(AuthModel.fromJson(result)));
    }).catchError((e) {
      //failure
      //print("signInError:${e.toString()}");
      emit(SignInFailure(e.toString()));
    });
  }
}
