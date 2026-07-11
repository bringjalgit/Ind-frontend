part of 'internet_status_bloc.dart';

abstract class InternetStatusEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class InternetStatusBackEvent extends InternetStatusEvent {}

class InternetStatusLostEvent extends InternetStatusEvent {}

class CheckInternetEvent extends InternetStatusEvent {}

