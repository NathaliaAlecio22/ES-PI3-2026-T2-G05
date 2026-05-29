//Beatriz leme - 25015554

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:invest_up/main.dart';
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
                // Recupera os dados do Firestore
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
                    Container(   // Cabeçalho superior
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
                      child: Column(  // Conteúdo interno do cabeçalho
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton( // Botão de voltar
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context), // Retorna para tela anterior
                              ),
                              Row(     // Linha do título
                                children: [
                                  const Text(
                                    'Configurações',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(   // Botão de editar perfil
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
                          Container(  // Card do usuário
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withAlpha(26),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar( // Avatar do usuário
                                  radius: 30,  // Tamanho do avatar
                                  backgroundColor: Colors.white24,
                                  child: Text(
                                    inicial,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(   // Área expandida dos textos
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        email,
                                        overflow: TextOverflow.ellipsis, // Evita overflow
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
                    Expanded(  // Parte inferior da tela
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
                            const SizedBox(height: 16), // Espaço vertical
                            //Cards
                            buildItem(Icons.email, 'E-mail', email),
                            buildItem(Icons.phone, 'Telefone', telefone),
                            buildItem(Icons.badge, 'CPF', cpf),
                            const Spacer(), // Empurra botão para baixo
                            ElevatedButton( // Botão de excluir conta
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
  // Tela caso perfil não exista
  Widget _buildMissingProfile(BuildContext context, User user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24), // Espaçamento interno
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ajusta tamanho da coluna
          children: [
            const Text(
              'Perfil não encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(  // Mostra caminho do documento
              'Não existe documento em users/${user.uid}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(  // Botão para criar perfil
              onPressed: () async {
                await FirebaseFirestore.instance // Cria documento do usuário
                    .collection('users')
                    .doc(user.uid)
                    .set({
                      'nome': user.displayName ?? '',
                      'email': user.email ?? '',
                      'cpf': '',
                      'telefone': '',
                      'saldo': 0,
                      'carteira': [],
                      'createdAt': Timestamp.now(),
                    });
              },
              child: const Text('Criar perfil'),
            ),
          ],
        ),
      ),
    );
  }
   // Método que exibe confirmação antes de excluir a conta
  Future<void> _confirmDeleteAccount(BuildContext context) async { 
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    showDialog<void>( // Exibe caixa de diálogo
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta?\n\n'
          'Você perdera:\n'
          '- Seus dados\n'
          '- Tokens/créditos\n'
          '- Saldo em conta\n\n'
          'Essa ação é irreversivel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAccount(context, user);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  // Método responsável por excluir conta
  Future<void> _deleteAccount(BuildContext context, User user) async {
    final password = await _askPassword(context, user.email);
    if (password == null) { // Caso usuário cancele
      return;
    }

    if (!context.mounted) { // Verifica se contexto ainda existe
      return;
    }

    _showLoadingDialog(context);

    try {
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(code: 'missing-email');
      }
       // Cria credencial para reautenticação
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
     // Reautentica usuário
      await user.reauthenticateWithCredential(credential);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete(); // Exclui conta do Firebase Auth

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop(); // Fecha loading
      Navigator.of(context).pushAndRemoveUntil( // Redireciona para login
        MaterialPageRoute(builder: (_) => const Login(title: 'Invest Up')),
        (route) => false, // Remove rotas anteriores
      );
    } on FirebaseAuthException catch (e) { // Tratamento de erros do Firebase
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar( // Exibe mensagem de erro
          SnackBar(content: Text(_deleteAccountErrorMessage(e.code))),
        );
      }
    } catch (_) { // Tratamento genérico
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar( // Mostra erro padrão
          const SnackBar(content: Text('Não foi possivel excluir a conta.')),
        );
      }
    }
  }
  // Método que solicita senha
  Future<String?> _askPassword(BuildContext context, String? email) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // Chave do formulário

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirme sua senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email == null || email.isEmpty
                    ? 'Digite sua senha para confirmar a exclusão.'
                    : 'Digite a senha da conta $email para confirmar a exclusão.',
              ),
              const SizedBox(height: 16),
              TextFormField( // Campo de senha
                controller: passwordController,
                obscureText: true, // Oculta caracteres
                decoration: const InputDecoration(labelText: 'Senha'),
                validator: (value) { // Validação do campo
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe sua senha';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [ // Botões do dialog
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) { // Retorna senha digitada
                Navigator.pop(dialogContext, passwordController.text);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ).whenComplete(passwordController.dispose); // Libera memória do controller
  }
   // Dialog de carregamento
  void _showLoadingDialog(BuildContext context) { 
    showDialog<void>(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(), // Indicador loading
            SizedBox(width: 16),
            Expanded(child: Text('Excluindo conta...')),
          ],
        ),
      ),
    );
  }
  // Método que retorna mensagens de erro
  String _deleteAccountErrorMessage(String code) { 
    switch (code) { // Verifica código do erro
      case 'wrong-password':
      case 'invalid-credential':
        return 'Senha incorreta. Tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      case 'requires-recent-login':
        return 'Entre novamente antes de excluir a conta.';
      case 'missing-email':
        return 'Não foi possivel confirmar o e-mail desta conta.';
      default:
        return 'Não foi possivel excluir a conta.';
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
