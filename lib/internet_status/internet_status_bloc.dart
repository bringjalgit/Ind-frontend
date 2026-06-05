import 'dart:async';


import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
part 'internet_status_event.dart';
part 'internet_status_state.dart';

class InternetStatusBloc extends Bloc<InternetStatusEvent, InternetStatusState> {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  InternetStatusBloc() : super(InternetStatusInitial()) {
    // Subscribe to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      add(CheckInternetEvent());
    });

    // Event handlers
    on<InternetStatusBackEvent>(
          (event, emit) => emit(InternetStatusBackState('Internet is back!')),
    );

    on<InternetStatusLostEvent>(
          (event, emit) => emit(InternetStatusLostState('No internet connection')),
    );

    on<CheckInternetEvent>((event, emit) async {
      // Check network connectivity
      List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results, emit);
    });
  }

  // Handle connectivity results and check internet availability
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results, Emitter<InternetStatusState> emit) async {
    final hasNetwork = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);

    if (!hasNetwork) {
      emit(InternetStatusLostState('No internet connection', hasNetwork: false));
      return;
    }

    // Check actual internet availability using Dio
    try {
      final response = await _dio.get('https://www.google.com').timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        emit(InternetStatusBackState('Internet is back!'));
      } else {
        emit(InternetStatusLostState('Network connected, but no internet', hasNetwork: true));
      }
    } catch (e) {
      emit(InternetStatusLostState('Network connected, but no internet', hasNetwork: true));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _dio.close();
    return super.close();
  }
}


