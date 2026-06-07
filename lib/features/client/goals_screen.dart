import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/goal_detail_screen.dart';

class ClientGoalsScreen extends StatelessWidget {
  const ClientGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .where('clientId', isEqualTo: uid)
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
              'No goals assigned yet.',
              style: TextStyle(color: Colors.black45),
            ),
          );
        }

        final active = docs
            .where((d) => (d.data() as Map)['status'] != 'completed')
            .toList();
        final completed = docs
            .where((d) => (d.data() as Map)['status'] == 'completed')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (active.isNotEmpty) ...[
              const Text(
                'Active',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...active.map((doc) => _GoalCard(doc: doc, uid: uid)),
              const SizedBox(height: 20),
            ],
            if (completed.isNotEmpty) ...[
              const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 8),
              ...completed.map((doc) => _GoalCard(doc: doc, uid: uid)),
            ],
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String uid;
  const _GoalCard({required this.doc, required this.uid});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] as String? ?? '';
    final status = data['status'] as String? ?? 'active';
    final progress = (data['progress'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GoalDetailScreen(goalId: doc.id, clientId: uid, isCoach: false),
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
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                color: status == 'completed'
                    ? Colors.green
                    : const Color(0xFF1565C0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: status == 'completed' ? Colors.green : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
