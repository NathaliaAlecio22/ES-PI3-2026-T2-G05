import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invest_up/theme/app_theme.dart';

class RecoverPassword extends StatefulWidget {
  const RecoverPassword({super.key});

  @override
  State<RecoverPassword> createState() => _RecoverPasswordState();
}

class _RecoverPasswordState extends State<RecoverPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  Future<void> verifyEmail() async {
    final String emailText = _emailController.text.trim();

    if (emailText.isEmpty) {
      _alertUser('É necessário informar seu e-mail para recuperação de senha.');
      return;
    } else if (!emailText.contains('@')) {
      _alertUser('E-mail inválido');
      return;
    } else {
      setState(() {
        _isSending = true;
      });

      try {
        await FirebaseAuth.instance.setLanguageCode('pt-BR');
        await FirebaseAuth.instance.sendPasswordResetEmail(email: emailText);
        if (!mounted) {
          return;
        }
        _alertUser(
          'Se existir uma conta para este e-mail, enviaremos as instruções de redefinição. Verifique caixa de entrada e spam.',
          onClose: goToLogIn,
        );
      } on FirebaseAuthException catch (e) {
        _alertUser(e.message ?? 'Não foi possível enviar o e-mail.');
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
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

  void _alertUser(String message, {VoidCallback? onClose}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alerta'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onClose != null) {
                  onClose();
                }
              },
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

    Widget buildField({
      required TextEditingController controller,
      required String labelText,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: labelText,
            filled: true,
            fillColor: const Color.fromARGB(255, 40, 43, 56),
          ),
          style: GoogleFonts.lato(
            textStyle: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        toolbarHeight: isCompact ? 96 : 120,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset('assets/Logo.png', height: isCompact ? 54 : 68),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Invest Up',
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
                        color: Color.fromARGB(255, 158, 158, 158),
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

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
                      children: [
                        SizedBox(height: isCompact ? 18 : 30),

                        Text(
                          'Recuperar senha',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 22 : 25,
                            ),
                          ),
                        ),

                        Text(
                          'Digite seu email e enviaremos instruções para redefinir sua senha',
                          textAlign: TextAlign.center,
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
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),
                        buildField(
                          controller: _emailController,
                          labelText: 'seu@email.com',
                        ),

                        SizedBox(height: isCompact ? 24 : 35),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSending ? null : verifyEmail,
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Enviar instruções',
                                    style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 24 : 35),

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
