import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const GravitySandboxApp());
}

class GravitySandboxApp extends StatelessWidget {
  const GravitySandboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gravity Particle Sandbox',
      theme: ThemeData.dark(useMaterial3: true),
      home: const GravityScreen(),
    );
  }
}

class CosmicParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;

  CosmicParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class GravityScreen extends StatefulWidget {
  const GravityScreen({super.key});

  @override
  State<GravityScreen> createState() => _GravityScreenState();
}

class _GravityScreenState extends State<GravityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<CosmicParticle> _particles = [];

  Offset? _touchPoint;
  bool _isRepelMode = false;
  double _gravityStrength = 1.4;
  Size _canvasSize = Size.zero;

  static const int _particleCount = 160;
  static const List<Color> _palette = [
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.amberAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty || size == Size.zero) return;
    _canvasSize = size;
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        CosmicParticle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          vx: (_random.nextDouble() - 0.5) * 2.5,
          vy: (_random.nextDouble() - 0.5) * 2.5,
          color: _palette[i % _palette.length],
          size: 2.0 + _random.nextDouble() * 2.8,
        ),
      );
    }
  }

  void _explodeCenter() {
    if (_canvasSize == Size.zero) return;
    final cx = _canvasSize.width / 2;
    final cy = _canvasSize.height / 2;
    for (final p in _particles) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 4.0 + _random.nextDouble() * 9.0;
      p.x = cx;
      p.y = cy;
      p.vx = cos(angle) * speed;
      p.vy = sin(angle) * speed;
    }
  }

  void _updatePhysics() {
    if (_canvasSize == Size.zero) return;
    setState(() {
      for (final p in _particles) {
        if (_touchPoint != null) {
          final dx = _touchPoint!.dx - p.x;
          final dy = _touchPoint!.dy - p.y;
          final distSq = max(120.0, dx * dx + dy * dy);
          final dist = sqrt(distSq);

          final force = (_gravityStrength * 260) / distSq;
          final dir = _isRepelMode ? -1.0 : 1.0;

          p.vx += (dx / dist) * force * dir;
          p.vy += (dy / dist) * force * dir;

          // Орбиталық айналу импульсі
          if (!_isRepelMode) {
            p.vx += (-dy / dist) * 0.08 * _gravityStrength;
            p.vy += (dx / dist) * 0.08 * _gravityStrength;
          }
        }

        // Жеңіл ауа кедергісі (damping)
        p.vx *= 0.985;
        p.vy *= 0.985;

        p.x += p.vx;
        p.y += p.vy;

        // Экран шетінен серпілу
        if (p.x < 0) {
          p.x = 0;
          p.vx = p.vx.abs() * 0.8;
        } else if (p.x > _canvasSize.width) {
          p.x = _canvasSize.width;
          p.vx = -p.vx.abs() * 0.8;
        }

        if (p.y < 0) {
          p.y = 0;
          p.vy = p.vy.abs() * 0.8;
        } else if (p.y > _canvasSize.height) {
          p.y = _canvasSize.height;
          p.vy = -p.vy.abs() * 0.8;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Gravity Particle Sandbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _explodeCenter,
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Big Bang Burst',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                _initParticles(size);

                return GestureDetector(
                  onPanStart: (d) =>
                      setState(() => _touchPoint = d.localPosition),
                  onPanUpdate: (d) =>
                      setState(() => _touchPoint = d.localPosition),
                  onPanEnd: (_) => setState(() => _touchPoint = null),
                  onTapDown: (d) =>
                      setState(() => _touchPoint = d.localPosition),
                  onTapUp: (_) => setState(() => _touchPoint = null),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            (_isRepelMode
                                    ? Colors.redAccent
                                    : Colors.cyanAccent)
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CustomPaint(
                        painter: _GravityPainter(
                          particles: _particles,
                          touchPoint: _touchPoint,
                          isRepel: _isRepelMode,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            child: Column(
              children: [
                Text(
                  _touchPoint == null
                      ? 'Touch & drag inside the cosmos to bend gravity'
                      : (_isRepelMode
                            ? 'REPULSION FIELD ACTIVE'
                            : 'SINGULARITY WELL ACTIVE'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: _isRepelMode ? Colors.redAccent : Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Black Hole'),
                      selected: !_isRepelMode,
                      onSelected: (_) => setState(() => _isRepelMode = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Repel Blast'),
                      selected: _isRepelMode,
                      onSelected: (_) => setState(() => _isRepelMode = true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _gravityStrength,
                        min: 0.4,
                        max: 3.0,
                        activeColor: _isRepelMode
                            ? Colors.redAccent
                            : Colors.cyanAccent,
                        onChanged: (v) => setState(() => _gravityStrength = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GravityPainter extends CustomPainter {
  final List<CosmicParticle> particles;
  final Offset? touchPoint;
  final bool isRepel;

  _GravityPainter({
    required this.particles,
    required this.touchPoint,
    required this.isRepel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (touchPoint != null) {
      final wellColor = isRepel ? Colors.redAccent : Colors.cyanAccent;
      final auraPaint = Paint()
        ..color = wellColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(touchPoint!, 28, auraPaint);

      final corePaint = Paint()
        ..color = isRepel ? Colors.redAccent : Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchPoint!, 10, corePaint);

      final ringPaint = Paint()
        ..color = wellColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(touchPoint!, 12, ringPaint);
    }

    for (final p in particles) {
      // Жылдамдық ізі (Velocity vector trail)
      final trailPaint = Paint()
        ..color = p.color.withValues(alpha: 0.35)
        ..strokeWidth = p.size * 0.7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(p.x, p.y),
        Offset(p.x - p.vx * 2.4, p.y - p.vy * 2.4),
        trailPaint,
      );

      final dotPaint = Paint()..color = p.color;
      canvas.drawCircle(Offset(p.x, p.y), p.size, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GravityPainter oldDelegate) => true;
}
