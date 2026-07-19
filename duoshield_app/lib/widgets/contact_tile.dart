import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/contact.dart';
import '../core/extensions.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ContactTile({
    super.key,
    required this.contact,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: colorSurface,
        child: Text(
          contact.displayName.initials,
          style: const TextStyle(
              color: colorAccent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        contact.displayName,
        style: const TextStyle(color: colorTextPrimary),
      ),
      subtitle: Text(
        contact.userId,
        style: const TextStyle(color: colorTextSecondary, fontSize: 11),
      ),
      trailing: trailing,
    );
  }
}
