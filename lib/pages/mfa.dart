import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invest_up/pages/home_page.dart';
import 'package:invest_up/theme/app_theme.dart';

class MfaPage extends StatefulWidget {
  final MultiFactorResolver resolver;

  const MfaPage({super.key, required this.resolver});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final TextEditingController _codeController = TextEditingController();

  String? verificationId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() => loading = true);

    try {
      // pega o primeiro método MFA (telefone)
      final hint = widget.resolver.hints
          .whereType<PhoneMultiFactorInfo>()
          .first;

      await FirebaseAuth.instance.verifyPhoneNumber(
        multiFactorSession: widget.resolver.session,

        phoneNumber: hint.phoneNumber,

        verificationCompleted: (_) {},

        verificationFailed: (e) {
          setState(() => loading = false);
          _showError(e.message ?? "Erro ao enviar SMS");
        },

        codeSent: (verificationId, _) {
          setState(() {
            this.verificationId = verificationId;
            loading = false;
          });
        },

        codeAutoRetrievalTimeout: (verificationId) {
          this.verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => loading = false);
      _showError("Erro ao enviar código MFA");
    }
  }

  Future<void> _verifyCode() async {
    if (verificationId == null) {
      _showError("Código ainda não foi enviado");
      return;
    }

    if (_codeController.text.trim().isEmpty) {
      _showError("Digite o código");
      return;
    }

    try {
      setState(() => loading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: _codeController.text.trim(),
      );

      final assertion = PhoneMultiFactorGenerator.getAssertion(credential);

      await widget.resolver.resolveSignIn(assertion);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showError("Código inválido ou expirado");
      setState(() => loading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Erro"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundAlt,
              AppTheme.background,
            ],
          ),
        ),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 425),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Verificação em 2 etapas",
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Enviamos um código por SMS para seu número cadastrado.",
                    style: GoogleFonts.lato(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.lato(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Código de verificação",
                        prefixIcon: Icon(Icons.sms_outlined),
                      ),
                    ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
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
                            "Confirmar",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: TextButton(
                      onPressed: _sendCode,
                      child: Text(
                        "Reenviar código",
                        style: GoogleFonts.lato(
                          color: AppTheme.accent,
                        ),
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
  }
}