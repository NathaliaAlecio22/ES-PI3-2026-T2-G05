import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/services/functions_api.dart';
import 'package:invest_up/theme/app_theme.dart';
import 'package:invest_up/pages/private_questions_page.dart';

class StartupDetailPage extends StatefulWidget {
  const StartupDetailPage({super.key, required this.startupId});

  final String startupId;

  @override
  State<StartupDetailPage> createState() => _StartupDetailPageState();
}

class _StartupDetailPageState extends State<StartupDetailPage> {
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  bool _isSubmitting = false;
  bool _prefilledPrice = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  static String _asText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    final list = value as List<dynamic>? ?? [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  bool _isInvestor(Map<String, dynamic> userData) {
    final carteira = userData['carteira'] as List<dynamic>? ?? [];
    for (final item in carteira) {
      if (item is Map && item['startup_id'] == widget.startupId) {
        return true;
      }
    }
    return false;
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
            colors: [AppTheme.backgroundAlt, AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('startups')
                .doc(widget.startupId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar startup',
                    style: GoogleFonts.lato(color: AppTheme.danger),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'Startup não encontrada',
                    style: GoogleFonts.lato(color: AppTheme.textSecondary),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              final nome = _asText(data['nome_startup'], fallback: 'Startup');
              final setor = _asText(
                data['setor'],
                fallback: 'Setor não informado',
              );
              final estagio = _asText(data['estagio'], fallback: 'Sem estágio');
              final descricao = _asText(
                data['descricao'],
                fallback: 'Sem descrição',
              );
              final video = _asText(data['video_demo'], fallback: 'Sem vídeo');
              final sumarioExecutivo = _asText(
                data['sumario_executivo'],
                fallback: 'Sem sumário executivo',
              );
              final tokensEmitidos = _toDouble(data['tokens_emitidos']);
              final capitalAportado = _toDouble(data['capital_aportado']);
              final precoToken = _toDouble(data['preco_token']);

              final estrutura = _asMapList(data['estrutura_societaria']);

              final faqs = _asMapList(data['faqs_publicas']);

              final mentores =
                  (data['mentores_conselho'] as List<dynamic>? ?? [])
                      .map((e) => e.toString())
                      .toList();

              if (!_prefilledPrice && precoToken > 0) {
                _precoController.text = precoToken.toStringAsFixed(2);
                _prefilledPrice = true;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _hero(
                    context: context,
                    nome: nome,
                    setor: setor,
                    estagio: estagio,
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    precoToken: precoToken,
                    tokensDisponiveis: tokensEmitidos,
                    capitalAportado: capitalAportado,
                  ),
                  const SizedBox(height: 12),
                  _buyOfferCard(precoToken: precoToken),
                  const SizedBox(height: 12),
                  _privateQuestionsEntry(startupName: nome),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Descrição',
                    child: Text(
                      descricao,
                      style: GoogleFonts.lato(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Sumário executivo',
                    child: Text(
                      sumarioExecutivo,
                      style: GoogleFonts.lato(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Estrutura societária',
                    child: estrutura.isEmpty
                        ? Text(
                            'Sem dados de sócios',
                            style: GoogleFonts.lato(
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Column(
                            children: estrutura.map((socio) {
                              final nomeSocio = _asText(
                                socio['nome_socio'],
                                fallback: 'Sócio',
                              );
                              final participacao = _asText(
                                socio['participacao_societaria'],
                                fallback: '0',
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nomeSocio,
                                        style: GoogleFonts.lato(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$participacao%',
                                      style: GoogleFonts.lato(
                                        color: AppTheme.cyan,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Conselho e mentores',
                    child: mentores.isEmpty
                        ? Text(
                            'Sem mentores cadastrados',
                            style: GoogleFonts.lato(
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: mentores
                                .map(
                                  (mentor) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      '• $mentor',
                                      style: GoogleFonts.lato(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Perguntas frequentes',
                    child: faqs.isEmpty
                        ? Text(
                            'Sem perguntas públicas',
                            style: GoogleFonts.lato(
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Column(
                            children: faqs.map((item) {
                              final pergunta = _asText(
                                item['pergunta'],
                                fallback: 'Pergunta',
                              );
                              final resposta = _asText(
                                item['resposta'],
                                fallback: 'Sem resposta',
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pergunta,
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resposta,
                                      style: GoogleFonts.lato(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    title: 'Vídeo demonstrativo',
                    child: SelectableText(
                      video,
                      style: GoogleFonts.lato(
                        color: AppTheme.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hero({
    required BuildContext context,
    required String nome,
    required String setor,
    required String estagio,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color(0xFF36C8EF)],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nome,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(setor, style: GoogleFonts.lato(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              estagio,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required double precoToken,
    required double tokensDisponiveis,
    required double capitalAportado,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _metric(
                    label: 'Preço do token',
                    value: 'R\$ ${precoToken.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _metric(
                    label: 'Tokens emitidos',
                    value: tokensDisponiveis.toStringAsFixed(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metric(
              label: 'Capital aportado',
              value: 'R\$ ${capitalAportado.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _privateQuestionsEntry({required String startupName}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.question_answer),
              label: const Text('Perguntas privadas'),
              onPressed: null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disponivel apenas para investidores logados.',
            style: GoogleFonts.lato(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.question_answer),
                  label: const Text('Perguntas privadas'),
                  onPressed: null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Disponivel apenas para investidores desta startup.',
                style: GoogleFonts.lato(color: AppTheme.textSecondary),
              ),
            ],
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isInvestor = _isInvestor(userData);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.question_answer),
                label: const Text('Perguntas privadas'),
                onPressed: isInvestor
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateQuestionsPage(
                              startupId: widget.startupId,
                              startupName: startupName,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ),
            if (!isInvestor) ...[
              const SizedBox(height: 8),
              Text(
                'Disponivel apenas para investidores desta startup.',
                style: GoogleFonts.lato(color: AppTheme.textSecondary),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buyOfferCard({required double precoToken}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprar tokens',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Quantidade',
              style: GoogleFonts.lato(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _quantidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
            ),
            const SizedBox(height: 12),
            Text(
              'Preco por token',
              style: GoogleFonts.lato(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _precoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: precoToken > 0
                    ? precoToken.toStringAsFixed(2)
                    : '0.00',
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBuyOffer,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Criar oferta de compra',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _submitBuyOffer() async {
    final quantidade = _parseNumber(_quantidadeController.text);
    final precoUnitario = _parseNumber(_precoController.text);
    if (quantidade == null || quantidade <= 0) {
      _showMessage('Informe uma quantidade valida');
      return;
    }
    if (precoUnitario == null || precoUnitario <= 0) {
      _showMessage('Informe um preco valido');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FunctionsApi.createBuyOffer(
        startupId: widget.startupId,
        quantidade: quantidade,
        precoUnitario: precoUnitario,
      );
      _quantidadeController.clear();
      _showMessage('Oferta de compra criada.');
    } catch (_) {
      _showMessage('Nao foi possivel criar a oferta.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  double? _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
