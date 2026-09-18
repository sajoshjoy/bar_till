// lib/database.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'models.dart';
import 'seed_extra.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = join(await getDatabasesPath(), 'bar_till.db');
    print('DATABASE PATH: $path');
    _db = await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _db!;
  }

  // ---------------- Schema ----------------
  static Future<void> _onCreate(Database db, int v) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sort_order INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        color TEXT NOT NULL DEFAULT '#7E8AA2'
      )
    ''');
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category_id INTEGER NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id TEXT PRIMARY KEY,
        tab_name TEXT,
        total REAL,
        points_earned REAL,
        gift_used REAL,
        staff_id INTEGER,
        voided INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        payment_method TEXT,
        created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE payment_buttons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL DEFAULT 'cash',
        value REAL NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _seed(db);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          sort_order INTEGER NOT NULL DEFAULT 0,
          active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      final info = await db.rawQuery('PRAGMA table_info(products)');
      final hasCategoryColumn = info.any((c) => c['name'] == 'category');
      if (hasCategoryColumn) {
        await db.execute('ALTER TABLE products RENAME TO products_old');
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            category_id INTEGER NOT NULL,
            active INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(category_id) REFERENCES categories(id)
          )
        ''');
        final oldRows = await db.query('products_old');
        final categoryMap = <String, int>{};
        for (final r in oldRows) {
          final catName = r['category'] as String;
          if (!categoryMap.containsKey(catName)) {
            final id = await db.insert('categories', {
              'name': catName,
              'sort_order': categoryMap.length,
              'active': 1,
            });
            categoryMap[catName] = id;
          }
        }
        for (final r in oldRows) {
          await db.insert('products', {
            'name': r['name'],
            'price': r['price'],
            'category_id': categoryMap[r['category'] as String],
            'active': r['active'] ?? 1,
          });
        }
        await db.execute('DROP TABLE products_old');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS staff(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          pin TEXT NOT NULL,
          role TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales(
          id TEXT PRIMARY KEY,
          tab_name TEXT,
          total REAL,
          points_earned REAL,
          gift_used REAL,
          staff_id INTEGER,
          created_at TEXT
        )
      ''');
      await _seedStaffOnly(db);
    }

    if (oldV < 4) {
      final info = await db.rawQuery('PRAGMA table_info(categories)');
      final hasColor = info.any((c) => c['name'] == 'color');
      if (!hasColor) {
        await db.execute(
            "ALTER TABLE categories ADD COLUMN color TEXT NOT NULL DEFAULT '#7E8AA2'");
        const defaults = {
          'Beer': '#1ABC9C',
          'Cider': '#F39C12',
          'Wine': '#9B59B6',
          'Spirits': '#5B6FE0',
          'Cocktails': '#E91E63',
          'Soft Drinks': '#26C6DA',
          'Hot Drinks': '#8D6E63',
          'Snacks': '#F39C12',
          'Food': '#3498DB',
        };
        for (final entry in defaults.entries) {
          await db.update(
            'categories',
            {'color': entry.value},
            where: 'name = ?',
            whereArgs: [entry.key],
          );
        }
      }
    }

    if (oldV < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cash_denominations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          value REAL NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM cash_denominations')) ??
          0;
      if (count == 0) {
        const defaults = [5.0, 10.0, 20.0, 50.0, 100.0];
        for (var i = 0; i < defaults.length; i++) {
          await db.insert('cash_denominations', {
            'value': defaults[i],
            'active': 1,
            'sort_order': i,
          });
        }
      }
    }

    if (oldV < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_buttons(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL DEFAULT 'cash',
          value REAL NOT NULL DEFAULT 0,
          active INTEGER NOT NULL DEFAULT 1,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='cash_denominations'");
      if (tables.isNotEmpty) {
        final rows = await db.query('cash_denominations');
        for (final r in rows) {
          await db.insert('payment_buttons', {
            'type': 'cash',
            'value': r['value'],
            'active': r['active'] ?? 1,
            'sort_order': r['sort_order'] ?? 0,
          });
        }
        await db.execute('DROP TABLE cash_denominations');
      }

      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM payment_buttons')) ??
          0;
      if (count == 0) {
        const cash = [5.0, 10.0, 20.0, 50.0, 100.0];
        for (var i = 0; i < cash.length; i++) {
          await db.insert('payment_buttons', {
            'type': 'cash',
            'value': cash[i],
            'active': 1,
            'sort_order': i,
          });
        }
      }

      final existingTypes = await db.query('payment_buttons',
          columns: ['type'], distinct: true);
      final types = existingTypes.map((r) => r['type']).toSet();
      var sort = 100;
      for (final t in ['card', 'gift', 'loyalty']) {
        if (!types.contains(t)) {
          await db.insert('payment_buttons', {
            'type': t,
            'value': 0,
            'active': 1,
            'sort_order': sort++,
          });
        }
      }
    }

    if (oldV < 7) {
      final info = await db.rawQuery('PRAGMA table_info(sales)');
      final hasVoided = info.any((c) => c['name'] == 'voided');
      final hasNote = info.any((c) => c['name'] == 'note');
      if (!hasVoided) {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN voided INTEGER NOT NULL DEFAULT 0');
      }
      if (!hasNote) {
        await db.execute('ALTER TABLE sales ADD COLUMN note TEXT');
      }
    }

    if (oldV < 8) {
      await SeedExtra.run(db);
    }

    if (oldV < 9) {
      final info = await db.rawQuery('PRAGMA table_info(sales)');
      final hasMethod = info.any((c) => c['name'] == 'payment_method');
      if (!hasMethod) {
        await db.execute('ALTER TABLE sales ADD COLUMN payment_method TEXT');
      }
    }
  }

  static Future<void> _seed(Database db) async {
    final cats = <Map<String, Object>>[
      {'name': 'Beer', 'color': '#1ABC9C'},
      {'name': 'Cider', 'color': '#F39C12'},
      {'name': 'Wine', 'color': '#9B59B6'},
      {'name': 'Spirits', 'color': '#5B6FE0'},
      {'name': 'Cocktails', 'color': '#E91E63'},
      {'name': 'Soft Drinks', 'color': '#26C6DA'},
      {'name': 'Hot Drinks', 'color': '#8D6E63'},
      {'name': 'Snacks', 'color': '#F39C12'},
      {'name': 'Food', 'color': '#3498DB'},
    ];
    final catIds = <String, int>{};
    for (var i = 0; i < cats.length; i++) {
      catIds[cats[i]['name'] as String] = await db.insert('categories', {
        'name': cats[i]['name'],
        'sort_order': i + 1,
        'active': 1,
        'color': cats[i]['color'],
      });
    }

    final items = <List<Object>>[
      ['Guinness Pint', 5.50, 'Beer'],
      ['Heineken Pint', 5.80, 'Beer'],
      ['Carlsberg Pint', 5.60, 'Beer'],
      ['Budweiser Bottle', 5.00, 'Beer'],
      ['Corona Bottle', 5.20, 'Beer'],
      ['Coors Light Pint', 5.50, 'Beer'],
      ['Bulmers Pint', 5.80, 'Cider'],
      ['Orchard Thieves', 5.80, 'Cider'],
      ['Kopparberg Bottle', 5.50, 'Cider'],
      ['House Red Glass', 6.00, 'Wine'],
      ['House White Glass', 6.00, 'Wine'],
      ['Pinot Grigio Glass', 7.00, 'Wine'],
      ['Merlot Glass', 7.00, 'Wine'],
      ['Prosecco Glass', 7.50, 'Wine'],
      ['House Red Bottle', 24.00, 'Wine'],
      ['House White Bottle', 24.00, 'Wine'],
      ['Jameson', 5.50, 'Spirits'],
      ['Powers', 5.50, 'Spirits'],
      ['Tullamore Dew', 5.50, 'Spirits'],
      ['Jack Daniels', 6.00, 'Spirits'],
      ['Smirnoff Vodka', 5.50, 'Spirits'],
      ['Gordons Gin', 5.50, 'Spirits'],
      ['Hennessy', 7.00, 'Spirits'],
      ['Baileys', 5.50, 'Spirits'],
      ['Gin & Tonic', 8.00, 'Cocktails'],
      ['Vodka & Coke', 8.00, 'Cocktails'],
      ['Whiskey & Ginger', 8.00, 'Cocktails'],
      ['Rum & Coke', 8.00, 'Cocktails'],
      ['Mojito', 9.50, 'Cocktails'],
      ['Espresso Martini', 10.00, 'Cocktails'],
      ['Aperol Spritz', 9.50, 'Cocktails'],
      ['Coke', 2.50, 'Soft Drinks'],
      ['Diet Coke', 2.50, 'Soft Drinks'],
      ['7 Up', 2.50, 'Soft Drinks'],
      ['Fanta Orange', 2.50, 'Soft Drinks'],
      ['Club Orange', 2.50, 'Soft Drinks'],
      ['Club Lemon', 2.50, 'Soft Drinks'],
      ['Red Bull', 4.00, 'Soft Drinks'],
      ['Orange Juice', 2.80, 'Soft Drinks'],
      ['Tonic Water', 2.50, 'Soft Drinks'],
      ['Bottled Water', 2.00, 'Soft Drinks'],
      ['Espresso', 2.50, 'Hot Drinks'],
      ['Americano', 3.00, 'Hot Drinks'],
      ['Cappuccino', 3.50, 'Hot Drinks'],
      ['Latte', 3.50, 'Hot Drinks'],
      ['Tea', 2.50, 'Hot Drinks'],
      ['Hot Whiskey', 6.50, 'Hot Drinks'],
      ['Crisps', 1.80, 'Snacks'],
      ['Peanuts', 2.00, 'Snacks'],
      ['Chocolate Bar', 1.80, 'Snacks'],
      ['Mixed Nuts', 2.50, 'Snacks'],
      ['Soup of the Day', 5.50, 'Food'],
      ['Chicken Wings', 8.50, 'Food'],
      ['Nachos', 7.50, 'Food'],
      ['Beef Burger', 12.50, 'Food'],
      ['Chicken Burger', 11.50, 'Food'],
      ['Fish & Chips', 13.00, 'Food'],
      ['Caesar Salad', 9.50, 'Food'],
      ['Steak Sandwich', 13.50, 'Food'],
      ['Garlic Bread', 4.50, 'Food'],
      ['Chips', 3.50, 'Food'],
    ];

    for (final it in items) {
      await db.insert('products', {
        'name': it[0],
        'price': it[1],
        'category_id': catIds[it[2]]!,
        'active': 1,
      });
    }

    await _seedStaffOnly(db);

    // Default cash buttons
    const cashDefaults = [5.0, 10.0, 20.0, 50.0, 100.0];
    for (var i = 0; i < cashDefaults.length; i++) {
      await db.insert('payment_buttons', {
        'type': 'cash',
        'value': cashDefaults[i],
        'active': 1,
        'sort_order': i,
      });
    }

    // Default action buttons
    await db.insert('payment_buttons', {
      'type': 'card',
      'value': 0,
      'active': 1,
      'sort_order': 100,
    });
    await db.insert('payment_buttons', {
      'type': 'gift',
      'value': 0,
      'active': 1,
      'sort_order': 101,
    });
    await db.insert('payment_buttons', {
      'type': 'loyalty',
      'value': 0,
      'active': 1,
      'sort_order': 102,
    });

    // Extra categories + products
    await SeedExtra.run(db);
  }

  static Future<void> _seedStaffOnly(Database db) async {
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM staff')) ??
        0;
    if (count == 0) {
      await db.insert('staff',
          {'name': 'Manager', 'pin': '1234', 'role': 'manager'});
      await db.insert('staff',
          {'name': 'Cashier', 'pin': '1111', 'role': 'cashier'});
    }
  }

  // ---------------- Categories ----------------
  static Future<List<Category>> getCategories({bool onlyActive = true}) async {
    final d = await db;
    final rows = await d.query(
      'categories',
      where: onlyActive ? 'active = 1' : null,
      orderBy: 'sort_order, name',
    );
    return rows.map(Category.fromMap).toList();
  }

  static Future<int> addCategory(Category c) async {
    final d = await db;
    return d.insert('categories', c.toMap());
  }

  static Future<void> updateCategory(Category c) async {
    final d = await db;
    await d.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  static Future<void> deleteCategory(int id) async {
    final d = await db;
    final used = Sqflite.firstIntValue(await d.rawQuery(
            'SELECT COUNT(*) FROM products WHERE category_id = ?', [id])) ??
        0;
    if (used > 0) {
      throw Exception(
          'Category is used by $used product(s). Move or delete them first.');
    }
    await d.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Products ----------------
  static Future<List<Product>> getProducts({
    bool onlyActive = true,
    int? categoryId,
  }) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (onlyActive) where.add('active = 1');
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    final rows = await d.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name',
    );
    return rows.map(Product.fromMap).toList();
  }

  static Future<int> addProduct(Product p) async {
    final d = await db;
    return d.insert('products', p.toMap());
  }

  static Future<void> updateProduct(Product p) async {
    final d = await db;
    await d.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  static Future<void> deleteProduct(int id) async {
    final d = await db;
    await d.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Staff ----------------
  static Future<Map<String, Object?>?> findStaffByPin(String pin) async {
    final d = await db;
    final rows =
        await d.query('staff', where: 'pin = ?', whereArgs: [pin], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<List<Map<String, Object?>>> getStaff() async {
    final d = await db;
    return d.query('staff', orderBy: 'name');
  }

  static Future<int> addStaff(String name, String pin, StaffRole role) async {
    final d = await db;
    return d.insert('staff', {'name': name, 'pin': pin, 'role': role.name});
  }

  static Future<void> updateStaffPin(int id, String pin) async {
    final d = await db;
    await d.update('staff', {'pin': pin}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteStaff(int id) async {
    final d = await db;
    await d.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Payment buttons ----------------
  static Future<List<PaymentButton>> getPaymentButtons({
    bool onlyActive = true,
    PaymentButtonType? type,
  }) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (onlyActive) where.add('active = 1');
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }
    final rows = await d.query(
      'payment_buttons',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'sort_order, value',
    );
    return rows.map(PaymentButton.fromMap).toList();
  }

  static Future<int> addPaymentButton(PaymentButton b) async {
    final d = await db;
    return d.insert('payment_buttons', b.toMap());
  }

  static Future<void> updatePaymentButton(PaymentButton b) async {
    final d = await db;
    await d.update('payment_buttons', b.toMap(),
        where: 'id = ?', whereArgs: [b.id]);
  }

  static Future<void> deletePaymentButton(int id) async {
    final d = await db;
    await d.delete('payment_buttons', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Sales ----------------
  static Future<void> logSale({
    required String id,
    required String tabName,
    required double total,
    required double points,
    required double giftUsed,
    int? staffId,
    bool voided = false,
    String? note,
    String? paymentMethod,
  }) async {
    final d = await db;
    await d.insert('sales', {
      'id': id,
      'tab_name': tabName,
      'total': total,
      'points_earned': points,
      'gift_used': giftUsed,
      'staff_id': staffId,
      'voided': voided ? 1 : 0,
      'note': note,
      'payment_method': paymentMethod,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, Object?>>> pendingSales() async {
    final d = await db;
    return d.query('sales', orderBy: 'created_at ASC');
  }

  /// Sales history for the Admin → Sales tab.
  static Future<List<Map<String, Object?>>> getSales({
    bool includeVoided = true,
    int limit = 500,
  }) async {
    final d = await db;
    return d.query(
      'sales',
      where: includeVoided ? null : 'voided = 0',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }
}