// lib/admin/sales_screen.dart
import 'package:flutter/material.dart';
import '../database.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Map<String, Object?>> sales = [];
  bool showVoided = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.getSales(includeVoided: true);
    if (!mounted) return;
    setState(() => sales = rows);
  }

  IconData _methodIcon(String? m) {
    switch (m) {
      case 'cash':
        return Icons.payments;
      case 'card':
        return Icons.credit_card;
      case 'gift':
        return Icons.card_giftcard;
      case 'loyalty':
        return Icons.stars;
      case 'void':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _methodLabel(String? m) {
    switch (m) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Credit Card';
      case 'gift':
        return 'Gift Card';
      case 'loyalty':
        return 'Loyalty';
      case 'void':
        return 'Void';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = showVoided
        ? sales
        : sales.where((s) => (s['voided'] as int? ?? 0) == 0).toList();

    final total = visible.fold<double>(
      0,
      (sum, s) => sum + ((s['total'] as num?)?.toDouble() ?? 0),
    );

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${visible.length} sales • €${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                FilterChip(
                  label: const Text('Show voided'),
                  selected: showVoided,
                  onSelected: (v) => setState(() => showVoided = v),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reload',
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text('No sales yet',
                        style: TextStyle(color: Colors.black45)))
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final s = visible[i];
                      final isVoid = (s['voided'] as int? ?? 0) == 1;
                      final total = (s['total'] as num?)?.toDouble() ?? 0;
                      final method = s['payment_method'] as String?;
                      final created =
                          (s['created_at'] as String? ?? '').replaceFirst('T', ' ');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isVoid
                              ? Colors.red.shade200
                              : const Color(0xFF2E4A57),
                          child: Icon(
                            _methodIcon(isVoid ? 'void' : method),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['tab_name'] as String? ?? '—',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isVoid
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              '€${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isVoid
                                    ? Colors.red
                                    : const Color(0xFF2B2B4A),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${_methodLabel(isVoid ? 'void' : method)} • '
                          '${created.length >= 16 ? created.substring(0, 16) : created}'
                          '${isVoid ? ' • VOIDED' : ''}',
                          style: TextStyle(
                              color: isVoid ? Colors.red : Colors.black54),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}