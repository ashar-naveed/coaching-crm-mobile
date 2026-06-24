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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.black26),
                SizedBox(height: 16),
                Text(
                  'No clients yet.',
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                ),
                SizedBox(height: 8),
                Text(
                  'Sign up a client and set their\ncoachId to your UID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black38),
                ),
              ],
            ),
          );
        }
        return _ClientSearchList(docs: docs);
      },
    );
  }
}

class _ClientSearchList extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  const _ClientSearchList({required this.docs});

  @override
  State<_ClientSearchList> createState() => _ClientSearchListState();
}

class _ClientSearchListState extends State<_ClientSearchList> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter locally
    final filtered = widget.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final email = (data['email'] as String? ?? '').toLowerCase();
      return name.contains(_query) || email.contains(_query);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),

        // Results count
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No clients matching "$_query"',
                        style: const TextStyle(color: Colors.black45),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    final name = data['name'] as String? ?? '';
                    final email = data['email'] as String? ?? '';
                    final isActive = data['isActive'] as bool? ?? true;
                    final clientId = filtered[i].id;

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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Archived',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
                ),
        ),
      ],
    );
  }
}
