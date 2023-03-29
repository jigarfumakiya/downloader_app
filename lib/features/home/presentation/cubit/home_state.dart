part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();
}

class HomeInitial extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoading extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeFailureState extends HomeState {
  final String failureMessage;

  const HomeFailureState(this.failureMessage);

  @override
  List<Object> get props => [failureMessage];
}

class HomeSuccessState extends HomeState {
  final List<DownloadNetwork> downloads;

  HomeSuccessState(this.downloads);

  @override
  List<Object> get props => [downloads];
}
