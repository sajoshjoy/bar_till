// lib/till_widgets.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'auth_service.dart';

/// ---------- Correction action marker ----------
class CorrectionAction {
  final CartItem? item;
  final bool? all;
  const CorrectionAction({this.item, this.all});
}

/// ---------- Time formatter ----------
String formatNow() {
  final now = DateTime.now();
  final mm = now.month.toString().padLeft(2, '0');
  final dd = now.day.toString().padLeft(2, '0');
  final mi = now.minute.toString().padLeft(2, '0');
  final ampm = now.hour >= 12 ? 'PM' : 'AM';
  final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
  return '$mm/$dd    ${h12.toString().padLeft(2, '0')}:$mi $ampm';
}

/// ---------- Bottom button label/icon helpers ----------
String bottomLabel(PaymentButtonType t) {
  switch (t) {
    case PaymentButtonType.card:
      return 'Credit Card Payment';
    case PaymentButtonType.gift:
      return 'Gift Card Payment';
    case PaymentButtonType.loyalty:
      return 'Loyalty Payment';
    case PaymentButtonType.cash:
      return 'CASH';
  }
}

IconData bottomIcon(PaymentButtonType t) {
  switch (t) {
    case PaymentButtonType.card:
      return Icons.credit_card;
    case PaymentButtonType.gift:
      return Icons.card_giftcard;
    case PaymentButtonType.loyalty:
      return Icons.stars;
    case PaymentButtonType.cash:
      return Icons.payments_outlined;
  }
}

/// ---------- Left rail item ----------
class RailItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const RailItem(this.icon, this.label, [this.onTap]);
}

/// ---------- Left rail ----------
class LeftRail extends StatelessWidget {
  final VoidCallback? onCorrection;
  final VoidCallback? onVoid;
  const LeftRail({super.key, this.onCorrection, this.onVoid});

  @override
  Widget build(BuildContext context) {
    final items = <RailItem>[
      const RailItem(Icons.grid_view, 'POS'),
      const RailItem(Icons.settings, 'Functions'),
      RailItem(Icons.backspace_outlined, 'Correction', onCorrection),
      RailItem(Icons.cancel_outlined, 'Void', onVoid),
      const RailItem(Icons.edit_note, 'Notice'),
      const RailItem(Icons.shopping_bag_outlined, 'Take Away'),
      const RailItem(Icons.card_giftcard, 'VIP sale'),
      const RailItem(Icons.percent, '5% discount'),
    ];
    final staffName =
        (AuthService.currentStaff?['name'] ?? 'Operator').toString();
    return Container(
      width: 84,
      color: const Color(0xFF2E4A57),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3E6272),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              staffName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final e in items)
                  RailButton(icon: e.icon, label: e.label, onTap: e.onTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Left rail button ----------
class RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const RailButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Icon(icon,
                color: onTap == null ? Colors.white38 : Colors.white70,
                size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: onTap == null ? Colors.white38 : Colors.white70,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Order panel ----------
class OrderPanel extends StatelessWidget {
  final BarTab tab;
  final List<PaymentButton> cashButtons;
  final String numpadInput;
  final void Function(CartItem, int) onQty;
  final VoidCallback onClear;
  final void Function(double) onCashTap;
  final void Function(String) onNumpadKey;
  final VoidCallback onCashButton;

  const OrderPanel({
    super.key,
    required this.tab,
    required this.cashButtons,
    required this.numpadInput,
    required this.onQty,
    required this.onClear,
    required this.onCashTap,
    required this.onNumpadKey,
    required this.onCashButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('New order',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B4A))),
        ),
        const Divider(height: 0),
        Expanded(
          child: tab.items.isEmpty
              ? const Center(
                  child: Text('No items',
                      style: TextStyle(color: Colors.black45)))
              : ListView.separated(
                  itemCount: tab.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final item = tab.items[i];
                    return ListTile(
                      dense: true,
                      title: Text('${item.qty} x ${item.product.name}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: Text(
                        item.lineTotal.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => onQty(item, 1),
                      onLongPress: () => onQty(item, -1),
                    );
                  },
                ),
        ),
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '€${tab.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2B4A)),
              ),
            ],
          ),
        ),
        if (numpadInput.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Cash:',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const Spacer(),
                Text('€$numpadInput',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F6FE0))),
              ],
            ),
          ),
        const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.all(10),
          child: MiniNumpad(onKey: onNumpadKey, onClear: onClear),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...cashButtons.map((b) {
                return SizedBox(
                  width: 82,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E4A57),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed:
                        tab.items.isEmpty ? null : () => onCashTap(b.value),
                    child: Text(b.label,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
              SizedBox(
                width: 82,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A94A6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: tab.items.isEmpty ? null : onCashButton,
                  child: const Text('CASH',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------- Mini numpad ----------
class MiniNumpad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onClear;
  const MiniNumpad({super.key, required this.onKey, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['↑', '7', '8', '9', 'x'],
      ['↓', '4', '5', '6', '⌂'],
      ['CL', '1', '2', '3', 'GCs'],
      ['ESC', '0', '00', '.', '↩'],
    ];
    return Column(
      children: rows
          .map((row) => Row(
                children: row
                    .map((key) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (key == 'ESC' ||
                                          key == 'CL' ||
                                          key == 'x')
                                      ? const Color(0xFFE4E7EE)
                                      : Colors.white,
                                  foregroundColor: const Color(0xFF2B2B4A),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(
                                        color: Color(0xFFD7DCEA)),
                                  ),
                                ),
                                onPressed: () => onKey(key),
                                child: Text(key,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ))
          .toList(),
    );
  }
}

/// ---------- Category column ----------
class CategoryColumn extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const CategoryColumn({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  IconData _icon(String c) {
    final s = c.toLowerCase();
    if (s.contains('beer')) return Icons.sports_bar;
    if (s.contains('cider')) return Icons.sports_bar;
    if (s.contains('wine')) return Icons.wine_bar;
    if (s.contains('spirit')) return Icons.local_bar;
    if (s.contains('cocktail')) return Icons.local_bar;
    if (s.contains('soft') || s.contains('juice')) return Icons.local_drink;
    if (s.contains('coffee') || s.contains('tea') || s.contains('hot')) {
      return Icons.coffee;
    }
    if (s.contains('snack')) return Icons.cookie;
    if (s.contains('food')) return Icons.restaurant;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final active = cat.id == selectedId;
        return InkWell(
          onTap: () => onSelect(cat.id!),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: active
                      ? const Color(0xFF2E4A57)
                      : Colors.transparent,
                  width: 4,
                ),
                bottom: const BorderSide(color: Color(0xFFE4E7EE)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(_icon(cat.name),
                    color: active ? cat.toColor() : Colors.black54,
                    size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.w500,
                      color: active
                          ? const Color(0xFF2B2B4A)
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------- Tab chips ----------
class TabChips extends StatelessWidget {
  final List<BarTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const TabChips({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tabs.length, (i) {
        final active = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ChoiceChip(
            selected: active,
            onSelected: (_) => onSelect(i),
            label: Text(tabs[i].name),
            selectedColor: const Color(0xFF2E4A57),
            labelStyle: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFD7DCEA)),
          ),
        );
      }),
    );
  }
}

/// ---------- Product tile ----------
class ProductTile extends StatelessWidget {
  final Product product;
  final Color color;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_bar,
                  color: Colors.white.withOpacity(0.85), size: 26),
              const Spacer(),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '€${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Bottom action button ----------
class BottomAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const BottomAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2E4A57),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}