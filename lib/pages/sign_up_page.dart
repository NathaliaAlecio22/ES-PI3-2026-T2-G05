// ALICE BESERRA - 24794521

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_up/pages/home_page.dart';
import 'package:invest_up/theme/app_theme.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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

  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final telefoneFormatter = MaskTextInputFormatter(
    mask: '+55 ## #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> verifySignUp() async {
    final nameText = _nameController.text.trim();
    final emailText = _emailController.text.trim();
    final cpfText = _cpfController.text.trim();
    final phoneText = _telController.text.trim();
    final passwordText = _passController.text.trim();
    final passwordConfirmText = _passConfirmController.text.trim();

    if (nameText.isEmpty ||
        emailText.isEmpty ||
        cpfText.isEmpty ||
        phoneText.isEmpty ||
        passwordText.isEmpty ||
        passwordConfirmText.isEmpty) {
      _alertUser('Preencha todos os campos');
      return;
    }

    if (!_isValidEmail(emailText)) {
      _alertUser('E-mail inválido');
      return;
    }

    if (!_isValidCPF(cpfText)) {
      _alertUser('CPF inválido');
      return;
    }

    if (!_isValidPhone(phoneText)) {
      _alertUser('Telefone inválido');
      return;
    }

    if (passwordText != passwordConfirmText) {
      _alertUser('As senhas não coincidem');
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailText,
        password: passwordText,
      );

      final user = userCredential.user;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'nome': nameText,
        'cpf': cpfText,
        'email': emailText,
        'telefone': phoneText,
      });

      final enrolled = await _enroll2FA(user, phoneText);

      if (!mounted) return;

      if (!enrolled) {
        await user.delete();
        _alertUser(
          'O cadastro requer verificação por SMS (2FA). '
          'Por favor, tente novamente.',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _alertUser(e.message ?? 'Erro');
    }
  }

  Future<bool> _enroll2FA(User user, String phoneNumber) async {
    final normalized = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    final completer = Completer<bool>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: normalized,

      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await user.multiFactor.enroll(
            PhoneMultiFactorGenerator.getAssertion(credential),
            displayName: 'Telefone',
          );
          if (!completer.isCompleted) completer.complete(true);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(false);
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.complete(false);
        if (mounted) _alertUser(e.message ?? 'Erro na verificação do telefone');
      },

      codeSent: (String verificationId, int? resendToken) async {
        final ok = await _showSmsDialog(user, verificationId);
        if (!completer.isCompleted) completer.complete(ok);
      },

      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<bool> _showSmsDialog(User user, String verificationId) async {
    if (!mounted) return false;

    final codeController = TextEditingController();
    bool enrolled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verificação SMS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite o código enviado por SMS para ativar a verificação em 2 etapas.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Código SMS',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final smsCode = codeController.text.trim();
                if (smsCode.isEmpty) return;

                try {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: smsCode,
                  );

                  await user.multiFactor.enroll(
                    PhoneMultiFactorGenerator.getAssertion(credential),
                    displayName: 'Telefone',
                  );

                  enrolled = true;

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('2FA ativado com sucesso!')),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Código inválido')),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    codeController.dispose();
    return enrolled;
  }

  bool _isValidEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return emailRegex.hasMatch(normalized);
  }

  bool _isValidPhone(String phone) {
    final numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length > 17) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return false;
    return true;
  }

  bool _isValidCPF(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length > 14) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return false;
    final digits = numbers.split('').map(int.parse).toList();

    int calcDigit(int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += digits[i] * (length + 1 - i);
      }
      final result = (sum * 10) % 11;
      return result == 10 ? 0 : result;
    }

    return digits[9] == calcDigit(9) && digits[10] == calcDigit(10);
  }

  void goToLogIn() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const Login(title: 'Invest Up'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 175),
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
          actions: [
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
        backgroundColor: AppTheme.background,
        toolbarHeight: 120,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/Logo.png', height: 72),
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
                      const SizedBox(height: 5),
                      Text(
                        'Criar conta',
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                        ),
                      ),
                      Text(
                        'Preencha seus dados para começar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 158, 158, 158),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label('Nome completo *'),
                      const SizedBox(height: 7),
                      _field(_nameController, 'Seu nome completo', TextInputType.text),
                      const SizedBox(height: 15),
                      _label('E-mail *'),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
                          decoration: const InputDecoration(labelText: 'seu@email.com'),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _label('CPF *'),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _cpfController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [cpfFormatter],
                          decoration: const InputDecoration(labelText: '000.000.000-00'),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _label('Telefone celular *'),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 700,
                        height: 40,
                        child: TextField(
                          controller: _telController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [telefoneFormatter],
                          decoration: const InputDecoration(labelText: '(00) 00000-0000'),
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _label('Senha *'),
                      const SizedBox(height: 7),
                      _field(_passController, '******', TextInputType.text, obscure: true),
                      const SizedBox(height: 15),
                      _label('Confirmar senha *'),
                      const SizedBox(height: 7),
                      _field(_passConfirmController, '******', TextInputType.text, obscure: true),
                      const SizedBox(height: 35),
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
                      const SizedBox(height: 35),
                      TextButton(
                        onPressed: goToLogIn,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 21, 23, 30),
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
                      const SizedBox(height: 35),
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

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint,
    TextInputType keyboard, {
    bool obscure = false,
  }) =>
      SizedBox(
        width: 700,
        height: 40,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: hint),
          style: GoogleFonts.lato(
            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
}