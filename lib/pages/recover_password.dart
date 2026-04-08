import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/main.dart';

class RecoverPassword extends StatefulWidget {
  const RecoverPassword({super.key});

  @override
  State<RecoverPassword> createState() => _RecoverPasswordState();
}

class _RecoverPasswordState extends State<RecoverPassword> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  void verifyEmail() {
    final String emailText = _emailController.text.trim();

    if (emailText.isEmpty) {
      _alertUser('É necessário informar seu e-mail para recuperação de senha.');
      return;
    } else if (!emailText.contains('@')) {
      _alertUser('E-mail inválido');
      return;
    } else {
      //Enviar email de recuperação de senha - Conexão com firebase
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
            Image.asset('assets/logo.png', height: 50),

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
                      'Recuperar senha',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),

                    Text(
                      'Digite seu email e enviaremos instruções para redefinir sua senha',
                      textAlign: TextAlign.center,
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

                    SizedBox(height: 35),

                    SizedBox(
                      width: 700,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: verifyEmail,
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
                          'Enviar instruções',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 15,
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
                          color: Color.fromARGB(255, 117, 50, 255),
                          fontSize: 13,
                        ),
                      ),
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
