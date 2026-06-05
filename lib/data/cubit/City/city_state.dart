import '../../../model/SelectCityModel.dart';


abstract class SelectCity {}

class SelectCityInitially extends SelectCity {}

class SelectCityLoading extends SelectCity {}

class SelectCityLoaded extends SelectCity {
  final SelectCityModel selectCityModel;
  final bool hasNextPage;

  SelectCityLoaded(this.selectCityModel, this.hasNextPage);
}

class SelectCityLoadingMore extends SelectCity {
  final SelectCityModel selectCityModel;
  final bool hasNextPage;

  SelectCityLoadingMore(this.selectCityModel, this.hasNextPage);
}

class SelectCityFailure extends SelectCity {
  final String error;
  SelectCityFailure(this.error);
}
