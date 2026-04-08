import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/main.dart';

//CONFIRMAR VERIFICAÇÕES DE TODOS OS CAMPOS
//APLICAR MÁSCARAS EM CPF E TELEFONE
//APLICAR MÁSCARA EM NOME (PRIMEIRAS LETRAS MAIÚSCULAS)

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

  void verifySignUp() {
    final String nameText = _nameController.text.trim();
    final String emailText = _emailController.text.trim();
    final String cpfText = _cpfController.text.trim();
    final String telText = _telController.text.trim();
    final String passText = _passController.text.trim();
    final String passConfirmText = _passConfirmController.text.trim();

    if (nameText.isEmpty || emailText.isEmpty || cpfText.isEmpty || telText.isEmpty || passText.isEmpty || passConfirmText.isEmpty) {
      _alertUser('É necessário preencher todos os campos da tela para realizar seu cadastro.');
      return;
    } else if (nameText.length <= 5) {
      _alertUser('Informe seu nome completo.');
      return;
    } else if (!emailText.contains('@')) {
      _alertUser('E-mail inválido.');
      return;
    } else if (cpfText.length < 10 || cpfText.length > 11) {
      _alertUser('CPF inválido.');
      return;
    } else if (telText.length < 10 || telText.length > 16) {
      _alertUser('Telefone inválido.\nObs.: Lembre-se de incluir o DDD antes do número.');
      return;
    } else if (passText.length <= 5 || passConfirmText.length <= 5) {
      _alertUser('Senhas precisam conter ao menos seis caracteres.');
      return;
    } else if (passText.compareTo(passConfirmText) != 0) {
      _alertUser('As senhas informadas não coincidem.');
      return;
    } else {
      //Fazer cadastro de usuário e redirecionar pra tela home - Conexão com Firebase + Navigator.pushReplacement
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
        child: Center(
          child: Column(
            children: [
              Container(
                width: 350,
                color: Color.fromARGB(255, 21, 23, 30),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    SizedBox(height: 5),

                    Text(
                      'Criar conta',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(color: Colors.white, fontSize: 25),
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
                          border: OutlineInputBorder(),
                          labelText: 'Seu nome completo',
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
                          border: OutlineInputBorder(),
                          labelText: '000.000.000-00',
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
                          border: OutlineInputBorder(),
                          labelText: '(00) 00000-0000',
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

                    SizedBox(height: 35),

                    SizedBox(
                      width: 700,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: verifySignUp,
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

                    SizedBox(height: 35),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
