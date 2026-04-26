import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/pages/home_page.dart';
import 'package:invest_up/pages/sign_up_page.dart';
import 'package:invest_up/pages/recover_password.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:invest_up/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const InvestUp());
}

class InvestUp extends StatelessWidget {
  const InvestUp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invest Up',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
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

  Future<void> verifyLogin() async {
    final String emailText = _emailController.text.trim();
    final String passwordText = _passwordController.text.trim();

    if (emailText.isEmpty || passwordText.isEmpty) {
      _alertUser('Informe email e senha');
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailText,
        password: passwordText,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _alertUser(e.message ?? 'Erro ao fazer login');
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
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      backgroundColor: AppTheme.background,

      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.backgroundAlt, AppTheme.background],
              ),
            ),
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 425),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isCompact ? 20 : 26),

                        Row(
                          children: [
                            Image.asset(
                              'assets/Logo.png',
                              height: isCompact ? 86 : 120,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    textStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: isCompact ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Powered by MesclaInvest',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    textStyle: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: isCompact ? 10 : 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: isCompact ? 96 : 120),

                        Text(
                          'Bem-vindo(a) de volta',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 22 : 25,
                            ),
                          ),
                        ),

                        Text(
                          'Entre na sua conta para continuar',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Color.fromARGB(255, 158, 158, 158),
                              fontSize: isCompact ? 14 : 15,
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 34 : 50),

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

                        const SizedBox(height: 7),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'seu@email.com',
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

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

                        const SizedBox(height: 7),

                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: TextField(
                            obscureText: true,
                            controller: _passwordController,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: const InputDecoration(
                              labelText: '******',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 18 : 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: goToRecoverPass,
                              style: TextButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  21,
                                  23,
                                  30,
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Esqueci minha senha',
                                style: GoogleFonts.lato(
                                  color: AppTheme.accent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isCompact ? 18 : 25),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: verifyLogin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.accent,
                                    AppTheme.accentSoft,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Entrar',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 18 : 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Não tem uma conta?',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            TextButton(
                              onPressed: goToSignUp,
                              style: TextButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  21,
                                  23,
                                  30,
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Cadastre-se',
                                style: GoogleFonts.lato(
                                  color: AppTheme.accent,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
