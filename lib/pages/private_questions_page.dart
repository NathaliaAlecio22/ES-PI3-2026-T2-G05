import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/theme/app_theme.dart';

class PrivateQuestionsPage extends StatefulWidget {
  const PrivateQuestionsPage({
    super.key,
    required this.startupId,
    required this.startupName,
  });

  final String startupId;
  final String startupName;

  @override
  State<PrivateQuestionsPage> createState() => _PrivateQuestionsPageState();
}

class _PrivateQuestionsPageState extends State<PrivateQuestionsPage> {
  final TextEditingController _controller = TextEditingController();

  bool _sending = false;

  Future<void> _sendQuestion() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      _showMessage('Digite uma pergunta');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('private_questions').add({
        'startupId': widget.startupId,
        'startupName': widget.startupName,
        'userId': user?.uid,
        'question': text,
        'createdAt': Timestamp.now(),
      });

      _controller.clear();

      _showMessage('Pergunta enviada');
    } catch (e) {
      _showMessage('Erro ao enviar pergunta');
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Perguntas Privadas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Digite sua pergunta',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendQuestion,
                child: _sending
                    ? const CircularProgressIndicator()
                    : Text(
                        'Enviar pergunta',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('private_questions')
                    .where('startupId', isEqualTo: widget.startupId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('Nenhuma pergunta ainda'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            data['question'] ?? '',
                            style: GoogleFonts.lato(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
