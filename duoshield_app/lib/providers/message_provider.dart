import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/message_dao.dart';
import '../models/message.dart';

final messageProvider = FutureProvider.family<List<Message>, String>((ref, chatId) async {
  final dao = MessageDao();
  return dao.getByChat(chatId);
});
