import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientAnnouncementsScreen extends StatelessWidget {
  const ClientAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, userSnap) {
          final coachId =
              (userSnap.data?.data() as Map<String, dynamic>?)?['coachId']
                  as String? ??
              '';

          if (coachId.isEmpty) {
            return const Center(
              child: Text(
                'No coach assigned yet.',
                style: TextStyle(color: Colors.black45),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .where('coachId', isEqualTo: coachId)
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
                    'No announcements yet.',
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
                  final id = docs[i].id;
                  final title = data['title'] as String? ?? '';
                  final body = data['body'] as String? ?? '';
                  final readBy =
                      (data['readBy'] as List<dynamic>?)?.cast<String>() ?? [];
                  final isRead = readBy.contains(uid);
                  final dt = (data['createdAt'] as Timestamp?)?.toDate();

                  // Mark as read when displayed
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(id)
                        .update({
                          'readBy': FieldValue.arrayUnion([uid]),
                        });
                  }

                  return Card(
                    color: isRead ? null : const Color(0xFFEEF4FF),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1565C0),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (dt != null)
                                Text(
                                  '${dt.day}/${dt.month}/${dt.year}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black38,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
