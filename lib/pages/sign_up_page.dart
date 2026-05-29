import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final cpfText = _onlyNumbers(_cpfController.text);
    final telText = _onlyNumbers(_telController.text);
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

    if (!_isValidEmail(emailText)) {
      _alertUser('E-mail inválido');
      return;
    }

    if (!_isValidCPF(cpfText)) {
      _alertUser('CPF inválido');
      return;
    }

    if (!_isValidPhone(telText)) {
      _alertUser('Telefone inválido');
      return;
    }

    if (passText != passConfirmText) {
      _alertUser('As senhas não coincidem');
      return;
    }

    User? createdUser;

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: emailText, password: passText);

      createdUser = userCredential.user;
      final uid = createdUser!.uid;

      final cpfExists = await _hasRegisteredValue('cpf', cpfText);
      if (cpfExists) {
        await createdUser.delete();
        _alertUser('CPF já cadastrado');
        return;
      }

      final phoneExists = await _hasRegisteredValue('telefone', telText);
      if (phoneExists) {
        await createdUser.delete();
        _alertUser('Telefone já cadastrado');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': nameText,
        'email': emailText,
        'cpf': cpfText,
        'telefone': telText,
        'saldo': 0,
        'carteira': [],
        'createdAt': Timestamp.now(),
      });

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        await _deleteCreatedUser(createdUser);
      }
      _alertUser(_authErrorMessage(e.code));
    } catch (e) {
      if (createdUser != null) {
        await _deleteCreatedUser(createdUser);
      }
      _alertUser('Erro inesperado');
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'E-mail já cadastrado';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail e senha não esta habilitado';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      default:
        return 'Erro ao cadastrar';
    }
  }

  Future<void> _deleteCreatedUser(User? user) async {
    try {
      await user?.delete();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<bool> _hasRegisteredValue(String field, String value) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where(field, isEqualTo: value)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  bool _isValidEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return emailRegex.hasMatch(normalized);
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  bool _isValidPhone(String phone) {
    final numbers = _onlyNumbers(phone);
    if (numbers.length < 10 || numbers.length > 11) {
      return false;
    }
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }
    return true;
  }

  bool _isValidCPF(String cpf) {
    final numbers = _onlyNumbers(cpf);

    if (numbers.length != 11) {
      return false;
    }

    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return false;
    }

    final digits = numbers.split('').map(int.parse).toList();

    int calcDigit(int length) {
      var sum = 0;
      for (var i = 0; i < length; i++) {
        sum += digits[i] * (length + 1 - i);
      }
      final result = (sum * 10) % 11;
      return result == 10 ? 0 : result;
    }

    final d1 = calcDigit(9);
    final d2 = calcDigit(10);

    return digits[9] == d1 && digits[10] == d2;
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
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          ],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
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
