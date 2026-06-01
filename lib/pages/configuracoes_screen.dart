//Beatriz Leme - 25015554

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:invest_up/main.dart';
import 'package:invest_up/pages/mfa.dart';
import 'editar_perfil_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});
  // Método auxiliar para tratar valores nulos ou vazios
  static String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Estrutura principal da tela
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),

      body: user == null
          ? const Center(
              child: Text(
                'Usuário não autenticado',
                style: TextStyle(color: Colors.white),
              ),
            )
          // Escuta alterações em tempo real do Firestore
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
                      'Erro ao carregar dados do usuário',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildMissingProfile(context, user);
                }

                final data = snapshot.data!.data() ?? {};

                final nome = _asText(
                  data['nome'] ?? data['name'] ?? user.displayName,
                  fallback: 'Investidor',
                );

                final email = _asText(
                  data['email'] ?? user.email,
                  fallback: 'E-mail não informado',
                );

                final telefone = _asText(
                  data['telefone'] ?? data['phone'],
                  fallback: 'Telefone não informado',
                );

                final cpf = _asText(data['cpf'], fallback: 'CPF não informado');

                final inicial = nome.isEmpty ? 'I' : nome[0].toUpperCase();
                // Estrutura principal da tela
                return Column(
                  children: [
                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.only(
                        top: 60,
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),

                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2FF7), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),

                      child: Column(
                        // Conteúdo interno do cabeçalho
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              IconButton(
                                // Botão de voltar
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),

                                onPressed: () => Navigator.pop(
                                  context,
                                ), // Retorna para tela anterior
                              ),

                              Row(
                                // Linha do título
                                children: [
                                  const Text(
                                    'Configurações',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  IconButton(
                                    // Botão de editar perfil
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),

                                    onPressed: () {
                                      Navigator.push(
                                        context,

                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const EditarPerfilScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(width: 24),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Container(
                            // Card do usuário
                            padding: const EdgeInsets.all(16),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),

                              color: Colors.white.withAlpha(26),
                            ),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  // Avatar do usuário
                                  radius: 30, // Tamanho do avatar
                                  backgroundColor: Colors.white24,

                                  child: Text(
                                    inicial,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  // Área expandida dos textos
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        nome,
                                        overflow:
                                            TextOverflow // Evita overflow
                                                .ellipsis,

                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),

                                      Text(
                                        email,
                                        overflow: TextOverflow.ellipsis,

                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      // Parte inferior da tela
                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Informações da conta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 16),

                            buildItem(Icons.email, 'E-mail', email),

                            buildItem(Icons.phone, 'Telefone', telefone),

                            buildItem(Icons.badge, 'CPF', cpf),

                            const Spacer(),

                            // ALICE BESERRA - 24794521
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                minimumSize: const Size(double.infinity, 50),
                              ),

                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();

                                if (!context.mounted) {
                                  return;
                                }
                                // Remove as telas anteriores e volta para o AuthGate.
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthGate(),
                                  ),
                                  (route) => false,
                                );
                              },

                              child: const Text('Sair da conta'),
                            ),

                            const SizedBox(height: 15),

                            ElevatedButton(
                              // Botão de excluir conta.
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,

                                minimumSize: const Size(double.infinity, 50),
                              ),

                              onPressed: () => _confirmDeleteAccount(context),

                              child: const Text('Excluir conta'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // Mostra uma tela alternativa caso o usuário exista no Auth, mas não exista documento dele em users/{uid}.
  Widget _buildMissingProfile(BuildContext context, User user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de alerta.
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Perfil incompleto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              // Explicação para o usuário.
              'Seus dados não foram encontrados. '
              'Por favor, saia e cadastre-se novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              // Botão para sair da conta.
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  // Volta para o AuthGate limpando a pilha de navegação.
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              },
              child: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }

  // Confirma a exclusão da conta pedindo a senha do usuário.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String senha = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar senha'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Digite sua senha'),
            onChanged: (value) => senha =
                value, // Atualiza a variável senha conforme o usuário digita.
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              // Botão confirmar tenta reautenticar e excluir a conta.
              onPressed: () async {
                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: senha,
                  );

                  await user.reauthenticateWithCredential(credential);

                  // Se a reautenticação está ok, prossegue com a exclusão
                  await _deleteAccountData(context, user);
                } on FirebaseAuthMultiFactorException catch (e) {
                  // Se o usuário tem 2FA fecha o dialog de senha e abre o MFA
                  if (!context.mounted) return;
                  Navigator.pop(context); // Fecha o diálogo de senha.

                  await Navigator.push(
                    // Abre a tela MFA para validar o segundo fator.
                    context,
                    MaterialPageRoute(
                      builder: (_) => MfaPage(
                        resolver: e.resolver,
                        onSuccess: () => _deleteAccountData(context, user),
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Senha incorreta')),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Exclui os dados do usuário no Firestore e depois exclui a conta no Auth.
  Future<void> _deleteAccountData(BuildContext context, User user) async {
    try {
      // 1. Firestore primeiro, enquanto o token ainda é válido
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // 2. Depois deleta o Auth
      await user.delete();

      // 3. signOut por garantia
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      // Volta para o AuthGate e limpa as telas anteriores.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir conta: $e')));
    }
  }

  // Widget reutilizável para itens da conta
  Widget buildItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFF161B22),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(icon, color: Colors.white70),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),

                Text(
                  value,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
