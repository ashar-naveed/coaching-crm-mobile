import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:coaching_crm/features/coach/session_form_screen.dart';
import 'package:coaching_crm/features/coach/chat_thread_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final bool isCoach;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.isCoach,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _coachNotesCtrl = TextEditingController();
  final _clientReflectionCtrl = TextEditingController();
  bool _editingNotes = false;
  bool _editingReflection = false;
  bool _saving = false;

  @override
  void dispose() {
    _coachNotesCtrl.dispose();
    _clientReflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNotes(String field, String value) async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({field: value});
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Detail'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final dt = (data['scheduledAt'] as Timestamp?)?.toDate();
          final duration = data['durationMinutes'] as int? ?? 60;
          final status = data['status'] as String? ?? 'upcoming';
          final coachNotes = data['coachNotes'] as String? ?? '';
          final reflection = data['clientReflection'] as String? ?? '';
          final clientId = data['clientId'] as String? ?? '';

          _coachNotesCtrl.text = coachNotes;
          _clientReflectionCtrl.text = reflection;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Session info ──────────────────────────────────
              _InfoCard(
                children: [
                  _InfoRow(
                    Icons.calendar_today,
                    dt != null ? '${dt.day}/${dt.month}/${dt.year}' : 'No date',
                  ),
                  _InfoRow(
                    Icons.access_time,
                    dt != null
                        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                        : 'No time',
                  ),
                  _InfoRow(Icons.timelapse, '$duration minutes'),
                  _InfoRow(Icons.info_outline, status.toUpperCase()),
                ],
              ),

              // ── Client name + message button ──────────────────
              const SizedBox(height: 12),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(clientId)
                    .get(),
                builder: (context, snap) {
                  final name =
                      (snap.data?.data() as Map<String, dynamic>?)?['name']
                          as String? ??
                      '';
                  if (name.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _InfoCard(children: [_InfoRow(Icons.person, name)]),
                      if (widget.isCoach) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            final coachId =
                                FirebaseAuth.instance.currentUser!.uid;
                            final chatId = '${coachId}_$clientId';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatThreadScreen(
                                  chatId: chatId,
                                  otherUserId: clientId,
                                  otherUserName: name,
                                  isCoach: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Message'),
                        ),
                      ],
                    ],
                  );
                },
              ),

              // ── Edit session button ───────────────────────────
              if (widget.isCoach) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionFormScreen(
                        clientId: clientId,
                        clientName: '',
                        sessionId: widget.sessionId,
                        existing: data,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Session'),
                ),
              ],

              const Divider(height: 32),

              // ── Coach notes ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coach Notes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isCoach)
                    Row(
                      children: [
                        if (coachNotes.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Clear notes',
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('sessions')
                                  .doc(widget.sessionId)
                                  .update({'coachNotes': ''});
                            },
                          ),
                        TextButton(
                          onPressed: () {
                            if (_editingNotes) {
                              _saveNotes('coachNotes', _coachNotesCtrl.text);
                            }
                            setState(() => _editingNotes = !_editingNotes);
                          },
                          child: Text(_editingNotes ? 'Save' : 'Edit'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.isCoach && _editingNotes)
                TextField(
                  controller: _coachNotesCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Add session notes...',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    coachNotes.isEmpty ? 'No notes yet.' : coachNotes,
                    style: TextStyle(
                      color: coachNotes.isEmpty
                          ? Colors.black38
                          : Colors.black87,
                    ),
                  ),
                ),

              const Divider(height: 32),

              // ── Client reflection ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Client Reflection',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (!widget.isCoach)
                    Row(
                      children: [
                        if (reflection.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Clear reflection',
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('sessions')
                                  .doc(widget.sessionId)
                                  .update({'clientReflection': ''});
                            },
                          ),
                        TextButton(
                          onPressed: () {
                            if (_editingReflection) {
                              _saveNotes(
                                'clientReflection',
                                _clientReflectionCtrl.text,
                              );
                            }
                            setState(
                              () => _editingReflection = !_editingReflection,
                            );
                          },
                          child: Text(_editingReflection ? 'Save' : 'Edit'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!widget.isCoach && _editingReflection)
                TextField(
                  controller: _clientReflectionCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Add your reflection...',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    reflection.isEmpty ? 'No reflection yet.' : reflection,
                    style: TextStyle(
                      color: reflection.isEmpty
                          ? Colors.black38
                          : Colors.black87,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
