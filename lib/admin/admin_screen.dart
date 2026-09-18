// lib/admin/admin_screen.dart
import 'package:flutter/material.dart';
import '../database.dart';
import '../models.dart';
import 'product_editor_screen.dart';
import 'cash_denominations_screen.dart';
import 'sales_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Product> products = [];
  List<Category> categories = [];
  List<Map<String, Object?>> staff = [];
  int pending = 0;

  final TextEditingController _searchCtl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await AppDatabase.getProducts(onlyActive: false);
    final c = await AppDatabase.getCategories(onlyActive: false);
    final s = await AppDatabase.getStaff();
    final pendingRows = await AppDatabase.pendingSales();
    if (!mounted) return;
    setState(() {
      products = p;
      categories = c;
      staff = s;
      pending = pendingRows.length;
    });
  }

  String _categoryName(int id) => categories
      .firstWhere((c) => c.id == id, orElse: () => Category(id: -1, name: '?'))
      .name;

  Color _hexToColor(String hex) {
    try {
      var h = hex.replaceFirst('#', '').trim();
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return const Color(0xFF7E8AA2);
    }
  }

  List<Product> get _filteredProducts {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products.where((p) {
      final name = p.name.toLowerCase();
      final cat = _categoryName(p.categoryId).toLowerCase();
      final price = p.price.toStringAsFixed(2);
      return name.contains(q) || cat.contains(q) || price.contains(q);
    }).toList();
  }

  // ---------- Products ----------
  Future<void> _addProduct() async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a category first')),
      );
      return;
    }
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductEditorScreen()),
    );
    if (ok == true) _load();
  }

  Future<void> _editProduct(Product p) async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductEditorScreen(product: p)),
    );
    if (ok == true) _load();
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${p.name}?'),
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
    if (confirm == true && p.id != null) {
      await AppDatabase.deleteProduct(p.id!);
      _load();
    }
  }

  // ---------- Categories ----------
  Future<void> _addOrEditCategory([Category? existing]) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final orderCtl =
        TextEditingController(text: (existing?.sortOrder ?? 0).toString());
    bool active = existing?.active ?? true;
    String color = existing?.color ?? '#3F6FE0';

    const palette = <String>[
      '#1ABC9C', '#16A085', '#2ECC71', '#43C97A', '#27AE60',
      '#F1C40F', '#F39C12', '#E67E22', '#E74C3C', '#E94B4B',
      '#E91E63', '#9B59B6', '#8E44AD', '#5B6FE0', '#3F6FE0',
      '#3498DB', '#26C6DA', '#00BCD4', '#8D6E63', '#607D8B',
      '#7E8AA2', '#2E4A57',
    ];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Add Category' : 'Edit Category'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Beer',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort order',
                      hintText: 'Lower number appears first',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Color',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(color,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: palette.map((hex) {
                      final selected =
                          hex.toUpperCase() == color.toUpperCase();
                      return GestureDetector(
                        onTap: () => setSt(() => color = hex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _hexToColor(hex),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? Colors.black : Colors.black12,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Custom hex (optional)',
                      hintText: '#RRGGBB',
                    ),
                    onChanged: (v) {
                      if (v.trim().isEmpty) return;
                      var h = v.trim();
                      if (!h.startsWith('#')) h = '#$h';
                      setSt(() => color = h);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (v) => setSt(() => active = v),
                  ),
                ],
              ),
            ),
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
    final name = nameCtl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final sort = int.tryParse(orderCtl.text.trim()) ?? 0;

    if (existing == null) {
      await AppDatabase.addCategory(
        Category(name: name, sortOrder: sort, active: active, color: color),
      );
    } else {
      await AppDatabase.updateCategory(
        existing.copyWith(
          name: name,
          sortOrder: sort,
          active: active,
          color: color,
        ),
      );
    }
    _load();
  }

  Future<void> _deleteCategory(Category c) async {
    try {
      await AppDatabase.deleteCategory(c.id!);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ---------- Staff ----------
  Future<void> _addStaff() async {
    final nameCtl = TextEditingController();
    final pinCtl = TextEditingController();
    String role = StaffRole.cashier.name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: pinCtl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: '4-digit PIN'),
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: StaffRole.values
                    .map((r) =>
                        DropdownMenuItem(value: r.name, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setSt(() => role = v!),
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
    if (ok == true) {
      final pin = pinCtl.text.trim();
      if (nameCtl.text.trim().isEmpty || pin.length != 4) return;
      await AppDatabase.addStaff(
        nameCtl.text.trim(),
        pin,
        StaffRole.values.firstWhere((r) => r.name == role),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
            Tab(text: 'Staff'),
            Tab(text: 'Buttons'),
            Tab(text: 'Sales'),
          ]),
        ),
        body: TabBarView(
          children: [
            // -------- Products --------
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_filteredProducts.length} of ${products.length} products',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reload',
                        icon: const Icon(Icons.refresh),
                        onPressed: _load,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                        onPressed: _addProduct,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: TextField(
                    controller: _searchCtl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, category, or price…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No products yet'
                                : 'No products match "$_searchQuery"',
                            style:
                                const TextStyle(color: Colors.black45),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 0),
                          itemBuilder: (_, i) {
                            final p = _filteredProducts[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _hexToColor(categories
                                    .firstWhere((c) => c.id == p.categoryId,
                                        orElse: () => Category(
                                            id: -1,
                                            name: '?',
                                            color: '#7E8AA2'))
                                    .color),
                                child: Text(
                                  _categoryName(p.categoryId).isNotEmpty
                                      ? _categoryName(p.categoryId)[0]
                                      : '?',
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(p.name),
                              subtitle: Text(
                                  '${_categoryName(p.categoryId)} • €${p.price.toStringAsFixed(2)}'
                                  '${p.active ? '' : ' • INACTIVE'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editProduct(p)),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteProduct(p)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            // -------- Categories --------
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${categories.length} categories',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      IconButton(
                        tooltip: 'Reload',
                        icon: const Icon(Icons.refresh),
                        onPressed: _load,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                        onPressed: () => _addOrEditCategory(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _hexToColor(c.color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        title: Text(c.name),
                        subtitle: Text(
                            'Sort: ${c.sortOrder} • ${c.color}${c.active ? '' : ' • INACTIVE'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _addOrEditCategory(c)),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deleteCategory(c)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // -------- Staff --------
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${staff.length} staff • $pending pending sales',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      IconButton(
                        tooltip: 'Reload',
                        icon: const Icon(Icons.refresh),
                        onPressed: _load,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Staff'),
                        onPressed: _addStaff,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: ListView.separated(
                    itemCount: staff.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final s = staff[i];
                      return ListTile(
                        leading: const Icon(Icons.badge),
                        title: Text(s['name'] as String),
                        subtitle: Text('Role: ${s['role']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await AppDatabase.deleteStaff(s['id'] as int);
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // -------- Buttons --------
            const CashDenominationsScreen(),
            // -------- Sales --------
            const SalesScreen(),
          ],
        ),
      ),
    );
  }
}