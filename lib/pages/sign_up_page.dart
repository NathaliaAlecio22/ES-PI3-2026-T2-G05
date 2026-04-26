import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_up/pages/home_page.dart';
import 'package:invest_up/theme/app_theme.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _passConfirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telController.dispose();
    _passController.dispose();
    _passConfirmController.dispose();

    super.dispose();
  }

  Future<void> verifySignUp() async {
    final nameText = _nameController.text.trim();
    final emailText = _emailController.text.trim();
    final cpfText = _cpfController.text.trim();
    final telText = _telController.text.trim();
    final passText = _passController.text.trim();
    final passConfirmText = _passConfirmController.text.trim();

    if (nameText.isEmpty ||
        emailText.isEmpty ||
        cpfText.isEmpty ||
        telText.isEmpty ||
        passText.isEmpty ||
        passConfirmText.isEmpty) {
      _alertUser('Preencha todos os campos');
      return;
    }

    if (passText != passConfirmText) {
      _alertUser('As senhas não coincidem');
      return;
    }

    try {
      //  1. Criar usuário no Auth
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: emailText, password: passText);

      final uid = userCredential.user!.uid;

      // 2. Salvar dados no Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': nameText,
        'email': emailText,
        'cpf': cpfText,
        'telefone': telText,
        'saldo': 0,
        'carteira': [],
        'createdAt': Timestamp.now(),
      });

      // 3. Ir para Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _alertUser(e.message ?? 'Erro ao cadastrar');
    } catch (e) {
      _alertUser('Erro inesperado');
    }
  }

  void goToLogIn() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Login(title: 'Invest Up'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 175),
      ),
    );
  }

  void _alertUser(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alerta'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 21, 23, 30),
        toolbarHeight: 120,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/Logo.png', height: 50),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invest Up',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  'Powered by MesclaInvest',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      color: Color.fromARGB(255, 158, 158, 158),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      backgroundColor: AppTheme.background,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundAlt, AppTheme.background],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 350,
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SizedBox(height: 5),

                      Text(
                        'Criar conta',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                      ),

                      Text(
                        'Preencha seus dados para começar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: Color.fromARGB(255, 158, 158, 158),
                            fontSize: 15,
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nome completo *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _nameController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome completo',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'E-mail *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'seu@email.com',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CPF *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: '000.000.000-00',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Telefone celular *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _telController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: '(00) 00000-0000',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Senha *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _passController,
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: '******',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirmar senha *',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 7),

                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _passConfirmController,
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: '******',
                          ),
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 35),

                      SizedBox(
                        width: 700,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: verifySignUp,
                          child: Text(
                            'Criar conta',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 35),

                      TextButton(
                        onPressed: goToLogIn,
                        style: TextButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 21, 23, 30),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Voltar para login',
                          style: GoogleFonts.lato(
                            color: AppTheme.accent,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      SizedBox(height: 35),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
