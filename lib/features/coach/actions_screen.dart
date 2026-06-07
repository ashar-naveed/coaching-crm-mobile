import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/goal_detail_screen.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF1565C0),
            unselectedLabelColor: Colors.black45,
            indicatorColor: Color(0xFF1565C0),
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Delayed'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ActionsList(coachId: uid, status: 'pending'),
                _ActionsList(coachId: uid, status: 'delayed'),
                _ActionsList(coachId: uid, status: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsList extends StatelessWidget {
  final String coachId;
  final String status;
  const _ActionsList({required this.coachId, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('actionItems')
          .where('coachId', isEqualTo: coachId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No $status actions.',
              style: const TextStyle(color: Colors.black45),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? '';
            final goalId = data['goalId'] as String? ?? '';
            final clientId = data['clientId'] as String? ?? '';
            final due = data['dueDate'] != null
                ? (data['dueDate'] as Timestamp).toDate()
                : null;

            final statusColor = switch (status) {
              'completed' => Colors.green,
              'delayed' => const Color(0xFF854F0B),
              _ => Colors.grey,
            };

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(
                    status == 'completed'
                        ? Icons.check
                        : status == 'delayed'
                        ? Icons.schedule
                        : Icons.radio_button_unchecked,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    decoration: status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                    color: status == 'completed'
                        ? Colors.black45
                        : Colors.black,
                  ),
                ),
                subtitle: Column(
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
                          'Client: $name',
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                    if (due != null)
                      Text(
                        'Due: ${due.day}/${due.month}/${due.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              due.isBefore(DateTime.now()) &&
                                  status == 'pending'
                              ? Colors.red
                              : Colors.black45,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    final ref = FirebaseFirestore.instance
                        .collection('actionItems')
                        .doc(docs[i].id);
                    if (val == 'done') {
                      await ref.update({
                        'status': 'completed',
                        'completedAt': FieldValue.serverTimestamp(),
                      });
                    } else if (val == 'delayed') {
                      await ref.update({'status': 'delayed'});
                    } else if (val == 'pending') {
                      await ref.update({
                        'status': 'pending',
                        'completedAt': null,
                      });
                    } else if (val == 'delete') {
                      await ref.delete();
                    } else if (val == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalDetailScreen(
                            goalId: goalId,
                            clientId: clientId,
                            isCoach: true,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('View goal'),
                    ),
                    if (status != 'completed')
                      const PopupMenuItem(
                        value: 'done',
                        child: Text('Mark as done'),
                      ),
                    if (status != 'delayed')
                      const PopupMenuItem(
                        value: 'delayed',
                        child: Text('Mark as delayed'),
                      ),
                    if (status != 'pending')
                      const PopupMenuItem(
                        value: 'pending',
                        child: Text('Mark as pending'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
