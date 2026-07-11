
abstract class LocationState {}

class LocationInitial extends LocationState {}
class LocationLoading extends LocationState {}
class LocationServiceDisabled extends LocationState {}
class LocationPermissionDenied extends LocationState {}
class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}
class LocationLoaded extends LocationState {
  final String locationName;
  final String latlng;
  LocationLoaded({required this.locationName, required this.latlng});
}

class LocationPermissionDeniedForever extends LocationState {}
class LocationSavedAvailable extends LocationState {
  final String locationName;
  final String latlng;
  LocationSavedAvailable({required this.locationName, required this.latlng});
}


