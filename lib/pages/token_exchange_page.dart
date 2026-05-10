import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/services/functions_api.dart';
import 'package:invest_up/theme/app_theme.dart';

class TokenExchangePage extends StatefulWidget {
  const TokenExchangePage({super.key});

  @override
  State<TokenExchangePage> createState() => _TokenExchangePageState();
}

class _TokenExchangePageState extends State<TokenExchangePage> {
  int _selectedTab = 0;
  int _buyCount = 0;
  int _sellCount = 0;
  String? _processingOfferId;

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
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              _tabSwitcher(),
              const SizedBox(height: 12),
              Expanded(child: _offerList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5328C7), Color(0xFF6C3CFF), Color(0xFF39C5F1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Balcão de Tokens',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3E2C6D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onPressed: _openCreateOffer,
                child: Text(
                  'Criar Oferta',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Crie ofertas de compra e venda ou aceite ofertas de outros investidores',
            style: GoogleFonts.lato(color: Colors.white.withAlpha(220)),
          ),
        ],
      ),
    );
  }

  Widget _tabSwitcher() {
    final compraSelected = _selectedTab == 0;
    final vendaSelected = _selectedTab == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF171B26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Ofertas de Compra',
              count: _buyCount,
              isSelected: compraSelected,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _tabButton(
              label: 'Ofertas de Venda',
              count: _sellCount,
              isSelected: vendaSelected,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0AC45F) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _offerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ofertas_investidores')
          .where('status', isEqualTo: 'aberta')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar ofertas',
              style: GoogleFonts.lato(color: AppTheme.danger),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final buyCount = docs
            .where(
              (doc) =>
                  ((doc.data() as Map<String, dynamic>)['tipo'] ?? 'venda') ==
                  'compra',
            )
            .length;
        final sellCount = docs.length - buyCount;

        if (_buyCount != buyCount || _sellCount != sellCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _buyCount = buyCount;
              _sellCount = sellCount;
            });
          });
        }
        final offers = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final tipo = (data['tipo'] ?? 'venda').toString();
          return _selectedTab == 0 ? tipo == 'compra' : tipo == 'venda';
        }).toList();

        if (offers.isEmpty) {
          return Center(
            child: Text(
              _selectedTab == 0
                  ? 'Nenhuma oferta de compra ativa'
                  : 'Nenhuma oferta de venda ativa',
              style: GoogleFonts.lato(color: AppTheme.textSecondary),
            ),
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('investidores').get(),
          builder: (context, investidoresSnap) {
            final investidoresMap = <String, String>{};
            if (investidoresSnap.data != null) {
              for (final doc in investidoresSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                investidoresMap[doc.id] = (data['nome'] ?? '').toString();
              }
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemBuilder: (context, index) {
                final doc = offers[index];
                final data = doc.data() as Map<String, dynamic>;
                final startupNome = (data['startup_nome'] ?? 'Startup')
                    .toString();
                final investidorId = (data['investidor_id'] ?? '').toString();
                final investidorNome = (data['investidor_nome'] ?? '')
                    .toString();
                final precoUnitario =
                    (data['preco_unitario'] as num?)?.toDouble() ?? 0;
                final quantidade =
                    (data['quantidade_disponivel'] as num?)?.toDouble() ?? 0;

                final exibicaoInvestidor = investidorNome.isNotEmpty
                    ? investidorNome
                    : investidoresMap[investidorId] ?? 'Investidor';

                final offerId = doc.id;
                final tipo = (data['tipo'] ?? 'venda').toString();

                return _offerCard(
                  startupNome: startupNome,
                  investidorNome: exibicaoInvestidor,
                  quantidade: quantidade,
                  precoUnitario: precoUnitario,
                  actionLabel: _selectedTab == 0 ? 'Vender' : 'Comprar',
                  isProcessing: _processingOfferId == offerId,
                  onAction: () {
                    _handleOfferAction(
                      offerId: offerId,
                      tipo: tipo,
                      maxQuantidade: quantidade,
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: offers.length,
            );
          },
        );
      },
    );
  }

  Widget _offerCard({
    required String startupNome,
    required String investidorNome,
    required double quantidade,
    required double precoUnitario,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isProcessing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startupNome,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Investidor: $investidorNome',
              style: GoogleFonts.lato(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metric('Quantidade', quantidade.toStringAsFixed(0)),
                ),
                Expanded(
                  child: _metric(
                    'Preço/token',
                    'R\$ ${precoUnitario.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : onAction,
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        actionLabel,
                        style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _openCreateOffer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C2030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => const _CreateOfferSheet(),
    );
  }

  Future<void> _handleOfferAction({
    required String offerId,
    required String tipo,
    required double maxQuantidade,
  }) async {
    final quantidade = await _promptQuantidade(maxQuantidade);
    if (quantidade == null) {
      return;
    }

    setState(() {
      _processingOfferId = offerId;
    });

    try {
      if (tipo == 'compra') {
        await FunctionsApi.acceptBuyOffer(
          offerId: offerId,
          quantidade: quantidade,
        );
      } else {
        await FunctionsApi.buyOffer(offerId: offerId, quantidade: quantidade);
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Operacao concluida.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nao foi possivel concluir: $message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingOfferId = null;
        });
      }
    }
  }

  Future<double?> _promptQuantidade(double maxQuantidade) async {
    final controller = TextEditingController(
      text: maxQuantidade.toStringAsFixed(0),
    );

    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1C2030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantidade',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: maxQuantidade.toStringAsFixed(0),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final parsed = _parseNumber(controller.text);
                    if (parsed == null || parsed <= 0) {
                      return;
                    }
                    Navigator.of(context).pop(parsed);
                  },
                  child: Text(
                    'Confirmar',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  double? _parseNumber(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

class _CreateOfferSheet extends StatefulWidget {
  const _CreateOfferSheet();

  @override
  State<_CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<_CreateOfferSheet> {
  int _tipo = 0;
  String? _startupId;
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Criar oferta',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tipo de oferta',
            style: GoogleFonts.lato(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tipoButton(
                  label: 'Compra',
                  selected: _tipo == 0,
                  onTap: () {
                    setState(() {
                      _tipo = 0;
                      _startupId = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tipoButton(
                  label: 'Venda',
                  selected: _tipo == 1,
                  onTap: () {
                    setState(() {
                      _tipo = 1;
                      _startupId = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Startup', style: GoogleFonts.lato(color: Colors.white)),
          const SizedBox(height: 6),
          _startupDropdown(),
          const SizedBox(height: 12),
          Text('Quantidade', style: GoogleFonts.lato(color: Colors.white)),
          const SizedBox(height: 6),
          TextField(
            controller: _quantidadeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '0'),
          ),
          const SizedBox(height: 12),
          Text('Preço por token', style: GoogleFonts.lato(color: Colors.white)),
          const SizedBox(height: 6),
          TextField(
            controller: _precoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '0.00'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
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
                      'Criar oferta',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0AC45F) : const Color(0xFF1A1E2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _startupDropdown() {
    if (_tipo == 1) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return const SizedBox.shrink();
      }

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          final carteira =
              (snapshot.data?.get('carteira') as List<dynamic>? ?? [])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

          return _dropdownBody(
            itens: carteira
                .map(
                  (item) => DropdownMenuItem(
                    value: item['startup_id']?.toString(),
                    child: Text(item['startup_nome']?.toString() ?? 'Startup'),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('startups').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return _dropdownBody(
          itens: docs
              .map(
                (doc) => DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    (doc.data() as Map<String, dynamic>)['nome_startup']
                            ?.toString() ??
                        'Startup',
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _dropdownBody({required List<DropdownMenuItem<String>> itens}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _startupId,
          isExpanded: true,
          dropdownColor: const Color(0xFF252A3A),
          hint: Text(
            'Selecione uma startup',
            style: GoogleFonts.lato(color: AppTheme.textSecondary),
          ),
          items: itens,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _startupId = value;
            });
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final startupId = _startupId;
    if (startupId == null || startupId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecione uma startup')),
      );
      return;
    }

    final quantidade = _parseNumber(_quantidadeController.text);
    final precoUnitario = _parseNumber(_precoController.text);
    if (quantidade == null || quantidade <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade valida')),
      );
      return;
    }
    if (precoUnitario == null || precoUnitario <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Informe um preco valido')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_tipo == 0) {
        await FunctionsApi.createBuyOffer(
          startupId: startupId,
          quantidade: quantidade,
          precoUnitario: precoUnitario,
        );
      } else {
        await FunctionsApi.sellTokens(
          startupId: startupId,
          quantidade: quantidade,
          precoUnitario: precoUnitario,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Oferta registrada.')),
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(
        SnackBar(content: Text('Nao foi possivel criar a oferta: $message')),
      );
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
}
