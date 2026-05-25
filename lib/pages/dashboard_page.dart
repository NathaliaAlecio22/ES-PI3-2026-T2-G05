import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invest_up/services/functions_api.dart';
import 'package:invest_up/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Map<String, String> _periodLabels = {
    'daily': 'Diário',
    'weekly': 'Semanal',
    'monthly': 'Mensal',
    'six_months': '6 meses',
    'ytd': 'YTD',
  };

  String _selectedPeriod = 'monthly';
  String? _selectedStartupId;
  String? _selectedStartupName;
  List<_DashboardPoint> _points = [];
  bool _loading = false;
  String? _error;

  Future<void> _loadSeries() async {
    final startupId = _selectedStartupId;
    if (startupId == null) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await FunctionsApi.getTokenVariation(
        startupId: startupId,
        period: _selectedPeriod,
      );

      final rawPoints = (data['points'] as List<dynamic>? ?? [])
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => _DashboardPoint(
              label: item['label']?.toString() ?? '',
              price: (item['price'] as num?)?.toDouble() ?? 0,
              variationPct: (item['variationPct'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _points = rawPoints;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString();
      setState(() {
        _error = message.isEmpty
            ? 'Não foi possivel carregar o gráfico.'
            : message;
        _loading = false;
      });
    }
  }

  void _selectStartup(String id, String name) {
    setState(() {
      _selectedStartupId = id;
      _selectedStartupName = name;
    });
    _loadSeries();
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadSeries();
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
              final startups = snapshot.data?.docs ?? [];
              final items = startups
                  .map<Map<String, String>>(
                    (doc) => {
                      'startup_id': doc.id,
                      'startup_nome':
                          (doc.data() as Map<String, dynamic>)['nome_startup']
                              ?.toString() ??
                          'Startup',
                    },
                  )
                  .toList();

              if (_selectedStartupId == null && items.isNotEmpty) {
                final first = items.first;
                final startupId = first['startup_id']?.toString() ?? '';
                final startupName = first['startup_nome']?.toString() ?? '';
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || startupId.isEmpty) {
                    return;
                  }
                  _selectStartup(startupId, startupName);
                });
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _header(context),
                  const SizedBox(height: 16),
                  _startupSelector(items),
                  const SizedBox(height: 16),
                  _periodSelector(),
                  const SizedBox(height: 16),
                  _chartCard(),
                  const SizedBox(height: 14),
                  _insightRow(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F2B67), Color(0xFF3F2E7B), Color(0xFF1C6DAF)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard de Tokens',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Variação e tendência com base nas transações',
                  style: GoogleFonts.lato(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _startupSelector(List<Map<String, String>> startups) {
    if (startups.isEmpty) {
      return _infoCard(
        icon: Icons.info_outline,
        color: const Color(0xFF5AA7FF),
        title: 'Sem startups cadastradas',
        message: 'Cadastre startups para visualizar o gráfico de valorização.',
      );
    }

    final selectedValue =
        startups.any(
          (item) => item['startup_id']?.toString() == _selectedStartupId,
        )
        ? _selectedStartupId
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151D2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecionar startup',
            style: GoogleFonts.lato(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedValue,
            dropdownColor: const Color(0xFF1A2232),
            iconEnabledColor: Colors.white,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF202A3D),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            items: startups
                .map(
                  (item) => DropdownMenuItem(
                    value: item['startup_id']?.toString() ?? '',
                    child: Text(
                      item['startup_nome']?.toString() ?? 'Startup',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              final selected = startups.firstWhere(
                (item) => item['startup_id']?.toString() == value,
                orElse: () => startups.first,
              );
              _selectStartup(
                selected['startup_id']?.toString() ?? '',
                selected['startup_nome']?.toString() ?? 'Startup',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _periodSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: _periodLabels.entries.map((entry) {
        final selected = entry.key == _selectedPeriod;
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => _selectPeriod(entry.key),
          label: Text(
            entry.value,
            style: GoogleFonts.lato(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          selectedColor: const Color(0xFF3F63F6),
          backgroundColor: const Color(0xFF171E2C),
          side: BorderSide(color: Colors.white.withAlpha(18)),
        );
      }).toList(),
    );
  }

  Widget _chartCard() {
    final content = _loading
        ? const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          )
        : _error != null
        ? SizedBox(
            height: 260,
            child: Center(
              child: Text(
                _error!,
                style: GoogleFonts.lato(color: AppTheme.danger),
              ),
            ),
          )
        : _points.isEmpty
        ? SizedBox(
            height: 260,
            child: Center(
              child: Text(
                'Sem transações para este período.',
                style: GoogleFonts.lato(color: AppTheme.textSecondary),
              ),
            ),
          )
        : _chart();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedStartupName ?? 'Startup',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _metricPill(
                label: 'Preço atual',
                value: _points.isEmpty
                    ? 'R\$ 0,00'
                    : 'R\$ ${_points.last.price.toStringAsFixed(2)}',
                color: const Color(0xFFFF8A1B),
              ),
              const SizedBox(width: 10),
              _metricPill(
                label: 'Variação',
                value: _points.isEmpty
                    ? '0.00%'
                    : '${(_points.last.variationPct * 100).toStringAsFixed(2)}%',
                color: _points.isNotEmpty && _points.last.variationPct >= 0
                    ? const Color(0xFF3BD6C6)
                    : AppTheme.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 260, child: content),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(color: const Color(0xFFFF8A1B), label: 'Preço'),
              const SizedBox(width: 14),
              _legendDot(color: const Color(0xFF3BD6C6), label: 'Tendência'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lato(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart() {
    final spots = <FlSpot>[];
    final trendSpots = <FlSpot>[];
    for (var i = 0; i < _points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _points[i].price));
    }

    const window = 3;
    for (var i = 0; i < _points.length; i++) {
      final start = i - window + 1;
      final values = <double>[];
      for (var j = start; j <= i; j++) {
        if (j >= 0) {
          values.add(_points[j].price);
        }
      }
      final avg = values.isEmpty
          ? _points[i].price
          : values.reduce((a, b) => a + b) / values.length;
      trendSpots.add(FlSpot(i.toDouble(), avg));
    }

    final prices = _points.map((point) => point.price).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.92;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.08;
    final rawInterval = (maxY - minY) / 3;
    final yInterval = rawInterval <= 0 ? 1.0 : rawInterval.toDouble();

    return LineChart(
      LineChartData(
        minY: minY.isFinite ? minY : 0,
        maxY: maxY.isFinite ? maxY : 1,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                'R\$ ${value.toStringAsFixed(0)}',
                style: GoogleFonts.lato(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              interval: yInterval,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _points.length > 6 ? 2 : 1,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= _points.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _points[index].label,
                  style: GoogleFonts.lato(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA42B), Color(0xFFFF6B1B)],
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF8A1B).withAlpha(90),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: trendSpots,
            isCurved: true,
            barWidth: 2,
            color: const Color(0xFF3BD6C6),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.lato(color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _insightRow() {
    final current = _points.isEmpty ? null : _points.last;
    final variation = current?.variationPct ?? 0;

    return Row(
      children: [
        Expanded(
          child: _infoCard(
            icon: Icons.show_chart,
            color: const Color(0xFFFF8A1B),
            title: 'Oscilação atual',
            message: variation >= 0
                ? 'Tendência de alta nos últimos períodos.'
                : 'Tendência de queda nos últimos períodos.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF3BD6C6),
            title: 'Preço médio',
            message: _points.isEmpty
                ? 'Sem dados no periodo.'
                : 'R\$ ${_averagePrice().toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  double _averagePrice() {
    if (_points.isEmpty) {
      return 0;
    }
    final total = _points.fold<double>(0, (sum, point) => sum + point.price);
    return total / _points.length;
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.lato(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _DashboardPoint {
  _DashboardPoint({
    required this.label,
    required this.price,
    required this.variationPct,
  });

  final String label;
  final double price;
  final double variationPct;
}
