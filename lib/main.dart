// git push --set-upstream origin feature/autenticacao
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/pages/home_page.dart';
import 'package:invest_up/pages/sign_up_page.dart';
import 'package:invest_up/pages/recover_password.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ///await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InvestUp());
}

class InvestUp extends StatelessWidget {
  const InvestUp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invest Up',
      debugShowCheckedModeBanner: false,
      home: const Login(title: "Invest Up"),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key, required this.title});

  final String title;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void verifyLogin() {
    final String emailText = _emailController.text.trim();
    final String passwordText = _passwordController.text.trim();

    if (emailText.isEmpty || passwordText.isEmpty) {
      _alertUser(
        'É necessário informar e-mail e senha para entrar no aplicativo.',
      );
      return;
    } else if (!emailText.contains('@')) {
      _alertUser('E-mail inválido');
      return;
    } else if (passwordText.length <= 5) {
      _alertUser('Senhas precisam conter ao menos seis caracteres');
      return;
    } else {
      validateLogin(emailText, passwordText);
    }
  }

  Future<Map<String, dynamic>?> resultLogin(
    String email,
    String password,
  ) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .where('senha', isEqualTo: password)
        .get();

    if (result.docs.isNotEmpty) return null;

    return result.docs.first.data();
  }

  void validateLogin(String email, String password) async {
    final userData = await resultLogin(email, password);

    if (userData != null) {
      if (!mounted) return;

      String cpf = userData['cpf'];
      String name = userData['nome'];
      String email = userData['email'];

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomePage(email: email, name: name, cpf: cpf),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 175),
        ),
      );
    } else {
      _alertUser(
        'O login informado não foi encontrado \n Verifique as informações fornecidas e tente novamente, ou faça seu cadastro.',
      );
    }
  }

  void goToSignUp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignUp(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 175),
      ),
    );
  }

  void goToRecoverPass() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecoverPassword(),
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
            Image.asset('assets/logo.png', height: 50),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
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

      backgroundColor: Color.fromARGB(255, 21, 23, 30),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                width: 350,
                color: Color.fromARGB(255, 21, 23, 30),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    Text(
                      'Bem-vindo(a) de volta',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),

                    Text(
                      'Entre na sua conta para continuar',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          color: Color.fromARGB(255, 158, 158, 158),
                          fontSize: 15,
                        ),
                      ),
                    ),

                    SizedBox(height: 50),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'E-mail',
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
                      height: 45,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'seu@email.com',
                          filled: true,
                          fillColor: Color.fromARGB(255, 40, 43, 56),
                        ),
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Senha',
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
                      height: 45,
                      child: TextField(
                        obscureText: true,
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '......',
                          filled: true,
                          fillColor: Color.fromARGB(255, 40, 43, 56),
                        ),
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: goToRecoverPass,
                          style: TextButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 21, 23, 30),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Esqueci minha senha',
                            style: GoogleFonts.lato(
                              color: Color.fromARGB(255, 117, 50, 255),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    SizedBox(
                      width: 700,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: verifyLogin,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Color.fromARGB(255, 117, 50, 255),
                          ),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(
                                    color: Color.fromARGB(255, 117, 50, 255),
                                  ),
                                ),
                              ),
                        ),
                        child: Text(
                          'Entrar',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem uma conta?',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 5),
                        TextButton(
                          onPressed: goToSignUp,
                          style: TextButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 21, 23, 30),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Cadastre-se',
                            style: GoogleFonts.lato(
                              color: Color.fromARGB(255, 117, 50, 255),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
