import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/pages/startup_detail_page.dart';
import 'package:invest_up/theme/app_theme.dart';

class StartupCatalogPage extends StatefulWidget {
  const StartupCatalogPage({super.key});

  @override
  State<StartupCatalogPage> createState() => _StartupCatalogPageState();
}

class _StartupCatalogPageState extends State<StartupCatalogPage> {
  String _filtro = 'Todas';
  String _busca = '';

  bool _matchesFiltro(String estagio) {
    if (_filtro == 'Todas') {
      return true;
    }

    final normalized = estagio.toLowerCase();
    if (_filtro == 'Novas') {
      return normalized.contains('nova');
    }
    if (_filtro == 'Operacao') {
      return normalized.contains('opera');
    }
    if (_filtro == 'Expansao') {
      return normalized.contains('expans');
    }

    return true;
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('startups')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              final filtradas = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nome = (data['nome_startup'] ?? '').toString();
                final setor = (data['setor'] ?? '').toString();
                final estagio = (data['estagio'] ?? '').toString();

                final query = _busca.trim().toLowerCase();
                final matchesBusca =
                    query.isEmpty ||
                    nome.toLowerCase().contains(query) ||
                    setor.toLowerCase().contains(query);

                return _matchesFiltro(estagio) && matchesBusca;
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _filtros(),
                  const SizedBox(height: 12),
                  Text(
                    '${filtradas.length} startups encontradas',
                    style: GoogleFonts.lato(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Erro ao carregar catálogo',
                          style: GoogleFonts.lato(color: AppTheme.danger),
                        ),
                      ),
                    )
                  else if (filtradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nenhuma startup com esse filtro',
                          style: GoogleFonts.lato(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filtradas.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nome = (data['nome_startup'] ?? 'Startup')
                          .toString();
                      final setor = (data['setor'] ?? 'Setor não informado')
                          .toString();
                      final descricao = (data['descricao'] ?? '').toString();
                      final estagio = (data['estagio'] ?? 'Sem estágio')
                          .toString();
                      final preco = ((data['preco_token'] ?? 0) as num)
                          .toDouble();

                      return _startupCard(
                        id: doc.id,
                        nome: nome,
                        setor: setor,
                        descricao: descricao,
                        estagio: estagio,
                        preco: preco,
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.accent, Color(0xFF36C8EF)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Text(
                'Catálogo de Startups',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) {
              setState(() {
                _busca = value;
              });
            },
            style: GoogleFonts.lato(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar startups...',
              hintStyle: GoogleFonts.lato(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    final filtros = ['Todas', 'Novas', 'Operacao', 'Expansao'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: filtros.map((label) {
          final selected = _filtro == label;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _filtro = label;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  label == 'Operacao'
                      ? 'Operação'
                      : label == 'Expansao'
                      ? 'Expansão'
                      : label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _startupCard({
    required String id,
    required String nome,
    required String setor,
    required String descricao,
    required String estagio,
    required double preco,
  }) {
    final isPositive = estagio.toLowerCase().contains('expans');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StartupDetailPage(startupId: id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nome,
                            style: GoogleFonts.lato(
                              fontSize: 23,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isPositive
                                        ? AppTheme.success
                                        : AppTheme.accent)
                                    .withAlpha(40),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            estagio,
                            style: GoogleFonts.lato(
                              color: isPositive
                                  ? AppTheme.success
                                  : AppTheme.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      setor,
                      style: GoogleFonts.lato(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preço do token: R\$ ${preco.toStringAsFixed(2)}',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
