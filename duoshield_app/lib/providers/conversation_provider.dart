import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/conversation_dao.dart';
import '../models/conversation.dart';
import 'auth_provider.dart';

final conversationProvider = FutureProvider<List<Conversation>>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  final dao = ConversationDao();
  return dao.getAll();
});
