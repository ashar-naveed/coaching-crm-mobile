import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/session_form_screen.dart';
import 'package:coaching_crm/features/coach/session_detail_screen.dart';

class CoachSessionsScreen extends StatelessWidget {
  const CoachSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .where('coachId', isEqualTo: uid)
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
                  'No sessions yet.',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const Text(
                    'Upcoming',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map(
                    (doc) => _SessionCard(doc: doc, isCoach: true),
                  ),
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
                  ...past.map((doc) => _SessionCard(doc: doc, isCoach: true)),
                ],
              ],
            );
          },
        ),

        // FAB
        Positioned(bottom: 16, right: 16, child: _ScheduleButton(coachId: uid)),
      ],
    );
  }
}

class _ScheduleButton extends StatelessWidget {
  final String coachId;
  const _ScheduleButton({required this.coachId});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('coachId', isEqualTo: coachId)
            .where('role', isEqualTo: 'client')
            .where('isActive', isEqualTo: true)
            .get();

        if (snap.docs.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No active clients found')),
            );
          }
          return;
        }

        if (!context.mounted) return;
        final selected = await showModalBottomSheet<Map<String, String>>(
          context: context,
          builder: (_) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...snap.docs.map((doc) {
                final data = doc.data();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      (data['name'] as String? ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(data['name'] as String? ?? ''),
                  onTap: () => Navigator.pop(context, {
                    'id': doc.id,
                    'name': data['name'] as String? ?? '',
                  }),
                );
              }),
            ],
          ),
        );

        if (selected == null || !context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionFormScreen(
              clientId: selected['id']!,
              clientName: selected['name']!,
            ),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Schedule'),
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
    );
  }
}

class _SessionCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isCoach;
  const _SessionCard({required this.doc, required this.isCoach});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final dt = (data['scheduledAt'] as Timestamp?)?.toDate();
    final duration = data['durationMinutes'] as int? ?? 60;
    final status = data['status'] as String? ?? 'upcoming';
    final clientId = data['clientId'] as String? ?? '';

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
                SessionDetailScreen(sessionId: doc.id, isCoach: isCoach),
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
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(clientId)
                          .get(),
                      builder: (context, snap) {
                        final name =
                            (snap.data?.data()
                                as Map<String, dynamic>?)?['name'] ??
                            '';
                        return Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dt != null
                          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}  ·  $duration min'
                          : '$duration min',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
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
