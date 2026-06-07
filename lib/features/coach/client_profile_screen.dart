import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/goal_form_screen.dart';
import 'package:coaching_crm/features/coach/goal_detail_screen.dart';
import 'package:coaching_crm/features/coach/session_detail_screen.dart';
import 'package:coaching_crm/features/coach/chat_thread_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProfileScreen extends StatelessWidget {
  final String clientId;
  final String clientName;
  const ClientProfileScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(clientName),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              tooltip: 'Message client',
              onPressed: () {
                final coachId = FirebaseAuth.instance.currentUser!.uid;
                final chatId = '${coachId}_$clientId';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(
                      chatId: chatId,
                      otherUserId: clientId,
                      otherUserName: clientName,
                      isCoach: true,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Goals'),
              Tab(text: 'Sessions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GoalsTab(clientId: clientId),
            _SessionsTab(clientId: clientId),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoalFormScreen(clientId: clientId),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Goal'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ── Goals tab ─────────────────────────────────────────────────────────────────
class _GoalsTab extends StatelessWidget {
  final String clientId;
  const _GoalsTab({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No goals yet. Tap + to add one.',
              style: TextStyle(color: Colors.black45),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final goalId = docs[i].id;
            final title = data['title'] as String? ?? '';
            final status = data['status'] as String? ?? 'active';
            final progress = (data['progress'] as num?)?.toInt() ?? 0;

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalDetailScreen(
                      goalId: goalId,
                      clientId: clientId,
                      isCoach: true,
                    ),
                  ),
                ),
                onLongPress: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Goal'),
                    content: const Text('Are you sure? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseFirestore.instance
                              .collection('goals')
                              .doc(goalId)
                              .delete();
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _StatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF1565C0),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$progress%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Sessions tab ──────────────────────────────────────────────────────────────
class _SessionsTab extends StatelessWidget {
  final String clientId;
  const _SessionsTab({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clientId', isEqualTo: clientId)
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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final dt = (data['scheduledAt'] as Timestamp?)?.toDate();
            final duration = data['durationMinutes'] as int? ?? 60;
            final status = data['status'] as String? ?? 'upcoming';
            final statusColor = switch (status) {
              'upcoming' => Colors.green,
              'completed' => Colors.blue,
              'cancelled' => Colors.red,
              _ => Colors.grey,
            };
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Text(
                    dt != null ? '${dt.day}' : '--',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  dt != null
                      ? '${dt.day}/${dt.month}/${dt.year}  ·  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                      : 'No date',
                ),
                subtitle: Text('$duration min'),
                trailing: Container(
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionDetailScreen(
                      sessionId: docs[i].id,
                      isCoach: true,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.green,
      'completed' => Colors.blue,
      'paused' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
