//Beatriz Leme - 25015554

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/services/functions_api.dart';
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
  final Map<String, String> _autoAnswers =
      {}; // Armazena respostas automáticas geradas
  final Set<String> _pendingAnswers = {}; // Evita gerar respostas duplicadas

  bool _isInvestor(Map<String, dynamic> userData) {
    // Verifica se o usuário investe na startup atual
    final carteira = userData['carteira'] as List<dynamic>? ?? [];
    for (final item in carteira) {
      if (item is Map && item['startup_id'] == widget.startupId) {
        return true;
      }
    }
    return false;
  }

  // Confirma se o usuário possui acesso à área privada
  Future<bool> _ensureInvestor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userSnap.exists) {
      return false;
    }

    final userData =
        userSnap.data()
            as Map<String, dynamic>; // Recupera os dados do documento
    return _isInvestor(userData);
  }

  // Envia uma nova pergunta privada
  Future<void> _sendQuestion() async {
    final text = _controller.text.trim(); // Obtém o texto digitado

    if (text.isEmpty) {
      _showMessage('Digite uma pergunta');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser; // Recupera usuário autenticado
      if (user == null) {
        _showMessage('Faca login para enviar perguntas privadas');
        return;
      }

      final isInvestor =
          await _ensureInvestor(); // Verifica permissão de investidor
      if (!isInvestor) {
        _showMessage('Apenas investidores podem enviar perguntas privadas');
        return;
      }
      // Salva a pergunta no Firestore
      await FirebaseFirestore.instance.collection('private_questions').add({
        'startupId': widget.startupId,
        'startupName': widget.startupName,
        'userId': user.uid,
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
    // Exibe mensagens rápidas na tela
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Gera uma resposta automática para a pergunta
  Future<void> _loadAutoAnswer(String docId, String question) async {
    if (_pendingAnswers.contains(docId)) {
      // Evita chamadas repetidas
      return;
    }

    _pendingAnswers.add(docId);
    try {
      // Chama a API de resposta automática
      final answer = await FunctionsApi.getAutoResponse(question);
      if (!mounted) {
        return;
      }
      setState(() {
        _autoAnswers[docId] = answer;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _autoAnswers[docId] = 'Nao foi possivel gerar uma resposta automatica.';
      });
    } finally {
      _pendingAnswers.remove(docId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Perguntas Privadas')),
        body: Center(
          child: Text(
            'Faca login para acessar as perguntas privadas.',
            style: GoogleFonts.lato(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Perguntas Privadas')),
      body: StreamBuilder<DocumentSnapshot>(
        // Escuta alterações do usuário em tempo real
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Caso não encontre usuário
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(
              child: Text(
                'Disponivel apenas para investidores desta startup.',
                style: GoogleFonts.lato(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }
          // Recupera os dados do usuário
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final isInvestor = _isInvestor(userData); // Verifica se é investidor

          if (!isInvestor) {
            return Center(
              child: Text(
                'Disponivel apenas para investidores desta startup.',
                style: GoogleFonts.lato(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  // Campo para digitar pergunta
                  controller: _controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua pergunta',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  // Botão de envio
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendQuestion,
                    child: _sending
                        ? const CircularProgressIndicator() // Indicador de carregamento
                        : Text(
                            'Enviar pergunta',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  // Lista de perguntas privadas
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('private_questions')
                        .where('startupId', isEqualTo: widget.startupId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        // Tratamento de erro
                        return Center(
                          child: Text(
                            'Erro ao carregar perguntas',
                            style: GoogleFonts.lato(color: AppTheme.danger),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('Nenhuma pergunta ainda'),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma pergunta ainda'),
                        );
                      }

                      return ListView.builder(
                        // Lista dinâmica de perguntas
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final question = (data['question'] ?? '').toString();
                          final docId = docs[index].id;
                          final answer = _autoAnswers[docId];
                          // Gera resposta automática
                          if (answer == null && question.isNotEmpty) {
                            _loadAutoAnswer(docId, question);
                          }

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question,
                                    style: GoogleFonts.lato(),
                                  ), // Exibe pergunta
                                  const SizedBox(height: 10),
                                  if (answer == null)
                                    Text(
                                      'Gerando resposta...',
                                      style: GoogleFonts.lato(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    )
                                  else if (answer.isNotEmpty)
                                    Text(
                                      answer,
                                      style: GoogleFonts.lato(
                                        color: AppTheme.cyan,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Sem resposta automatica.',
                                      style: GoogleFonts.lato(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
          );
        },
      ),
    );
  }
}
