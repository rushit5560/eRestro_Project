import 'package:erestro/data/model/faqsModel.dart';
import 'package:erestro/data/repositories/faq/faqsRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FaqsState {}

class FaqsInitial extends FaqsState {}

class FaqsProgress extends FaqsState {}

class FaqsSuccess extends FaqsState {
  final List<FaqsModel> faqsList;

  FaqsSuccess(this.faqsList);
}

class FaqsFailure extends FaqsState {
  final String errorCode;

  FaqsFailure(this.errorCode);
}

class FaqsCubit extends Cubit<FaqsState> {
  final FaqsRepository _faqsRepository;

  FaqsCubit(this._faqsRepository) : super(FaqsInitial());

  void fetchFaqs() {
    emit(FaqsProgress());
    _faqsRepository.getFaqs().then((value) => emit(FaqsSuccess(value))).catchError((e) {
      //print("faqsError:${e.toString()}");
      emit(FaqsFailure(e.toString()));
    });
  }
}