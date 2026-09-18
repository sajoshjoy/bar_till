// lib/models.dart
import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int sortOrder;
  final bool active;
  final String color; // hex like "#1ABC9C"

  Category({
    this.id,
    required this.name,
    this.sortOrder = 0,
    this.active = true,
    this.color = '#7E8AA2',
  });

  Category copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? active,
    String? color,
  }) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        active: active ?? this.active,
        color: color ?? this.color,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sort_order': sortOrder,
        'active': active ? 1 : 0,
        'color': color,
      };

  static Category fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        sortOrder: (m['sort_order'] as int?) ?? 0,
        active: (m['active'] as int) == 1,
        color: (m['color'] as String?) ?? '#7E8AA2',
      );

  Color toColor() {
    try {
      var hex = color.replaceFirst('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length != 8) return const Color(0xFF7E8AA2);
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF7E8AA2);
    }
  }
}

class Product {
  final int? id;
  final String name;
  final double price;
  final int categoryId;
  final bool active;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.active = true,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? categoryId,
    bool? active,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        categoryId: categoryId ?? this.categoryId,
        active: active ?? this.active,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'category_id': categoryId,
        'active': active ? 1 : 0,
      };

  static Product fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        categoryId: m['category_id'] as int,
        active: (m['active'] as int) == 1,
      );
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});
  double get lineTotal => product.price * qty;
}

class BarTab {
  final String id;
  final String name;
  final List<CartItem> items;
  BarTab({required this.id, required this.name, List<CartItem>? items})
      : items = items ?? [];
  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);
}

class Customer {
  final String id;
  final String name;
  double loyaltyPoints;
  double giftCardBalance;
  Customer({
    required this.id,
    required this.name,
    this.loyaltyPoints = 0,
    this.giftCardBalance = 0,
  });
}

enum StaffRole { cashier, manager }
enum PaymentButtonType { cash, card, gift, loyalty }

class PaymentButton {
  final int? id;
  final PaymentButtonType type;
  final double value;      // amount for cash / card / gift, points for loyalty
  final bool active;
  final int sortOrder;

  PaymentButton({
    this.id,
    required this.type,
    required this.value,
    this.active = true,
    this.sortOrder = 0,
  });

  PaymentButton copyWith({
    int? id,
    PaymentButtonType? type,
    double? value,
    bool? active,
    int? sortOrder,
  }) =>
      PaymentButton(
        id: id ?? this.id,
        type: type ?? this.type,
        value: value ?? this.value,
        active: active ?? this.active,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'value': value,
        'active': active ? 1 : 0,
        'sort_order': sortOrder,
      };

  static PaymentButton fromMap(Map<String, Object?> m) => PaymentButton(
        id: m['id'] as int?,
        type: PaymentButtonType.values.firstWhere(
          (t) => t.name == (m['type'] as String? ?? 'cash'),
          orElse: () => PaymentButtonType.cash,
        ),
        value: (m['value'] as num).toDouble(),
        active: (m['active'] as int) == 1,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );

  /// Human label. For cash/card/gift we show €X. For loyalty we show
  /// the points value in text form.
  String get label {
    switch (type) {
      case PaymentButtonType.cash:
        return value == value.roundToDouble()
            ? '€${value.toStringAsFixed(0)}'
            : '€${value.toStringAsFixed(2)}';
      case PaymentButtonType.card:
        return 'Credit Card';
      case PaymentButtonType.gift:
        return 'Gift Card';
      case PaymentButtonType.loyalty:
        return 'Loyalty Pay';
    }
  }
}