import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PastryShopGameApp());
}

class AppColors {
  static const Color background = Color(0xFFFFE2E2);
  static const Color container = Color(0xFFFFEED6);
  static const Color textBorder = Color(0xFF827148);
  static const Color peach = Color(0xFFE8A07C);
  static const Color lavender = Color(0xFFC5B3D3);
  static const Color sage = Color(0xFFA5AF79);
  static const Color card = Color(0xFFFBEFEF);
  static const Color cardBorder = Color(0xFFF5CBCB);
}

class PastryShopGameApp extends StatelessWidget {
  const PastryShopGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastry Shop Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Comic Sans MS', // Fallback playful font
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              color: AppColors.textBorder,
              fontSize: 16,
              fontWeight: FontWeight.bold),
          titleLarge: TextStyle(
              color: AppColors.textBorder,
              fontSize: 24,
              fontWeight: FontWeight.w900),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum Ingredient {
  sponge('Sponge', AppColors.container),
  chocoBase('Choco Base', Color(0xFF6B4E31)),
  matcha('Matcha', AppColors.sage),
  cream('Cream', Colors.white),
  berries('Berries', Color(0xFFD64550)),
  ganache('Ganache', Color(0xFF4A3018)),
  macaron('Macaron', AppColors.lavender),
  cherry('Cherry', Colors.redAccent);

  final String name;
  final Color color;
  const Ingredient(this.name, this.color);
}

class Customer {
  final String id;
  final List<Ingredient> order;
  double patience; // 0.0 to 1.0
  final double patienceDepletionRate;

  Customer({
    required this.id,
    required this.order,
    this.patience = 1.0,
    required this.patienceDepletionRate,
  });
}

class _GameScreenState extends State<GameScreen> {
  List<Ingredient> _currentPlate = [];
  List<Customer> _queue = [];
  int _score = 0;
  Timer? _gameTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _score = 0;
    _currentPlate.clear();
    _queue.clear();
    _spawnCustomer();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // Decrease patience
        for (var customer in _queue) {
          customer.patience -= customer.patienceDepletionRate;
        }
        // Remove angry customers
        _queue.removeWhere((c) => c.patience <= 0);

        // Randomly spawn new customers if queue is not full
        if (_queue.length < 4 && _random.nextDouble() < 0.02) {
          _spawnCustomer();
        }
      });
    });
  }

  void _spawnCustomer() {
    final length = _random.nextInt(3) + 2; // Orders are 2 to 4 layers
    List<Ingredient> order = [];
    for (int i = 0; i < length; i++) {
      order.add(Ingredient.values[_random.nextInt(Ingredient.values.length)]);
    }
    _queue.add(Customer(
      id: UniqueKey().toString(),
      order: order,
      patienceDepletionRate: 0.002 + (_random.nextDouble() * 0.003),
    ));
  }

  void _addIngredient(Ingredient i) {
    setState(() {
      if (_currentPlate.length < 6) {
        _currentPlate.add(i);
      }
    });
  }

  void _clearPlate() {
    setState(() {
      _currentPlate.clear();
    });
  }

  void _serveCustomer(Customer customer) {
    // Check if plate matches order completely
    bool isMatch = _currentPlate.length == customer.order.length;
    if (isMatch) {
      for (int i = 0; i < _currentPlate.length; i++) {
        if (_currentPlate[i] != customer.order[i]) {
          isMatch = false;
          break;
        }
      }
    }

    if (isMatch) {
      setState(() {
        _score += 100 + (customer.order.length * 50);
        _queue.remove(customer);
        _currentPlate.clear();
      });
    } else {
      // Small penalty or visual feedback could be added here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wrong order!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cute Pastry & Dessert Shop', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textBorder)),
        backgroundColor: AppColors.peach,
        elevation: 0,
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Score: $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 800;
            return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _buildQueueArea()),
            ],
          ),
        ),
        Container(width: 4, color: AppColors.textBorder),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: _buildPlateArea()),
              _buildIngredientsArea(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        SizedBox(height: 180, child: _buildQueueArea()),
        Container(height: 4, color: AppColors.textBorder),
        Expanded(child: _buildPlateArea()),
        _buildIngredientsArea(),
      ],
    );
  }

  Widget _buildQueueArea() {
    return Container(
      color: AppColors.container,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Customer Queue', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textBorder)),
          const SizedBox(height: 8),
          Expanded(
            child: _queue.isEmpty 
                ? const Center(child: Text('Waiting for customers...'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _queue.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerCard(_queue[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return GestureDetector(
      onTap: () => _serveCustomer(customer),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.cardBorder, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.cardBorder, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Text('Order:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: customer.order.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: customer.order[i].color,
                      border: Border.all(color: AppColors.textBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.order[i].name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: AppColors.textBorder, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: customer.patience,
              backgroundColor: Colors.grey.shade300,
              color: customer.patience > 0.5 ? AppColors.sage : (customer.patience > 0.25 ? AppColors.peach : Colors.red),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlateArea() {
    return Container(
      color: AppColors.background,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Your Cake', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: 250,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.textBorder, width: 4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _currentPlate.reversed.map((ingredient) {
                return Container(
                  height: 30,
                  width: 150,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: ingredient.color,
                    border: Border.all(color: AppColors.textBorder, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ingredient.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _3DButton(
            text: 'Clear Plate',
            color: Colors.red.shade300,
            onPressed: _clearPlate,
          )
        ],
      ),
    );
  }

  Widget _buildIngredientsArea() {
    return Container(
      color: AppColors.container,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: Ingredient.values.map((i) {
          return _3DButton(
            text: i.name,
            color: i.color,
            onPressed: () => _addIngredient(i),
          );
        }).toList(),
      ),
    );
  }
}

class _3DButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const _3DButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_3DButton> createState() => _3DButtonState();
}

class _3DButtonState extends State<_3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textBorder, width: 2),
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(
                    color: AppColors.textBorder,
                    offset: Offset(0, 4),
                  )
                ],
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textBorder,
          ),
        ),
      ),
    );
  }
}
