part of 'internet_status_bloc.dart';

abstract class InternetStatusState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class InternetStatusInitial extends InternetStatusState {}

// Internet is available
class InternetStatusBackState extends InternetStatusState {
  final String message;
  InternetStatusBackState(this.message);
  @override
  List<Object> get props => [message];
}

// Internet is lost
class InternetStatusLostState extends InternetStatusState {
  final String message;
  final bool hasNetwork; // Added to differentiate no network vs. no internet

  InternetStatusLostState(this.message, {this.hasNetwork = false});
  @override
  List<Object> get props => [message, hasNetwork];
}
