import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/client_profile_screen.dart';

class CoachClientsScreen extends StatelessWidget {
  const CoachClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('coachId', isEqualTo: uid)
          .where('role', isEqualTo: 'client')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No clients yet.',
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
            final name = data['name'] as String? ?? '';
            final email = data['email'] as String? ?? '';
            final isActive = data['isActive'] as bool? ?? true;
            final clientId = docs[i].id;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? const Color(0xFF1565C0)
                      : Colors.grey,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.black45,
                  ),
                ),
                subtitle: Text(email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientProfileScreen(
                      clientId: clientId,
                      clientName: name,
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
