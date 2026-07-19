import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/contact_dao.dart';
import '../models/contact.dart';

final contactProvider = FutureProvider<List<Contact>>((ref) async {
  final dao = ContactDao();
  return dao.getAll();
});
