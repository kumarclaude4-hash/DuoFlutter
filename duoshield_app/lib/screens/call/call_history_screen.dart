import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../db/call_dao.dart';
import '../../models/call_record.dart';
import '../../security/app_lock_manager.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<CallRecord> _calls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _loadCalls();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    super.dispose();
  }

  Future<void> _loadCalls() async {
    final calls = await CallDao().getAll();
    if (!mounted) return;
    setState(() {
      _calls = calls;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text('Calls'),
        backgroundColor: colorSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await CallDao().clearAll();
              await _loadCalls();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: colorAccent))
          : _calls.isEmpty
              ? const Center(child: Text('No recent calls', style: TextStyle(color: colorTextSecondary)))
              : ListView.builder(
                  itemCount: _calls.length,
                  itemBuilder: (_, i) {
                    final call = _calls[i];
                    final ts = DateTime.fromMillisecondsSinceEpoch(call.startedAt);
                    final isIncoming = call.direction == 'incoming';
                    final isMissed = call.status == 'missed';
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorSurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          call.type == 'video' ? Icons.videocam_outlined : Icons.call_outlined,
                          color: isMissed ? colorError : colorTextPrimary,
                        ),
                      ),
                      title: Text(call.peerName, style: TextStyle(
                        color: isMissed ? colorError : colorTextPrimary,
                        fontWeight: FontWeight.w500,
                      )),
                      subtitle: Row(children: [
                        Icon(
                          isIncoming ? Icons.call_received : Icons.call_made,
                          size: 14,
                          color: isMissed ? colorError : colorTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2,'0')}',
                          style: TextStyle(
                              color: isMissed ? colorError : colorTextSecondary,
                              fontSize: 12),
                        ),
                        if (call.durationSecs > 0) ...[
                          const Text(' · ', style: TextStyle(color: colorTextMuted)),
                          Text(_formatDuration(call.durationSecs),
                              style: const TextStyle(fontSize: 12, color: colorTextSecondary)),
                        ],
                      ]),
                      trailing: IconButton(
                        icon: Icon(
                          call.type == 'video' ? Icons.videocam : Icons.call,
                          color: colorAccent,
                        ),
                        onPressed: () => context.push('/call', extra: {
                          'partnerUid': call.peerUid,
                          'partnerName': call.peerName,
                          'isVideo': call.type == 'video',
                        }),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
