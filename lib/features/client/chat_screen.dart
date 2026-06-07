import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/chat_thread_screen.dart';

class ClientChatScreen extends StatelessWidget {
  const ClientChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final coachId = userData?['coachId'] as String? ?? '';

        if (coachId.isEmpty) {
          return const Center(
            child: Text(
              'No coach assigned yet.',
              style: TextStyle(color: Colors.black45),
            ),
          );
        }

        final chatId = '${coachId}_$uid';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(coachId)
              .get(),
          builder: (context, coachSnap) {
            final coachName =
                (coachSnap.data?.data() as Map<String, dynamic>?)?['name']
                    as String? ??
                'Coach';

            // Go directly into the chat thread
            return ChatThreadScreen(
              chatId: chatId,
              otherUserId: coachId,
              otherUserName: coachName,
              isCoach: false,
            );
          },
        );
      },
    );
  }
}
