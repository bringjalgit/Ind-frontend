import 'package:classifieds/data/remote_data_source.dart';
import 'package:classifieds/model/ChatMessagesModel.dart';

abstract class ChatMessagesRepository {
  Future<ChatMessagesModel?> getChatMessages(String user_id,String listingId,int page);
}

class ChatMessagesRepositoryImpl implements ChatMessagesRepository{
  RemoteDataSource remoteDataSource;
  ChatMessagesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatMessagesModel?> getChatMessages(String user_id,String listingId,int page) async{
    return  await remoteDataSource.getChatMessages(user_id,listingId,page);
  }
}