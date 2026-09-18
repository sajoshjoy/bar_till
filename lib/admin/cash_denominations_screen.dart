// lib/admin/cash_denominations_screen.dart
import 'package:flutter/material.dart';
import '../database.dart';
import '../models.dart';

class CashDenominationsScreen extends StatefulWidget {
  const CashDenominationsScreen({super.key});
  @override
  State<CashDenominationsScreen> createState() =>
      _CashDenominationsScreenState();
}

class _CashDenominationsScreenState extends State<CashDenominationsScreen> {
  List<PaymentButton> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AppDatabase.getPaymentButtons(onlyActive: false);
    if (!mounted) return;
    setState(() => items = list);
  }

  String _typeLabel(PaymentButtonType t) {
    switch (t) {
      case PaymentButtonType.cash:
        return 'Cash';
      case PaymentButtonType.card:
        return 'Credit Card';
      case PaymentButtonType.gift:
        return 'Gift Card';
      case PaymentButtonType.loyalty:
        return 'Loyalty';
    }
  }

  Future<void> _addOrEdit([PaymentButton? existing]) async {
    PaymentButtonType type = existing?.type ?? PaymentButtonType.cash;
    final valueCtl = TextEditingController(
        text: existing != null && existing.value > 0
            ? existing.value.toStringAsFixed(2)
            : '');
    final orderCtl =
        TextEditingController(text: (existing?.sortOrder ?? 0).toString());
    bool active = existing?.active ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Add Button' : 'Edit Button'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PaymentButtonType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: PaymentButtonType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => type = v!),
              ),
              if (type == PaymentButtonType.cash)
                TextField(
                  controller: valueCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Value (€)', hintText: 'e.g. 20'),
                ),
              TextField(
                controller: orderCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sort order'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible on till'),
                value: active,
                onChanged: (v) => setSt(() => active = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    double value = 0;
    if (type == PaymentButtonType.cash) {
      final parsed = double.tryParse(valueCtl.text.trim());
      if (parsed == null || parsed <= 0) return;
      value = parsed;
    }
    final sort = int.tryParse(orderCtl.text.trim()) ?? 0;

    if (existing == null) {
      await AppDatabase.addPaymentButton(
        PaymentButton(type: type, value: value, active: active, sortOrder: sort),
      );
    } else {
      await AppDatabase.updatePaymentButton(
        existing.copyWith(
          type: type,
          value: value,
          active: active,
          sortOrder: sort,
        ),
      );
    }
    _load();
  }

  Future<void> _delete(PaymentButton b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${_typeLabel(b.type)}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && b.id != null) {
      await AppDatabase.deletePaymentButton(b.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cash = items.where((i) => i.type == PaymentButtonType.cash).toList();
    final actions =
        items.where((i) => i.type != PaymentButtonType.cash).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text('${items.length} buttons',
                      style: const TextStyle(fontSize: 16)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => _addOrEdit(),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Cash Buttons',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (cash.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No cash buttons',
                        style: TextStyle(color: Colors.black45)),
                  ),
                ...cash.map((b) => _row(b)),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text('Action Buttons',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (actions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No action buttons',
                        style: TextStyle(color: Colors.black45)),
                  ),
                ...actions.map((b) => _row(b)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(PaymentButton b) {
    final subtitle = b.type == PaymentButtonType.cash
        ? '€${b.value.toStringAsFixed(2)} • Sort: ${b.sortOrder}${b.active ? '' : ' • HIDDEN'}'
        : 'Sort: ${b.sortOrder}${b.active ? '' : ' • HIDDEN'}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: b.type == PaymentButtonType.cash
            ? const Color(0xFF2E4A57)
            : const Color(0xFF8A94A6),
        child: Icon(
          b.type == PaymentButtonType.cash
              ? Icons.payments
              : b.type == PaymentButtonType.card
                  ? Icons.credit_card
                  : b.type == PaymentButtonType.gift
                      ? Icons.card_giftcard
                      : Icons.stars,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(_typeLabel(b.type)),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.edit), onPressed: () => _addOrEdit(b)),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(b)),
        ],
      ),
    );
  }
}