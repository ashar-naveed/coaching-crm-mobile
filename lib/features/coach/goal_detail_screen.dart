import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/goal_form_screen.dart';
import 'package:coaching_crm/features/coach/action_item_form_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  final String goalId;
  final String clientId;
  final bool isCoach;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
    required this.clientId,
    required this.isCoach,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Detail'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('goals')
            .doc(goalId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final title = data['title'] as String? ?? '';
          final desc = data['description'] as String? ?? '';
          final status = data['status'] as String? ?? 'active';
          final progress = (data['progress'] as num?)?.toInt() ?? 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCoach)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalFormScreen(
                            clientId: clientId,
                            goalId: goalId,
                            existing: data,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF1565C0),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              _StatusChip(status),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Action Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isCoach)
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActionItemFormScreen(
                            goalId: goalId,
                            clientId: clientId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _ActionItemsList(
                goalId: goalId,
                isCoach: isCoach,
                clientId: clientId,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionItemsList extends StatelessWidget {
  final String goalId;
  final String clientId;
  final bool isCoach;
  const _ActionItemsList({
    required this.goalId,
    required this.clientId,
    required this.isCoach,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('actionItems')
          .where('goalId', isEqualTo: goalId)
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No action items yet.',
                style: TextStyle(color: Colors.black45),
              ),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final itemId = doc.id;
            final title = data['title'] as String? ?? '';
            final status = data['status'] as String? ?? 'pending';
            final due = data['dueDate'] != null
                ? (data['dueDate'] as Timestamp).toDate()
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _statusIcon(status),
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
                subtitle: due != null
                    ? Text(
                        'Due: ${due.day}/${due.month}/${due.year}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                trailing: isCoach
                    ? _CoachActionMenu(
                        itemId: itemId,
                        data: data,
                        goalId: goalId,
                        clientId: clientId,
                      )
                    : _ClientStatusToggle(itemId: itemId, status: status),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statusIcon(String status) {
    return switch (status) {
      'completed' => const CircleAvatar(
        backgroundColor: Color(0xFF0F6E56),
        radius: 16,
        child: Icon(Icons.check, color: Colors.white, size: 16),
      ),
      'delayed' => const CircleAvatar(
        backgroundColor: Color(0xFF854F0B),
        radius: 16,
        child: Icon(Icons.schedule, color: Colors.white, size: 16),
      ),
      _ => const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 16,
        child: Icon(
          Icons.radio_button_unchecked,
          color: Colors.white,
          size: 16,
        ),
      ),
    };
  }
}

// ── Coach action menu (now includes mark as done + undo) ──────────────────────
class _CoachActionMenu extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> data;
  final String goalId;
  final String clientId;
  const _CoachActionMenu({
    required this.itemId,
    required this.data,
    required this.goalId,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    return PopupMenuButton<String>(
      onSelected: (val) async {
        final ref = FirebaseFirestore.instance
            .collection('actionItems')
            .doc(itemId);
        switch (val) {
          case 'done':
            await ref.update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Marked as done'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () async {
                      await ref.update({
                        'status': 'pending',
                        'completedAt': null,
                      });
                    },
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          case 'undo':
            await ref.update({'status': 'pending', 'completedAt': null});
          case 'delayed':
            await ref.update({'status': 'delayed'});
          case 'delete':
            await ref.delete();
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActionItemFormScreen(
                  goalId: goalId,
                  clientId: clientId,
                  itemId: itemId,
                  existing: data,
                ),
              ),
            );
        }
      },
      itemBuilder: (_) => [
        if (status != 'completed')
          const PopupMenuItem(value: 'done', child: Text('Mark as done')),
        if (status == 'completed')
          const PopupMenuItem(value: 'undo', child: Text('Undo')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delayed', child: Text('Mark as delayed')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ── Client status toggle (with undo snackbar) ─────────────────────────────────
class _ClientStatusToggle extends StatelessWidget {
  final String itemId;
  final String status;
  const _ClientStatusToggle({required this.itemId, required this.status});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('actionItems')
        .doc(itemId);

    if (status == 'completed') {
      return TextButton(
        onPressed: () async {
          await ref.update({'status': 'pending', 'completedAt': null});
        },
        child: const Text('Undo', style: TextStyle(color: Colors.orange)),
      );
    }

    return TextButton(
      onPressed: () async {
        await ref.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Marked as done'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ref.update({'status': 'pending', 'completedAt': null});
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: const Text('Done'),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
