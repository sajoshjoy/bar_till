// lib/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'database.dart';
import 'auth_service.dart';

/// Simple receipt dialog — shared by all payment flows.
Future<void> showReceiptDialog(
  BuildContext context, {
  required BarTab tab,
  required Customer customer,
  required double subtotal,
  required double giftUsed,
  required double payable,
  required double cashGiven,
  required double change,
  required double pointsEarned,
  String? paymentMethodLabel,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.green),
          SizedBox(width: 8),
          Text('Receipt'),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('Tab', tab.name),
              const Divider(),
              ...tab.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i.qty} x ${i.product.name}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          i.lineTotal.toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              const Divider(),
              _row('Subtotal', '€${subtotal.toStringAsFixed(2)}'),
              if (giftUsed > 0)
                _row('Gift Card', '-€${giftUsed.toStringAsFixed(2)}'),
              _row('Total', '€${payable.toStringAsFixed(2)}', bold: true),
              if (paymentMethodLabel != null)
                _row('Payment', paymentMethodLabel),
              _row('Cash', '€${cashGiven.toStringAsFixed(2)}'),
              _row('Change', '€${change.toStringAsFixed(2)}',
                  bold: true, color: Colors.green.shade700),
              const Divider(),
              if (customer.name.isNotEmpty) _row('Customer', customer.name),
              const SizedBox(height: 8),
              const Center(
                child: Text('Thank you!',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _row(String label, String value,
    {bool bold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Optional full-screen Checkout (kept for compatibility / if you still
// want a dedicated Checkout page).
// ---------------------------------------------------------------------------
class CheckoutScreen extends StatefulWidget {
  final BarTab tab;
  final Customer customer;
  const CheckoutScreen({super.key, required this.tab, required this.customer});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool useGift = false;
  bool earnPoints = true;

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.tab.subtotal;
    final giftUsed = useGift
        ? (widget.customer.giftCardBalance < subtotal
            ? widget.customer.giftCardBalance
            : subtotal)
        : 0.0;
    final payable = subtotal - giftUsed;
    final pointsEarned = earnPoints ? payable : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text('Checkout - ${widget.tab.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtotal: €${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                  'Use Gift Card (Balance €${widget.customer.giftCardBalance.toStringAsFixed(2)})'),
              value: useGift,
              onChanged: (v) => setState(() => useGift = v),
            ),
            SwitchListTile(
              title: const Text('Earn Loyalty Points (1 pt per €1)'),
              value: earnPoints,
              onChanged: (v) => setState(() => earnPoints = v),
            ),
            const Divider(),
            Text('Gift Applied: -€${giftUsed.toStringAsFixed(2)}'),
            Text(
              'Amount Due: €${payable.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text('Points Earned: ${pointsEarned.toStringAsFixed(0)}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  widget.customer.giftCardBalance -= giftUsed;
                  widget.customer.loyaltyPoints += pointsEarned;

                  await AppDatabase.logSale(
                    id: const Uuid().v4(),
                    tabName: widget.tab.name,
                    total: payable,
                    points: pointsEarned,
                    giftUsed: giftUsed,
                    staffId: AuthService.staffId,
                  );

                  if (!context.mounted) return;
                  await showReceiptDialog(
                    context,
                    tab: widget.tab,
                    customer: widget.customer,
                    subtotal: subtotal,
                    giftUsed: giftUsed,
                    payable: payable,
                    cashGiven: payable,
                    change: 0,
                    pointsEarned: pointsEarned,
                  );

                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Complete Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}