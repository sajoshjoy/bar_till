// lib/admin/product_editor_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../database.dart';

class ProductEditorScreen extends StatefulWidget {
  final Product? product;
  const ProductEditorScreen({super.key, this.product});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _price;
  bool _active = true;
  List<Category> categories = [];
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _price = TextEditingController(
        text: widget.product?.price.toStringAsFixed(2) ?? '');
    _active = widget.product?.active ?? true;
    _categoryId = widget.product?.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await AppDatabase.getCategories();
    if (!mounted) return;
    setState(() {
      categories = cats;
      _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    final p = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      price: double.parse(_price.text.trim()),
      categoryId: _categoryId!,
      active: _active,
    );
    if (p.id == null) {
      await AppDatabase.addProduct(p);
    } else {
      await AppDatabase.updateProduct(p);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (€)'),
                validator: (v) {
                  final d = double.tryParse(v?.trim() ?? '');
                  return d == null || d <= 0 ? 'Enter a valid price' : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              SwitchListTile(
                title: const Text('Active (visible on till)'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Update' : 'Save'),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}