import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/session_detail_screen.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatCard(
                label: 'Clients',
                icon: Icons.people,
                color: const Color(0xFF1565C0),
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('coachId', isEqualTo: uid)
                    .where('role', isEqualTo: 'client')
                    .where('isActive', isEqualTo: true)
                    .count()
                    .get()
                    .then((s) => s.count?.toString() ?? '0'),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Sessions Today',
                icon: Icons.event,
                color: const Color(0xFF0F6E56),
                future: _countSessionsToday(uid),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Pending Actions',
                icon: Icons.task_alt,
                color: const Color(0xFF854F0B),
                future: FirebaseFirestore.instance
                    .collection('actionItems')
                    .where('coachId', isEqualTo: uid)
                    .where('status', isEqualTo: 'pending')
                    .count()
                    .get()
                    .then((s) => s.count?.toString() ?? '0'),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Announcements',
                icon: Icons.campaign,
                color: const Color(0xFF3C3489),
                future: FirebaseFirestore.instance
                    .collection('announcements')
                    .where('coachId', isEqualTo: uid)
                    .count()
                    .get()
                    .then((s) => s.count?.toString() ?? '0'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Upcoming Sessions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _UpcomingSessionsList(coachId: uid),
          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _RecentActivityList(coachId: uid),
        ],
      ),
    );
  }

  Future<String> _countSessionsToday(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final snap = await FirebaseFirestore.instance
        .collection('sessions')
        .where('coachId', isEqualTo: uid)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .count()
        .get();
    return snap.count?.toString() ?? '0';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Future<String> future;
  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<String>(
        future: future,
        builder: (context, snap) {
          final value = snap.data ?? '—';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UpcomingSessionsList extends StatelessWidget {
  final String coachId;
  const _UpcomingSessionsList({required this.coachId});

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: 'upcoming')
          .where('scheduledAt', isGreaterThanOrEqualTo: now)
          .orderBy('scheduledAt')
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyCard('No upcoming sessions');
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dt = (data['scheduledAt'] as Timestamp).toDate();
            final clientId = data['clientId'] as String? ?? '';
            return _SessionTile(
              dateTime: dt,
              clientId: clientId,
              sessionId: doc.id,
            );
          }).toList(),
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final DateTime dateTime;
  final String clientId;
  final String sessionId;
  const _SessionTile({
    required this.dateTime,
    required this.clientId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get(),
      builder: (context, snap) {
        final name =
            (snap.data?.data() as Map<String, dynamic>?)?['name'] as String? ??
            'Client';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1565C0),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(name),
            subtitle: Text(
              '${_weekday(dateTime.weekday)}, ${dateTime.day}/${dateTime.month}  ·  ${_time(dateTime)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SessionDetailScreen(sessionId: sessionId, isCoach: true),
              ),
            ),
          ),
        );
      },
    );
  }

  String _weekday(int w) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _RecentActivityList extends StatelessWidget {
  final String coachId;
  const _RecentActivityList({required this.coachId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('actionItems')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyCard('No recent activity');
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0F6E56),
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
                title: Text(data['title'] ?? ''),
                subtitle: const Text('Action item completed'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

Widget _emptyCard(String message) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Center(
    child: Text(
      message,
      style: const TextStyle(color: Colors.black45, fontSize: 14),
    ),
  ),
);
