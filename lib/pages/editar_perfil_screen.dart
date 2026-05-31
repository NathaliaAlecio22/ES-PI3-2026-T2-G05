//Beatriz Leme - 25015554

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();

  bool _loadedForm = false; // Evita preencher o formulário várias vezes
  bool _saving = false; // Controla o estado de carregamento ao salvar

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose(); // Libera a memória utilizada pelos controllers
  }

  // Converte qualquer valor para texto de forma segura
  static String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  // Preenche os campos com os dados do usuário
  void _fillForm(Map<String, dynamic> data, User user) {
    if (_loadedForm) {
      return;
    }

    _nomeController.text = _asText(
      data['nome'] ?? data['name'] ?? user.displayName,
    );
    _emailController.text = _asText(data['email'] ?? user.email);
    _telefoneController.text = _asText(data['telefone'] ?? data['phone']);
    _cpfController.text = _asText(data['cpf']);
    _loadedForm = true;
  }

  // Método responsável por salvar alterações
  Future<void> _save(User user) async {
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty || telefone.isEmpty) {
      _showMessage('Preencha nome e telefone.');
      return;
    }
    // Ativa indicador de carregamento
    setState(() {
      _saving = true;
    });

    try {
      // Atualiza os dados do usuário no Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nome': nome,
        'email': _emailController.text.trim(),
        'telefone': telefone,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(
        nome,
      ); // Atualiza também o nome no Firebase Auth

      if (mounted) {
        _showMessage('Perfil atualizado.');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possivel salvar.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // Exibe mensagens rápidas na parte inferior da tela
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF7B2FF7),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Usuário nao autenticado',
                style: TextStyle(color: Colors.white),
              ),
            )
          // Escuta alterações em tempo real no documento do usuário
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Erro ao carregar perfil',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                // Recupera os dados do documento
                final data = snapshot.data?.data() ?? {};
                _fillForm(data, user); // Preenche os campos

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildField('Nome', _nomeController),
                      buildField(
                        'E-mail',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                      ), // Campo e-mail bloqueado para edição
                      buildField(
                        'Telefone',
                        _telefoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      buildField(
                        'CPF',
                        _cpfController,
                        enabled: false,
                      ), // Campo CPF bloqueado para edição
                      const SizedBox(height: 20),
                      SizedBox(
                        // Botão para salvar alterações
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _save(user),
                          child: _saving
                              ? const SizedBox(
                                  // Indicador de carregamento
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Método reutilizável para criar campos de texto
  Widget buildField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Espaçamento entre os campos
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: enabled
              ? null
              : const Icon(Icons.lock), // Cadeado para campos bloqueados
        ),
      ),
    );
  }
}
