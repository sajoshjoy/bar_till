// lib/seed_extra.dart
//
// Extra categories and products for the bar till.
// Called once after AppDatabase._seed() so the main file stays readable.
//
import 'package:sqflite/sqflite.dart';

class SeedExtra {
  static Future<void> run(Database db) async {
    // ---- Extra categories ----
    final cats = <Map<String, String>>[
      {'name': 'Champagne', 'color': '#F1C40F'},
      {'name': 'Liqueurs', 'color': '#8E44AD'},
      {'name': 'Juices', 'color': '#00BCD4'},
      {'name': 'Starters', 'color': '#E67E22'},
      {'name': 'Mains', 'color': '#2E86C1'},
      {'name': 'Desserts', 'color': '#E74C3C'},
      {'name': 'Sides', 'color': '#43C97A'},
      {'name': 'Spirits Premium', 'color': '#8E44AD'},
    ];

    // Insert categories only if they don't already exist
    for (var i = 0; i < cats.length; i++) {
      final existing = await db.query('categories',
          where: 'name = ?', whereArgs: [cats[i]['name']], limit: 1);
      if (existing.isEmpty) {
        await db.insert('categories', {
          'name': cats[i]['name'],
          'sort_order': 100 + i,
          'active': 1,
          'color': cats[i]['color'],
        });
      }
    }

    // Build a name→id map for all categories
    final catRows = await db.query('categories');
    final catIds = <String, int>{};
    for (final r in catRows) {
      catIds[r['name'] as String] = r['id'] as int;
    }

    // ---- Extra products ----
    final items = <List<Object>>[
      // ---- Champagne ----
      ['Champagne Glass', 12.00, 'Champagne'],
      ['Moet & Chandon Bottle', 75.00, 'Champagne'],
      ['Veuve Clicquot Bottle', 80.00, 'Champagne'],
      ['Bollinger Bottle', 90.00, 'Champagne'],
      ['Dom Perignon Bottle', 220.00, 'Champagne'],
      ['Krug Bottle', 260.00, 'Champagne'],
      ['Taittinger Bottle', 85.00, 'Champagne'],
      ['Laurent Perrier Bottle', 80.00, 'Champagne'],
      ['Perrier Jouet Bottle', 90.00, 'Champagne'],
      ['Pol Roger Bottle', 95.00, 'Champagne'],

      // ---- Liqueurs ----
      ['Cointreau', 6.00, 'Liqueurs'],
      ['Grand Marnier', 6.50, 'Liqueurs'],
      ['Amaretto', 5.50, 'Liqueurs'],
      ['Disaronno', 6.00, 'Liqueurs'],
      ['Frangelico', 6.00, 'Liqueurs'],
      ['Chambord', 6.00, 'Liqueurs'],
      ['Midori', 5.50, 'Liqueurs'],
      ['Blue Curacao', 5.50, 'Liqueurs'],
      ['Sambuca', 5.50, 'Liqueurs'],
      ['Sambuca Black', 5.80, 'Liqueurs'],
      ['Galliano', 6.00, 'Liqueurs'],
      ['Drambuie', 6.50, 'Liqueurs'],
      ['Glayva', 6.50, 'Liqueurs'],
      ['Jagermeister', 6.00, 'Liqueurs'],
      ['Schnapps Apple', 5.50, 'Liqueurs'],
      ['Schnapps Peach', 5.50, 'Liqueurs'],
      ['Pimms No.1', 5.80, 'Liqueurs'],
      ['Aperol', 6.00, 'Liqueurs'],
      ['Campari', 6.00, 'Liqueurs'],
      ['Fernet Branca', 6.00, 'Liqueurs'],
      ['Limoncello', 5.80, 'Liqueurs'],
      ['Creme de Menthe', 5.50, 'Liqueurs'],
      ['Creme de Cacao', 5.50, 'Liqueurs'],
      ['Creme de Cassis', 5.50, 'Liqueurs'],
      ['Passoa', 5.80, 'Liqueurs'],
      ['Peach Schnapps', 5.50, 'Liqueurs'],
      ['Melon Liqueur', 5.50, 'Liqueurs'],
      ['Banana Liqueur', 5.50, 'Liqueurs'],
      ['St Germain', 6.50, 'Liqueurs'],
      ['Chartreuse Green', 7.00, 'Liqueurs'],

      // ---- More Spirits (premium) ----
      ['Redbreast 12yo', 8.50, 'Spirits Premium'],
      ['Green Spot', 7.50, 'Spirits Premium'],
      ['Yellow Spot', 9.00, 'Spirits Premium'],
      ['Teeling Small Batch', 6.50, 'Spirits Premium'],
      ['Connemara Peated', 6.50, 'Spirits Premium'],
      ['Glenfiddich 12yo', 8.00, 'Spirits Premium'],
      ['Glenfiddich 15yo', 10.00, 'Spirits Premium'],
      ['Glenlivet 12yo', 8.00, 'Spirits Premium'],
      ['Macallan 12yo', 11.00, 'Spirits Premium'],
      ['Lagavulin 16yo', 12.00, 'Spirits Premium'],
      ['Laphroaig 10yo', 9.00, 'Spirits Premium'],
      ['Talisker 10yo', 9.00, 'Spirits Premium'],
      ['Chivas Regal 12yo', 7.50, 'Spirits Premium'],
      ['Monkey Shoulder', 7.50, 'Spirits Premium'],
      ['Bulleit Bourbon', 6.50, 'Spirits Premium'],
      ['Makers Mark', 6.50, 'Spirits Premium'],
      ['Woodford Reserve', 7.00, 'Spirits Premium'],
      ['Gentleman Jack', 7.00, 'Spirits Premium'],
      ['Grey Goose', 8.00, 'Spirits Premium'],
      ['Belvedere', 7.50, 'Spirits Premium'],
      ['Ciroc', 7.50, 'Spirits Premium'],
      ['Ketel One', 7.00, 'Spirits Premium'],
      ['Titos Vodka', 6.50, 'Spirits Premium'],
      ['Haku Vodka', 7.00, 'Spirits Premium'],
      ['Tanqueray 10', 7.50, 'Spirits Premium'],
      ['Hendricks Orbium', 8.00, 'Spirits Premium'],
      ['Gin Mare', 8.00, 'Spirits Premium'],
      ['Monkey 47', 8.50, 'Spirits Premium'],
      ['Sipsmith', 7.00, 'Spirits Premium'],
      ['Aviation Gin', 7.50, 'Spirits Premium'],
      ['Drumshanbo Gunpowder', 7.50, 'Spirits Premium'],
      ['Havana Club 7yo', 7.00, 'Spirits Premium'],
      ['Bacardi 8yo', 7.00, 'Spirits Premium'],
      ['Kraken Black Spiced', 6.50, 'Spirits Premium'],
      ['Diplomatico Reserva', 8.00, 'Spirits Premium'],
      ['Patron Silver', 8.50, 'Spirits Premium'],
      ['Patron Reposado', 9.00, 'Spirits Premium'],
      ['Don Julio Blanco', 9.00, 'Spirits Premium'],
      ['Don Julio Reposado', 10.00, 'Spirits Premium'],
      ['Hennessy VSOP', 10.00, 'Spirits Premium'],
      ['Remy Martin VSOP', 10.00, 'Spirits Premium'],

      // ---- More Cocktails ----
      ['Mimosa', 8.50, 'Cocktails'],
      ['Bellini', 9.00, 'Cocktails'],
      ['Kir Royale', 9.50, 'Cocktails'],
      ['French 75', 11.00, 'Cocktails'],
      ['Corpse Reviver', 10.50, 'Cocktails'],
      ['Sazerac', 11.00, 'Cocktails'],
      ['Vieux Carre', 11.50, 'Cocktails'],
      ['Last Word', 11.00, 'Cocktails'],
      ['Aviation', 10.50, 'Cocktails'],
      ['Hemingway Daiquiri', 10.50, 'Cocktails'],
      ['Strawberry Mojito', 9.50, 'Cocktails'],
      ['Frozen Margarita', 10.00, 'Cocktails'],
      ['Strawberry Margarita', 10.00, 'Cocktails'],
      ['Tequila Sunrise', 9.50, 'Cocktails'],
      ['Paloma', 9.00, 'Cocktails'],
      ['Cosmopolitan', 9.50, 'Cocktails'],
      ['Pornstar Martini', 11.00, 'Cocktails'],
      ['French Martini', 10.00, 'Cocktails'],
      ['Apple Martini', 10.00, 'Cocktails'],
      ['Lemon Drop Martini', 10.00, 'Cocktails'],

      // ---- More Soft Drinks ----
      ['Monster Energy', 4.00, 'Soft Drinks'],
      ['Lucozade Original', 3.50, 'Soft Drinks'],
      ['Lucozade Sport', 3.50, 'Soft Drinks'],
      ['Powerade', 3.50, 'Soft Drinks'],
      ['Mi Wadi Orange', 2.50, 'Soft Drinks'],
      ['Mi Wadi Blackcurrant', 2.50, 'Soft Drinks'],
      ['Ribena', 2.80, 'Soft Drinks'],
      ['Innocent Smoothie', 4.00, 'Soft Drinks'],
      ['Tropicana Orange', 3.50, 'Soft Drinks'],
      ['Sparkling Elderflower', 3.00, 'Soft Drinks'],
      ['Sparkling Rose Lemonade', 3.00, 'Soft Drinks'],
      ['Fever Tree Tonic', 3.50, 'Soft Drinks'],
      ['Fever Tree Ginger Ale', 3.50, 'Soft Drinks'],
      ['Fever Tree Soda', 3.00, 'Soft Drinks'],
      ['Belvoir Ginger Beer', 3.50, 'Soft Drinks'],
      ['Iced Tea Lemon', 3.00, 'Soft Drinks'],
      ['Iced Tea Peach', 3.00, 'Soft Drinks'],
      ['Vimto', 2.80, 'Soft Drinks'],
      ['Fizzy Vimto', 2.80, 'Soft Drinks'],
      ['San Pellegrino Limonata', 3.20, 'Soft Drinks'],
      ['San Pellegrino Aranciata', 3.20, 'Soft Drinks'],

      // ---- Juices ----
      ['Orange Juice', 2.80, 'Juices'],
      ['Apple Juice', 2.80, 'Juices'],
      ['Cranberry Juice', 2.80, 'Juices'],
      ['Pineapple Juice', 2.80, 'Juices'],
      ['Tomato Juice', 2.80, 'Juices'],
      ['Grapefruit Juice', 2.80, 'Juices'],
      ['Mango Juice', 3.00, 'Juices'],
      ['Passion Fruit Juice', 3.00, 'Juices'],
      ['Pomegranate Juice', 3.20, 'Juices'],
      ['Fresh Orange Juice', 4.00, 'Juices'],
      ['Fresh Apple Juice', 4.00, 'Juices'],
      ['Fresh Carrot Juice', 4.00, 'Juices'],

      // ---- More Hot Drinks ----
      ['Double Espresso', 3.00, 'Hot Drinks'],
      ['Flat White', 3.50, 'Hot Drinks'],
      ['Mocha', 3.80, 'Hot Drinks'],
      ['Macchiato', 3.20, 'Hot Drinks'],
      ['Cortado', 3.20, 'Hot Drinks'],
      ['Decaf Coffee', 3.00, 'Hot Drinks'],
      ['Green Tea', 2.80, 'Hot Drinks'],
      ['Peppermint Tea', 2.80, 'Hot Drinks'],
      ['Camomile Tea', 2.80, 'Hot Drinks'],
      ['Earl Grey', 2.80, 'Hot Drinks'],
      ['Herbal Tea', 2.80, 'Hot Drinks'],
      ['Hot Chocolate', 3.50, 'Hot Drinks'],
      ['White Hot Chocolate', 3.80, 'Hot Drinks'],
      ['Hot Port', 6.50, 'Hot Drinks'],
      ['Baileys Coffee', 7.00, 'Hot Drinks'],
      ['Mulled Wine', 6.50, 'Hot Drinks'],
      ['Chai Latte', 3.80, 'Hot Drinks'],
      ['Matcha Latte', 4.00, 'Hot Drinks'],

      // ---- More Snacks ----
      ['Tayto', 1.80, 'Snacks'],
      ['King Crisps', 1.80, 'Snacks'],
      ['Hunky Dorys', 1.80, 'Snacks'],
      ['Pringles', 2.50, 'Snacks'],
      ['Doritos', 2.50, 'Snacks'],
      ['Salted Cashews', 3.00, 'Snacks'],
      ['Snickers', 1.80, 'Snacks'],
      ['Mars Bar', 1.80, 'Snacks'],
      ['Twix', 1.80, 'Snacks'],
      ['Kit Kat', 1.80, 'Snacks'],
      ['Dairy Milk', 1.80, 'Snacks'],
      ['Galaxy', 1.80, 'Snacks'],
      ['Aero', 1.80, 'Snacks'],
      ['Wispa', 1.80, 'Snacks'],
      ['Flake', 1.80, 'Snacks'],
      ['Crunchie', 1.80, 'Snacks'],
      ['Bounty', 1.80, 'Snacks'],
      ['Twirl', 1.80, 'Snacks'],
      ['Oreo Packet', 2.00, 'Snacks'],
      ['Kinder Bueno', 2.00, 'Snacks'],

      // ---- Starters ----
      ['Soup of the Day', 5.50, 'Starters'],
      ['Vegetable Soup', 5.50, 'Starters'],
      ['Chicken Wings', 8.50, 'Starters'],
      ['BBQ Wings', 8.50, 'Starters'],
      ['Buffalo Wings', 8.50, 'Starters'],
      ['Garlic Bread', 4.50, 'Starters'],
      ['Garlic Bread with Cheese', 5.50, 'Starters'],
      ['Bruschetta', 6.50, 'Starters'],
      ['Nachos', 7.50, 'Starters'],
      ['Loaded Nachos', 9.50, 'Starters'],
      ['Calamari', 8.50, 'Starters'],
      ['Prawn Cocktail', 8.00, 'Starters'],
      ['Smoked Salmon', 9.50, 'Starters'],
      ['Caesar Salad', 9.50, 'Starters'],
      ['Greek Salad', 8.50, 'Starters'],
      ['Caprese Salad', 8.50, 'Starters'],
      ['Goats Cheese Tart', 8.50, 'Starters'],
      ['Onion Rings', 5.50, 'Starters'],
      ['Mozzarella Sticks', 6.50, 'Starters'],
      ['Potato Skins', 6.50, 'Starters'],
      ['Chicken Tenders', 7.50, 'Starters'],
      ['Antipasti Board', 12.00, 'Starters'],

      // ---- Mains ----
      ['Beef Burger', 12.50, 'Mains'],
      ['Chicken Burger', 11.50, 'Mains'],
      ['Fish & Chips', 13.00, 'Mains'],
      ['Bangers & Mash', 12.50, 'Mains'],
      ['Shepherds Pie', 12.50, 'Mains'],
      ['Steak Sandwich', 13.50, 'Mains'],
      ['Chicken Caesar Salad', 11.50, 'Mains'],
      ['Steak (10oz)', 22.00, 'Mains'],
      ['Ribeye Steak (10oz)', 24.00, 'Mains'],
      ['Sirloin Steak (8oz)', 21.00, 'Mains'],
      ['Salmon Fillet', 17.50, 'Mains'],
      ['Sea Bass', 18.50, 'Mains'],
      ['Cod Fillet', 16.50, 'Mains'],
      ['Chicken Curry', 13.50, 'Mains'],
      ['Beef Curry', 14.00, 'Mains'],
      ['Vegetable Curry', 12.00, 'Mains'],
      ['Lasagne', 13.50, 'Mains'],
      ['Spaghetti Bolognese', 12.50, 'Mains'],
      ['Carbonara', 12.50, 'Mains'],
      ['Penne Arrabbiata', 11.50, 'Mains'],
      ['Margherita Pizza', 11.00, 'Mains'],
      ['Pepperoni Pizza', 12.50, 'Mains'],
      ['Vegetarian Pizza', 12.00, 'Mains'],
      ['Hawaiian Pizza', 12.50, 'Mains'],
      ['Chicken Goujons', 11.00, 'Mains'],
      ['Fish Pie', 13.50, 'Mains'],
      ['Cottage Pie', 12.50, 'Mains'],
      ['Lamb Shank', 18.00, 'Mains'],
      ['Duck Breast', 19.00, 'Mains'],
      ['Pork Belly', 16.50, 'Mains'],

      // ---- Desserts ----
      ['Chocolate Brownie', 5.50, 'Desserts'],
      ['Cheesecake', 5.50, 'Desserts'],
      ['Apple Crumble', 5.50, 'Desserts'],
      ['Sticky Toffee Pudding', 6.00, 'Desserts'],
      ['Ice Cream (3 scoops)', 4.50, 'Desserts'],
      ['Ice Cream (1 scoop)', 2.00, 'Desserts'],
      ['Chocolate Fudge Cake', 5.50, 'Desserts'],
      ['Carrot Cake', 5.00, 'Desserts'],
      ['Banoffee Pie', 5.50, 'Desserts'],
      ['Tiramisu', 5.50, 'Desserts'],
      ['Profiteroles', 5.50, 'Desserts'],
      ['Creme Brulee', 6.00, 'Desserts'],
      ['Panna Cotta', 5.50, 'Desserts'],
      ['Fruit Salad', 4.50, 'Desserts'],
      ['Eton Mess', 5.50, 'Desserts'],

      // ---- Sides ----
      ['Chips', 3.50, 'Sides'],
      ['Garlic Chips', 4.00, 'Sides'],
      ['Cheesy Chips', 4.50, 'Sides'],
      ['Mashed Potato', 3.50, 'Sides'],
      ['Roast Potato', 3.50, 'Sides'],
      ['Onion Rings', 3.50, 'Sides'],
      ['Side Salad', 3.50, 'Sides'],
      ['Coleslaw', 2.50, 'Sides'],
      ['Bread & Butter', 2.50, 'Sides'],
      ['Dipping Sauce', 1.00, 'Sides'],
      ['Extra Cheese', 1.00, 'Sides'],
      ['Bacon Strip', 1.50, 'Sides'],
    ];

    // Insert each product only if the name doesn't already exist
    for (final it in items) {
      final name = it[0] as String;
      final existing = await db.query('products',
          where: 'name = ?', whereArgs: [name], limit: 1);
      if (existing.isNotEmpty) continue;

      final catId = catIds[it[2]];
      if (catId == null) continue;

      await db.insert('products', {
        'name': name,
        'price': it[1],
        'category_id': catId,
        'active': 1,
      });
    }
  }
}