import 'package:cloud_firestore/cloud_firestore.dart';

class CoachConnection {
  final String id;
  final String ownerUid;
  final String? coachUid;
  final String? ownerName;
  final String? coachName;
  final String type; // 'invite' | 'connection'
  final String status; // 'pending' | 'active'
  final DateTime createdAt;
  final DateTime? connectedAt;

  const CoachConnection({
    required this.id,
    required this.ownerUid,
    this.coachUid,
    this.ownerName,
    this.coachName,
    required this.type,
    required this.status,
    required this.createdAt,
    this.connectedAt,
  });

  factory CoachConnection.fromMap(String id, Map<String, dynamic> data) {
    return CoachConnection(
      id: id,
      ownerUid: data['ownerUid'] as String,
      coachUid: data['coachUid'] as String?,
      ownerName: data['ownerName'] as String?,
      coachName: data['coachName'] as String?,
      type: data['type'] as String? ?? 'connection',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      connectedAt: (data['connectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        if (coachUid != null) 'coachUid': coachUid,
        if (ownerName != null) 'ownerName': ownerName,
        if (coachName != null) 'coachName': coachName,
        'type': type,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        if (connectedAt != null) 'connectedAt': Timestamp.fromDate(connectedAt!),
      };
}
