import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_up/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String nome = '';
  double saldo = 0;
  String estagioSelecionado = 'Todos';
  int currentTab = 0;

  @override
  void initState() {
    super.initState();
    carregarUsuario();
  }

  Future<void> carregarUsuario() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        nome = doc['nome'];
        saldo = (doc['saldo'] as num).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('startups').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.backgroundAlt, AppTheme.background],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                children: [
                  _headerCard(),
                  const SizedBox(height: 14),
                  _quickActionsRow(),
                  const SizedBox(height: 18),
                  _sectionTitle('Maiores altas', 'Ver todas'),
                  const SizedBox(height: 10),
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
                          'Erro ao carregar startups',
                          style: GoogleFonts.lato(color: AppTheme.danger),
                        ),
                      ),
                    )
                  else
                    ...docs.take(3).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nomeStartup = (data['nome_startup'] ?? 'Startup')
                          .toString();
                      final desc = (data['descricao'] ?? '').toString();
                      final preco = ((data['preco_token'] ?? 0) as num)
                          .toDouble();

                      return _marketCard(
                        nome: nomeStartup,
                        setor: desc.isEmpty ? 'Setor não informado' : desc,
                        preco: preco,
                        variacao: '+${(1.2 + (preco % 3)).toStringAsFixed(2)}%',
                      );
                    }),
                  const SizedBox(height: 18),
                  _sectionTitle('Transações recentes', 'Ver todas'),
                  const SizedBox(height: 10),
                  _transactionCard(
                    startup: 'TechHealth',
                    detalhe: 'Compra · 500 tokens',
                    valor: '-R\$ 7.000,00',
                    data: '14/02/2024',
                  ),
                  _transactionCard(
                    startup: 'EduTech Brasil',
                    detalhe: 'Compra · 300 tokens',
                    valor: '-R\$ 6.000,00',
                    data: '29/02/2024',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF191F2D),
          border: Border(top: BorderSide(color: Colors.white.withAlpha(20))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, 'Início'),
              _navItem(1, Icons.search, 'Explorar'),
              _navItem(2, Icons.show_chart, 'Balcão'),
              _navItem(3, Icons.pie_chart_outline, 'Portfólio'),
              _navItem(4, Icons.settings_outlined, 'Config'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
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
              Expanded(
                child: Text(
                  'Olá,\n${nome.isEmpty ? 'Investidor' : nome}',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 0.95,
                  ),
                ),
              ),
              const Icon(Icons.notifications_none_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('Carteira', style: GoogleFonts.lato(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Saldo disponível',
                  style: GoogleFonts.lato(color: Colors.white.withAlpha(220)),
                ),
                Text(
                  'R\$ ${saldo.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withAlpha(60), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _walletMetric(
                        label: 'Total investido',
                        value: 'R\$ 14.440,00',
                      ),
                    ),
                    Expanded(
                      child: _walletMetric(
                        label: 'Lucro/Prejuízo',
                        value: '~ 11.08%',
                        color: AppTheme.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF433067),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      '+   Adicionar saldo',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletMetric({
    required String label,
    required String value,
    Color color = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(color: Colors.white70)),
        Text(
          value,
          style: GoogleFonts.lato(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _quickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _quickActionCard(
            icon: Icons.trending_up_rounded,
            title: 'Explorar Startups',
            iconColor: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickActionCard(
            icon: Icons.north_east_rounded,
            title: 'Balcão de Tokens',
            iconColor: AppTheme.cyan,
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withAlpha(38),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 26),
            Text(
              title,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          action,
          style: GoogleFonts.lato(
            color: AppTheme.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _marketCard({
    required String nome,
    required String setor,
    required double preco,
    required String variacao,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.white10,
                child: const Icon(Icons.image_outlined, color: Colors.white54),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    setor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${preco.toStringAsFixed(2)}',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  variacao,
                  style: GoogleFonts.lato(
                    color: AppTheme.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionCard({
    required String startup,
    required String detalhe,
    required String valor,
    required String data,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startup,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detalhe,
                    style: GoogleFonts.lato(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valor,
                  style: GoogleFonts.lato(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data,
                  style: GoogleFonts.lato(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = currentTab == index;
    final color = selected ? AppTheme.accent : AppTheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            currentTab = index;
          });

          if (index == 4) {
            FirebaseAuth.instance.signOut();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
