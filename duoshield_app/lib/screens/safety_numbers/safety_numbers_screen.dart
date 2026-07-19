import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/colors.dart';
import '../../security/app_lock_manager.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';

class SafetyNumbersScreen extends StatefulWidget {
  final String partnerUid;

  const SafetyNumbersScreen({super.key, required this.partnerUid});

  @override
  State<SafetyNumbersScreen> createState() => _SafetyNumbersScreenState();
}

class _SafetyNumbersScreenState extends State<SafetyNumbersScreen> {
  String _safetyNumber = '';
  List<String> _blocks = [];
  bool _loading = true;
  String _partnerName = '';
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _computeSafetyNumber();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    super.dispose();
  }

  Future<void> _computeSafetyNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final myDoc = await FirebaseFirestore.instance.collection('identities').doc(uid).get();
    final partnerDoc = await FirebaseFirestore.instance
        .collection('users').doc(widget.partnerUid).get();
    final partnerIdentityDoc = await FirebaseFirestore.instance
        .collection('identities').doc(partnerDoc.data()?['userId'] as String? ?? '').get();

    final myKey = myDoc.data()?['identityKey'] as String? ?? '';
    final partnerKey = partnerIdentityDoc.data()?['identityKey'] as String? ?? '';
    final partnerName = partnerDoc.data()?['displayName'] as String? ?? 'Unknown';

    final combined = '$myKey:$partnerKey';
    final bytes = Uint8List.fromList(utf8.encode(combined));
    final digits = bytes.map((b) => b.toString().padLeft(3, '0')).join('');
    final number = digits.length >= 60 ? digits.substring(0, 60) : digits.padRight(60, '0');

    final blocks = <String>[];
    for (int i = 0; i < number.length; i += 5) {
      blocks.add(number.substring(i, (i + 5).clamp(0, number.length)));
    }

    final prevKey = await SecurePrefs.instance.get('${AppConstants.prefSafetyNumKey}${widget.partnerUid}');
    if (prevKey != null && prevKey != partnerKey) {
      await SecurePrefs.instance.setBool('${AppConstants.prefSafetyNumChanged}${widget.partnerUid}', true);
    }
    await SecurePrefs.instance.set('${AppConstants.prefSafetyNumKey}${widget.partnerUid}', partnerKey);

    final verified = await SecurePrefs.instance.getBool('${AppConstants.prefSafetyNumVerified}${widget.partnerUid}');

    if (!mounted) return;
    setState(() {
      _safetyNumber = number;
      _blocks = blocks;
      _partnerName = partnerName;
      _loading = false;
      _verified = verified;
    });
  }

  Future<void> _markVerified() async {
    await SecurePrefs.instance.setBool('${AppConstants.prefSafetyNumVerified}${widget.partnerUid}', true);
    await SecurePrefs.instance.setBool('${AppConstants.prefSafetyNumChanged}${widget.partnerUid}', false);
    setState(() => _verified = true);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safety numbers verified')));
  }

  void _showQrCode() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('QR Code', style: TextStyle(color: colorTextPrimary)),
        content: Center(child: QrImageView(data: _safetyNumber, size: 240)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: colorAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Safety Numbers'), backgroundColor: colorSurface),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: colorAccent))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: colorSurface, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(
                          'Safety numbers with\n$_partnerName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: colorTextPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: _blocks.map((b) => Container(
                            width: 64,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                                color: colorSurfaceVariant,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(b,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: colorTextPrimary,
                                    fontSize: 13),
                                textAlign: TextAlign.center),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_verified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: colorAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: colorAccent),
                          SizedBox(width: 8),
                          Text('Safety numbers verified', style: TextStyle(color: colorAccent)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Compare these numbers with your contact in person or via another secure channel to verify your secure connection.',
                    style: TextStyle(color: colorTextSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.qr_code, color: colorAccent),
                          label: const Text('Scan QR', style: TextStyle(color: colorAccent)),
                          onPressed: _showQrCode,
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: colorAccent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _verified ? null : _markVerified,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: colorAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text(
                            _verified ? 'Verified ✓' : 'Mark as Verified',
                            style: const TextStyle(color: colorOnAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
