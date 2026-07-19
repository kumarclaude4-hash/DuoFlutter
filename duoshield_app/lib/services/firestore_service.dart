import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static Future<void> setUser(String uid, Map<String, dynamic> data) async {
    await _fs.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _fs.collection('users').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot> watchUser(String uid) {
    return _fs.collection('users').doc(uid).snapshots();
  }

  static Future<void> setIdentity(String userId, Map<String, dynamic> data) async {
    await _fs.collection('identities').doc(userId).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getIdentity(String userId) async {
    final doc = await _fs.collection('identities').doc(userId).get();
    return doc.data();
  }

  static Future<String> sendMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> data,
  ) async {
    await _fs
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(data);
    return messageId;
  }

  static Future<void> updateChatMeta(String chatId, Map<String, dynamic> data) async {
    await _fs.collection('chats').doc(chatId).set(data, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> watchMessages(String chatId, int sinceTs) {
    return _fs
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Stream<QuerySnapshot> watchChats(String uid) {
    return _fs
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots();
  }

  static Future<List<QueryDocumentSnapshot>> getChatsForUser(String uid) async {
    final snap = await _fs
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();
    return snap.docs;
  }

  static Future<List<QueryDocumentSnapshot>> getMessagesForChat(String chatId) async {
    final snap = await _fs
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
    return snap.docs;
  }

  static Future<void> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> data,
  ) async {
    await _fs
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update(data);
  }

  static Future<void> sendGroupMessage(
    String groupId,
    String messageId,
    Map<String, dynamic> data,
  ) async {
    await _fs
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .set(data);
  }

  static Stream<QuerySnapshot> watchGroupMessages(String groupId) {
    return _fs
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  static Future<Map<String, dynamic>?> getGroupKey(
      String groupId, String memberUid) async {
    final doc = await _fs
        .collection('groups')
        .doc(groupId)
        .collection('keys')
        .doc(memberUid)
        .get();
    return doc.data();
  }

  static Future<void> setGroupKey(
      String groupId, String memberUid, String encryptedKey) async {
    await _fs
        .collection('groups')
        .doc(groupId)
        .collection('keys')
        .doc(memberUid)
        .set({'encryptedKey': encryptedKey});
  }

  static Future<void> createCall(String callId, Map<String, dynamic> data) async {
    await _fs.collection('calls').doc(callId).set(data);
  }

  static Future<void> updateCall(String callId, Map<String, dynamic> data) async {
    await _fs.collection('calls').doc(callId).update(data);
  }

  static Stream<DocumentSnapshot> watchCall(String callId) {
    return _fs.collection('calls').doc(callId).snapshots();
  }

  static Future<Map<String, dynamic>?> getCall(String callId) async {
    final doc = await _fs.collection('calls').doc(callId).get();
    return doc.data();
  }

  static Future<void> addCallerCandidate(String callId, String candidate) async {
    await _fs.collection('calls').doc(callId).update({
      'callerCandidates': FieldValue.arrayUnion([candidate]),
    });
  }

  static Future<void> addCalleeCandidate(String callId, String candidate) async {
    await _fs.collection('calls').doc(callId).update({
      'calleeCandidates': FieldValue.arrayUnion([candidate]),
    });
  }

  static Future<void> sendInCallMessage(
      String callId, String msgId, Map<String, dynamic> data) async {
    await _fs
        .collection('calls')
        .doc(callId)
        .collection('chat')
        .doc(msgId)
        .set(data);
  }

  static Stream<QuerySnapshot> watchInCallMessages(String callId) {
    return _fs
        .collection('calls')
        .doc(callId)
        .collection('chat')
        .orderBy('timestamp')
        .snapshots();
  }
}
