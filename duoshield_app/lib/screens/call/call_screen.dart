import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/colors.dart';
import '../../db/call_dao.dart';
import '../../models/call_record.dart';
import '../../security/app_lock_manager.dart';
import '../../services/firestore_service.dart';

class CallScreen extends StatefulWidget {
  final String partnerUid;
  final String partnerName;
  final bool isVideo;
  final String? incomingCallId;

  const CallScreen({
    super.key,
    required this.partnerUid,
    required this.partnerName,
    this.isVideo = false,
    this.incomingCallId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _callId;
  StreamSubscription? _callSub;
  String _status = 'Calling...';
  bool _muted = false;
  bool _speakerOn = false;
  bool _videoEnabled = true;
  bool _callEnded = false;
  DateTime? _callStartTime;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _initRenderers();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    _callSub?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _localStream?.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (widget.incomingCallId != null) {
      _callId = widget.incomingCallId;
      setState(() => _status = 'Connecting...');
      await _answerCall();
    } else {
      await _startCall();
    }
  }

  Future<void> _startCall() async {
    _callId = const Uuid().v4();
    setState(() => _status = 'Calling ${widget.partnerName}...');

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo,
    });
    _localRenderer.srcObject = _localStream;

    _peerConnection = await _createPeerConnection();

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await FirestoreService.createCall(_callId!, {
      'callerId': _myUid,
      'calleeId': widget.partnerUid,
      'type': widget.isVideo ? 'video' : 'audio',
      'status': 'ringing',
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'createdAt': FieldValue.serverTimestamp(),
    });

    _listenForAnswer();
  }

  Future<void> _answerCall() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo,
    });
    _localRenderer.srcObject = _localStream;
    _peerConnection = await _createPeerConnection();
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final callData = await FirestoreService.getCall(_callId!);
    if (callData == null) return;

    final offerData = callData['offer'] as Map<String, dynamic>;
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(
      offerData['sdp'] as String,
      offerData['type'] as String,
    ));

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await FirestoreService.updateCall(_callId!, {
      'status': 'answered',
      'answer': {'type': answer.type, 'sdp': answer.sdp},
    });

    setState(() {
      _status = 'Connected';
      _callStartTime = DateTime.now();
    });
    _listenForCallerCandidates();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (candidate) async {
      if (_callId == null) return;
      if (widget.incomingCallId != null) {
        await FirestoreService.addCalleeCandidate(_callId!, candidate.toMap().toString());
      } else {
        await FirestoreService.addCallerCandidate(_callId!, candidate.toMap().toString());
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        setState(() => _remoteRenderer.srcObject = event.streams.first);
      }
    };

    pc.onConnectionState = (state) {
      if (!mounted) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          _status = 'Connected';
          _callStartTime ??= DateTime.now();
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _endCall();
      }
    };

    return pc;
  }

  void _listenForAnswer() {
    if (_callId == null) return;
    _callSub = FirestoreService.watchCall(_callId!).listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      if (data['status'] == 'answered' && data['answer'] != null) {
        final answerData = data['answer'] as Map<String, dynamic>;
        _peerConnection?.setRemoteDescription(RTCSessionDescription(
          answerData['sdp'] as String,
          answerData['type'] as String,
        ));
      }
      if (data['status'] == 'ended') _endCall();
    });
  }

  void _listenForCallerCandidates() {
    if (_callId == null) return;
    _callSub = FirestoreService.watchCall(_callId!).listen((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data?['status'] == 'ended' && mounted) _endCall();
    });
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    setState(() => _callEnded = true);

    final duration = _callStartTime != null
        ? DateTime.now().difference(_callStartTime!).inSeconds
        : 0;

    if (_callId != null) {
      try {
        await FirestoreService.updateCall(_callId!, {'status': 'ended'});
      } catch (_) {}
    }

    await _peerConnection?.close();
    _localStream?.dispose();

    if (_callId != null) {
      await CallDao().insert(CallRecord(
        id: _callId!,
        peerUid: widget.partnerUid,
        peerName: widget.partnerName,
        direction: widget.incomingCallId != null ? 'incoming' : 'outgoing',
        type: widget.isVideo ? 'video' : 'audio',
        startedAt: (_callStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
        durationSecs: duration,
        status: duration > 0 ? 'completed' : 'missed',
      ));
    }

    if (mounted) context.pop();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_muted);
  }

  void _toggleVideo() {
    setState(() => _videoEnabled = !_videoEnabled);
    _localStream?.getVideoTracks().forEach((t) => t.enabled = _videoEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.isVideo) ...[
            RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            Positioned(
              top: 80,
              right: 16,
              width: 100,
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
          ] else
            Container(
              color: colorBackground,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircleAvatar(radius: 64, backgroundColor: colorAccent,
                      child: Icon(Icons.person, size: 64, color: Colors.white)),
                  const SizedBox(height: 24),
                  Text(widget.partnerName, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(color: colorTextSecondary)),
                ]),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(icon: _muted ? Icons.mic_off : Icons.mic, onTap: _toggleMute,
                    color: _muted ? colorError : colorSurface),
                _CallButton(icon: Icons.call_end, onTap: _endCall, color: colorError, size: 56),
                if (widget.isVideo)
                  _CallButton(icon: _videoEnabled ? Icons.videocam : Icons.videocam_off, onTap: _toggleVideo,
                      color: colorSurface)
                else
                  _CallButton(icon: _speakerOn ? Icons.volume_up : Icons.volume_down_outlined,
                      onTap: () => setState(() => _speakerOn = !_speakerOn), color: colorSurface),
              ],
            ),
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(child: Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _CallButton({required this.icon, required this.onTap, required this.color, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
