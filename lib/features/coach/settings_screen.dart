import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final language = data?['language'] as String? ?? 'en';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _LangTile(
              label: 'English',
              value: 'en',
              selected: language == 'en',
              uid: uid,
            ),
            _LangTile(
              label: 'العربية',
              value: 'ar',
              selected: language == 'ar',
              uid: uid,
            ),
          ],
        );
      },
    );
  }
}

class _LangTile extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final String uid;
  const _LangTile({
    required this.label,
    required this.value,
    required this.selected,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF1565C0))
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () async {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'language': value,
          });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Language set to $label')));
          }
        },
      ),
    );
  }
}
