import 'package:classifieds/model/TransectionHistoryModel.dart';

abstract class TransactionsStates {}

class TransactionsInitially extends TransactionsStates {}

class TransactionsLoading extends TransactionsStates {}

class TransactionsLoadingMore extends TransactionsStates {
  final TransectionHistoryModel transactionModel;
  final bool hasNextPage;

  TransactionsLoadingMore(this.transactionModel, this.hasNextPage);
}

class TransactionsLoaded extends TransactionsStates {
  final TransectionHistoryModel transactionModel;
  final bool hasNextPage;

  TransactionsLoaded(this.transactionModel, this.hasNextPage);
}

class TransactionsFailure extends TransactionsStates {
  final String error;
  TransactionsFailure(this.error);
}
