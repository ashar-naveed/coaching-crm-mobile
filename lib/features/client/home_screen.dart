import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coaching_crm/features/client/announcements_screen.dart';
import 'package:coaching_crm/features/coach/chat_thread_screen.dart';
import 'package:coaching_crm/features/coach/goal_detail_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] as String? ?? '';
        final coachId = userData?['coachId'] as String? ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty) ...[
                Text(
                  'Hello, $name 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's your coaching overview.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  _ClientCard(
                    label: 'Next Session',
                    icon: Icons.event,
                    color: const Color(0xFF1565C0),
                    child: _NextSessionWidget(clientId: uid),
                  ),
                  const SizedBox(width: 12),
                  _ClientCard(
                    label: 'Unread',
                    icon: Icons.notifications_outlined,
                    color: const Color(0xFF3C3489),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientAnnouncementsScreen(),
                        ),
                      ),
                      child: _UnreadAnnouncementsWidget(clientId: uid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Active Goals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ActiveGoalsList(clientId: uid),
              const SizedBox(height: 24),

              const Text(
                'Recent Message',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RecentMessageWidget(clientId: uid, coachId: coachId),
              const SizedBox(height: 24),

              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RecentActivityWidget(clientId: uid),
            ],
          ),
        );
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget child;
  const _ClientCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _NextSessionWidget extends StatelessWidget {
  final String clientId;
  const _NextSessionWidget({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'upcoming')
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('scheduledAt')
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'None scheduled',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          );
        }
        final data = docs.first.data() as Map<String, dynamic>;
        final dt = (data['scheduledAt'] as Timestamp).toDate();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dt.day}/${dt.month}/${dt.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        );
      },
    );
  }
}

class _UnreadAnnouncementsWidget extends StatelessWidget {
  final String clientId;
  const _UnreadAnnouncementsWidget({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('readBy', arrayContains: clientId)
          .snapshots(),
      builder: (context, readSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .snapshots(),
          builder: (context, allSnap) {
            final total = allSnap.data?.docs.length ?? 0;
            final read = readSnap.data?.docs.length ?? 0;
            final unread = (total - read).clamp(0, 999);
            return Text(
              '$unread new',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            );
          },
        );
      },
    );
  }
}

class _ActiveGoalsList extends StatelessWidget {
  final String clientId;
  const _ActiveGoalsList({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'active')
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyCard('No active goals yet');
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? '';
            final progress = (data['progress'] as num?)?.toInt() ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalDetailScreen(
                      goalId: doc.id,
                      clientId: clientId,
                      isCoach: false,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1565C0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RecentMessageWidget extends StatelessWidget {
  final String clientId;
  final String coachId;
  const _RecentMessageWidget({required this.clientId, required this.coachId});

  @override
  Widget build(BuildContext context) {
    if (coachId.isEmpty) return _emptyCard('No coach assigned yet');
    final chatId = '${coachId}_$clientId';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        if (data == null) return _emptyCard('No messages yet');
        final last = data['lastMessage'] as String? ?? '';
        if (last.isEmpty) return _emptyCard('No messages yet');
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1565C0),
              child: Icon(Icons.chat, color: Colors.white, size: 18),
            ),
            title: const Text('Coach'),
            subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatThreadScreen(
                  chatId: chatId,
                  otherUserId: coachId,
                  otherUserName: 'Coach',
                  isCoach: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentActivityWidget extends StatelessWidget {
  final String clientId;
  const _RecentActivityWidget({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('actionItems')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyCard('No completed actions yet');
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
                subtitle: const Text('Completed'),
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
