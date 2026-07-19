import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../security/secure_prefs.dart';
import '../../core/constants.dart';
import '../../services/backup_service.dart';
import '../../widgets/ds_button.dart';
import '../../widgets/ds_text_field.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  String _lastBackup = 'Never';
  bool _loading = false;
  final _mnemonicController = TextEditingController();
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _loadLastBackupDate() async {
    final ts = await SecurePrefs.instance.get(AppConstants.prefLastBackupDate);
    if (!mounted) return;
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
      setState(() => _lastBackup = '${dt.day}/${dt.month}/${dt.year}');
    }
  }

  void _showBackupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('Create Backup', style: TextStyle(color: colorTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your recovery phrase to encrypt the backup.',
                style: TextStyle(color: colorTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            DSTextField(hint: '12 recovery words', controller: ctrl, maxLines: 3, minLines: 2),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final mnemonic = ctrl.text.trim();
                if (mnemonic.split(' ').length != 12) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter your 12-word phrase')));
                  return;
                }
                setState(() => _loading = true);
                try {
                  await _backupService.createBackup(mnemonic);
                  await _loadLastBackupDate();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: const Text('Export', style: TextStyle(color: colorAccent))),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorSurface,
        title: const Text('Restore Backup', style: TextStyle(color: colorTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your recovery phrase to decrypt the backup.',
                style: TextStyle(color: colorTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            DSTextField(hint: '12 recovery words', controller: ctrl, maxLines: 3, minLines: 2),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: colorTextSecondary))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final mnemonic = ctrl.text.trim();
                setState(() => _loading = true);
                try {
                  final count = await _backupService.importBackup(mnemonic);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restored $count messages')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              child: const Text('Import', style: TextStyle(color: colorAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(title: const Text('Backup & Restore'), backgroundColor: colorSurface),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorSurface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.backup_outlined, color: colorAccent, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last Backup', style: TextStyle(color: colorTextSecondary, fontSize: 12)),
                      Text(_lastBackup, style: const TextStyle(color: colorTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Backups are encrypted with your recovery phrase and stored locally.',
                style: TextStyle(color: colorTextSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            if (_loading) const LinearProgressIndicator(color: colorAccent),
            const SizedBox(height: 16),
            DSButton(text: 'Create Backup', gradient: true, enabled: !_loading, onTap: _showBackupDialog),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _showRestoreDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: colorAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Restore from Backup', style: TextStyle(color: colorAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
