import 'package:classifieds/model/AdSuccessModel.dart';

import '../../../model/ChatUsersModel.dart';
import '../../remote_data_source.dart';

abstract class ChatUsersRepo {
  Future<ChatUsersModel?> getChatUsers(String query);
  Future<AdSuccessModel?> chatUserPin(Map<String, dynamic> data);
}

class ChatUsersRepoImpl implements ChatUsersRepo {
  final RemoteDataSource remoteDataSource;

  ChatUsersRepoImpl({required this.remoteDataSource});

  @override
  Future<ChatUsersModel?> getChatUsers(String query) async {
    try {
      return await remoteDataSource.getChatUsers(query);
    } catch (e) {
      throw Exception('Failed to fetch chat users');
    }
  }

  @override
  Future<AdSuccessModel?> chatUserPin(Map<String, dynamic> data) async {
    return await remoteDataSource.chatUserPin(data);
  }
}
