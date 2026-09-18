// lib/till_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'database.dart';
import 'checkout_screen.dart';
import 'auth_service.dart';
import 'admin/admin_screen.dart';
import 'login_screen.dart';
import 'till_widgets.dart';

class TillScreen extends StatefulWidget {
  const TillScreen({super.key});
  @override
  State<TillScreen> createState() => _TillScreenState();
}

class _TillScreenState extends State<TillScreen> {
  List<Product> products = [];
  List<Category> categories = [];
  List<PaymentButton> paymentButtons = [];
  int? selectedCategoryId;

  final List<BarTab> tabs = [
    BarTab(id: 't1', name: 'Table 1'),
    BarTab(id: 't2', name: 'Table 2'),
    BarTab(id: 'b1', name: 'Bar Seat 1'),
  ];
  int activeTabIndex = 0;
  BarTab get activeTab => tabs[activeTabIndex];

  final Customer customer = Customer(
    id: 'c1',
    name: 'John',
    loyaltyPoints: 120,
    giftCardBalance: 25.00,
  );

  String _numpadInput = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await AppDatabase.getCategories();
    final prods = await AppDatabase.getProducts();
    final buttons = await AppDatabase.getPaymentButtons();
    if (!mounted) return;
    setState(() {
      categories = cats;
      products = prods;
      paymentButtons = buttons;
      if (selectedCategoryId == null && cats.isNotEmpty) {
        selectedCategoryId = cats.first.id;
      }
    });
  }

  List<Product> get visibleProducts {
    if (selectedCategoryId == null) return products;
    return products.where((p) => p.categoryId == selectedCategoryId).toList();
  }

  List<PaymentButton> get _cashButtons =>
      paymentButtons.where((b) => b.type == PaymentButtonType.cash).toList();

  List<PaymentButton> get _bottomButtons => paymentButtons
      .where((b) =>
          b.type == PaymentButtonType.card ||
          b.type == PaymentButtonType.gift ||
          b.type == PaymentButtonType.loyalty)
      .toList();

  void addToTab(Product p) {
    setState(() {
      final existing = activeTab.items.firstWhere(
        (i) => i.product.id == p.id,
        orElse: () => CartItem(product: p, qty: 0),
      );
      if (existing.qty == 0) {
        activeTab.items.add(CartItem(product: p));
      } else {
        existing.qty++;
      }
    });
  }

  void changeQty(CartItem item, int delta) {
    setState(() {
      item.qty += delta;
      if (item.qty <= 0) activeTab.items.remove(item);
    });
  }

  void _resetActiveTab() {
    setState(() {
      tabs.removeAt(activeTabIndex);
      tabs.add(BarTab(id: const Uuid().v4(), name: 'New Tab'));
      activeTabIndex = tabs.length - 1;
      _numpadInput = '';
    });
  }

  // ---------------- Numpad ----------------
  void _numpadPress(String key) {
    setState(() {
      switch (key) {
        case 'CL':
        case 'ESC':
          _numpadInput = '';
          break;
        case 'x':
          if (_numpadInput.isNotEmpty) {
            _numpadInput =
                _numpadInput.substring(0, _numpadInput.length - 1);
          }
          break;
        case '.':
          if (!_numpadInput.contains('.')) {
            _numpadInput =
                _numpadInput.isEmpty ? '0.' : '$_numpadInput.';
          }
          break;
        case '00':
          _numpadInput += '00';
          break;
        case '↩':
          _payCashWithNumpad();
          break;
        default:
          _numpadInput += key;
      }
    });
  }

  double? get _numpadValue {
    if (_numpadInput.isEmpty) return null;
    return double.tryParse(_numpadInput);
  }

  // ---------------- CORRECTION ----------------
  Future<void> _correction() async {
    if (activeTab.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to correct — tab is empty')),
      );
      return;
    }
    if (!AuthService.isManager) {
      final ok = await _requireManagerPin();
      if (ok != true) return;
    }
    if (!mounted) return;
    final action = await showModalBottomSheet<CorrectionAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Correction — pick a line',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 0),
              ...activeTab.items.map((item) {
                return ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text('${item.qty} x ${item.product.name}'),
                  trailing: Text('€${item.lineTotal.toStringAsFixed(2)}'),
                  onTap: () =>
                      Navigator.pop(ctx, CorrectionAction(item: item)),
                );
              }),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Remove entire line',
                    style: TextStyle(color: Colors.red)),
                onTap: () =>
                    Navigator.pop(ctx, const CorrectionAction(all: true)),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (action == null || !mounted) return;
    if (action.all == true) {
      setState(() => activeTab.items.clear());
      return;
    }
    final item = action.item!;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.product.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('€${item.product.price.toStringAsFixed(2)} each',
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: item.qty > 1
                              ? () {
                                  setState(() => item.qty--);
                                  setLocal(() {});
                                }
                              : null,
                        ),
                        Text('${item.qty}',
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold)),
                        IconButton(
                          iconSize: 40,
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() => item.qty++);
                            setLocal(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete line',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              setState(() => activeTab.items.remove(item));
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43C97A),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- VOID ----------------
  Future<void> _voidTab() async {
    if (activeTab.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to void — tab is empty')),
      );
      return;
    }
    final ok = await _requireManagerPin();
    if (ok != true) return;
    final subtotal = activeTab.subtotal;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Void tab?'),
          ],
        ),
        content: Text(
          'This will cancel the entire tab "${activeTab.name}" '
          '(€${subtotal.toStringAsFixed(2)}).\n\n'
          'A voided sale will be recorded for audit.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Void', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await AppDatabase.logSale(
      id: const Uuid().v4(),
      tabName: activeTab.name,
      total: -subtotal,
      points: 0,
      giftUsed: 0,
      staffId: AuthService.staffId,
      voided: true,
    );
    if (!mounted) return;
    setState(() => activeTab.items.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tab voided'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool?> _requireManagerPin() async {
    final pinCtl = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 8),
            Text('Manager PIN required'),
          ],
        ),
        content: TextField(
          controller: pinCtl,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: '4-digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final staff =
                  await AppDatabase.findStaffByPin(pinCtl.text.trim());
              if (staff == null || staff['role'] != StaffRole.manager.name) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Not a manager PIN'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------- Quick cash ----------
  Future<void> _payCash(double amount) async {
    if (activeTab.items.isEmpty) return;
    final subtotal = activeTab.subtotal;
    final payable = subtotal;
    if (amount < payable) {
      final short = payable - amount;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Insufficient cash'),
            ],
          ),
          content: Text(
            'Total is €${payable.toStringAsFixed(2)} but only '
            '€${amount.toStringAsFixed(2)} was offered.\n\n'
            'Short by €${short.toStringAsFixed(2)}.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final change = amount - payable;
    await AppDatabase.logSale(
      id: const Uuid().v4(),
      tabName: activeTab.name,
      total: payable,
      points: 0,
      giftUsed: 0,
      staffId: AuthService.staffId,
    );
    if (!mounted) return;
    await showReceiptDialog(
      context,
      tab: activeTab,
      customer: customer,
      subtotal: subtotal,
      giftUsed: 0,
      payable: payable,
      cashGiven: amount,
      change: change,
      pointsEarned: 0,
      paymentMethodLabel: 'Cash',
    );
    if (!mounted) return;
    _resetActiveTab();
  }

  // ---------- Manual CASH ----------
  Future<void> _payCashWithNumpad() async {
    if (activeTab.items.isEmpty) return;
    final total = activeTab.subtotal;
    final entered = _numpadValue;
    final cashGiven = entered ?? total;
    if (cashGiven < total) {
      final short = total - cashGiven;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Insufficient cash'),
            ],
          ),
          content: Text(
            'Total is €${total.toStringAsFixed(2)} but only '
            '€${cashGiven.toStringAsFixed(2)} was entered.\n\n'
            'Short by €${short.toStringAsFixed(2)}.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final change = cashGiven - total;
    await AppDatabase.logSale(
      id: const Uuid().v4(),
      tabName: activeTab.name,
      total: total,
      points: 0,
      giftUsed: 0,
      staffId: AuthService.staffId,
    );
    if (!mounted) return;
    await showReceiptDialog(
      context,
      tab: activeTab,
      customer: customer,
      subtotal: total,
      giftUsed: 0,
      payable: total,
      cashGiven: cashGiven,
      change: change,
      pointsEarned: 0,
      paymentMethodLabel: 'Cash',
    );
    if (!mounted) return;
    _resetActiveTab();
  }

  // ---------- Card / Gift / Loyalty ----------
  Future<void> _payWithAction(PaymentButtonType type) async {
    if (activeTab.items.isEmpty) return;
    final subtotal = activeTab.subtotal;
    final payable = subtotal;
    if (type == PaymentButtonType.gift &&
        customer.giftCardBalance < payable) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Gift card insufficient'),
            ],
          ),
          content: Text(
            'Balance: €${customer.giftCardBalance.toStringAsFixed(2)}\n'
            'Total:   €${payable.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    if (type == PaymentButtonType.loyalty &&
        customer.loyaltyPoints < payable) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Not enough loyalty points'),
            ],
          ),
          content: Text(
            'Points available: ${customer.loyaltyPoints.toStringAsFixed(0)}\n'
            'Points needed: ${payable.toStringAsFixed(0)}',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    double giftUsed = 0;
    if (type == PaymentButtonType.gift) {
      customer.giftCardBalance -= payable;
      giftUsed = payable;
    } else if (type == PaymentButtonType.loyalty) {
      customer.loyaltyPoints -= payable;
    }
    await AppDatabase.logSale(
      id: const Uuid().v4(),
      tabName: activeTab.name,
      total: payable,
      points: 0,
      giftUsed: giftUsed,
      staffId: AuthService.staffId,
    );
    if (!mounted) return;
    String methodLabel;
    switch (type) {
      case PaymentButtonType.card:
        methodLabel = 'Credit Card';
        break;
      case PaymentButtonType.gift:
        methodLabel = 'Gift Card';
        break;
      case PaymentButtonType.loyalty:
        methodLabel = 'Loyalty Points';
        break;
      case PaymentButtonType.cash:
        methodLabel = 'Cash';
        break;
    }
    await showReceiptDialog(
      context,
      tab: activeTab,
      customer: customer,
      subtotal: subtotal,
      giftUsed: giftUsed,
      payable: payable,
      cashGiven: payable,
      change: 0,
      pointsEarned: 0,
      paymentMethodLabel: methodLabel,
    );
    if (!mounted) return;
    _resetActiveTab();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF3),
      body: SafeArea(
        child: Row(
          children: [
            LeftRail(
              onCorrection: _correction,
              onVoid: _voidTab,
            ),
            Container(
              width: 280,
              color: Colors.white,
              child: OrderPanel(
                tab: activeTab,
                cashButtons: _cashButtons,
                numpadInput: _numpadInput,
                onQty: changeQty,
                onClear: () => setState(() {
                  activeTab.items.clear();
                  _numpadInput = '';
                }),
                onCashTap: _payCash,
                onNumpadKey: _numpadPress,
                onCashButton: _payCashWithNumpad,
              ),
            ),
            Container(
              width: 150,
              color: const Color(0xFFF7F8FA),
              child: categories.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No categories',
                            style: TextStyle(color: Colors.black45)),
                      ),
                    )
                  : CategoryColumn(
                      categories: categories,
                      selectedId: selectedCategoryId,
                      onSelect: (id) =>
                          setState(() => selectedCategoryId = id),
                    ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF3),
                child: Column(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Text(formatNow(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B2B4A))),
                          const Spacer(),
                          TabChips(
                            tabs: tabs,
                            activeIndex: activeTabIndex,
                            onSelect: (i) =>
                                setState(() => activeTabIndex = i),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Reload',
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              await _loadData();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Loaded ${products.length} products, ${categories.length} categories, ${paymentButtons.length} buttons'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          if (AuthService.isManager)
                            IconButton(
                              tooltip: 'Admin',
                              icon: const Icon(Icons.settings),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AdminScreen()),
                                );
                                _loadData();
                              },
                            ),
                          IconButton(
                            tooltip: 'Logout',
                            icon: const Icon(Icons.logout),
                            onPressed: () {
                              AuthService.logout();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visibleProducts.isEmpty
                          ? const Center(
                              child: Text('No products in this category',
                                  style:
                                      TextStyle(color: Colors.black45)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 140,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.05,
                              ),
                              itemCount: visibleProducts.length,
                              itemBuilder: (_, i) {
                                final p = visibleProducts[i];
                                final cat = categories.firstWhere(
                                  (c) => c.id == p.categoryId,
                                  orElse: () => Category(
                                      id: -1, name: '', color: '#7E8AA2'),
                                );
                                return ProductTile(
                                  product: p,
                                  color: cat.toColor(),
                                  onTap: () => addToTab(p),
                                );
                              },
                            ),
                    ),
                    Container(
                      height: 84,
                      padding: const EdgeInsets.all(10),
                      color: const Color(0xFFEDEFF3),
                      child: Row(
                        children: _buildBottomButtons(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBottomButtons(BuildContext context) {
    final buttons = _bottomButtons;
    final children = <Widget>[];
    final order = <PaymentButtonType>[
      PaymentButtonType.card,
      PaymentButtonType.gift,
      PaymentButtonType.loyalty,
    ];
    for (final t in order) {
      final match = buttons.where((b) => b.type == t).toList();
      if (match.isEmpty) continue;
      final b = match.first;
      children.add(Expanded(
        child: BottomAction(
          label: bottomLabel(b.type),
          icon: bottomIcon(b.type),
          onTap: activeTab.items.isEmpty
              ? () {}
              : () => _payWithAction(b.type),
        ),
      ));
      children.add(const SizedBox(width: 10));
    }
    if (children.isNotEmpty && children.last is SizedBox) {
      children.removeLast();
    }
    return children;
  }
}
