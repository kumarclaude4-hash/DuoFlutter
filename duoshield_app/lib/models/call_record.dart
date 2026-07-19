class CallRecord {
  final String id;
  final String peerUid;
  final String peerName;
  final String type;
  final String direction;
  final String status;
  final int startedAt;
  final int durationSecs;

  const CallRecord({
    required this.id,
    required this.peerUid,
    required this.peerName,
    required this.type,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.durationSecs = 0,
  });

  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'] as String,
      peerUid: map['peerUid'] as String? ?? '',
      peerName: map['peerName'] as String? ?? '',
      type: map['type'] as String? ?? 'audio',
      direction: map['direction'] as String? ?? 'outgoing',
      status: map['status'] as String? ?? 'completed',
      startedAt: map['startedAt'] as int,
      durationSecs: map['durationSecs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peerUid': peerUid,
      'peerName': peerName,
      'type': type,
      'direction': direction,
      'status': status,
      'startedAt': startedAt,
      'durationSecs': durationSecs,
    };
  }
}
