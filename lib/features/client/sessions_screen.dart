import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/session_detail_screen.dart';

class ClientSessionsScreen extends StatelessWidget {
  const ClientSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clientId', isEqualTo: uid)
          .orderBy('scheduledAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No sessions scheduled yet.',
              style: TextStyle(color: Colors.black45),
            ),
          );
        }

        final upcoming = docs
            .where((d) => (d.data() as Map)['status'] == 'upcoming')
            .toList();
        final past = docs
            .where((d) => (d.data() as Map)['status'] != 'upcoming')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (upcoming.isNotEmpty) ...[
              const Text(
                'Upcoming',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...upcoming.map((doc) => _ClientSessionCard(doc: doc)),
              const SizedBox(height: 20),
            ],
            if (past.isNotEmpty) ...[
              const Text(
                'Past',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 8),
              ...past.map((doc) => _ClientSessionCard(doc: doc)),
            ],
          ],
        );
      },
    );
  }
}

class _ClientSessionCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _ClientSessionCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final dt = (data['scheduledAt'] as Timestamp?)?.toDate();
    final duration = data['durationMinutes'] as int? ?? 60;
    final status = data['status'] as String? ?? 'upcoming';
    final reflection = data['clientReflection'] as String? ?? '';

    final statusColor = switch (status) {
      'upcoming' => Colors.green,
      'completed' => Colors.blue,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SessionDetailScreen(sessionId: doc.id, isCoach: false),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      dt != null ? '${dt.day}' : '--',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    Text(
                      dt != null ? _month(dt.month) : '--',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dt != null
                          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}  ·  $duration min'
                          : '$duration min',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (status == 'completed' && reflection.isEmpty)
                      const Text(
                        'Tap to add your reflection',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}
