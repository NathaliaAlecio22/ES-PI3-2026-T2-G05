import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/theme/app_theme.dart';

class StartupDetailPage extends StatelessWidget {
  const StartupDetailPage({super.key, required this.startupId});

  final String startupId;

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
                .doc(startupId)
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
              final tokensEmitidos = _toDouble(data['tokens_emitidos']);
              final capitalAportado = _toDouble(data['capital_aportado']);
              final precoToken = _toDouble(data['preco_token']);

              final estrutura =
                  (data['estrutura_societaria'] as List<dynamic>? ?? [])
                      .whereType<Map>()
                      .map((e) => e.cast<String, dynamic>())
                      .toList();

              final mentores =
                  (data['mentores_conselho'] as List<dynamic>? ?? [])
                      .map((e) => e.toString())
                      .toList();

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
                  _infoCard(
                    title: 'Descrição',
                    child: Text(
                      descricao,
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
}
